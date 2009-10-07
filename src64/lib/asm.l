# 29aug09abu
# (c) Software Lab. Alexander Burger

# *LittleEndian *Registers picfun picvar optimize

# *FPic *Section *Label *Program *Statement *Instructions *IfStack *DoStack
# "*Mode" "*Modes"

(de *Transfers
   call
   jmp
   jz jeq
   jnz jne
   js
   jns
   jsz
   jnsz
   jc jlt
   jnc jge
   jcz jle
   jncz jgt )

(de *Conditions
   (T jmp . jmp)
   (z jz . jnz)
   (nz jnz . jz)
   (s js . jns)
   (ns jns . js)
   (sz jsz . jnsz)
   (nsz jnsz . jsz)
   (c jc . jnc)
   (nc jnc . jc)
   (cz jcz . jncz)
   (ncz jncz . jcz)
   (eq jz . jnz)
   (ne jnz . jz)
   (lt jc . jnc)
   (le jcz . jncz)
   (gt jncz . jcz)
   (ge jnc . jc) )

(de build ("File" . "Prg")
   (off *Section *IfStack *DoStack)
   (out "File"
      (prinl "/* " (datSym (date)) " */")
      (run "Prg") ) )

(de asm Args
   (put (car Args) 'asm (cdr Args)) )

(de fpic ()
   (on *FPic) )

# Sections
(de section (Fun @Sym)
   (def Fun
      (curry (@Sym) (Lbl Align)
         (unless (== *Section '@Sym)
            (prinl)
            (prinl "   ." '@Sym)
            (setq *Section '@Sym) )
         (prinl)
         (when Align
            (prinl "   .balign  16")
            (do Align
               ((get 'nop 'asm)) ) )
         (when (reg Lbl)
            (quit "Register" Lbl) )
         (when Lbl
            (label (setq *Label Lbl)) )
         (setq *Program
            (make
               (while (and (skip "#") (<> "(" (peek)))
                  (let Atom (read)
                     (cond
                        ((== ': Atom)
                           (link (cons ': (read))) )
                        ((num? Atom)
                           (link (cons ': (pack *Label "_" Atom))) )
                        ((lup *FlowControl Atom)
                           ((get Atom 'asm) (eval (cadr @))) )
                        ((lup *Instructions Atom)
                           (link (cons Atom (mapcar eval (cdr @)))) )
                        (T (quit "Bad instruction" Atom)) ) ) ) ) )
         (when (or *IfStack *DoStack)
            (quit "Unbalanced flow") )
         (cleanUp)
         (setq *Program
            (make
               (for (L *Program L)
                  (ifn (optimize L)
                     (link (pop 'L))
                     (setq L (nth L (inc (car @))))
                     (chain (cdr @)) ) ) ) )
         (for *Statement *Program
            (if (== ': (car *Statement))
               (prinl (cdr *Statement) ':)
               (apply (get (car *Statement) 'asm) (cdr *Statement)) ) ) ) ) )

(section 'data 'data)
(section 'code 'text)

(de cleanUp ()
   (use (L1 L2)
      (while  # Remove duplicate labels
         (seek
            '((L)
               (and
                  (== ': (caar L))
                  (== ': (caadr L))
                  (cond
                     ((= `(char ".") (char (setq L1 (cdar L))))
                        (setq L2 (cdadr L)) )
                     ((= `(char ".") (char (setq L1 (cdadr L))))
                        (setq L2 (cdar L)) ) ) ) )
            *Program )
         (setq *Program
            (mapcan
               '((L)
                  (cond
                     ((<> L1 ((if (atom (cdr L)) cdr cadr) L))
                        (cons L) )
                     ((memq (car L) *Transfers)
                        (cons (list (car L) L2)) ) ) )
               *Program ) ) )
      (while  # Remove jmp-only labels
         (seek
            '((L)
               (and
                  (== ': (car (setq L1 (car L))))
                  (= `(char ".") (char (cdr L1)))
                  (== 'jmp (car (setq L2 (cadr L)))) ) )
            *Program )
         (setq *Program
            (mapcan
               '((L)
                  (unless (== L L1)
                     (cons
                        (if
                           (and
                              (memq (car L) *Transfers)
                              (= (cdr L1) (cadr L)) )
                           (list (car L) (cadr L2))
                           L ) ) ) )
               *Program ) ) ) )
      (setq *Program  # Remove unreachable statements
         (make
            (while *Program
               (when (memq (car (link (pop '*Program))) '(jmp ret eval/ret))
                  (while (and *Program (n== ': (caar *Program)))
                     (pop '*Program) ) ) ) ) )
   (setq *Program  # Remove zero jumps
      (make
         (while *Program
            (let P (pop '*Program)
               (unless
                  (and
                     (memq (car P) (cdr *Transfers))
                     (== ': (caar *Program))
                     (= (cadr P) (cdar *Program)) )
                  (link P) ) ) ) ) )
   (setq *Program  # Toggle inverted jumps
      (make
         (while *Program
            (let P (pop '*Program)
               (ifn
                  (and
                     (memq (car P) (cddr *Transfers))
                     (== 'jmp (caar *Program))
                     (== ': (caadr *Program))
                     (= (cadr P) (cadr (cadr *Program))) )
                  (link P)
                  (link
                     (list
                        (cddr
                           (find
                              '((C) (== (car P) (cadr C)))
                              (cdr *Conditions) ) )
                        (cadr (pop '*Program)) ) ) ) ) ) ) ) )


# Print instruction
(de prinst (Name . @)
   (if (rest)
      (tab (3 -9 0) NIL Name (glue ", " @))
      (tab (3 -9) NIL Name) ) )

# Registers
(de reg (X)
   (cdr (asoq X *Registers)) )

# Operand evaluation
(de operand (X)
   (cond
      ((num? X) X)
      ((sym? X)
         (cond
            ((asoq X *Registers) X)
            ((get X 'equ) @)
            (T X) ) )
      ((asoq (car X) *Registers)
         (cons (car X) (operand (cadr X))) )
      ((memq (car X) '(+ - * */ / % >> & | char hex oct))
         (apply (car X) (mapcar operand (cdr X))) )
      (T (cons (car X) (operand (cadr X)))) ) )

# Constants
(de equ Args
   (def (car Args)
      (put (car Args) 'equ (run (cdr Args) 1)) ) )


# Addressing modes
(de immediate (S F)
   (pack '$ (and F "~") S) )

(de indirect (S N)
   (if N (pack S "+" N) S) )

(de indexed (R N)
   (pack N "(" R ")") )


# Source/Destination addressing mode:
#  1234 -> Immediate
#  NIL  -> Register
#  T    -> Memory
(de "source" (X F)
   (on "*Mode")
   (cond
      ((num? X) (immediate (setq "*Mode" X) F)) # Immediate
      ((reg X) (off "*Mode") @)                 # Register
      ((atom X) (zero "*Mode") (picvar X))      # Direct
      ((atom (car X))
         (cond
            ((cdr X)
               (if (reg (car X))
                  (indexed @ (cdr X))              # Indexed with offset
                  (indirect (car X) (cdr X)) ) )   # Indirect with offset
            ((reg (car X)) (indexed @))                  # Indexed
            (T (indirect (car X))) ) )                   # Indirect
      (T
         (prog1 ("source" (operand (car X)) F)
            (setq "*Mode"
               (conc "*Mode" (cons (cdr X) (fin "*Mode"))) ) ) ) ) )

(de source (F)
   ("source" (operand (read)) F) )

(de sources ()
   (off "*Modes")
   (let Arg (read)
      (if (lst? Arg)
         (mapcar
            '((X)
               (prog1 ("source" (operand X))
                  (queue '"*Modes" "*Mode") ) )
            Arg )
         ("source" (operand Arg)) ) ) )

(de "destination" (X)
   (on "*Mode")
   (cond
      ((reg X) (off "*Mode") @)                 # Register
      ((atom X) (quit "Bad destination" X))     # Immediate, Direct
      ((atom (car X))
         (cond
            ((cdr X)
               (if (reg (car X))
                  (indexed @ (cdr X))              # Register indirect with offset
                  (indirect (car X) (cdr X)) ) )   # Indirect with offset
            ((reg (car X)) (indexed @))            # Register indirect
            (T (indirect (car X))) ) )             # Indirect
      (T
         (prog1 ("destination" (operand (car X)))
            (setq "*Mode"
               (conc "*Mode" (cons (cdr X) (fin "*Mode"))) ) ) ) ) )

(de destination ()
   ("destination" (operand (read))) )

(de destinations ()
   (off "*Modes")
   (mapcar
      '((X)
         (prog1 ("destination" (operand X))
            (queue '"*Modes" "*Mode") ) )
      (read) ) )


# Target addressing mode:
#  NIL -> Absolute
#  0   -> Indexed
#  T   -> Indirect
(de address ()
   (let X (read)
      (off "*Mode")
      (cond
         ((num? X) (pack *Label "_" X))            # Label
         ((reg X) (quit "Bad address" X))          # Register
         ((atom X) (picfun X))                     # Absolute
         ((cdr X) (quit "Bad address" X))
         ((reg (car X)) (zero "*Mode") @)          # Register indirect
         (T (on "*Mode") X) ) ) )                  # Indirect


# Flow control
(balance '*FlowControl
   (quote
      (break (read))
      (continue (read))
      (do)
      (else)
      (end)
      (if (read))
      (loop)
      (until (read))
      (while (read)) ) )

(de flowCondition (Sym Lbl Neg)
   (if ((if Neg cddr cadr) (asoq Sym *Conditions))
      (link (list @ Lbl))
      (quit "Bad condition" Sym) ) )

(de flowLabel ()
   (pack "." (inc (0))) )

(asm if (Sym)
   (flowCondition Sym (push '*IfStack (flowLabel)) T) )

(asm else ()
   (let Lbl (car *IfStack)
      (link
         (list 'jmp (set *IfStack (flowLabel)))
         (cons ': Lbl) ) ) )

(asm end ()
   (link (cons ': (pop '*IfStack))) )

(asm do ()
   (link (cons ': (push '*DoStack (flowLabel)))) )

(asm while (Sym)
   (flowCondition Sym
      (if (pair (car *DoStack))
         (car @)
         (push *DoStack (flowLabel)) )
      T ) )

(asm until (Sym)
   (let X (pop '*DoStack)
      (flowCondition Sym (fin X) T)
      (and (pair X) (link (cons ': (car X)))) ) )

(asm break (Sym)
   (flowCondition Sym
      (if (pair (car *DoStack))
         (car @)
         (push *DoStack (flowLabel)) ) ) )

(asm continue (Sym)
   (flowCondition Sym (fin (car *DoStack))) )

(asm loop ()
   (let X (pop '*DoStack)
      (link (list 'jmp (fin X)))
      (and (pair X) (link (cons ': (car X)))) ) )


# Instruction set
(balance '*Instructions
   (quote
      (add (destination) "*Mode" (source) "*Mode")
      (addc (destination) "*Mode" (source) "*Mode")
      (align (operand (read)))
      (and (destination) "*Mode" (source) "*Mode")
      (ascii (operand (read)))
      (atom (source) "*Mode")
      (begin (operand (read)))
      (big (source) "*Mode")
      (byte (operand (read)))
      (bytes (mapcar operand (read)))
      (cc (address) "*Mode" (sources) "*Modes")
      (call (address) "*Mode")
      (clrc)
      (clrz)
      (cmp (destination) "*Mode" (source) "*Mode")
      (cmp4 (source) "*Mode")
      (cmpm (destination) "*Mode" (source) "*Mode" (source) "*Mode")
      (cmpn (destination) "*Mode" (source) "*Mode" (source) "*Mode")
      (cnt (source) "*Mode")
      (dbg)
      (div (source) "*Mode")
      (drop)
      (eval)
      (eval+)
      (eval/ret)
      (exec (reg (read)))
      (hx2 (read))
      (init)
      (initSym (read) (read) (operand (read)))
      (int)
      (jc (address) "*Mode")
      (jcz (address) "*Mode")
      (jeq (address) "*Mode")
      (jge (address) "*Mode")
      (jgt (address) "*Mode")
      (jle (address) "*Mode")
      (jlt (address) "*Mode")
      (jmp (address) "*Mode")
      (jnc (address) "*Mode")
      (jncz (address) "*Mode")
      (jne (address) "*Mode")
      (jns (address) "*Mode")
      (jnsz (address) "*Mode")
      (jnz (address) "*Mode")
      (js (address) "*Mode")
      (jsz (address) "*Mode")
      (jz (address) "*Mode")
      (:: (read))
      (ld (destination) "*Mode" (source) "*Mode")
      (ld2 (source) "*Mode")
      (ld4 (source) "*Mode")
      (ldc (destination) "*Mode" (source) "*Mode")
      (ldnc (destination) "*Mode" (source) "*Mode")
      (ldnz (destination) "*Mode" (source) "*Mode")
      (ldz (destination) "*Mode" (source) "*Mode")
      (lea (destination) "*Mode" (source) "*Mode")
      (link)
      (memb (source) "*Mode" (source) "*Mode")
      (movm (destination) "*Mode" (source) "*Mode" (source) "*Mode")
      (movn (destination) "*Mode" (source) "*Mode" (source) "*Mode")
      (mset (destination) "*Mode" (source) "*Mode")
      (mul (source) "*Mode")
      (neg (destination) "*Mode")
      (nop)
      (not (destination) "*Mode")
      (nul (source) "*Mode")
      (nul4)
      (null (source) "*Mode")
      (num (source) "*Mode")
      (off (destination) "*Mode" (source T) "*Mode")
      (or (destination) "*Mode" (source) "*Mode")
      (pop (destination) "*Mode")
      (prog (reg (read)))
      (push (source) "*Mode")
      (rcl (destination) "*Mode" (source) "*Mode")
      (rcr (destination) "*Mode" (source) "*Mode")
      (ret)
      (return (operand (read)))
      (rol (destination) "*Mode" (source) "*Mode")
      (ror (destination) "*Mode" (source) "*Mode")
      (set (destination) "*Mode" (source) "*Mode")
      (setc)
      (setz)
      (shl (destination) "*Mode" (source) "*Mode")
      (shr (destination) "*Mode" (source) "*Mode")
      (skip (operand (read)))
      (slen (destination) "*Mode" (source) "*Mode")
      (st2 (destination) "*Mode")
      (st4 (destination) "*Mode")
      (string (operand (read)))
      (sub (destination) "*Mode" (source) "*Mode")
      (subc (destination) "*Mode" (source) "*Mode")
      (sxt)
      (sym (source) "*Mode")
      (test (destination) "*Mode" (source) "*Mode")
      (tuck (source) "*Mode")
      (word (operand (read)))
      (xchg (destination) "*Mode" (destination) "*Mode")
      (xor (destination) "*Mode" (source) "*Mode")
      (zero (source) "*Mode")
      (zxt) ) )


# Directives
(de label (Lbl)
   (prinl "   .global  " Lbl)
   (prinl Lbl ':) )

(asm :: (Lbl)
   (label Lbl) )

(asm align (N)
   (prinst ".balign" N) )

(asm word (N)
   (prinst ".quad" N) )

(asm byte (N)
   (prinst ".byte" N) )

(asm bytes (Lst)
   (prinst ".byte" (glue ", " Lst)) )

(asm hx2 (Lst)
   (prinst ".short" (glue ", " (mapcar hex Lst))) )

(asm ascii (Str)
   (prinst ".ascii " (pack "\"" Str "\"")) )

(asm string (Str)
   (prinst ".string " (pack "\"" Str "\"")) )

(asm skip (N)
   (prinst ".skip" N) )

(asm initSym (Lbl Name Val)
   (setq Name
      (let (N 2  Lst (chop Name)  C)
         (make
            (while (nth Lst 8)
               (let L (mapcar char (cut 8 'Lst))
                  (unless *LittleEndian
                     (setq L (flip L)) )
                  (chain L) ) )
            (let L
               (make
                  (do 7
                     (setq C (char (pop 'Lst)))
                     (link (| N (>> -4 (& 15 C))))
                     (setq N (& 15 (>> 4 C))) )
                  (link N) )
               (unless *LittleEndian
                  (setq L (flip L)) )
               (chain L) ) ) ) )
   (if (nth Name 9)
      (prinst ".quad" ".+20")
      (prinl "   .byte    " (glue ", " Name))
      (off Name) )
   (when Lbl
      (label Lbl) )
   (prinst ".quad" Val)
   (while Name
      (prinl "   .byte    " (glue ", " (cut 8 'Name))) ) )

(de warn (Msg)
   (out 2
      (printsp *Label *Statement)
      (prinl Msg) ) )

# vi:et:ts=3:sw=3
