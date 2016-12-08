# 22jul16abu
# (c) Software Lab. Alexander Burger

# *Globals

# Architecture
(on *LittleEndian)
(on *AlignedCode)

# Register assignments
(de *Registers
   (A . "x0") (C . "x19") (E . "x20")
   (B . B) (D . D)
   (X . "x21") (Y . "x22") (Z . "x23")
   (Nil . "x24") (TSym . "x25") (StkLimit . "x26")
   (L . "x29") (S . "x28")
   (zscx . zscx) (zsc . zsc) (x . x) )

# A                  x0
# ABI arguments      x1 - x7, x31 (sp)
# Indirect result    x8
# X-bit              x9
# Immediate          x10
# Source temp        x11, x12
# Destination temp   x13, x14
# Temporary          x15, x16, x17, x18
# C, E, X, Y, Z      x19, x20, x21, x22, x23
# Nil                x24
# T                  x25
# StkLimit           x26
# Unused             x27
# S                  x28
# L                  x29
# Return link        x30
# NULL               xzr (x31)

(redef label (Lbl Flg)
   (and Flg (not *FPic) (push '*Globals Lbl))
   (label Lbl Flg) )

(redef code (Lbl Align)
   (when (memq Lbl *RetLabels)
      (prinl)
      (alignSection Align)
      (label (pack Lbl "TOS"))
      (prinst "ldr" "x30" "[x28],8") )
   (code Lbl Align) )

# Debug output
(de comment (Sym . @)
   (when *Dbg
      (prin "   /* " Sym " ")
      (while (args)
         (let Arg (next)
            (printsp
               (recur (Arg)
                  (if (pair Arg)
                     (cons (recurse (car @)) (recurse (cdr @)))
                     (cond
                        ((rassoc Arg *Registers) (car @))
                        ((or (num? Arg) (format Arg)) @)
                        (T (intern Arg)) ) ) ) ) ) )
      (prinl "*/") ) )

# Addressing modes
(de imm? (Src)
   (pre? "#" Src) )

(de imm12 (N)
   (and
      (ge0 N)
      (or
         (>= 4095 N)
         (and (>= 16777215 N) (=0 (& N 4095))) ) ) )

(de imm16 (N)
   (>= 65535 N) )

(de imm64 (N)
   (not (member "1" (member "0" (chop (bin N))))) )

(de reg? (S)
   (or
      (== S 'xzr)
      (and
         (= "x" (car (setq S (chop S))))
         (format (cdr S))
         (>= 30 @) ) ) )

(de reg (Reg Tmp)  #> Register
   (if (reg? Reg) Reg Tmp) )

(de immReg (Reg Num)
   (if (imm64 Num)
      (prinst "mov" Reg Num)
      (let (I 0  N (or (ge0 Num) (- -1 Num)))
         (while (=0 (& 65535 N))
            (setq
               N (>> 16 N)
               I (+ I 16) ) )
         (prinst
            (if (ge0 Num) "movz" "movn")
            Reg
            (& 65535 N)
            (pack "lsl " I) )
         (until (=0 (setq N (>> 16 N)))
            (inc 'I 16)
            (unless (=0 (& 65535 N))
               (prinst
                  "movk"
                  Reg
                  (if (ge0 Num)
                     (& 65535 N)
                     (- `(hex "FFFF") (& 65535 N)) )
                  (pack "lsl " I) ) ) ) ) )
   Reg )

(de ldr (Dst Tmp)  #> Register
   (cond
      ((== 'B Dst) "x0")
      ((reg? Dst) Dst)
      (T (prog1 Tmp (prinst "ldr" @ Dst))) ) )

(de mov (Dst Val C)
   (unless (= Val Dst)
      (cond
         ((== 'B Dst)
            (cond
               ((imm? Val)
                  (prinst "mov" "x10" Val)
                  (prinst "bfm" "x0" "x10" 0 7) )
               ((= "x0" Val))
               ((reg? Val)
                  (prinst "bfm" "x0" Val 0 7) )
               (T
                  (prinst "ldrb" "w15" Val)
                  (prinst "bfm" "x0" "x15" 0 7) ) ) )
         ((reg? Dst)
            (if (and (= "b" C) (reg? Val))
               (prinst "ubfm" Dst Val 0 7)
               (when C
                  (setq Dst (pack (cons "w" (cdr (chop Dst)))))
                  (and (= "w" C) (off C)) )
               (prinst
                  (pack
                     (if (or (imm? Val) (reg? Val)) "mov" "ldr")
                     C )
                  Dst
                  Val ) ) )
         ((imm? Val)
            (prinst "mov" "x10" Val)
            (mov Dst "x10" C) )
         ((== 'B Val)
            (prinst "strb" "w0" Dst) )
         ((reg? Val)
            (cond
               ((== 'B Val) (setq Val "w0"  C "b"))
               (C
                  (setq Val (pack (cons "w" (cdr (chop Val)))))
                  (and (= "w" C) (off C)) ) )
            (prinst (pack "str" C) Val Dst) )
         (T
            (prinst "ldr" "x10" Val)
            (prinst "str" "x10" Dst) ) ) ) )

(de adrp (Sym Reg)
   (if (memq Sym *Globals)
      (prog
         (prinst "adrp" Reg (pack ":got:" Sym))
         (prinst "ldr" Reg (pack "[" Reg ", #:got_lo12:" Sym "]")) )
      (prinst "adrp" Reg Sym)
      (prinst "add" Reg Reg (pack ":lo12:" Sym)) ) )

(de src (Src S Imm? Reg C)  #> Immediate or register
   (cond
      ((=0 S)  # Immediate
         (cond
            ((pre? "~" Src)
               (prinst "mov" "x10" (pack "#-1-" (cdr (chop Src))))
               "x10" )
            ((=0 (setq Src (format Src))) 'xzr)
            ((Imm? Src) (pack "#" Src))
            (T (immReg (reg Reg "x10") Src)) ) )
      ((not S) Src)  # Register
      ((and (=T S) (sub? "-" Src))  # Label difference
         (pack "#" Src) )
      (T
         (setq Reg (reg Reg "x11"))
         (cond
            ((=T S) (adrp Src Reg))  # Direct
            ((not (car S))  # Indexed
               (nond
                  ((=T (cdr S))
                     (mov Reg
                        (cond
                           ((not (cdr Src)) (pack "[" (car Src) "]"))
                           ((>= 256 (cdr Src) -256)
                              (pack "[" (car Src) "," (cdr Src) "]") )
                           (T
                              (prinst "mov" "x12" (cdr Src))
                              (pack "[" (car Src) ",x12]") ) )
                        C ) )
                  ((sub? "-" Src)  # Label difference
                     (prinst "adrp" Reg (cdr Src))
                     (prinst "add" Reg Reg (pack ":lo12:" (cdr Src)))
                     (mov Reg
                        (pack "[" (car Src) "," Reg "]")
                        C ) )
                  (NIL (mov Reg (pack "[" (car Src) ",#" (cdr Src) "]"))) ) )
            ((=T (car S))  # Indirect
               (adrp (car Src) Reg)
               (mov Reg
                  (pack "[" Reg (and (cdr Src) ",") (cdr Src) "]")
                  C ) )
            (T  # Combined
               (src (car Src) (car S))
               (nond
                  ((=T (cdr S))
                     (mov Reg
                        (pack "[x11" (and (cdr Src) ",") (cdr Src) "]")
                        C ) )
                  ((sub? "-" Src)  # Label difference
                     (prinst "adrp" "x12" (cdr Src))
                     (prinst "add" "x12" "x12" (pack ":lo12:" (cdr Src)))
                     (mov Reg "[x12,x11]" C) )
                  (NIL (mov Reg (pack "[x11," (cdr Src) "]"))) ) ) )
         Reg ) ) )

(de lea (Src S Reg)
   (cond
      ((=0 S)  # Immediate
         (quit "Bad immediate operand") )
      ((not S)  # Register
         (prinst "mov" Reg Src) )
      ((=T S)  # Direct
         (adrp Src Reg) )
      ((not (car S))  # Indexed
         (nond
            ((cdr S) (prinst "mov" Reg (car Src)))
            ((=T @)
               (prinst "add" Reg (car Src)
                  (if (imm12 (cdr Src))
                     (cdr Src)
                     (immReg "x11" (cdr Src)) ) ) )
            ((sub? "-" (cdr Src))  # Label difference
               (prinst "adrp" "x11" (cdr Src))
               (prinst "add" Reg "x11" (pack ":lo12:" (cdr Src))) )
            (NIL (prinst "add" Reg (car Src) (cdr Src))) ) )
      ((=T (car S))  # Indirect
         (adrp (car Src) Reg)
         (and (cdr S) (prinst "add" Reg Reg (cdr Src))) )
      (T  # Combined
         (src (car Src) (car S) NIL Reg)
         (when (cdr S)
            (ifn (=T @)
               (prinst "add" Reg Reg (cdr Src))
               (prinst "adrp" "x12" (cdr Src))
               (prinst "add" Reg "x12" (pack ":lo12:" (cdr Src))) ) ) ) ) )

(de dst (Dst D Reg1 Reg2)  #> Register or memory
   (default Reg1 "x13"  Reg2 "x14")
   (cond
      ((=0 D)  # Immediate
         (quit "Bad immediate operand") )
      ((not D) Dst)  # Register
      ((=T D)  # Direct
         (quit "Bad direct operand") )
      ((not (car D))  # Indexed
         (nond
            ((=T (cdr D))
               (cond
                  ((not (cdr Dst)) (pack "[" (car Dst) "]"))
                  ((>= 256 (cdr Dst) -256)
                     (pack "[" (car Dst) "," (cdr Dst) "]") )
                  (T
                     (prinst "mov" Reg1 (cdr Dst))
                     (pack "[" (car Dst) "," Reg1 "]") ) ) )
            ((sub? "-" Dst)  # Label difference
               (prinst "adrp" Reg1 (cdr Dst))
               (prinst "add" Reg1 Reg1 (pack ":lo12:" (cdr Dst)))
               (pack "[" (car Dst) "," Reg1 "]") )
            (NIL (pack "[" (car Dst) ",#" (cdr Dst) "]")) ) )
      ((=T (car D))  # Indirect
         (adrp (car Dst) Reg1)
         (pack "[" Reg1 (and (cdr Dst) ",") (cdr Dst) "]") )
      (T  # Combined
         (src (car Dst) (car D) NIL Reg1)
         (ifn (=T (cdr D))
            (pack "[" Reg1 (and (cdr Dst) ",") (cdr Dst) "]")
            (prinst "adrp" Reg2 (cdr Dst))
            (prinst "add" Reg2 Reg1 (pack ":lo12:" (cdr Dst)))
            (pack "[" Reg2 "," Reg1 "]") ) ) ) )

### Instruction set ###
(de alignSection (Align)
   (if (== 'text *Section)
      (prinst ".balign" 8)
      (prinst ".balign" 16)
      (or (=0 Align) (prinst ".space" Align)) ) )

(asm nop ()
   (comment 'nop)
   (prinst "nop") )

(asm align (N)
   (prinst ".balign" N) )

(asm skip (N)
   (if (== 'data *Section)
      (or (=0 N) (prinst ".space" N))
      (do (/ N 2) (prinst "nop")) ) )

# Move data
(asm ld (Dst D Src S)
   (comment 'ld Dst Src)
   (cond
      ((== 'D Dst)
         (lea Src S "x15")
         (prinst "ldp" "x0" "x19" "[x15]") )
      ((== 'D Src)
         (lea Dst D "x15")
         (prinst "stp" "x0" "x19" "[x15]") )
      (T
         (mov
            (setq Dst (dst Dst D))
            (src Src S imm16 Dst (and (== 'B Dst) "b")) ) ) ) )

(asm ld2 (Src S)
   (comment 'ld2 Src)
   (mov "x0" (dst Src S) "h") )

(asm ld4 (Src S)
   (comment 'ld4 Src)
   (mov "x0" (dst Src S) "w") )

(asm ldz (Dst D Src S)
   (comment 'ldz Dst Src)
   (if (and (reg? Dst) (reg? Src))
      (prinst "csel" Dst Src Dst "eq")
      (prinst "b.ne" "1f")
      (setq Dst (dst Dst D))
      (mov Dst (src Src S imm16 Dst))
      (prinl "1:") ) )

(asm ldnz (Dst D Src S)
   (comment 'ldnz Dst Src)
   (if (and (reg? Dst) (reg? Src))
      (prinst "csel" Dst Src Dst "ne")
      (prinst "b.eq" "1f")
      (setq Dst (dst Dst D))
      (mov Dst (src Src S imm16 Dst))
      (prinl "1:") ) )

(asm lea (Dst D Src S)
   (comment 'lea Dst Src)
   (setq Dst (dst Dst D)  D (reg Dst "x15"))
   (lea Src S D)
   (mov Dst D) )

(asm st2 (Dst D)
   (comment 'st2 Dst)
   (mov (dst Dst D) "x0" "h") )

(asm st4 (Dst D)
   (comment 'st4 Dst)
   (mov (dst Dst D) "x0" "w") )

(asm xchg (Dst D Dst2 D2)
   (comment 'xchg Dst Dst2)
   (setq Dst (dst Dst D)  Dst2 (dst Dst2 D2 "x17" "x18"))
   (mov "x15" (ldr Dst "x15"))
   (if (== 'B Dst)
      (prog
         (mov "x0" Dst2 "b")
         (mov Dst2 "x15" "b") )
      (mov Dst Dst2)
      (mov Dst2 "x15") ) )

(asm movn (Dst D Src S Cnt C)
   (comment 'movn Dst Src Cnt)
   (lea Dst D "x1")
   (lea Src S "x2")
   (mov "x10" (src Cnt C imm16 "x10"))
   (prinl "1:")
   (prinst "ldrb" "w3" "[x2],1")  # Byte from 'src'
   (prinst "strb" "w3" "[x1],1")  # store in 'dst'
   (prinst "subs" "x10" "x10" "#1")  # Decrement 'cnt'
   (prinst "b.ne" "1b") )

(asm mset (Dst D Cnt C)
   (comment 'mset Dst Cnt)
   (lea Dst D "x1")
   (mov "x10" (src Cnt C imm16 "x10"))
   (prinl "1:")
   (prinst "strb" "w0" "[x1],1")  # Store B in 'dst'
   (prinst "subs" "x10" "x10" "#1")  # Decrement 'cnt'
   (prinst "b.ne" "1b") )

(asm save (Src S End E Dst D)
   (comment 'save Src End Dst)
   (lea Dst D "x1")
   (lea Src S "x2")
   (lea End E "x3")
   (prinl "1:")
   (prinst "ldr" "x4" "[x2],8")  # Word from 'src'
   (prinst "str" "x4" "[x1],8")  # store in 'dst'
   (prinst "cmp" "x2" "x3")  # Done?
   (prinst "b.ne" "1b") )

(asm load (Dst D End E Src S)
   (comment 'load Dst End Src)
   (lea Dst D "x1")
   (lea Src S "x2")
   (lea End E "x3")
   (prinl "1:")
   (prinst "ldr" "x4" "[x2],8")  # Word from 'src'
   (prinst "str" "x4" "[x1],8")  # store in 'dst'
   (prinst "cmp" "x1" "x3")  # Done?
   (prinst "b.ne" "1b") )

# Arithmetics
# add
(de addAsm (CC Dst D Src S)
   (comment 'add Dst Src)
   (cond
      ((== 'D Dst)
         (cond
            ((=0 S)  # Immediate
               (prinst "adds" "x0" "x0" (pack "#" Src)) )
            ((not S)  # Register
               (prinst "adds" "x0" "x0" Src) )
            (T (prinst "adds" "x0" "x0" (src Src S imm12))) )
         (prinst (if CC "adcs" "adc") "x19" "x19" 'xzr) )
      (T
         (setq Dst (dst Dst D))
         (let D (ldr Dst "x15")
            (prinst (if CC "adds" "add") D D (src Src S imm12))
            (mov Dst D) ) ) ) )

(asm add (Dst D Src S)
   (addAsm T Dst D Src S) )

(asmNoCC add (Dst D Src S)
   (addAsm NIL Dst D Src S) )

# addc
(de addcAsm (CC Dst D Src S)
   (comment 'addc Dst Src)
   (cond
      ((== 'D Dst)
         (cond
            ((=0 S)  # Immediate
               (prinst "adcs" "x0" "x0" (pack "#" Src)) )
            ((not S)  # Register
               (prinst "adcs" "x0" "x0" Src) )
            (T (prinst "adcs" "x0" "x0" (src Src S imm12))) )
         (prinst (if CC "adcs" "adc") "x19" "x19" 'xzr) )
      (T
         (setq Dst (dst Dst D))
         (let D (ldr Dst "x15")
            (prinst (if CC "adcs" "adc") D D (src Src S imm12))
            (mov Dst D) ) ) ) )

(asm addc (Dst D Src S)
   (addcAsm T Dst D Src S) )

(asmNoCC addc (Dst D Src S)
   (addcAsm NIL Dst D Src S) )

# sub
(de subAsm (CC Dst D Src S)
   (comment 'sub Dst Src)
   (setq Dst (dst Dst D))
   (let D (ldr Dst "x15")
      (prinst (if CC "subs" "sub") D D (src Src S imm12))
      (mov Dst D) ) )

(asm sub (Dst D Src S)
   (subAsm T Dst D Src S) )

(asmNoCC sub (Dst D Src S)
   (subAsm NIL Dst D Src S) )

# subb
(de subbAsm (CC Dst D Src S)
   (comment 'subb Dst Src)
   (setq Dst (dst Dst D))
   (let D (ldr Dst "x15")
      (prinst "sbcs" D D (src Src S imm12))
      (mov Dst D) ) )

(asm subb (Dst D Src S)
   (subbAsm T Dst D Src S) )

(asmNoCC subb (Dst D Src S)
   (subbAsm NIL Dst D Src S) )

# inc
(de incAsm (CC Dst D)
   (comment 'inc Dst)
   (setq Dst (dst Dst D))
   (let D (ldr Dst "x15")
      (prinst (if CC "adds" "add") D D "#1")
      (mov Dst D) ) )

(asm inc (Dst D)
   (incAsm T Dst D) )

(asmNoCC inc (Dst D)
   (incAsm NIL Dst D) )

# dec
(de decAsm (CC Dst D)
   (comment 'dec Dst)
   (setq Dst (dst Dst D))
   (let D (ldr Dst "x15")
      (prinst (if CC "subs" "sub") D D "#1")
      (mov Dst D) ) )

(asm dec (Dst D)
   (decAsm T Dst D) )

(asmNoCC dec (Dst D)
   (decAsm NIL Dst D) )

# not
(asm not (Dst D)
   (comment 'not Dst)
   (setq Dst (dst Dst D))
   (if (== 'B Dst)
      (prinst "eor" "x0" "x0" "#255")
      (let D (ldr Dst "x15")
         (prinst "eon" D D 'xzr)
         (mov Dst D) ) ) )

# neg
(de negAsm (CC Dst D)
   (comment 'neg Dst)
   (setq Dst (dst Dst D))
   (let D (ldr Dst "x15")
      (prinst (if CC "negs" "neg") D D)
      (mov Dst D) ) )

(asm neg (Dst D)
   (negAsm T Dst D) )

(asmNoCC neg (Dst D)
   (negAsm NIL Dst D) )

# and
(de andAsm (CC Dst D Src S)
   (comment 'and Dst Src)
   (setq Dst (dst Dst D))
   (cond
      ((== 'B Dst)
         (prinst (if CC "ands" "and") "x0" "x0" (src Src S imm64 NIL "b")) )
      ((== 'B Src)
         (mov "x15" Dst "b")
         (prinst (if CC "ands" "and") "x15" "x15" "x0")
         (mov Dst "x15" "b") )
      (T
         (let D (ldr Dst "x15")
            (prinst (if CC "ands" "and") D D (src Src S imm64))
            (mov Dst D) ) ) ) )

(asm and (Dst D Src S)
   (andAsm T Dst D Src S) )

(asmNoCC and (Dst D Src S)
   (andAsm NIL Dst D Src S) )

# or
(de orAsm (CC Dst D Src S)
   (comment 'or Dst Src)
   (setq Dst (dst Dst D))
   (cond
      ((== 'B Dst)
         (prinst "orr" "x0" "x0" (src Src S imm64 NIL "b")) )
      ((== 'B Src)
         (if (reg? Dst)
            (prog
               (mov "x15" "x0" "b")
               (prinst "orr" Dst Dst "x0") )
            (mov "x15" Dst "b")
            (prinst "orr" "x15" "x15" "x0")
            (mov Dst "x15" "b") ) )
      (T
         (setq Src (src Src S imm64))
         (let D (ldr Dst "x15")
            (prinst "orr" D D Src)
            (and CC (prinst "ands" 'xzr D D))
            (mov Dst D) ) ) ) )

(asm or (Dst D Src S)
   (orAsm T Dst D Src S) )

(asmNoCC or (Dst D Src S)
   (orAsm NIL Dst D Src S) )

# xor
(de xorAsm (CC Dst D Src S)
   (comment 'xor Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm64))
   (let D (ldr Dst "x15")
      (if (== 'B Dst)
         (prinst "eor" "x0" "x0" Src)
         (prinst "eor" D D Src)
         (and CC (prinst "ands" 'xzr D D))
         (mov Dst D) ) ) )

(asm xor (Dst D Src S)
   (xorAsm T Dst D Src S) )

(asmNoCC xor (Dst D Src S)
   (xorAsm NIL Dst D Src S) )

# off
(de offAsm (CC Dst D Src S)
   (comment 'off Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm64))
   (let D (ldr Dst "x15")
      (if (== 'B Dst)
         (prinst (if CC "ands" "and") "x0" "x0" Src)
         (prinst (if CC "ands" "and") D D Src)
         (mov Dst D) ) ) )

(asm off (Dst D Src S)
   (offAsm T Dst D Src S) )

(asmNoCC off (Dst D Src S)
   (offAsm NIL Dst D Src S) )

# test
(asm test (Dst D Src S)
   (comment 'test Dst Src)
   (setq Dst (dst Dst D))
   (cond
      ((== 'B Dst)
         (mov "x15" "x0" "b")
         (prinst "ands" 'xzr "x15" (src Src S imm64 NIL "b")) )
      ((== 'B Src)
         (mov "x15" "x0" "b")
         (mov "x16" Dst "b")
         (prinst "ands" 'xzr "x16" "x15") )
      (T
         (prinst "ands" 'xzr (ldr Dst "x15") (src Src S imm64)) ) ) )

# shl
(de shlAsm (CC Dst D Src S)
   (comment 'shl Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (let D (ldr Dst "x15")
      (cond
         ((imm? Src)
            (when CC
               (let N (pack "#64-" (cdr (chop Src)))
                  (prinst "sbfm" "x9" D N N) ) ) )
         ((== 'B Dst)
            (mov "x15" "x0" "b")
            (setq D "x15") )
         ((== 'B Src)
            (mov "x16" "x0" "b")
            (setq Src "x16") ) )
      (prinst "lsl" D D Src)
      (and CC (prinst "ands" 'xzr D D))
      (mov Dst D) ) )

(asm shl (Dst D Src S)
   (shlAsm T Dst D Src S) )

(asmNoCC shl (Dst D Src S)
   (shlAsm NIL Dst D Src S) )

# shr
(de shrAsm (CC Dst D Src S)
   (comment 'shr Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (let D (ldr Dst "x15")
      (cond
         ((imm? Src)
            (when CC
               (let N (pack Src "-1")
                  (prinst "sbfm" "x9" D N N) ) ) )
         ((== 'B Dst)
            (mov "x15" "x0" "b")
            (setq D "x15") )
         ((== 'B Src)
            (mov "x16" "x0" "b")
            (setq Src "x16") ) )
      (prinst "lsr" D D Src)
      (and CC (prinst "ands" 'xzr D D))
      (mov Dst D) ) )

(asm shr (Dst D Src S)
   (shrAsm T Dst D Src S) )

(asmNoCC shr (Dst D Src S)
   (shrAsm NIL Dst D Src S) )

# rol
(asm rol (Dst D Src S)
   (comment 'rol Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (if (imm? Src)
      (let D (ldr Dst "x15")
         (prinst "ror" D D (pack "#64-" (cdr (chop Src))))
         (mov Dst D) )
      (quit "Non-immediate 'rol' not available") ) )

# ror
(asm ror (Dst D Src S)
   (comment 'ror Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (let D (ldr Dst "x15")
      (prinst "ror" D D Src)
      (mov Dst D) ) )

# rxl
(de rxlAsm (CC Dst D Src S)
   (comment 'rxl Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (if (imm? Src)
      (let (N (pack "#64-" (cdr (chop Src)))  D (ldr Dst "x15"))
         (prinst "mov" "x16" D)
         (prinst "bfm" "x9" D 1 63)
         (prinst "extr" D D "x9" N)
         (and CC (prinst "sbfm" "x9" "x16" N N))
         (mov Dst D) )
      (quit "Non-immediate 'rxl' not available") ) )

(asm rxl (Dst D Src S)
   (rxlAsm T Dst D Src S) )

(asmNoCC rxl (Dst D Src S)
   (rxlAsm NIL Dst D Src S) )

# rxr
(de rxrAsm (CC Dst D Src S)
   (comment 'rxr Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (if (imm? Src)
      (let (N (pack Src "-1")  D (ldr Dst "x15"))
         (prinst "mov" "x16" D)
         (prinst "bfm" "x9" D 1 63)
         (prinst "extr" D D "x9" N)
         (and CC (prinst "sbfm" "x9" "x16" N N))
         (mov Dst D) )
      (quit "Non-immediate 'rxr' not available") ) )

(asm rxr (Dst D Src S)
   (rxrAsm T Dst D Src S) )

(asmNoCC rxr (Dst D Src S)
   (rxrAsm NIL Dst D Src S) )

# mul
(asm mul (Src S)
   (comment 'mul Src)
   (when (or (= "x19" Src) (imm? (setq Src (src Src S imm16))))
      (mov "x15" Src)
      (setq Src "x15") )
   (prinst "umulh" "x19" "x0" Src)
   (prinst "mul" "x0" "x0" Src) )

# div
(asm TOS div (Src S)
   (comment 'div Src)
   (mov "x1" (src Src S imm16 "x1"))
   (prinst "bl" "div") )

# zxt
(asm zxt ()  # 8 bit -> 64 bit
   (comment 'zxt)
   (prinst "ubfm" "x0" "x0" 0 7) )

# eq
(asm eq ()
   (comment 'eq)
   (prinst "cmp" 'xzr 'xzr) )

# gt
(asm gt ()
   (comment 'gt)
   (prinst "cmp" "x28" 0) )

# lt
(asm lt ()
   (comment 'lt)
   (prinst "cmp" "x28" -1) )

# setx
(asm setx ()
   (comment 'setx)
   (prinst "mov" "x9" -1) )

# clrx
(asm clrx ()
   (comment 'clrx)
   (prinst "mov" "x9" 0) )

# Comparisons
(asm cmp (Dst D Src S)
   (comment 'cmp Dst Src)
   (setq Dst (dst Dst D))
   (cond
      ((== 'B Dst)
         (mov "x15" "x0" "b")
         (ifn (reg? Src)
            (prinst "cmp" "x15" (src Src S imm12 NIL "b"))
            (mov "x16" Src "b")
            (prinst "cmp" "x15" "x16") ) )
      ((== 'B Src)
         (mov "x15" "x0" "b")
         (mov "x16" Dst "b")
         (prinst "cmp" "x16" "x15") )
      (T
         (when (and (= Dst "x28") (= Src '("x26")))  # cmp S (StkLimit)
            (prinst "sub" "x8" "x28" "#4096")
            (prinst "cmp" 'sp "x8")
            (prinst "b.lo" "1f")
            (prinst "and" "x8" "x8" "#~15")
            (prinst "mov" 'sp "x8")
            (prinl "1:") )
         (prinst "cmp" (ldr Dst "x15") (src Src S imm12)) ) ) )

(asm cmpn (Dst D Src S Cnt C)
   (comment 'cmpn Dst Src Cnt)
   (lea Dst D "x1")
   (lea Src S "x2")
   (mov "x10" (src Cnt C imm16 "x10"))
   (prinl "1:")
   (prinst "ldrb" "w3" "[x1],1")  # Bytes from 'dst'
   (prinst "ldrb" "w4" "[x2],1")  # and 'src'
   (prinst "cmp" "w3" "w4")  # Same?
   (prinst "b.ne" "2f")  # No: Return 'ne'
   (prinst "subs" "x10" "x10" "#1")  # Decrement 'cnt'
   (prinst "b.ne" "1b")
   (prinl "2:") )

(asm slen (Dst D Src S)
   (comment 'slen Dst Src)
   (setq Dst (dst Dst D))
   (let D (reg Dst "x1")
      (lea Src S "x2")
      (prinst "mov" D "#-1")
      (prinl "1:")
      (prinst "add" D D "#1")
      (prinst "ldrb" "w3" (pack "[x2],1"))  # Byte from 'src'
      (prinst "cbnz" "w3" "1b")
      (mov Dst D) ) )

(asm memb (Src S Cnt C)
   (comment 'memb Src Cnt)
   (prinst "ubfm" "w1" "w0" 0 7)
   (lea Src S "x2")
   (mov "x10" (src Cnt C imm16 "x10"))
   (prinl "1:")
   (prinst "subs" "x10" "x10" "#1")  # Decrement 'cnt'
   (prinst "b.cc" "2f")  # Return 'ne' if done
   (prinst "ldrb" "w3" (pack "[x2],1"))  # Byte from 'src'
   (prinst "cmp" "w3" "w1")  # Same?
   (prinst "b.ne" "1b")  # No
   (unless S (prinst "mov" Src "x2"))
   (unless C (prinst "mov" Cnt "x10"))
   (prinl "2:") )


(asm null (Src S)
   (comment 'null Src)
   (prinst "cmp" (src Src S) 0) )

(asm null/ldz (Src S Dst D Src2 S2)  # optimize
   (comment 'null Src "--" "ldz" Dst Src2)
   (prinst "cbnz" (src Src S) "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )

(asm null/ldnz (Src S Dst D Src2 S2)  # optimize
   (comment 'null Src "--" "ldnz" Dst Src2)
   (prinst "cbz" (src Src S) "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )


(asm nulp (Src S)
   (comment 'nulp Src)
   (prinst "cmp" (src Src S) 0) )

(asm nulp/jz (Src S Adr A)  # optimize
   (comment 'nulp Src "--" "jz" Adr)
   (prinst "cbz" (src Src S) Adr) )

(asm nulp/ldz (Src S Dst D Src2 S2)  # optimize
   (comment 'nulp Src "--" "ldz" Dst Src2)
   (prinst "cbnz" (src Src S) "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )

(asm nulp/jnz (Src S Adr A)
   (comment 'nulp Src "--" "jnz" Adr)
   (prinst "cbnz" (src Src S) Adr) )

(asm nulp/ldnz (Src S Dst D Src2 S2)  # optimize
   (comment 'nulp Src "--" "ldnz" Dst Src2)
   (prinst "cbz" (src Src S) "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )


(asm nul4 ()
   (comment 'nul4)
   (prinst "cmp" "w0" 0) )

(asm nul4/jz (Adr A)  # optimize
   (comment 'nul4 "--" "jz" Adr)
   (prinst "cbz" "w0" Adr) )

(asm nul4/ldz (Dst D Src2 S2)  # optimize
   (comment 'nul4 "--" "ldz" Dst Src2)
   (prinst "cbnz" "w0" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )

(asm nul4/jnz (Adr A)
   (comment 'nul4 "--" "jnz" Adr)
   (prinst "cbnz" "w0" Adr) )

(asm nul4/ldnz (Dst D Src2 S2)  # optimize
   (comment 'nul4 "--" "ldnz" Dst Src2)
   (prinst "cbz" "w0" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )


# Byte addressing
(asm set (Dst D Src S)
   (comment 'set Dst Src)
   (setq Dst (dst Dst D)  Src (src Src S imm12))
   (mov Dst Src "b") )


(asm nul (Src S)
   (comment 'nul Src)
   (when (== 'B (setq Src (src Src S NIL NIL "b")))
      (prinst "ubfm" (setq Src "x11") "x0" 0 7) )
   (prinst "cmp" Src 0) )

(asm nul/jz (Src S Adr A)  # optimize
   (comment 'nul Src "--" "jz" Adr)
   (when (== 'B (setq Src (src Src S NIL NIL "b")))
      (prinst "ubfm" (setq Src "x11") "x0" 0 7) )
   (prinst "cbz" Src Adr) )

(asm nul/jnz (Src S Adr A)
   (comment 'nul Src "--" "jnz" Adr)
   (when (== 'B (setq Src (src Src S NIL NIL "b")))
      (prinst "ubfm" (setq Src "x11") "x0" 0 7) )
   (prinst "cbnz" Src Adr) )


# Types
(asm cnt (Src S)
   (comment 'cnt Src)
   (prinst "ands" 'xzr (src Src S NIL NIL "b") "#0x02") )

(asm cnt/jz (Src S Adr A)  # optimize
   (comment 'cnt Src "--" "jz" Adr)
   (prinst "tbz" (src Src S NIL NIL "b") "#1" Adr) )

(asm cnt/ldz (Src S Dst D Src2 S2)  # optimize
   (comment 'cnt Src "--" "ldz" Dst Src2)
   (prinst "tbnz" (src Src S NIL NIL "b") "#1" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )

(asm cnt/jnz (Src S Adr A)
   (comment 'cnt Src "--" "jnz" Adr)
   (prinst "tbnz" (src Src S NIL NIL "b") "#1" Adr) )

(asm cnt/ldnz (Src S Dst D Src2 S2)  # optimize
   (comment 'cnt Src "--" "ldnz" Dst Src2)
   (prinst "tbz" (src Src S NIL NIL "b") "#1" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )


(asm big (Src S)
   (comment 'big Src)
   (prinst "ands" 'xzr (src Src S NIL NIL "b") "#0x04") )

(asm big/jz (Src S Adr A)  # optimize
   (comment 'big Src "--" "jz" Adr)
   (prinst "tbz" (src Src S NIL NIL "b") "#2" Adr) )

(asm big/ldz (Src S Dst D Src2 S2)  # optimize
   (comment 'big Src "--" "ldz" Dst Src2)
   (prinst "tbnz" (src Src S NIL NIL "b") "#2" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )

(asm big/jnz (Src S Adr A)
   (comment 'big Src "--" "jnz" Adr)
   (prinst "tbnz" (src Src S NIL NIL "b") "#2" Adr) )

(asm big/ldnz (Src S Dst D Src2 S2)  # optimize
   (comment 'big Src "--" "ldnz" Dst Src2)
   (prinst "tbz" (src Src S NIL NIL "b") "#2" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )


(asm num (Src S)
   (comment 'num Src)
   (prinst "ands" 'xzr (src Src S NIL NIL "b") "#0x06") )


(asm sym (Src S)
   (comment 'sym Src)
   (prinst "ands" 'xzr (src Src S NIL NIL "b") "#0x08") )

(asm sym/jz (Src S Adr A)  # optimize
   (comment 'sym Src "--" "jz" Adr)
   (prinst "tbz" (src Src S NIL NIL "b") "#3" Adr) )

(asm sym/ldz (Src S Dst D Src2 S2)  # optimize
   (comment 'sym Src "--" "ldz" Dst Src2)
   (prinst "tbnz" (src Src S NIL NIL "b") "#3" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )

(asm sym/jnz (Src S Adr A)
   (comment 'sym Src "--" "jnz" Adr)
   (prinst "tbnz" (src Src S NIL NIL "b") "#3" Adr) )

(asm sym/ldnz (Src S Dst D Src2 S2)  # optimize
   (comment 'sym Src "--" "ldnz" Dst Src2)
   (prinst "tbz" (src Src S NIL NIL "b") "#3" "1f")
   (setq Dst (dst Dst D))
   (mov Dst (src Src2 S2 imm16 Dst))
   (prinl "1:") )


(asm atom (Src S)
   (comment 'atom Src)
   (prinst "ands" 'xzr (src Src S NIL NIL "b") "#0x0E") )

# Flow control
(asm ++tos ()
   (comment '++tos)
   (prinst "str" "x30" "[x28,-8]!") )

(asm tos-- ()
   (comment 'tos--)
   (prinst "ldr" "x30" "[x28],8") )

(asm TOS call (Adr A)
   (comment 'call Adr)
   (nond
      (A  # Absolute
         (prinst "bl" Adr) )
      ((=T A)
         (if (=0 A)
            (prinst "blr" Adr)
            (prinst "sub" "x1" Adr "#2")  # SUBR
            (prinst "blr" "x1") ) )
      (NIL  # Indirect
         (prinst "ldr" "x1" (pack "[" (src Adr A NIL NIL "x1") "]"))
         (prinst "blr" "x1") ) ) )

(asm jmp (Adr A)
   (comment 'jmp Adr)
   (nond
      (A  # Absolute
         (prinst "b" Adr) )
      ((=T A)
         (if (=0 A)
            (prinst "br" Adr)
            (prinst "sub" "x1" Adr "#2")  # SUBR
            (prinst "br" "x1") ) )
      (NIL  # Indirect
         (prinst "ldr" "x1" (pack "[" (src Adr A NIL NIL "x1") "]"))
         (prinst "br" "x1") ) ) )

(asm tos (Dst D)
   (comment 'tos Dst)
   (setq Dst (dst Dst D))
   (mov Dst "x30") )

(de _jmp (Opc Opc2 Reg)
   (ifn A
      (if Reg
         (prinst Opc Reg Adr)
         (prinst Opc Adr) )
      (if Reg
         (prinst Opc2 Reg "1f")
         (prinst Opc2 "1f") )
      (ifn (=T A)
         (if (=0 A)
            (prinst "br" Adr)
            (prinst "sub" "x1" Adr "#2")  # SUBR
            (prinst "br" "x1") )
         (prinst "ldr" "x1" (pack "[" (src Adr A NIL NIL "x1") "]"))
         (prinst "br" "x1") )
      (prinl "1:") ) )

(asm jz (Adr A)
   (comment 'jz Adr)
   (_jmp "b.eq" "b.ne") )

(asm jeq (Adr A)
   (comment 'jeq Adr)
   (_jmp "b.eq" "b.ne") )

(asm jnz (Adr A)
   (comment 'jnz Adr)
   (_jmp "b.ne" "b.eq") )

(asm jne (Adr A)
   (comment 'jne Adr)
   (_jmp "b.ne" "b.eq") )

(asm js (Adr A)
   (comment 'js Adr)
   (_jmp "b.mi" "b.pl") )

(asm jns (Adr A)
   (comment 'jns Adr)
   (_jmp "b.pl" "b.mi") )

(asm jsz (Adr A)
   (comment 'jsz Adr)
   (_jmp "b.le" "b.gt") )

(asm jnsz (Adr A)
   (comment 'jnsz Adr)
   (_jmp "b.gt" "b.le") )

(asm jc (Adr A)
   (comment 'jc Adr)
   (_jmp "b.cs" "b.cc") )

(asm jb (Adr A)
   (comment 'jb Adr)
   (_jmp "b.cc" "b.cs") )

(asm jx (Adr A)
   (comment 'jx Adr)
   (_jmp "cbnz" "cbz" "x9") )

(asm jlt (Adr A)
   (comment 'jlt Adr)
   (_jmp "b.cc" "b.cs") )

(asm jnc (Adr A)
   (comment 'jnc Adr)
   (_jmp "b.cc" "b.cs") )

(asm jnb (Adr A)
   (comment 'jnb Adr)
   (_jmp "b.cs" "b.cc") )

(asm jnx (Adr A)
   (comment 'jnx Adr)
   (_jmp "cbz" "cbnz" "x9") )

(asm jge (Adr A)
   (comment 'jge Adr)
   (_jmp "b.cs" "b.cc") )

(asm jle (Adr A)
   (comment 'jle Adr)
   (_jmp "b.ls" "b.hi") )

(asm jgt (Adr A)
   (comment 'jgt Adr)
   (_jmp "b.hi" "b.ls") )

(asm ret ()
   (comment 'ret)
   (prinst "ret") )

(asm catch ()
   (comment 'catch)
   (prinst "str" "x30" "[x28,-8]!") )

(asm throw ()
   (comment 'throw)
   (prinst "ldr" "x30" "[x28],8")
   (prinst "ret") )

# Floating point
(asm ldd ()
   (comment 'ldd)
   (prinst "ldr" "d0" "[x19]") )

(asm ldf ()
   (comment 'ldf)
   (prinst "ldr" "s0" "[x19]") )

(asm fixnum ()
   (comment 'fixnum)
   (prinst "tbnz" "x20" "#3" "1f")        # Jump if scale negative
   (prinst "lsr" "x20" "x20" "#4")        # Normalize scale
   (prinst "scvtf" "d16" "x20")           # and and convert
   (prinst "fmul" "d0" "d0" "d16")        # Mulitply double with scale
   (prinst "fcvtas" "x20" "d0")           # Convert to integer
   (prinst "b" "2f")
   (prinl "1:")
   (prinst "lsr" "x20" "x20" "#4")        # Normalize scale
   (prinst "scvtf" "s16" "x20")           # and and convert
   (prinst "fmul" "s0" "s0" "s16")        # Mulitply float with scale
   (prinst "fcvtas" "x20" "s0")           # Convert to integer
   (prinl "2:")
   (prinst "lsl" "x10" "x20" "#4")        # Make short
   (prinst "cmp" "x10" 0)                 # Negative?
   (prinst "b.pl" "3f")                   # No: Skip
   (prinst "negs" "x10" "x10")            # Negate
   (prinst "b.mi" "4f")                   # Still negative: Overflow
   (prinst "orr" "x10" "x10" "#8")
   (prinl "3:")
   (prinst "orr" "x20" "x10" "#2")
   (prinst "b" "5f")
   (prinl "4:")                           # Infinite/NaN
   (prinst "fcmp" "d0" "#0.0")            # Float value negative?
   (prinst "csel" "x20" "x24" "x25" "mi") # Load NIL else T
   (prinl "5:") )

(asm float ()
   (comment 'float)
   (prinst "lsr" "x16" "x0" "#4")      # Normalize scale
   (prinst "ldr" "x17" "[x21]")        # Load fixnum
   (prinst "tbnz" "x0" "#3" "3f")      # Jump if negative scale
   (prinst "tbz" "x17" "#1" "1f")      # Jump if not short fixnum
   (prinst "scvtf" "d16" "x16")        # Convert scale
   (prinst "ands" 'xzr "x17" "#0x08")  # Fixnum negative?
   (prinst "lsr" "x17" "x17" "#4")     # Normalize
   (prinst "cneg" "x17" "x17" "ne")    # Yes: Negate
   (prinst "scvtf" "d17" "x17")        # and convert to double
   (prinst "fdiv" "d0" "d17" "d16")    # Divide by scale
   (prinst "b" "6f")                   # Done
   (prinl "1:")
   (prinst "cmp" "x17" "x24")          # Minus infinite?
   (prinst "mov" "x17" "#0x7FF0000000000000")
   (prinst "b.ne" "2f")                # No: Jump
   (prinst "mov" "x17" "#0xFFF0000000000000")
   (prinl "2:")
   (prinst "fmov" "d0" "x17")
   (prinst "b" "6f")                   # Done
   (prinl "3:")
   (prinst "tbz" "x17" "#1" "4f")      # Jump if not short fixnum
   (prinst "scvtf" "s16" "x16")        # Convert scale
   (prinst "ands" 'xzr "x17" "#0x08")  # Fixnum negative?
   (prinst "lsr" "x17" "x17" "#4")     # Normalize
   (prinst "cneg" "x17" "x17" "ne")    # Yes: Negate
   (prinst "scvtf" "s17" "x17")        # and convert to double
   (prinst "fdiv" "s0" "s17" "s16")    # Divide by scale
   (prinst "b" "6f")                   # Done
   (prinl "4:")
   (prinst "cmp" "x17" "x24")          # Minus infinite?
   (prinst "mov" "x17" "#0x7F800000")
   (prinst "b.ne" "5f")                # No: Jump
   (prinst "mov" "x17" "#0xFF800000")
   (prinl "5:")
   (prinst "fmov" "s0" "x17")
   (prinl "6:") )

(asm std ()
   (comment 'std)
   (prinst "str" "d0" "[x23]") )

(asm stf ()
   (comment 'stf)
   (prinst "str" "s0" "[x23]") )

# C-Calls
(asm TOS cc (Adr A Arg M)
   (comment 'cc Adr Arg)
   (if (lst? Arg)
      (let (Reg '("x0" "x1" "x2" "x3" "x4" "x5" "x6" "x7")   Lea NIL  Tmp NIL)
         (when (fish '((X) (= "x0" X)) (cdr Arg))
            (prinst "mov" (setq Tmp "x9") "x0") )  # No need to preserve x-bit
         (mapc
            '((Src S)
               (if (== '& Src)
                  (on Lea)
                  (setq Src
                     (recur (Src)
                        (cond
                           ((= "x0" Src) (or Tmp "x0"))
                           ((atom Src) Src)
                           (T (cons (recurse (car Src)) (recurse (cdr Src)))) ) ) )
                  (cond
                     ((and (=T S) (== 'pop Src))
                        (prinst "ldr" (pop 'Reg) "[x28],8") )
                     ((= "x0" Src) (pop 'Reg))
                     (Lea (lea Src S (pop 'Reg)))
                     (T (mov (car Reg) (src Src S imm16 (pop 'Reg)))) )
                  (off Lea) ) )
            Arg
            M ) )
      (prinst "sub" "x20" Arg "x28")      # Size of arguments in E (x20)
      (prinst "lsr" "x20" "x20" "#1")     # Take half
      (prinst "add" "x20" "x20" "#8")     # Align
      (prinst "and" "x20" "x20" "#~15")
      (prinst "sub" 'sp 'sp "x20")        # Allocate space
      (prinst "mov" "x11" 'sp)            # x11 on stack space
      (prinst "mov" "x12" "x28")          # x12 on arguments
      (prinst "adrp" "x13" "ldInt")       # x13 on integer loaders
      (prinst "add" "x13" "x13" ":lo12:ldInt")
      (prinst "adrp" "x14" "ldFlt")       # x14 on float loaders
      (prinst "add" "x14" "x14" ":lo12:ldFlt")
      (prinst "adrp" "x15" "ldDbl")       # x15 on double loaders
      (prinst "add" "x15" "x15" ":lo12:ldDbl")
      (prinl "1:")
      (prinst "cmp" "x12" Arg)            # Done?
      (prinst "b.eq" "8f")                # Yes
      (prinst "ldr" "x16" "[x12],8")      # Next arg
      (prinst "cbnz" "x16" "2f")          # Jump if float/double
      (prinst "blr" "x13")                # Load integer
      (prinst "b" "1b")
      (prinl "2:")
      (prinst "ldr" "x17" "[x12],8")      # Mantissa in x17
      (prinst "tbz" "x16" "#3" "5f")      # Jump if scale positive
      (prinst "tbz" "x17" "#1" "3f")      # Jump if no short mantissa
      (prinst "lsr" "x16" "x16" "#4")     # Normalize scale
      (prinst "scvtf" "s16" "x16")        # and and convert
      (prinst "ands" 'xzr "x17" "#0x08")  # Mantissa negative?
      (prinst "lsr" "x17" "x17" "#4")     # Normalize
      (prinst "cneg" "x17" "x17" "ne")    # Yes: Negate
      (prinst "scvtf" "s17" "x17")        # and convert to float
      (prinst "fdiv" "s17" "s17" "s16")   # Float mantissa / scale
      (prinst "blr" "x14")                # Load float
      (prinst "b" "1b")
      (prinl "3:")
      (prinst "cmp" "x17" "x24")          # Mantissa Nil?
      (prinst "b.eq" "4f")                # Yes: Jump
      (prinst "mov" "w17" "#0x7F800000")  # INF
      (prinst "fmov" "s17" "w17")
      (prinst "blr" "x14")                # Load float
      (prinst "b" "1b")
      (prinl "4:")
      (prinst "mov" "w17" "#0xFF800000")  # -INF
      (prinst "fmov" "s17" "w17")
      (prinst "blr" "x14")                # Load float
      (prinst "b" "1b")
      (prinl "5:")
      (prinst "tbz" "x17" "#1" "6f")      # Jump if no short mantissa
      (prinst "lsr" "x16" "x16" "#4")     # Normalize scale
      (prinst "scvtf" "d16" "x16")        # and and convert
      (prinst "ands" 'xzr "x17" "#0x08")  # Mantissa negative?
      (prinst "lsr" "x17" "x17" "#4")     # Normalize
      (prinst "cneg" "x17" "x17" "ne")    # Yes: Negate
      (prinst "scvtf" "d17" "x17")        # and convert to double
      (prinst "fdiv" "d17" "d17" "d16")   # Double mantissa / scale
      (prinst "blr" "x15")                # Load double
      (prinst "b" "1b")
      (prinl "6:")
      (prinst "cmp" "x17" "x24")          # Mantissa Nil?
      (prinst "b.eq" "7f")                # Yes: Jump
      (prinst "mov" "x17" "#0x7FF0000000000000")
      (prinst "fmov" "d17" "x17")
      (prinst "blr" "x15")                # Load double
      (prinst "b" "1b")
      (prinl "7:")
      (prinst "mov" "x17" "#0xFFF0000000000000")
      (prinst "fmov" "d17" "x17")
      (prinst "blr" "x15")                # Load double
      (prinst "b" "1b")
      (prinl "8:") )
   (nond
      (A  # Absolute
         (prinst "bl" Adr) )
      ((=T A)  # Indexed
         (prinst "blr" Adr) ) )
   (unless (lst? Arg)
      (prinst "add" 'sp 'sp "x20") ) )  # Restore stack

(asm func ())

(asm begin ()
   (comment 'begin)
   (prinst "stp" "x30" "x28" "[sp,-80]!")
   (prinst "bl" "begin") )

(asm return ()
   (comment 'return)
   (prinst "b" "return") )

# Stack Manipulations
(asm push (Src S)
   (comment 'push Src)
   (setq Src (src Src S imm16))
   (casq Src
      (zscx
         (prinst "mrs" "x15" "nzcv")
         (prinst "bfm" "x15" "x9" 0 0)
         (prinst "str" "x15" "[x28,-8]!") )
      (zsc
         (prinst "mrs" "x15" "nzcv")
         (prinst "str" "x15" "[x28,-8]!") )
      (x (prinst "str" "x9" "[x28,-8]!"))
      (T (mov "[x28,-8]!" Src)) ) )

(asm push/2 (Reg1 Reg2)
   (comment 'push/2 Reg1 Reg2)
   (prinst "stp" Reg2 Reg1 "[x28,-16]!") )

(asm pop (Dst D)
   (comment 'pop Dst)
   (setq Dst (dst Dst D))
   (casq Dst
      (zscx
         (prinst "ldr" "x15" "[x28],8")
         (prinst "sbfm" "x9" "x15" 0 0)
         (prinst "msr" "nzcv" "x15") )
      (zsc
         (prinst "ldr" "x15" "[x28],8")
         (prinst "msr" "nzcv" "x15") )
      (x (prinst "ldr" "x9" "[x28],8"))
      (T (mov Dst "[x28],8")) ) )

(asm pop/2 (Reg1 Reg2)
   (comment 'pop/2 Reg1 Reg2)
   (prinst "ldp" Reg1 Reg2 "[x28],16") )

(asm link ()
   (comment 'link)
   (prinst "str" "x29" "[x28,-8]!")
   (prinst "mov" "x29" "x28") )

(asm push/link (Reg)
   (comment 'push/link)
   (prinst "stp" "x29" Reg "[x28,-16]!")
   (prinst "mov" "x29" "x28") )

(asm tuck (Src S)
   (comment 'tuck Src)
   (setq Src (src Src S imm16))
   (prinst "ldr" "x29" "[x28]")
   (mov "[x28]" Src) )

(asm drop ()
   (comment 'drop)
   (prinst "ldr" "x28" "[x29]")
   (prinst "ldr" "x29" "[x28],8") )

(asm drop/pop (Reg)
   (comment 'drop/pop)
   (prinst "ldr" "x28" "[x29]")
   (prinst "ldp" "x29" Reg "[x28],16") )

# Evaluation
(asm TOS eval ()
   (comment 'eval)
   (prinst "ands" 'xzr "x20" "#0x06")  # Number?
   (prinst "b.ne" "2f")                # Yes: Skip
   (prinst "tbz" "x20" "#3" "1f")      # Symbol:
   (prinst "ldr" "x20" "[x20]")        # Get value
   (prinst "b" "2f")                   # and skip
   (prinl "1:")
   (prinst "bl" 'evListE_E)            # Else evaluate list
   (prinl "2:") )

(asm TOS eval+ ()
   (comment 'eval+)
   (prinst "ands" 'xzr "x20" "#0x06")  # Number?
   (prinst "b.ne" "2f")                # Yes: Skip
   (prinst "tbz" "x20" "#3" "1f")      # Symbol:
   (prinst "ldr" "x20" "[x20]")        # Get value
   (prinst "b" "2f")                   # and skip
   (prinl "1:")
   (prinst "str" "x29" "[x28,-8]!")    # Else 'link'
   (prinst "mov" "x29" "x28")
   (prinst "bl" 'evListE_E)            # Evaluate list
   (prinst "ldr" "x29" "[x28],8")
   (prinl "2:") )

(asm eval/ret ()
   (comment 'eval/ret)
   (prinst "ands" 'xzr "x20" "#0x06")  # Number?
   (prinst "b.ne" "1f")                # Yes: Return
   (prinst "ands" 'xzr "x20" "#0x08")  # Symbol?
   (prinst "b.eq" 'evListE_E)          # No
   (prinst "ldr" "x20" "[x20]")        # Else get value
   (prinl "1:")
   (prinst "ret") )

(asm TOS exec (Reg)
   (comment 'exec Reg)
   (prinl "1:")                        # do
   (prinst "ldr" "x20"                 # ld E (R)
      (pack "[" Reg "]") )
   (prinst "ands" 'wzr "w20" "#0x0E")  # atom E
   (prinst "b.ne" "2f")
   (prinst "bl" 'evListE_E)            # Evaluate list
   (prinl "2:")
   (prinst "ldr" Reg                   # ld R (R CDR)
      (pack "[" Reg ",8]") )
   (prinst "ands" 'xzr Reg "#0x0E")    # atom R
   (prinst "b.eq" "1b") )              # until nz

(asm TOS prog (Reg)
   (comment 'prog Reg)
   (prinl "1:")                        # do
   (prinst "ldr" "x20"                 # ld E (R)
      (pack "[" Reg "]") )
   (prinst "ands" 'wzr "w20" "#0x06")  # eval
   (prinst "b.ne" "3f")
   (prinst "tbz" "w20" "#3" "2f")
   (prinst "ldr" "x20" "[x20]")
   (prinst "b" "3f")
   (prinl "2:")
   (prinst "bl" 'evListE_E)
   (prinl "3:")
   (prinst "ldr" Reg                   # ld R (R CDR)
      (pack "[" Reg ",8]") )
   (prinst "ands" 'xzr Reg "#0x0E")    # atom R
   (prinst "b.eq" "1b") )              # until nz


# System
(asm initData ())

(asm initCode ()
   (unless *FPic
      (label "div")  # x19:x0 / x1
      (let
         (@u1 "x19"  @u0 "x0"  @src "x1"  @s "x2"     # un21 = un32 = u1
            @un1 "x3"  @un0 "x4"  @vn1 "x5"  @vn0 "x6"  @t "x7"  @t2 "x8"
            @q1 "x15"  @q0 "x16"  @rhat "x17" )
         (macro
            (prinst "cmp" @u1 @src)                   # u1 >= src?
            (prinst "b.hs" "divOvfl")                 # Yes: Overflow
            (prinst "mov" @s 0)                       # Init 's'
            (prinst "cmp" @src 0)                     # Normalize
            (prinst "b.le" "div2")
            (prinl "div1:")
            (prinst "add" @s @s "#1")                 # Increment 's'
            (prinst "adds" @u0 @u0 @u0)               # Shift dividend left
            (prinst "adc" @u1 @u1 @u1)
            (prinst "adds" @src @src @src)            # and divisor
            (prinst "b.pl" "div1")
            (prinl "div2:")
            (prinst "ubfm" @vn1 @src 32 63)           # Split divisor into high 32 bits
            (prinst "ubfm" @vn0 @src 0 31)            # and low 32 bits
            (prinst "ubfm" @un1 @u0 32 63)            # Split 'u0' into high 32 bits
            (prinst "ubfm" @un0 @u0 0 31)             # and low 32 bits
            (prinst "udiv" @q1 @u1 @vn1)              # First quotient digit
            (prinst "mul" @t @q1 @vn1)
            (prinst "sub" @rhat @u1 @t)
            (prinl "div3:")
            (prinst "ands" 'xzr @q1 `(hex "FFFFFFFF00000000"))  # q1 >= b?
            (prinst "b.ne" "div4")                    # Yes
            (prinst "lsl" @t2 @rhat "#32")            # b*rhat + un1
            (prinst "add" @t2 @t2 @un1)
            (prinst "mul" @t @q1 @vn0)
            (prinst "cmp" @t @t2)                     # q1 * vn0 > b*rhat + un1?
            (prinst "b.ls" "div5")                    # No
            (prinl "div4:")
            (prinst "sub" @q1 @q1 "#1")               # Else decrement 'q1'
            (prinst "add" @rhat @rhat @vn1)           # Increment 'rhat'
            (prinst "ands" 'xzr @rhat `(hex "FFFFFFFF00000000"))  # Less than 'b'?
            (prinst "b.eq" "div3")                    # Yes
            (prinl "div5:")
            (prinst "lsl" @u1 @u1 "#32")              # (un32*b)
            (prinst "add" @u1 @u1 @un1)               # (un1 + un32*b)
            (prinst "mul" @t @q1 @src)
            (prinst "sub" @u1 @u1 @t)                 # un21 = un1 + un32*b - q1*src
            (prinst "udiv" @q0 @u1 @vn1)              # Second quotient digit
            (prinst "mul" @t @q0 @vn1)
            (prinst "sub" @rhat @u1 @t)
            (prinl "div6:")
            (prinst "ands" 'xzr @q0 `(hex "FFFFFFFF00000000"))  # q0 >= b?
            (prinst "b.ne" "div7")                    # Yes
            (prinst "lsl" @t2 @rhat "#32")            # b*rhat + un0
            (prinst "add" @t2 @t2 @un0)
            (prinst "mul" @t @q0 @vn0)
            (prinst "cmp" @t @t2)                     # q0 * vn0 > b*rhat + un0?
            (prinst "b.ls" "div8")                    # No
            (prinl "div7:")
            (prinst "sub" @q0 @q0 "#1")               # Else decrement 'q0'
            (prinst "add" @rhat @rhat @vn1)           # Increment 'rhat'
            (prinst "ands" 'xzr @rhat `(hex "FFFFFFFF00000000"))  # Less than 'b'?
            (prinst "b.eq" "div6")                    # Yes
            (prinl "div8:")
            (prinst "lsl" @u0 @q1 "#32")              # Quotient
            (prinst "add" @u0 @u0 @q0)
            (prinst "lsl" @u1 @u1 "#32")              # Remainder: u1 = (un0 + un21*b - q0*src) >> s
            (prinst "add" @u1 @u1 @un0)
            (prinst "mul" @t @q0 @src)
            (prinst "sub" @u1 @u1 @t)
            (prinst "lsr" @u1 @u1 @s)
            (prinst "ret")
            (prinl "divOvfl:")
            (prinst "mov" @u0 -1)                     # Overflow
            (prinst "mov" @u1 -1)
            (prinst "ret") ) )
      (prinl)
      (label "begin")
      (prinst "stp" "x20" "x19" "[sp,64]")
      (prinst "stp" "x22" "x21" "[sp,48]")
      (prinst "stp" "x24" "x23" "[sp,32]")
      (prinst "stp" "x26" "x25" "[sp,16]")
      (prinst "mov" "x19" "x1")  # C
      (prinst "mov" "x20" "x2")  # E
      (prinst "mov" "x21" "x3")  # X
      (prinst "mov" "x22" "x4")  # Y
      (prinst "mov" "x23" "x5")  # Z
      (prinst "adrp" "x24" ":got:Nil")  # Nil
      (prinst "ldr" "x24" "[x24, #:got_lo12:Nil]")
      (prinst "adrp" "x25" ":got:TSym")  # T
      (prinst "ldr" "x25" "[x25, #:got_lo12:TSym]")
      (prinst "adrp" "x26" ":got:StkLimit")  # StkLimit
      (prinst "ldr" "x26" "[x26, #:got_lo12:StkLimit]")
      (prinst "mov" "x28" 'sp)
      (prinst "sub" 'sp 'sp "#4096")
      (prinst "ret")
      (prinl)
      (label "return")
      (prinst "mov" 'sp "x28")
      (prinst "ldp" "x20" "x19" "[sp,64]")
      (prinst "ldp" "x22" "x21" "[sp,48]")
      (prinst "ldp" "x24" "x23" "[sp,32]")
      (prinst "ldp" "x26" "x25" "[sp,16]")
      (prinst "ldp" "x30" "x28" "[sp],80")
      (prinst "ret")
      (prinl)
      (label "ldInt")
      (prinst "ldr" "x0" "[x12],8")     # Load integer register
      (prinst "add" "x13" "x13" "#12")  # Skip to next loader
      (prinst "ret")
      (prinst "ldr" "x1" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x2" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x3" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x4" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x5" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x6" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x7" "[x12],8")
      (prinst "add" "x13" "x13" "#12")
      (prinst "ret")
      (prinst "ldr" "x16" "[x12],8")    # Store in stack
      (prinst "str" "x16" "[x11],8")
      (prinst "ret")
      (prinl)
      (label "ldFlt")
      (prinst "fmov" "s0" "s17")        # Load float register
      (prinst "add" "x14" "x14" "#12")  # Skip to next loader
      (prinst "ret")
      (prinst "fmov" "s1" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "fmov" "s2" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "fmov" "s3" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "fmov" "s4" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "fmov" "s5" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "fmov" "s6" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "fmov" "s7" "s17")
      (prinst "add" "x14" "x14" "#12")
      (prinst "ret")
      (prinst "add" "x12" "x12" "#8")  # Ignore
      (prinst "ret")
      (prinl)
      (label "ldDbl")
      (prinst "fmov" "d0" "d17")        # Load double register
      (prinst "add" "x15" "x15" "#12")  # Skip to next loader
      (prinst "ret")
      (prinst "fmov" "d1" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "fmov" "d2" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "fmov" "d3" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "fmov" "d4" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "fmov" "d5" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "fmov" "d6" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "fmov" "d7" "d17")
      (prinst "add" "x15" "x15" "#12")
      (prinst "ret")
      (prinst "add" "x12" "x12" "#8")  # Ignore
      (prinst "ret") ) )

(asm initMain ()
   (prinst "ldr" "x21" "[x1]")  # Get command in X
   (prinst "add" "x22" "x1" "#8")  # argument vector in Y
   (prinst "add" "x23" "x1" "x0" "LSL#3")  # pointer to last argument in Z
   (prinst "sub" "x23" "x23" "#8")
   (prinst "adrp" "x24" ":got:Nil")  # Nil
   (prinst "ldr" "x24" "[x24, #:got_lo12:Nil]")
   (prinst "adrp" "x25" ":got:TSym")  # T
   (prinst "ldr" "x25" "[x25, #:got_lo12:TSym]")
   (prinst "adrp" "x26" ":got:StkLimit")  # StkLimit
   (prinst "ldr" "x26" "[x26, #:got_lo12:StkLimit]")
   (prinst "mov" "x28" 'sp)  # Set stack pointer
   (prinst "sub" 'sp 'sp "#4096") )

(asm initLib ())

(asm stop ()
   (comment 'stop)
   (prinst "mov" "x0" "x20")  # Return 'E'
   (prinst "bl" "exit") )

### Optimizer ###
# Replace the the next 'cnt' elements with 'lst'
(de optimize (Lst)  #> (cnt . lst)
   (cond
      ((memq (caar Lst) '(cnt big sym))
         (cond
            ((memq (caadr Lst) '(jz jnz))
               (and
                  (or
                     (= `(char ".") (char (get Lst 2 2)))
                     (and
                        (cdr (split (chop (get Lst 2 2)) "_"))
                        (format (last @)) ) )
                  (optimBranch Lst) ) )
            ((and (memq (caadr Lst) '(ldz ldnz)) (not (needCC (cddr Lst))))
               (let? L (cadr Lst)
                  (unless (and (reg? (cadr L)) (reg? (cadddr L)))
                     (optimBranch Lst) ) ) ) ) )
      ((memq (caar Lst) '(nulp nul4 nul))
         (cond
            ((memq (caadr Lst) '(jz jnz))
               (and
                  (not (needCC (cons (cons 'jmp (cdadr Lst)) (cddr Lst))))
                  (nor (pre? "ret" (get Lst 2 2)) (pre? "Ret" (get Lst 2 2)))
                  (optimBranch Lst) ) )
            ((and (memq (caadr Lst) '(ldz ldnz)) (not (needCC (cddr Lst))))
               (let? L (cadr Lst)
                  (unless (and (reg? (cadr L)) (reg? (cadddr L)))
                     (optimBranch Lst) ) ) ) ) )
      ((and
            (== 'push (caar Lst))
            (reg? (cadar Lst))
            (== 'push (caadr Lst))
            (reg? (cadadr Lst)) )
         (list 2 (list 'push/2 (cadar Lst) (cadadr Lst))) )
      ((and
            (== '++tos (caar Lst))
            (== 'push (caadr Lst))
            (reg? (cadadr Lst)) )
         (list 2 (list 'push/2 "x30" (cadadr Lst))) )
      ((and
            (== 'push (caar Lst))
            (reg? (cadar Lst))
            (== '++tos (caadr Lst)) )
         (list 2 (list 'push/2 (cadar Lst) "x30")) )
      ((and
            (== 'push (caar Lst))
            (reg? (cadar Lst))
            (== 'link (caadr Lst)) )
         (list 2 (list 'push/link (cadar Lst))) )
      ((and
            (== 'pop (caar Lst))
            (reg? (cadar Lst))
            (== 'pop (caadr Lst))
            (reg? (cadadr Lst)) )
         (list 2 (list 'pop/2 (cadar Lst) (cadadr Lst))) )
      ((and
            (== 'tos-- (caar Lst))
            (== 'pop (caadr Lst))
            (reg? (cadadr Lst)) )
         (list 2 (list 'pop/2 "x30" (cadadr Lst))) )
      ((and
            (== 'pop (caar Lst))
            (reg? (cadar Lst))
            (== 'tos-- (caadr Lst)) )
         (list 2 (list 'pop/2 (cadar Lst) "x30")) )
      ((and
            (== 'drop (caar Lst))
            (== 'pop (caadr Lst))
            (reg? (cadadr Lst)) )
         (list 2 (list 'drop/pop (cadadr Lst))) )
      ((and
            (== 'drop (caar Lst))
            (== 'tos-- (caadr Lst)) )
         (list 2 (list 'drop/pop "x30")) )
      ((noCC Lst)
         (cons 1 (cons (cons @ (cdar Lst)))) ) ) )

(de optimBranch (Lst)
   (cons 2
      (list
         (cons
            (intern (pack (caar Lst) '/ (caadr Lst)))
            (append (cdar Lst) (cdadr Lst)) ) ) ) )

### Decoration ###
(de prolog (File)
   (when *FPic
      (in "arm64.symtab"
         (setq *Globals (read)) ) ) )

(de epilog (File)
   (unless *FPic
      (out "arm64.symtab"
         (println *Globals) ) ) )

# vi:et:ts=3:sw=3
