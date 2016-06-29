# 30may16abu
# (c) Software Lab. Alexander Burger

# *LittleEndian *AlignedCode *Registers optimize

# *FPic *Section *Label *Tags *Map *Program *Statement
# *Instructions *IfStack *DoStack
# "*Mode" "*Modes"

(de *Transfers
   cc call
   jmp
   jz jeq
   jnz jne
   js
   jns
   jsz
   jnsz
   jc jb jx jlt
   jnc jnb jnx jge
   jle
   jgt )

(de *Terminators
   jmp ret throw return eval/ret stop )

(de *RetLabels
   Ret RetEq RetGt RetLt RetNil RetT RetE_E
   ret retEq retGt retLt retNull retNil retT retE_E )

(de *Conditions
   (T jmp . jmp)
   (z jz . jnz)
   (nz jnz . jz)
   (s js . jns)
   (ns jns . js)
   (sz jsz . jnsz)
   (nsz jnsz . jsz)
   (c jc . jnc)
   (b jb . jnb)
   (x jx . jnx)
   (nc jnc . jc)
   (nb jnb . jb)
   (nx jnx . jx)
   (eq jeq . jne)
   (ne jne . jeq)
   (lt jlt . jge)
   (le jle . jgt)
   (gt jgt . jle)
   (ge jge . jlt) )

(de build ("File" "Map" . "Prg")
   (off *Section *Tags *Map *IfStack *DoStack)
   (out "File"
      (prinl "/* " (datSym (date)) " */")
      (prolog "File")
      (run "Prg")
      (epilog "File") )
   (when "Map"
      (out "tags"
         (for Lst
            (group  # (file (line . sym) (line . sym) ..)
               (mapcar
                  '((This)
                     (cons
                        (pack (: src 1) (: src 2))
                        (: src -2)
                        This ) )
                  (idx '*Tags) ) )
            (let Tags
               (in (car Lst)
                  (let (Line 1  Ofs 0)
                     (mapcar
                        '((X)
                           (do (- (car X) Line)
                              (inc 'Ofs (inc (size (line T)))) )
                           (pack
                              `(pack "^J" (char 127))
                              (cdr X)
                              (char 1)
                              (setq Line (car X))
                              ","
                              Ofs ) )
                        (sort (cdr Lst)) ) ) )
               (prinl "^L^J" (car Lst) "," (sum size Tags) Tags) ) ) )
      (out "Map"
         (for Sym (idx '*Map)
            (and
               (sym? (val Sym))
               (; Sym 0 tag)
               (prinl Sym " (" (cdr @) " . \"@src64/" (car @) "\")") ) ) ) ) )

(de asm Args
   (cond
      ((=T (car Args))
         (put (car (setq Args (cdr Args))) 'asm NIL) )
      ((== 'TOS (car Args))
         (put (car (setq Args (cdr Args))) 'TOS T) ) )
   (def (car Args) 'asm (cdr Args)) )

(asm asm (Val)
   (prinl "   " Val) )

(de idxTags (Lbl Src)
   (when Src
      (idx '*Tags (def Lbl 'src @) T) ) )

# Sections
(de section (Fun @Sym)
   (def Fun
      (curry (@Sym) (Lbl Align)
         (newSection '@Sym)
         (and Align (alignSection @))
         (when Lbl
            (and (register Lbl) (quit "Register" Lbl))
            (let Src (file)
               (idxTags Lbl Src)
               (def Lbl 'tag (cdr Src)) )
            (label (setq *Label Lbl) T) )
         (setq *Program
            (make
               (while (and (skip "#") (<> "(" (peek)))
                  (let Atom (read)
                     (cond
                        ((== ': Atom)  # Label
                           (let Lbl (read)
                              (idxTags Lbl (file))
                              (link (cons Atom Lbl)) ) )
                        ((== '? Atom)  # Conditional
                           (unless (eval (read))
                              (while (and (skip "#") (n== '= (read)))) ) )
                        ((== '= Atom))  # Conditional end
                        ((num? Atom)
                           (link (cons ': (pack *Label "_" Atom))) )
                        ((lup *FlowControl Atom)
                           ((; Atom asm) (eval (cadr @))) )
                        ((lup *Instructions Atom)
                           (link (cons Atom (mapcar eval (cdr @)))) )
                        (T (quit "Bad instruction" Atom)) ) ) ) ) )
         (when (or *IfStack *DoStack)
            (quit "Unbalanced flow") )
         (cleanUp)
         # TOS Management
         (or
            (find
               '((S) (== S (caar *Program)))
               '(initMain tos begin) )
            (memq *Label
               (quote
                  restart giveupX finishE
                  errnoEXY errEXYZ dlErrX
                  execErrS doExec doQuit doBye byeE ) )
            (let
               (Nodes (maplist prog *Program)
                  JumpOK
                  (extract
                     '((X)
                        (cond
                           ((and
                                 (== ': (car X))
                                 (or
                                    (= `(char ".") (char (cdr X)))
                                    (format (last (split (chop (cdr X)) "_"))) ) )
                              (cdr X) )
                           ((and
                                 (memq (car X) *Transfers)
                                 (find
                                    '((S) (sub? S (cadr X)))
                                    '("err" "Err" "undefined" "byeE") ) )
                              (cadr X) ) ) )
                     *Program )
                  Hot )
               (let? Flood
                  (flood
                     Nodes
                     '((X)
                        (when
                           (or
                              (== ': (caar X))
                              (and
                                 (memq (caar X) *Transfers)
                                 (not (memq (cadar X) *RetLabels)) )
                              (get (caar X) 'TOS) )
                           (on Hot) )
                        (make
                           (and
                              (memq (caar X) (cddr *Transfers))
                              (assoc (cons ': (cadar X)) Nodes)
                              (link @) )
                           (or
                              (not (cdr X))
                              (and
                                 (memq (caar X) (cdddr *Transfers))
                                 (nor
                                    (member (cadar X) JumpOK)
                                    (and Hot (memq (cadar X) *RetLabels)) ) )
                              (memq (caar X) *Terminators)
                              (and
                                 (== (caar X) ':)
                                 (not (member (cdar X) JumpOK)) )
                              (and
                                 (memq (caadr X) (cddr *Transfers))
                                 (nor
                                    (member (cadadr X) JumpOK)
                                    (and Hot (memq (cadadr X) *RetLabels)) ) )
                              (casq (caadr X)
                                 (jmp (not (member (cadadr X) JumpOK)))
                                 (: (not (member (cdadr X) JumpOK)))
                                 (T (memq @ *Terminators)) )
                              (link (cdr X)) ) ) )
                     (mapcon
                        '((L)
                           (and (get (caar L) 'TOS) (list L)) )
                        *Program ) )
                  (setq *Program
                     (make
                        (and
                           (asoq (car *Program) Flood)
                           (n== 'catch (caar *Program))
                           (link '(++tos)) )
                        (map
                           '((L)
                              (link
                                 (if
                                    (and
                                       (asoq (car L) Flood)
                                       (memq (caar L) (cddr *Transfers))
                                       (memq (cadar L) *RetLabels) )
                                    (list (caar L) (pack (cadar L) "TOS"))
                                    (car L) ) )
                              (cond
                                 ((and
                                       (not (memq (caar L) *Terminators))
                                       (not (asoq (car L) Flood))
                                       (asoq (cadr L) Flood) )
                                    (link '(++tos)) )
                                 ((cdr L)
                                    (and
                                       (asoq (car L) Flood)
                                       (not (asoq (cadr L) Flood))
                                       (n== 'throw (caadr L))
                                       (link '(tos--)) ) )
                                 ((and
                                       (asoq (car L) Flood)
                                       (not (memq (caar L) *Terminators))
                                       (link '(tos--)) ) ) ) )
                           *Program ) ) ) ) ) )
         # Optimization
         (setq *Program
            (make
               (for (L *Program L)
                  (ifn (optimize L)
                     (link (pop 'L))
                     (setq L (nth L (inc (car @))))
                     (chain (cdr @)) ) ) ) )
         # Code Output
         (for *Statement *Program
            (cond
               ((== ': (car *Statement)) (label (cdr *Statement)))
               ((; (car *Statement) asm) (apply @ (cdr *Statement)))
               (T (quit "Instruction not implemented" (car *Statement))) ) ) ) ) )

# (data 'lbl)
# (data 'lbl 0)
(section 'data 'data)

# (code 'lbl)
# (code 'lbl 0)
# (code 'lbl 2)
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
            (when (memq (car (link (pop '*Program))) *Terminators)
               (while (and *Program (n== ': (caar *Program)))
                  (pop '*Program) ) ) ) ) )
   (setq *Program  # Remove zero jumps
      (make
         (while *Program
            (let P (pop '*Program)
               (unless
                  (and
                     (memq (car P) (cddr *Transfers))
                     (== ': (caar *Program))
                     (= (cadr P) (cdar *Program)) )
                  (link P) ) ) ) ) )
   (setq *Program  # Toggle inverted jumps
      (make
         (while *Program
            (let P (pop '*Program)
               (ifn
                  (and
                     (memq (car P) (cdddr *Transfers))
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

# Registers
(de register (S)
   (get *Registers S) )

# Operand evaluation
(de operand (X)
   (cond
      ((num? X) X)
      ((sym? X)
         (cond
            ((asoq X *Registers) X)
            ((; X equ) @)
            (T X) ) )
      ((asoq (car X) *Registers)
         (cons (car X) (operand (cadr X))) )
      ((memq (car X) '(+ - * */ / % >> & | %% pack short char hex oct))
         (apply (car X) (mapcar operand (cdr X))) )
      (T (cons (car X) (operand (cadr X)))) ) )

# Constants
(de %% (N)
   (>> -3 (>> 3 (+ N 7))) )

(de short (N)
   (| 2 (>> -4 N)) )

(de equ Args
   (idxTags (car Args) (file))
   (let Val (run (cdr Args) 1)
      (def (car Args) 'equ Val)
      (def (car Args) Val) ) )


# Source/Destination addressing mode:
#  0    -> Immediate
#  NIL  -> Register
#  T    -> Direct
# (..)  -> Combined
(de "source" (X F)
   (setq X (operand X))
   (cond
      ((num? X)                                 # Immediate
         (zero "*Mode")
         (pack (and F "~") X) )
      ((register X) (off "*Mode") @)            # Register
      ((atom X) (on "*Mode") X)                 # Direct
      ((or (num? (cdr X)) (; (cdr X) equ))
         (prog1
            (cons ("source" (car X) F) @)
            (setq "*Mode" (cons "*Mode" 0)) ) )
      ((cdr X)
         (and (register (cdr X)) (quit "Bad source" X))
         (prog1
            (cons ("source" (car X) F) @)
            (setq "*Mode" (cons "*Mode" T)) ) )
      (T
         (prog1
            (cons ("source" (car X) F))
            (setq "*Mode" (cons "*Mode")) ) ) ) )

(de source (F)
   ("source" (read) F) )

(de sources ()
   (off "*Modes")
   (let Arg (read)
      (if (lst? Arg)
         (mapcan
            '((X)
               (if (and (pair X) (pair (; X 1 equ)))
                  (mapcar
                     '((Y)
                        (prog1
                           ("source" Y)
                           (queue '"*Modes" "*Mode") ) )
                     (append @ (cdr X)) )
                  (prog1
                     (cons ("source" X))
                     (queue '"*Modes" "*Mode") ) ) )
            Arg )
         ("source" Arg) ) ) )

(de "destination" (X F)
   (setq X (operand X))
   (cond
      ((num? X) (quit "Bad destination" X))     # Immediate
      ((register X) (off "*Mode") @)            # Register
      ((atom X)                                 # Direct
         (or F (quit "Bad destination" X))
         (on "*Mode")
         X )
      ((or (num? (cdr X)) (; (cdr X) equ))
         (prog1
            (cons ("destination" (car X) T) @)
            (setq "*Mode" (cons "*Mode" 0)) ) )
      ((cdr X)
         (and (register (cdr X)) (quit "Bad destination" X))
         (prog1
            (cons ("destination" (car X) T) (cdr X))
            (setq "*Mode" (cons "*Mode" T)) ) )
      (T
         (prog1
            (cons ("destination" (car X) T))
            (setq "*Mode" (cons "*Mode")) ) ) ) )

(de destination ()
   ("destination" (read)) )

(de destinations ()
   (off "*Modes")
   (mapcar
      '((X)
         (prog1
            ("destination" X)
            (queue '"*Modes" "*Mode") ) )
      (read) ) )


# Target addressing mode:
#  NIL  -> Absolute
#  0    -> Indexed
# (0)   -> SUBR
#  T    -> Indirect
(de address ()
   (let X (read)
      (off "*Mode")
      (cond
         ((num? X) (pack *Label "_" X))            # Label
         ((register X) (quit "Bad address" X))     # Register
         ((atom X) X)                              # Absolute
         ((and (=T (cadr X)) (register (car X)))   # SUBR
            (setq "*Mode" (0))
            @ )
         ((cdr X) (quit "Bad address" X))
         ((register (car X)) (zero "*Mode") @)     # Register indirect
         (T (on "*Mode") (car X)) ) ) )            # Indirect


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
      (++tos)
      (add (destination) "*Mode" (source) "*Mode")
      (addc (destination) "*Mode" (source) "*Mode")
      (asm (read))
      (align (operand (read)))
      (and (destination) "*Mode" (source) "*Mode")
      (ascii (operand (read)))
      (asciz (operand (read)))
      (atom (source) "*Mode")
      (begin)
      (big (source) "*Mode")
      (byte (operand (read)))
      (bytes (mapcar operand (read)))
      (call (address) "*Mode")
      (catch)
      (cc (address) "*Mode" (sources) "*Modes")
      (clrx)
      (cmp (destination) "*Mode" (source) "*Mode")
      (cmpn (destination) "*Mode" (source) "*Mode" (source) "*Mode")
      (cnt (source) "*Mode")
      (dec (destination) "*Mode")
      (div (source) "*Mode")
      (drop)
      (eq)
      (eval)
      (eval+)
      (eval/ret)
      (exec (register (read)))
      (fixnum)
      (float)
      (func)
      (gt)
      (hx2 (read))
      (inc (destination) "*Mode")
      (initCode)
      (initData)
      (initFun (file) (read) (read) (operand (read)))
      (initLib)
      (initMain)
      (initSym (file) (read) (read) (operand (read)))
      (jb (address) "*Mode")
      (jc (address) "*Mode")
      (jeq (address) "*Mode")
      (jge (address) "*Mode")
      (jgt (address) "*Mode")
      (jle (address) "*Mode")
      (jlt (address) "*Mode")
      (jmp (address) "*Mode")
      (jnb (address) "*Mode")
      (jnc (address) "*Mode")
      (jne (address) "*Mode")
      (jns (address) "*Mode")
      (jnsz (address) "*Mode")
      (jnx (address) "*Mode")
      (jnz (address) "*Mode")
      (js (address) "*Mode")
      (jsz (address) "*Mode")
      (jx (address) "*Mode")
      (jz (address) "*Mode")
      (:: (file) (read))
      (ld (destination) "*Mode" (source) "*Mode")
      (ld2 (source) "*Mode")
      (ld4 (source) "*Mode")
      (ldd)
      (ldf)
      (ldnz (destination) "*Mode" (source) "*Mode")
      (ldz (destination) "*Mode" (source) "*Mode")
      (lea (destination) "*Mode" (source) "*Mode")
      (link)
      (load (destination) "*Mode" (destination) "*Mode" (source) "*Mode")
      (lt)
      (memb (source) "*Mode" (source) "*Mode")
      (movn (destination) "*Mode" (source) "*Mode" (source) "*Mode")
      (mset (destination) "*Mode" (source) "*Mode")
      (mul (source) "*Mode")
      (neg (destination) "*Mode")
      (nop)
      (not (destination) "*Mode")
      (nul (source) "*Mode")
      (nul4)
      (null (source) "*Mode")
      (nulp (source) "*Mode")
      (num (source) "*Mode")
      (off (destination) "*Mode" (source T) "*Mode")
      (or (destination) "*Mode" (source) "*Mode")
      (pop (destination) "*Mode")
      (prog (register (read)))
      (push (source) "*Mode")
      (ret)
      (return)
      (rol (destination) "*Mode" (source) "*Mode")
      (ror (destination) "*Mode" (source) "*Mode")
      (rxl (destination) "*Mode" (source) "*Mode")
      (rxr (destination) "*Mode" (source) "*Mode")
      (save (source) "*Mode" (source) "*Mode" (destination) "*Mode")
      (set (destination) "*Mode" (source) "*Mode")
      (setx)
      (shl (destination) "*Mode" (source) "*Mode")
      (shr (destination) "*Mode" (source) "*Mode")
      (skip (operand (read)))
      (slen (destination) "*Mode" (source) "*Mode")
      (st2 (destination) "*Mode")
      (st4 (destination) "*Mode")
      (std)
      (stf)
      (stop)
      (sub (destination) "*Mode" (source) "*Mode")
      (subb (destination) "*Mode" (source) "*Mode")
      (sym (source) "*Mode")
      (test (destination) "*Mode" (source) "*Mode")
      (throw)
      (tos (destination) "*Mode")
      (tos--)
      (tuck (source) "*Mode")
      (word (operand (read)))
      (xchg (destination) "*Mode" (destination) "*Mode")
      (xor (destination) "*Mode" (source) "*Mode")
      (zxt) ) )


# Directives

(asm :: (Src Lbl)
   (idxTags Lbl Src)
   (label Lbl T) )

(asm initFun (Src Lbl Name Val)
   (initSym Src Lbl Name Val (pack Val (and *AlignedCode "+2"))) )

(asm initSym (Src Lbl Name Val)
   (initSym Src Lbl Name Val Val) )

(de initSym (Src Lbl Name Sym Val)
   (and Lbl (idxTags Lbl Src))
   (idx '*Map (def Name Sym) T)
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
      ((; 'word asm) ".+20")
      ((; 'bytes asm) Name)
      (off Name) )
   (when Lbl
      (label Lbl T) )
   ((; 'word asm) Val)
   (while Name
      ((; 'bytes asm) (cut 8 'Name)) ) )


# Condition code optimizations
(de asmNoCC Args
   (let Sym (intern (pack (car Args) "-"))
      (put (car Args) 'noCC Sym)
      (def Sym 'asm (cdr Args)) ) )

(de useCC Lst
   (for This Lst
      (=: useCC T) ) )

(de chgCC Lst
   (for This Lst
      (=: chgCC T) ) )

(useCC
   ldz ldnz
   addc subb rxl rxr
   jz jeq jnz jne js jns jsz jnsz jc jb jx jlt jnc jnb jnx jge jle jgt )

(chgCC
   movn mset save load
   add sub inc dec not neg and or xor off test shl shr rol ror
   mul div zxt eq gt lt
   cmp cmpn slen memb null nul4 nul cnt big num sym atom
   call cc return
   eval eval+ eval/ret exec prog )

(de noCC (Lst)
   (with (caar Lst)
      (and (: noCC) (not (needCC (cdr Lst))) (: noCC)) ) )

(de needCC (Lst)
   (loop
      (T (; Lst 1 1 useCC) T)
      (T (; Lst 1 1 chgCC))
      (T
         (member (car Lst)
            '((push zscx NIL) (push zsc NIL) (push x NIL)) )
         T )
      (T
         (member (car Lst)
            '((pop zscx NIL) (pop zsc NIL) (pop x NIL)) ) )
      (T
         (or
            (memq (caar Lst) '(ret throw))
            (and
               (== 'jmp (caar Lst))
               (memq (cadar Lst) '(Ret ret)) ) )
         (use (@A @B @Z)
            (match '(@A "_" @B "F" @Z) (chop *Label)) ) )
      (T
         (when (memq (caar Lst) *Transfers)
            (let Lbl (cons ': (cadar Lst))
               (cond
                  ((member Lbl (cddr Lst))
                     (needCC (cdr @)) )
                  ((and (offset Lst *Program) (member Lbl (head (dec @) *Program)))
                     (needCC (cdr @)) ) ) ) )
         T )
      (NIL (setq Lst (cdr Lst))) ) )


# Warning message
(de warn (Msg)
   (out 2
      (printsp *Label *Statement)
      (prinl Msg) ) )

# vi:et:ts=3:sw=3
