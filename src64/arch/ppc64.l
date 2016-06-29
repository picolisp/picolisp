# 27may16abu
# (c) Software Lab. Alexander Burger

# Architecture
(on *LittleEndian)
(on *AlignedCode)

# Register assignments
(de *Registers
   (A . 3) (C . 14) (E . 15)
   (B . -3) (D 3 . 14)
   (X . 16) (Y . 17) (Z . 18)
   (L . 19) (S . 1)
   (zscx . zscx) (zsc . zscx) (x . x) )

(de *TempRegs
   (27 28 29 30 .) )

# TOC: 2
# C arguments: 3 - 10
# C calls: 12
# NULL: 20
# ONE: 21
# Data: 22
# Code: 23
# DllToc: 24
# Nil: 25
# Reserved: 26
# Carry flag: 31

# Temporary register
(de tmpReg @
   (let R (pop *TempRegs)
      (if (find lt0 (rest))
         (- R)
         R ) ) )

# Machine specific
(zero *DataPos *CodePos)
(off *DataLabels *CodeLabels *DataIndex *CodeIndex)

(redef label (Lbl Flg)
   (ifn *FPic
      (cond
         ((== *Section 'data)
            (push '*DataLabels (cons Lbl *DataPos)) )
         ((== *Section 'text)
            (unless (pre? "." Lbl)
               (push '*CodeLabels (cons Lbl *CodePos)) ) ) )
      (when (and Flg (== *Section 'text) (n0 *CodePos) (upp? Lbl))
         (prinst ".quad" ".TOC.@tocbase") ) )
   (label Lbl Flg)
   (when (and *FPic Flg (== *Section 'text) (n0 *CodePos) (upp? Lbl))
      (prinst "mfctr" 12)
      (prinst "subi" 12 12 2)
      (prinst "ld" 24 "-8(12)") ) )

(de asciiLen (Str)
   (- (size (pack (replace (chop Str) "\\"))) 2) )  # Don't count double quotes

(redef prinst (Name . @)
   (pass prinst Name)
   (cond
      ((== *Section 'data)
         (inc '*DataPos
            (case Name
               (".balign"
                  (if (gt0 (% *DataPos (next)))
                     (- (arg) @)
                     0 ) )
               (".quad" 8)
               (".byte"
                  (if (num? (next))
                     1
                     (length (split (chop (arg)) ",")) ) )
               (".short"
                  (if (num? (next))
                     2
                     (* 2 (length (split (chop (arg)) ","))) ) )
               (".space" (next))
               (".ascii" (asciiLen (next)))
               (".asciz" (inc (asciiLen (next))))
               (T (quit "Unknown data directive")) ) ) )
      ((== *Section 'text)
         (inc '*CodePos
            (case Name
               (".quad" 24)  # Function headers
               (".balign"
                  (if (gt0 (% *CodePos (next)))
                     (- (arg) @)
                     0 ) )
               (T 4) ) ) ) ) )

(de dataOffset (Sym)
   (if (lup *DataIndex Sym)
      (cdr @)
      (pack Sym "-Data") ) )

(de dataGot (Reg Sym)
   (cond
      ((lup *DataIndex Sym)
         (prinst "la" Reg (pack (cdr @) "(22)")) )
      (*FPic (prinst "ld" Reg (pack Sym "@got(24)")))
      (T (prinst "ld" Reg (pack Sym "@got(2)"))) ) )

(de codeCall (Sym)
   (if (lup *CodeIndex Sym)
      (prog
         (prinst "mtctr" 23)
         (prinst "bctrl")
         (prinst ".int" (cdr @)) )
      (prinst "bl" "callRel")
      (prinst ".int" (pack Sym "-.")) ) )

# Addressing modes
(de checkOp (Fun)
   (unless (Fun Op)
      (quit "Illegal operation" *Statement) ) )

(de opReg (Op Reg Ofs R)
   (let Adr (pack Ofs "(" R ")")
      (cond
         ((lt0 Reg)
            (checkOp bool)
            (cond
               ((=0 Op)
                  (if (= -3 Reg)
                     (let Byte (tmpReg)
                        (prinst "lbz" Byte Adr)
                        (prinst "insrdi" 3 Byte 8 56) )
                     (prinst "lbz" (abs Reg) Adr) ) )
               ((=T Op) (prinst "stb" (abs Reg) Adr))
               (T (prinst Op (abs Reg) Adr)) ) )
         ((not Op)
            (unless (and (=0 Ofs) (= Reg R))
               (prinst "la" Reg Adr) ) )
         ((=0 Op) (prinst "ld" Reg Adr))
         ((=T Op) (prinst "std" Reg Adr))
         (T (prinst Op Reg Adr)) )
      (cons Adr) ) )

(de opxReg (Op Reg R R2)
   (let Adr (pack R ", " R2)
      (cond
         ((lt0 Reg)
            (checkOp bool)
            (cond
               ((=0 Op)
                  (if (= -3 Reg)
                     (let Byte (tmpReg)
                        (prinst "lbzx" Byte Adr)
                        (prinst "insrdi" 3 Byte 8 56) )
                     (prinst "lbzx" (abs Reg) Adr) ) )
               ((=T Op) (prinst "stbx" (abs Reg) Adr))
               (T (prinst (pack Op "x") (abs Reg) Adr)) ) )
         ((not Op) (prinst "add" Reg Adr))
         ((=0 Op) (prinst "ldx" Reg R R2))
         ((=T Op) (prinst "stdx" Reg Adr))
         (T (prinst (pack Op "x") Reg Adr)) )
      (cons Adr "x") ) )

(de mvReg (Dst Src)
   (if (or (lt0 Dst) (lt0 Src))
      (prinst "insrdi" (abs Dst) (abs Src) 8 56)
      (prinst "mr" Dst Src) ) )

# Operation 'Op':
#  NIL   Lea
#  0     Fetch
#  T     Store
(de memory (Mem M Reg Op Tmp)  #> ([adr [. "x"]])
   (cond
      ((=0 M)  # Immediate
         (checkOp =0)
         (if (= "0" Mem)
            (if (lt0 Reg)
               (prinst "insrdi" (abs Reg) 20 8 56)
               (prinst "li" Reg 0) )
            (setq Mem
               (if (pre? "~" Mem)
                  (x| `(hex "FFFFFFFFFFFFFFFF") (format (cdr (chop Mem))))
                  (format Mem) ) )
            (cond
               ((lt0 Reg)
                  (prinst "insrdi" (abs Reg) 20 8 56)
                  (prinst "ori" (abs Reg) (abs Reg) (& 255 Mem)) )
               ((>= 32767 Mem -32768)
                  (prinst "li" Reg Mem) )
               ((>= 2147483647 Mem -2147483648)
                  (prinst "lis" Reg (>> 16 Mem))
                  (unless (=0 (setq Mem (& 65535 Mem)))
                     (prinst "ori" Reg Reg Mem) ) )
               (T
                  (let
                     (A (>> 48 Mem)
                        B (& 65535 (>> 32 Mem))
                        C (& 65535 (>> 16 Mem))
                        D (& 65535 Mem) )
                     (prinst "lis" Reg A)
                     (unless (=0 B)
                        (prinst "ori" Reg Reg B) )
                     (if (=0 C)
                        (prinst "sldi" Reg Reg 32)
                        (prinst "sldi" Reg Reg 16)
                        (prinst "ori" Reg Reg C)
                        (prinst "sldi" Reg Reg 16) )
                     (unless (=0 D)
                        (prinst "ori" Reg Reg D) ) ) ) ) )
         NIL )
      ((not M)  # Register
         (cond
            ((not Reg) (setq Reg Mem))
            ((= Mem Reg))
            ((not Op) (prinst "mr" Reg Mem))
            ((=0 Op) (mvReg Reg Mem))
            ((=T Op) (mvReg Mem Reg))
            (T (prinst Op Reg Mem)) )
         NIL )
      ((=T M)  # Direct
         (cond
            ((sub? "-" Mem)  # Label difference
               (checkOp =0)
               (prinst "li" Reg Mem)
               NIL )
            ((== 'Nil Mem) (prinst "mr" Reg 25))
            ((or *FPic (low? Mem))  # -fpic or code label
               (dataGot Reg Mem) )
            (T (opReg NIL Reg (dataOffset Mem) 22)) ) )
      ((not (car M))  # Indexed
         (cond
            ((not (cdr M)) (opReg Op Reg 0 (car Mem)))
            ((=0 (cdr M))
               (if (>= 32767 (cdr Mem) -32768)
                  (opReg Op Reg (cdr Mem) (car Mem))
                  (let R (or Tmp (tmpReg))
                     (prinst "lis" R (>> 16 (cdr Mem)))
                     (unless (=0 (& 65535 (cdr Mem)))
                        (prinst "ori" R R (& 65535 (cdr Mem))) )
                     (opxReg Op Reg R (car Mem)) ) ) )
            ((=T (cdr M))
               (cond
                  ((sub? "-" (cdr Mem))  # Label difference
                     (opReg Op Reg (cdr Mem) (car Mem)) )
                  ((or *FPic (low? (cdr Mem)))  # -fpic or code label
                     (let R (tmpReg)
                        (dataGot R (cdr Mem))
                        (opxReg Op Reg R (car Mem)) ) )
                  (T
                     (let R (tmpReg)
                        (prinst "la" R (pack (dataOffset (cdr Mem)) "(22)"))
                        (opxReg Op Reg R (car Mem)) ) ) ) ) ) )
      ((=T (car M))  # Indirect
         (if (or *FPic (low? (car Mem)))  # -fpic or code label
            (let R (tmpReg)
               (dataGot R (car Mem))
               (opReg Op Reg 0 R) )
            (opReg Op Reg
               (pack
                  (and (cdr M) (pack (cdr Mem) "+"))
                  (dataOffset (car Mem)) )
               22 ) ) )
      (T  # Combined
         (let R (or Tmp (tmpReg))
            (memory (car Mem) (car M) R 0 R)
            (opReg Op Reg (or (cdr Mem) 0) R) ) ) ) )

(de memory2 (Cmd Reg Ref Ofs)
   (prinst
      (pack (if (lt0 Reg) "stb" Cmd) (cdr Ref))
      (abs Reg)
      (if Ofs
         (pack @ "+" (car Ref))
         (car Ref) ) ) )

(de srcReg (Src S Tmp)  #> register
   (cond
      ((not S)
         (ifn Tmp
            Src
            (prinst "mr" Tmp Src)
            Tmp ) )
      ((= "0" Src)
         (ifn Tmp
            20
            (prinst "li" Tmp 0)
            Tmp ) )
      ((= "1" Src)
         (ifn Tmp
            21
            (prinst "li" Tmp 1)
            Tmp ) )
      ((== 'Nil Src)
         (ifn Tmp
            25
            (prinst "mr" Tmp 25)
            Tmp ) )
      (T
         (prog1
            (or Tmp (tmpReg))
            (memory Src S @ 0) ) ) ) )

(de srcByteReg (Src S)  #> register
   (cond
      ((not S)
         (prog1
            (tmpReg)
            (prinst "extrdi" @ (abs Src) 8 56) ) )
      ((n0 S)
         (prog1
            (tmpReg)
            (memory Src S @ "lbz") ) )
      ((= "0" Src) 20)
      ((= "1" Src) 21)
      (T
         (prog1
            (tmpReg)
            (prinst "li" @
               (if (pre? "~" Src)
                  (x| `(hex "FF") (format (cdr (chop Src))))
                  (format Src) ) ) ) ) ) )

(de dstReg (Dst D)  #> (NIL dst adr [. "x"])
   (cond
      (D
         (let R (tmpReg)
            (cons NIL R (memory Dst D R 0)) ) )
      ((= -3 Dst)
         (let R (tmpReg)
            (prinst "extrdi" R 3 8 56)
            (cons NIL R -3) ) )
      (T (list NIL Dst)) ) )

(de dstByteReg (Dst D)  #> (T dst adr [. "x"])
   (cond
      (D
         (let R (tmpReg)
            (cons T R (memory Dst D R "lbz")) ) )
      ((= -3 Dst)
         (let R (tmpReg)
            (prinst "extrdi" R 3 8 56)
            (cons T R -3) ) )
      (T (list T Dst)) ) )

(de dstSrcReg (Dst D Src S)  #> (src flg dst adr [. "x"])
   (if (or (= -3 Dst) (= -3 Src))
      (cons
         (srcByteReg Src S)
         (dstByteReg Dst D) )
      (cons
         (srcReg Src S)
         (dstReg Dst D) ) ) )

(de regDst (RegRef)
   (cond
      ((= -3 (cddr RegRef))
         (prinst "insrdi" 3 (cadr RegRef) 8 56) )
      ((car RegRef)  # byte-flg
         (when (cddr RegRef)
            (memory2 "stb" (cadr RegRef) (cddr RegRef)) ) )
      ((cddr RegRef)
         (memory2 "std" (cadr RegRef) (cddr RegRef)) ) ) )

### Instruction set ###
(de alignSection (Align)
   (if (== 'text *Section)
      (prinst ".balign" 8)
      (prinst ".balign" 16)
      (or (=0 Align) (prinst ".space" Align)) ) )

(asm nop ()
   (prinst "nop") )

(asm align (N)
   (prinst ".balign" N) )

(asm skip (N)
   (if (== 'data *Section)
      (or (=0 N) (prinst ".space" N))
      (do (/ N 2) (prinst "nop")) ) )

# Move data
(asm ld (Dst D Src S)
   (cond
      ((not D)
         (ifn (= (3 . 14) Dst)
            (memory Src S Dst 0)
            (let A (memory Src S 3 0)  # D
               (prinst "ld" 14 (pack "8+" (car A))) ) ) )
      ((not S)
         (ifn (= (3 . 14) Src)
            (memory Dst D Src T)
            (let A (memory Dst D 3 T)  # D
               (prinst "std" 14 (pack "8+" (car A))) ) ) )
      ((= "0" Src) (memory Dst D 20 T))
      ((= "1" Src) (memory Dst D 21 T))
      ((== 'Nil Src) (memory Dst D 25 T))
      (T
         (let R (tmpReg)
            (memory Src S R 0)
            (memory Dst D R T) ) ) ) )

(asm ld2 (Src S)
   (memory Src S 3 "lhz") )

(asm ld4 (Src S)
   (memory Src S 3 "lwz") )

(asm ldz (Dst D Src S)
   (prinst "bne-" "1f")
   (memory Src S Dst 0)
   (prinl "1:") )

(asm ldnz (Dst D Src S)
   (prinst "beq-" "1f")
   (memory Src S Dst 0)
   (prinl "1:") )

(asm lea (Dst D Src S)
   (ifn D
      (memory Src S Dst)
      (let R (tmpReg)
         (memory Src S R)
         (memory Dst D R T) ) ) )

(asm st2 (Dst D)
   (memory Dst D 3 "sth") )

(asm st4 (Dst D)
   (memory Dst D 3 "stw") )

(asm xchg (Dst D Dst2 D2)
   (let (Tmp (tmpReg Dst Dst2)  A (memory Dst D Tmp 0))  # Tmp = Dst
      (nond
         (D
            (if (memory Dst2 D2 Dst 0)                   # Dst = Dst2
               (memory2 "std" Tmp @)                     # Dst2 = Tmp
               (mvReg Dst2 Tmp) ) )
         (D2
            (memory2 "std" Dst2 A)
            (mvReg Dst2 Tmp) )
         (NIL
            (let (R (tmpReg)  B (memory Dst2 D2 R 0))
               (memory2 "std" R A)
               (memory2 "std" Tmp B) ) ) ) ) )

(asm movn (Dst D Src S Cnt C)
   (memory Dst D 4)
   (memory Src S 5)
   (memory Cnt C 6 0)
   (codeCall "movn") )

(asm mset (Dst D Cnt C)
   (memory Dst D 4)
   (memory Cnt C 5 0)
   (codeCall "mset") )

(asm save (Src S End E Dst D)
   (memory Src S 4)
   (memory End E 5)
   (memory Dst D 6)
   (codeCall "save") )

(asm load (Dst D End E Src S)
   (memory Dst D 4)
   (memory End E 5)
   (memory Src S 6)
   (codeCall "load") )

# Arithmetics
(asm add (Dst D Src S)
   (ifn (= (3 . 14) Dst)
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (let A (dstReg Dst D)
            (prinst "addic." (cadr A) (cadr A) Src)
            (regDst A) )
         (let A (dstSrcReg Dst D Src S)
            (prinst "addc." (caddr A) (caddr A) (car A))
            (regDst (cdr A)) ) )
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (prinst "addic" 3 3 Src)
         (prinst "addc" 3 3 (srcReg Src S)) )
      (prinst "addze." 14 14) )
   (prinst "subfze" 31 21) )  # Set carry

(asmNoCC add (Dst D Src S)
   (ifn (= (3 . 14) Dst)
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (let A (dstReg Dst D)
            (prinst "addi" (cadr A) (cadr A) Src)
            (regDst A) )
         (let A (dstSrcReg Dst D Src S)
            (prinst "add" (caddr A) (caddr A) (car A))
            (regDst (cdr A)) ) )
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (prinst "addic" 3 3 Src)
         (prinst "addc" 3 3 (srcReg Src S)) )
      (prinst "addze" 14 14) ) )

(asm addc (Dst D Src S)
   (prinst "sradi" 0 31 1)  # Get carry
   (ifn (= (3 . 14) Dst)
      (let A (dstSrcReg Dst D Src S)
         (prinst "adde." (caddr A) (caddr A) (car A))
         (regDst (cdr A)) )
      (prinst "adde" 3 3 (srcReg Src S))
      (prinst "addze." 14 14) )
   (prinst "subfze" 31 21) )  # Set carry

(asmNoCC addc (Dst D Src S)
   (prinst "sradi" 0 31 1)  # Get carry
   (ifn (= (3 . 14) Dst)
      (let A (dstSrcReg Dst D Src S)
         (prinst "adde" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) )
      (prinst "adde" 3 3 (srcReg Src S))
      (prinst "adde" 14 14 20) ) )

(asm sub (Dst D Src S)
   (ifn (= (3 . 14) Dst)
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (let A (dstReg Dst D)
            (prinst "subic." (cadr A) (cadr A) Src)
            (regDst A) )
         (let A (dstSrcReg Dst D Src S)
            (prinst "subc." (caddr A) (caddr A) (car A))
            (regDst (cdr A)) ) )
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (prinst "subic" 3 3 Src)
         (prinst "subc" 3 3 (srcReg Src S)) )
      (prinst "subfze." 14 14) )
   (prinst "subfme" 31 21) )  # Set inverted carry

(asmNoCC sub (Dst D Src S)
   (ifn (= (3 . 14) Dst)
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (let A (dstReg Dst D)
            (prinst "subi" (cadr A) (cadr A) Src)
            (regDst A) )
         (let A (dstSrcReg Dst D Src S)
            (prinst "sub" (caddr A) (caddr A) (car A))
            (regDst (cdr A)) ) )
      (if (and (=0 S) (>= 32767 (format Src) -32768))
         (prinst "subic" 3 3 Src)
         (prinst "subc" 3 3 (srcReg Src S)) )
      (prinst "subfze" 14 14) ) )

(asm subb (Dst D Src S)
   (prinst "xori" 0 31 1)  # Get inverted carry
   (prinst "sradi" 0 0 1)
   (ifn (= (3 . 14) Dst)
      (let A (dstSrcReg Dst D Src S)
         (prinst "subfe." (caddr A) (car A) (caddr A))
         (regDst (cdr A)) )
      (prinst "sube" 3 3 (srcReg Src S))
      (prinst "subfze." 14 14) )
   (prinst "subfme" 31 21) )  # Set inverted carry

(asmNoCC subb (Dst D Src S)
   (prinst "xori" 0 31 1)  # Get inverted carry
   (prinst "sradi" 0 0 1)
   (ifn (= (3 . 14) Dst)
      (let A (dstSrcReg Dst D Src S)
         (prinst "subfe" (caddr A) (car A) (caddr A))
         (regDst (cdr A)) )
      (prinst "sube" 3 3 (srcReg Src S))
      (prinst "sube" 14 14 20) ) )

(asm inc (Dst D)
   (let A (dstReg Dst D)
      (prinst "addic." (cadr A) (cadr A) 1)
      (regDst A) ) )

(asmNoCC inc (Dst D)
   (let A (dstReg Dst D)
      (prinst "addi" (cadr A) (cadr A) 1)
      (regDst A) ) )

(asm dec (Dst D)
   (let A (dstReg Dst D)
      (prinst "subic." (cadr A) (cadr A) 1)
      (regDst A) ) )

(asmNoCC dec (Dst D)
   (let A (dstReg Dst D)
      (prinst "subi" (cadr A) (cadr A) 1)
      (regDst A) ) )

(asm not (Dst D)
   (let A (dstReg Dst D)
      (prinst "not." (cadr A) (cadr A))
      (regDst A) ) )

(asmNoCC not (Dst D)
   (let A (dstReg Dst D)
      (prinst "not" (cadr A) (cadr A))
      (regDst A) ) )

(asm neg (Dst D)
   (let A (dstReg Dst D)
      (prinst "neg." (cadr A) (cadr A))
      (regDst A) ) )

(asmNoCC neg (Dst D)
   (let A (dstReg Dst D)
      (prinst "neg" (cadr A) (cadr A))
      (regDst A) ) )

(asm and (Dst D Src S)
   (if (and (=0 S) (>= 65535 (format Src) 0))
      (let A (dstReg Dst D)
         (prinst "andi." (cadr A) (cadr A) (format Src))
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "and." (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asmNoCC and (Dst D Src S)
   (if (and (=0 S) (>= 65535 (format Src) 0))
      (let A (dstReg Dst D)
         (prinst "andi." (cadr A) (cadr A) (format Src))  # 'and' doesn't exist
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "and" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asm or (Dst D Src S)
   (let A (dstSrcReg Dst D Src S)
      (prinst "or." (caddr A) (caddr A) (car A))  # 'ori.' doesn't exist
      (regDst (cdr A)) ) )

(asmNoCC or (Dst D Src S)
   (if (and (=0 S) (>= 65535 (format Src) 0))
      (let A (dstReg Dst D)
         (prinst "ori" (cadr A) (cadr A) (format Src))
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "or" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asm xor (Dst D Src S)
   (let A (dstSrcReg Dst D Src S)
      (prinst "xor." (caddr A) (caddr A) (car A))  # 'xori.' doesn't exist
      (regDst (cdr A)) ) )

(asmNoCC xor (Dst D Src S)
   (if (and (=0 S) (>= 65535 (format Src) 0))
      (let A (dstReg Dst D)
         (prinst "xori" (cadr A) (cadr A) (format Src))
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "xor" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asm off (Dst D Src S)
   (let (A (dstReg Dst D)  R (tmpReg))
      (prinst "li" R Src)
      (prinst "and." (cadr A) (cadr A) R)
      (regDst A) ) )

(asm test (Dst D Src S)
   (prinst "li" 31 -2)  # Clear carry
   (if (and (=0 S) (>= 65535 (format Src) 0))
      (let A (dstReg Dst D)
         (prinst "andi." 0 (cadr A) (format Src)) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "and." 0 (caddr A) (car A)) ) ) )

(asm shl (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (when (gt0 (dec (format Src)))
            (prinst "sldi" (cadr A) (cadr A) @) )
         (prinst "addc." (cadr A) (cadr A) (cadr A))
         (regDst A)
         (prinst "subfze" 31 21) )  # Set carry from MSB
      (let A (dstSrcReg Dst D Src S)
         (prinst "sld." (caddr A) (caddr A) (car A))  # Ignore carry
         (regDst (cdr A)) ) ) )

(asmNoCC shl (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (prinst "sldi" (cadr A) (cadr A) (format Src))
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "sld" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asm shr (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (when (gt0 (dec (format Src)))
            (prinst "srdi" (cadr A) (cadr A) @) )
         (prinst "li" 31 -2)  # Set carry from LSB
         (prinst "insrdi" 31 (cadr A) 1 63)
         (prinst "srdi." (cadr A) (cadr A) 1)
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "srd." (caddr A) (caddr A) (car A))  # Ignore carry
         (regDst (cdr A)) ) ) )

(asmNoCC shr (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (prinst "srdi" (cadr A) (cadr A) (format Src))
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "srd" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asm rol (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (prinst "rotldi" (cadr A) (cadr A) (format Src))
         (regDst A) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "rotld" (caddr A) (caddr A) (car A))
         (regDst (cdr A)) ) ) )

(asm ror (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (prinst "rotrdi" (cadr A) (cadr A) (format Src))
         (regDst A) )
      (quit "Non-immediate 'ror' not available") ) )

(asm rxl (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (prinst "sradi" 0 31 1)  # Get carry
         (do (format Src)
            (prinst "adde." (cadr A) (cadr A) (cadr A)) )
         (regDst A)
         (prinst "subfze" 31 21) )  # Set carry
      (quit "Non-immediate 'rxl' not available") ) )

(asmNoCC rxl (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (prinst "sradi" 0 31 1)  # Get carry
         (do (format Src)
            (prinst "adde" (cadr A) (cadr A) (cadr A)) )
         (regDst A) )
      (quit "Non-immediate 'rxl' not available") ) )

(asm rxr (Dst D Src S)
   (if (=0 S)
      (let A (dstReg Dst D)
         (do (setq Src (format Src))
            (prinst "mr" 0 (cadr A))
            (prinst "rotrdi" (cadr A) (cadr A) 1)
            (prinst "insrdi" (cadr A) 31 1 0)
            (prinst "insrdi" 31 0 1 63) )
         (regDst A) )
      (quit "Non-immediate 'rxr' not available") ) )

(asm mul (Src S)
   (let R (srcReg Src S)
      (prinst "mulhdu" 14 3 R)
      (prinst "mulld" 3 3 R) ) )

(asm div (Src S)
   (srcReg Src S 4)
   (codeCall "div") )

(asm zxt ()  # 8 bit -> 64 bit
   (prinst "andi." 3 3 255) )  # 'and' doesn't exist

(asm eq ()
   (prinst "li" 31 -2)  # Clear carry
   (prinst "addic." 0 20 0) )  # Add zero to null

(asm gt ()  #! (prinst "cmpd" 20 1)  # Compare zero to stack pointer
   (prinst "li" 31 -2)  # Clear carry
   (prinst "cmpdi" 1 0) )  # Compare stack pointer to zero

(asm lt ()  #! (prinst "cmpdi" 1 0)  # Compare stack pointer to zero
   (prinst "li" 31 -1)  # Set carry
   (prinst "cmpdi" 1 0) )  # Compare stack pointer to zero

(asm setx ()
   (prinst "li" 31 -1) )

(asm clrx ()
   (prinst "li" 31 -2) )

# Comparisons
(asm cmp (Dst D Src S)
   (if (and (=0 S) (>= 32767 (format Src) -32768))
      (let A (dstReg Dst D)
         (prinst "subic." 0 (cadr A) Src) )
      (let A (dstSrcReg Dst D Src S)
         (prinst "subc." 0 (caddr A) (car A)) ) )
   (prinst "subfme" 31 21) )  # Set inverted carry

(asm cmpn (Dst D Src S Cnt C)
   (memory Dst D 4)
   (memory Src S 5)
   (memory Cnt C 6 0)
   (codeCall "cmpn") )

(asm slen (Dst D Src S)
   (memory Src S 5)
   (codeCall "slen")
   (memory Dst D 4 T) )

(asm memb (Src S Cnt C)
   (memory Src S 4)
   (memory Cnt C 5 0)
   (codeCall "memb")
   (unless S (prinst "mr" Src 4))
   (unless C (prinst "mr" Cnt 5)) )

(asm null (Src S)
   (prinst "li" 31 -2)  # Clear carry
   (prinst "cmpdi" (srcReg Src S) 0) )

(asm nulp (Src S)
   (prinst "cmpdi" (srcReg Src S) 0) )

(asm nul4 ()
   (prinst "li" 31 -2)  # Clear carry
   (prinst "sldi" 3 3 32)
   (prinst "sradi." 3 3 32) )

# Byte addressing
(asm set (Dst D Src S)
   (memory Dst D (srcByteReg Src S) "stb") )

(asm nul (Src S)
   (prinst "li" 31 -2)  # Clear carry
   (prinst "cmpdi" (srcByteReg Src S) 0) )

# Types
(asm cnt (Src S)
   (prinst "andi." 0 (srcReg Src S) "0x02") )

(asm big (Src S)
   (prinst "andi." 0 (srcReg Src S) "0x04") )

(asm num (Src S)
   (prinst "andi." 0 (srcReg Src S) "0x06") )

(asm sym (Src S)
   (prinst "andi." 0 (srcReg Src S) "0x08") )

(asm atom (Src S)
   (prinst "andi." 0 (srcReg Src S) "0x0E") )

# Flow control
(asm call (Adr A)
   (nond
      (A  # Absolute
         (codeCall Adr) )
      ((=T A)  # Indexed: Ignore SUBR
         (prinst "mtctr" Adr)
         (prinst "bl" "callCtr") )
      (NIL  # Indirect
         (prinst "ld" 12 (pack (dataOffset Adr) "(22)"))
         (prinst "mtctr" 12)
         (prinst "bl" "callCtr") ) ) )

(de _jmp Args
   (nond
      (A
         (let @Lbl Adr
            (cond
               ((lup *CodeIndex Adr)
                  (let Ofs (cdr @)
                     (if (>= 32767 Ofs)
                        (prinst "addi" 12 23 Ofs)
                        (prinst "lis" 12 (>> 16 Ofs))
                        (unless (=0 (setq Ofs (& 65535 Ofs)))
                           (prinst "ori" 12 12 Ofs) )
                        (prinst "add" 12 12 23) )
                     (prinst "mtctr" 12)
                     (for E (caddr Args)
                        (apply prinst (cons (pack (pop 'E) (pop 'E)) E)) ) ) )
               ((not (cadr Args))
                  (for E (fill (car Args))  # b
                     (apply prinst (cons (pack (pop 'E) (pop 'E)) E)) ) )
               (T
                  (let Back
                     (for (P *Program (n== *Statement (car P)) (cdr P))
                        (T (and (== ': (caar P)) (= Adr (cdar P))) T) )
                     (for E
                        (fill
                           ((if
                                 (or
                                    (= `(char ".") (char Adr))  # Local label
                                    (and
                                       (cdr (split (chop Adr) "_"))
                                       (format (last @)) ) )
                                 car
                                 cadr )
                              Args ) )
                        (apply prinst
                           (cons
                              (pack
                                 (pop 'E)
                                 (case (pop 'E)
                                    ("+" (if Back "-" "+"))
                                    ("-" (if Back "+" "-")) ) )
                              E ) ) ) ) ) ) ) )
      ((=T A)  # Ignore SUBR
         (prinst "mtctr" Adr)
         (for E (fill (caddr Args))
            (apply prinst (cons (pack (pop 'E) (pop 'E)) E)) ) )
      (NIL  # Indirect
         (prinst "ld" 12 (pack (dataOffset Adr) "(22)"))
         (prinst "mtctr" 12)
         (for E (caddr Args)
            (apply prinst (cons (pack (pop 'E) (pop 'E)) E)) ) ) ) )

(asm jmp (Adr A)
   (_jmp
      (("b" NIL @Lbl))
      NIL
      (("bctr" NIL)) ) )

(asm tos (Dst D)
   (if D
      (let R (tmpReg)
         (prinst "ld" R "0(1)")
         (memory Dst D R T) )
      (prinst "ld" Dst "0(1)") )
   (prinst "addi" 1 1 8) )

(asm jz (Adr A)
   (_jmp
      (("beq" - @Lbl))
      (("bne" + ".+8") ("b" NIL @Lbl))
      (("beqctr" -)) ) )

(asm jeq (Adr A)
   (_jmp
      (("beq" - @Lbl))
      (("bne" + ".+8") ("b" NIL @Lbl))
      (("beqctr" -)) ) )

(asm jnz (Adr A)
   (_jmp
      (("bne" - @Lbl))
      (("beq" + ".+8") ("b" NIL @Lbl))
      (("bnectr" -)) ) )

(asm jne (Adr A)
   (_jmp
      (("bne" - @Lbl))
      (("beq" + ".+8") ("b" NIL @Lbl))
      (("bnectr" -)) ) )

(asm js (Adr A)
   (_jmp
      (("blt" - @Lbl))
      (("bge" + ".+8") ("b" NIL @Lbl))
      (("bltctr" -)) ) )

(asm jns (Adr A)
   (_jmp
      (("bge" - @Lbl))
      (("blt" + ".+8") ("b" NIL @Lbl))
      (("bgectr" -)) ) )

(asm jsz (Adr A)
   (_jmp
      (("ble" - @Lbl))
      (("bgt" + ".+8") ("b" NIL @Lbl))
      (("blectr" -)) ) )

(asm jnsz (Adr A)
   (_jmp
      (("bgt" - @Lbl))
      (("ble" + ".+8") ("b" NIL @Lbl))
      (("bgtctr" -)) ) )

(asm jc (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("bne" - "cr1" @Lbl))
      (("beq" + "cr1" ".+8") ("b" NIL @Lbl))
      (("bnectr" - "cr1")) ) )

(asm jb (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("bne" - "cr1" @Lbl))
      (("beq" + "cr1" ".+8") ("b" NIL @Lbl))
      (("bnectr" - "cr1")) ) )

(asm jx (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("bne" - "cr1" @Lbl))
      (("beq" + "cr1" ".+8") ("b" NIL @Lbl))
      (("bnectr" - "cr1")) ) )

(asm jlt (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("bne" - "cr1" @Lbl))
      (("beq" + "cr1" ".+8") ("b" NIL @Lbl))
      (("bnectr" - "cr1")) ) )

(asm jnc (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("beq" - "cr1" @Lbl))
      (("bne" + "cr1" ".+8") ("b" NIL @Lbl))
      (("beqctr" - "cr1")) ) )

(asm jnb (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("beq" - "cr1" @Lbl))
      (("bne" + "cr1" ".+8") ("b" NIL @Lbl))
      (("beqctr" - "cr1")) ) )

(asm jnx (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("beq" - "cr1" @Lbl))
      (("bne" + "cr1" ".+8") ("b" NIL @Lbl))
      (("beqctr" - "cr1")) ) )

(asm jge (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("beq" - "cr1" @Lbl))
      (("bne" + "cr1" ".+8") ("b" NIL @Lbl))
      (("beqctr" - "cr1")) ) )

(asm jle (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("bne" - "cr1" @Lbl) ("beq" - @Lbl))
      (("beq" - "cr1" ".+12") ("bne" + ".+8") ("b" NIL @Lbl))
      (("bnectr" - "cr1") ("beqctr" -) ) ) )

(asm jgt (Adr A)
   (prinst "cmpdi" "cr1" 31 -2)
   (_jmp
      (("bne" + "cr1" ".+8") ("bne" - @Lbl))
      (("bne" + "cr1" ".+12") ("beq" + ".+8") ("b" NIL @Lbl))
      (("bne" + "cr1" ".+8") ("bnectr" NIL)) ) )

(asm ret ()
   (prinst "blr") )

(asm catch ())

(asm throw ()
   (prinst "blr") )

# Floating point
(asm ldd ()
   (prinst "lfd" 1 "0(14)") )

(asm ldf ()
   (prinst "lfs" 1 "0(14)") )

(asm fixnum ()
   (prinst "srdi" 0 15 4)  # Normalize scale (ignore sign)
   (prinst "std" 0 "-8(1)")
   (prinst "lfd" 0 "-8(1)")  # Get scale in f13
   (prinst "fcfid" 13 0)
   (prinst "fmul" 1 1 13)  # Multiply with value
   (prinst "fctid" 0 1)  # Convert to integer
   (prinst "stfd" 0 "-8(1)")
   (prinst "ld" 15 "-8(1)")  # In E
   (prinst "or." 15 15 15)  # Sign?
   (prinst "blt-" "1f")  # Yes
   (prinst "extrdi." 0 15 4 0)  # Overflow?
   (prinst "beq+" "3f")  # No
   (prinst "la" 15 "TSym-Data(22)")
   (prinst "b" "4f")
   (prinl "1:")
   (prinst "extrdi" 0 15 4 0)  # Underflow?
   (prinst "neg" 15 15)  # Negate
   (prinst "cmpdi" 0 0 15)
   (prinst "beq+" "2f")  # No
   (prinst "mr" 15 25)  # Nil
   (prinst "b" "4f")
   (prinl "2:")
   (prinst "sldi" 15 15 4)  # Make negative short number
   (prinst "ori" 15 15 10)
   (prinst "b" "4f")
   (prinl "3:")
   (prinst "sldi" 15 15 4)  # Make short number
   (prinst "ori" 15 15 2)
   (prinl "4:") )

(asm float ()
   (prinst "mr" 0 3)             # Get scale in A
   (prinst "srdi" 0 0 4)         # Normalize (ignore sign)
   (prinst "std" 0 "-8(1)")
   (prinst "ld" 27 "0(16)")      # Value
   (prinst "andi." 0 27 "0x02")  # Short?
   (prinst "beq-" "2f")          # No
   (prinst "lfd" 0 "-8(1)")      # Get scale in f13
   (prinst "fcfid" 13 0)
   (prinst "andi." 0 27 "0x08")  # Value negative?
   (prinst "srdi" 27 27 4)       # Scale value
   (prinst "beq-" "1f")
   (prinst "neg" 27 27)          # Negate
   (prinl "1:")
   (prinst "std" 27 "-8(1)")     # Get value
   (prinst "lfd" 0 "-8(1)")
   (prinst "fcfid" 1 0)          # in f1
   (prinst "fdiv" 1 1 13)        # Divide by scale
   (prinst "b" "3f")
   (prinl "2:")                  # T or NIL
   (prinst "cmpd" 25 27)         # Nil?
   (prinst "li" 27 (hex "7FF"))  # inf
   (prinst "bne-" ".+8")
   (prinst "li" 27 (hex "FFF"))  # -inf
   (prinst "rotrdi" 27 27 12)
   (prinst "std" 27 "-8(1)")     # Get value
   (prinst "lfd" 1 "-8(1)")
   (prinl "3:") )

(asm std ()
   (prinst "stfd" 1 "0(18)") )

(asm stf ()
   (prinst "stfs" 1 "0(18)") )

# C-Calls
(asm cc (Adr A Arg M)
   (let Reg (3 4 5 6 7 8 9 10)  # Support only max. 8 parameters
      (if (lst? Arg)
         (let (Lea NIL  Tmp NIL)
            (when (fish '((X) (= 3 X)) (cdr Arg))
               (prinst "mr" (setq Tmp 12) 3) )
            (mapc
               '((Src S)
                  (if (== '& Src)
                     (on Lea)
                     (setq Src
                        (recur (Src)
                           (cond
                              ((= 3 Src) (or Tmp 3))
                              ((atom Src) Src)
                              (T (cons (recurse (car Src)) (recurse (cdr Src)))) ) ) )
                     (cond
                        ((not Reg)  # 'Src' not stack-relative here!
                           #{MADA}# )
                        ((and (=T S) (== 'pop Src))
                           (prinst "ld" (pop 'Reg) "0(1)")
                           (prinst "addi" 1 1 8) )
                        (Lea (memory Src S (pop 'Reg)))
                        ((= 3 Src) (pop 'Reg))
                        (T (srcReg Src S (pop 'Reg))) )
                     (off Lea) ) )
               Arg
               M ) )
         (prinst "mr" 27 1)            # 27 on arguments
         (prinst "ld" 12 "flt1@got(2)")
         (for R Reg
            (prinst "cmpd" Arg 27)
            (prinst "beq-" "2f")
            (prinst "ld" 0 "0(27)")
            (prinst "cmpdi" 0 0)       # Float?
            (prinst "beq-" "1f")       # No
            (prinst "mtctr" 12)        # Else call float conversion
            (prinst "bctrl")
            (prinl "1:")
            (prinst "ld" R "8(27)")    # Get value
            (prinst "addi" 27 27 16) )
         (prinl "2:") ) )
   (nond
      (A  # Absolute
         (prinst "mflr" 27)
         (prinst "stdu" 1 "-112(1)")
         (prinst "bl" Adr)
         (prinst "nop")
         (prinst "addi" 1 1 112)
         (prinst "mtlr" 27) )
      ((=T A)  # Indexed
         (prinst "mflr" 0)
         (prinst "stdu" 1 "-120(1)")
         (prinst "std" 0 "112(1)")
         (prinst "std" 2 "24(1)")
         (prinst "mr" 12 Adr)
         (prinst "mtctr" Adr)
         (prinst "bctrl")
         (prinst "ld" 2 "24(1)")
         (prinst "ld" 0 "112(1)")
         (prinst "addi" 1 1 120)
         (prinst "mtlr" 0) ) )
   (and
      (lst? Arg)
      (gt0 (- (length Arg) 8))
      (prinst "addi" 1 1 (* @ 8)) ) )

(asm func ())

(asm begin ()
   (prinst "addis" 2 12 (pack ".TOC.-" *Label "@ha"))
   (prinst "addi" 2 2 (pack ".TOC.-" *Label "@l"))
   (prinst "mflr" 0)
   (prinst "bl" "begin") )

(asm return ()
   (prinst "b" "return") )

# Stack Manipulations
(asm push (Src S)
   (casq Src
      (zscx
         (let R (tmpReg)
            (prinst "mfocrf" R 128)  # Get CR[0]
            (prinst "insrdi" R 31 1 63)  # Carry into LSB
            (prinst "stdu" R "-8(1)") ) )
      (x (prinst "stdu" 31 "-8(1)"))
      (T (prinst "stdu" (srcReg Src S) "-8(1)")) ) )

(asm pop (Dst D)
   (cond
      (D
         (let R (tmpReg)
            (prinst "ld" R "0(1)")
            (memory Dst D R T) ) )
      ((== 'zscx Dst)
         (let R (tmpReg)
            (prinst "ld" R "0(1)")
            (prinst "insrdi" 31 R 1 63)  # Set carry from LSB
            (prinst "mtocrf" 128 R) ) )  # Set CR[0] (LT, GT, EQ, SO)
      ((== 'x Dst)
         (prinst "ld" 31 "0(1)") )
      (T (prinst "ld" Dst "0(1)")) )
   (prinst "addi" 1 1 8) )

(asm link ()
   (prinst "stdu" 19 "-8(1)")  # Push L
   (prinst "mr" 19 1) )

(asm tuck (Src S)
   (prinst "ld" 19 "0(1)")  # Get L
   (prinst "std" (srcReg Src S) "0(1)") )

(asm drop ()
   (prinst "ld" 1 "0(19)")  # Restore S
   (prinst "ld" 19 "0(1)")  # and L
   (prinst "addi" 1 1 8) )

# Evaluation
(asm eval ()
   (prinst "andi." 0 15 "0x06")   # Number?
   (prinst "bne-" "2f")           # Yes: Skip
   (prinst "andi." 0 15 "0x08")   # Symbol?
   (prinst "beq-" "1f")           # Yes: Get value
   (prinst "ld" 15 "0(15)")
   (prinst "b" "2f")              # and skip
   (prinl "1:")
   (codeCall "evListE_E")         # Else evaluate list
   (prinl "2:") )

(asm eval+ ()
   (prinst "andi." 0 15 "0x06")   # Number?
   (prinst "bne-" "2f")           # Yes: Skip
   (prinst "andi." 0 15 "0x08")   # Symbol?
   (prinst "beq-" "1f")           # Yes: Get value
   (prinst "ld" 15 "0(15)")
   (prinst "b" "2f")              # and skip
   (prinl "1:")
   (prinst "stdu" 19 "-8(1)")     # Else 'link'
   (prinst "mr" 19 1)
   (codeCall "evListE_E")         # Evaluate list
   (prinst "ld" 19 "0(1)")        # Pop L
   (prinst "addi" 1 1 8)
   (prinl "2:") )

(asm eval/ret ()
   (prinst "andi." 0 15 "0x06")   # Number?
   (prinst "bnelr-")              # Yes: Return
   (prinst "andi." 0 15 "0x08")   # Symbol?
   (prinst "beq-" "1f")           # No: Evaluate list
   (prinst "ld" 15 "0(15)")       # Get value
   (prinst "blr")
   (prinl "1:")
   (prinst "b" "evListE_E") )

(asm exec (Reg)
   (prinl "1:")                            # do
   (prinst "ld" 15 (pack "0(" Reg ")"))    # ld E (R)
   (prinst "andi." 0 15 "0x0E")            # atom E
   (prinst "bne+" "2f")
   (codeCall "evListE_E")                  # Evaluate list
   (prinl "2:")
   (prinst "ld" Reg  (pack "8(" Reg ")"))  # ld R (R CDR)
   (prinst "andi." 0 Reg "0x0E")           # atom R
   (prinst "beq+" "1b") )                  # until nz

(asm prog (Reg)
   (prinl "1:")                           # do
   (prinst "ld" 15 (pack "0(" Reg ")"))   # ld E (R)
   (prinst "andi." 0 15 "0x06")           # eval
   (prinst "bne-" "2f")
   (prinst "andi." 0 15 "0x08")
   (prinst "beq-" ".+12")
   (prinst "ld" 15 "0(15)")
   (prinst "b" "2f")
   (codeCall "evListE_E")                 # Evaluate list
   (prinl "2:")
   (prinst "ld" Reg (pack "8(" Reg ")"))  # ld R (R CDR)
   (prinst "andi." 0 Reg "0x0E")          # atom R
   (prinst "beq+" "1b") )                 # until nz


# System
(asm initData ())

(asm initCode ()
   (unless *FPic
      (prinst "mflr" 12)         # Get return address
      (prinst "lwa" 0 "0(12)")   # Target offset
      (prinst "add" 0 0 23)      # Code-relative
      (prinst "mtlr" 0)          # Set target address
      (prinst "addi" 0 12 4)     # Update return address
      (prinst "stdu" 0 "-8(1)")  # Save it
      (prinst "blrl")            # Call target
      (prinst "ld" 0 "0(1)")     # Pop return address
      (prinst "addi" 1 1 8)
      (prinst "mtctr" 0)         # Return
      (prinst "bctr")
      (prinl) )
   (label "callRel")
   (prinst "mflr" 12)          # Get return address
   (prinst "lwa" 0 "0(12)")    # Target offset
   (prinst "add" 0 0 12)       # PC-relative
   (prinst "mtlr" 0)           # Set target address
   (prinst "addi" 0 12 4)      # Update return address
   (prinst "stdu" 0 "-8(1)")   # Save it
   (prinst "blrl")             # Call target
   (prinst "ld" 0 "0(1)")      # Pop return address
   (prinst "addi" 1 1 8)
   (prinst "mtctr" 0)          # Return
   (prinst "bctr")
   (prinl)
   (label "callCtr")
   (prinst "mflr" 12)          # Get return address
   (prinst "stdu" 12 "-8(1)")  # Save it
   (prinst "bctrl")            # Call target
   (prinst "ld" 0 "0(1)")      # Pop return address
   (prinst "addi" 1 1 8)
   (prinst "mtctr" 0)          # Return
   (prinst "bctr")
   (prinl)
   (unless *FPic
      (prinl "# movn dst src cnt")
      (label "movn")
      (prinst "subi" 4 4 1)     # Adjust 'dst'
      (prinst "subi" 5 5 1)     # and 'src'
      (prinl "1:")
      (prinst "subic." 6 6 1)   # Decrement 'cnt'
      (prinst "bltlr")          # Return if done
      (prinst "lbzu" 7 "1(5)")  # Next byte from 'src'
      (prinst "stbu" 7 "1(4)")  # Write to 'dst'
      (prinst "b" "1b")
      (prinl)
      (prinl "# mset dst src cnt")
      (label "mset")
      (prinst "subi" 4 4 1)     # Adjust 'dst'
      (prinl "1:")
      (prinst "subic." 5 5 1)   # Decrement 'cnt'
      (prinst "bltlr")          # Return if done
      (prinst "stbu" 3 "1(4)")  # Write B to 'dst'
      (prinst "b" "1b")
      (prinl)
      (prinl "# save src end dst")
      (label "save")
      (prinst "ld" 7 "0(4)")    # First word from 'src'
      (prinst "std" 7 "0(6)")   # Write to 'dst'
      (prinl "1:")
      (prinst "ldu" 7 "8(4)")   # Next word from 'src'
      (prinst "cmpd" 4 5)       # Done?
      (prinst "beqlr-")         # Yes: Return
      (prinst "stdu" 7 "8(6)")  # Write to 'dst'
      (prinst "b" "1b")
      (prinl)
      (prinl "# load dst end src")
      (label "load")
      (prinst "ld" 7 "0(6)")    # First word from 'src'
      (prinst "std" 7 "0(4)")   # Write to 'dst'
      (prinst "subi" 5 5 8)     # Adjust 'end'
      (prinl "1:")
      (prinst "ldu" 7 "8(6)")   # Next word from 'src'
      (prinst "stdu" 7 "8(4)")  # Write to 'dst'
      (prinst "cmpd" 4 5)       # Done?
      (prinst "bne+" "1b")      # No
      (prinst "blr")
      (prinl)
      (prinl "# cmpn dst src cnt")
      (label "cmpn")
      (prinst "lbz" 7 "0(4)")   # First byte from 'dst'
      (prinst "lbz" 8 "0(5)")   # First byte from 'src'
      (prinl "1:")
      (prinst "subc." 0 7 8)    # Same bytes?
      (prinst "bnelr-")         # No: Return 'ne'
      (prinst "subic." 6 6 1)   # Decrement 'cnt'
      (prinst "beqlr-")         # Return 'eq' if done
      (prinst "lbzu" 7 "1(4)")  # Next bytes
      (prinst "lbzu" 8 "1(5)")
      (prinst "b" "1b")
      (prinl)
      (prinl "# slen dst src")
      (label "slen")
      (prinst "li" 4 0)         # Init 'dst' counter
      (prinst "lbz" 7 "0(5)")   # First byte from 'src'
      (prinl "1:")
      (prinst "cmpdi" 7 0)      # Done?
      (prinst "beqlr-")         # Yes: Return
      (prinst "addi" 4 4 1)     # Increment 'cnt'
      (prinst "lbzu" 7 "1(5)")  # Next byte
      (prinst "b" "1b")
      (prinl)
      (prinl "# memb src cnt")
      (label "memb")
      (prinst "mr" 6 4)           # Get 'src'
      (prinst "extrdi" 7 3 8 56)  # and B
      (prinl "1:")
      (prinst "subic." 5 5 1)     # Decrement 'cnt'
      (prinst "bltlr-")           # Return 'ne' if done
      (prinst "lbz" 8 "0(6)")     # Next byte from 'src'
      (prinst "addi" 6 6 1)       # Increment 'src'
      (prinst "cmpd" 8 7)         # Found?
      (prinst "bne+" "1b")        # No
      (prinst "mr" 4 6)           # Else return 'eq'
      (prinst "blr")
      (prinl)
      (prinl "# div src")  # From: http://hackers-delight.org.ua
      (label "div")        # 14:3 / 4
      (let
         (@u1 14  @u0 3  @v 4  @s 5            # un21 = un32 = u1
            @un1 6  @un0 7  @vn1 8  @vn0 9
            @q1 27  @q0 28  @rhat 29  @tmp 30 )
         (macro
            (prinst "cmpld" @u1 @v)            # u1 >= v?
            (prinst "bge-" "divOvfl")          # Yes: Overflow
            (prinst "li" @s 0)                 # Init 's'
            (prinst "cmpdi" @v 0)              # Normalize
            (prinst "blt" "div2")
            (prinl "div1:")
            (prinst "addi" @s @s 1)            # Increment 's'
            (prinst "addc" @u0 @u0 @u0)        # Shift dividend left
            (prinst "adde" @u1 @u1 @u1)
            (prinst "add." @v @v @v)           # and divisor
            (prinst "bge" "div1")
            (prinl "div2:")
            (prinst "extrdi" @vn1 @v 32 0)     # Split divisor into high 32 bits
            (prinst "extrdi" @vn0 @v 32 32)    # and low 32 bits
            (prinst "extrdi" @un1 @u0 32 0)    # Split 'u0' into high 32 bits
            (prinst "extrdi" @un0 @u0 32 32)   # and low 32 bits
            (prinst "divdu" @q1 @u1 @vn1)      # First quotient digit
            (prinst "mulld" 0 @q1 @vn1)
            (prinst "sub" @rhat @u1 0)
            (prinl "div3:")
            (prinst "extrdi." 0 @q1 32 0)      # q1 >= b?
            (prinst "bne-" "div4")             # Yes
            (prinst "sldi" @tmp @rhat 32)      # b*rhat + un1
            (prinst "add" @tmp @tmp @un1)
            (prinst "mulld" 0 @q1 @vn0)
            (prinst "cmpld" 0 @tmp)            # q1 * vn0 > b*rhat + un1?
            (prinst "ble+" "div5")             # No
            (prinl "div4:")
            (prinst "subi" @q1 @q1 1)          # Else decrement 'q1'
            (prinst "add" @rhat @rhat @vn1)    # Increment 'rhat'
            (prinst "extrdi." 0 @rhat 32 0)    # Less than 'b'?
            (prinst "beq-" "div3")             # Yes
            (prinl "div5:")
            (prinst "sldi" @u1 @u1 32)         # (un32*b)
            (prinst "add" @u1 @u1 @un1)        # (un1 + un32*b)
            (prinst "mulld" 0 @q1 @v)
            (prinst "sub" @u1 @u1 0)           # un21 = un1 + un32*b - q1*v
            (prinst "divdu" @q0 @u1 @vn1)      # Second quotient digit
            (prinst "mulld" 0 @q0 @vn1)
            (prinst "sub" @rhat @u1 0)
            (prinl "div6:")
            (prinst "extrdi." 0 @q0 32 0)      # q0 >= b?
            (prinst "bne-" "div7")             # Yes
            (prinst "sldi" @tmp @rhat 32)      # b*rhat + un0
            (prinst "add" @tmp @tmp @un0)
            (prinst "mulld" 0 @q0 @vn0)
            (prinst "cmpld" 0 @tmp)            # q0 * vn0 > b*rhat + un0?
            (prinst "ble+" "div8")             # No
            (prinl "div7:")
            (prinst "subi" @q0 @q0 1)          # Else decrement 'q0'
            (prinst "add" @rhat @rhat @vn1)    # Increment 'rhat'
            (prinst "extrdi." 0 @rhat 32 0)    # Less than 'b'?
            (prinst "beq-" "div6")             # Yes
            (prinl "div8:")
            (prinst "sldi" @u0 @q1 32)         # Quotient
            (prinst "add" @u0 @u0 @q0)
            (prinst "sldi" @u1 @u1 32)         # Remainder: u1 = (un0 + un21*b - q0*v) >> s
            (prinst "add" @u1 @u1 @un0)
            (prinst "mulld" 0 @q0 @v)
            (prinst "sub" @u1 @u1 0)
            (prinst "srd" @u1 @u1 @s)
            (prinst "blr")
            (prinl "divOvfl:")
            (prinst "li" @u0 -1)               # Overflow
            (prinst "li" @u1 -1)
            (prinst "blr") ) )
      (prinl)
      (let R 28  # 'cc' uses 27 as argument pointer
         (for F 8
            (label (pack "flt" F))
            (unless (= 8 F)
               (prinst "addi" 12 12 (pack "flt" (inc F) "-flt" F)) )
            (prinst "srdi" 0 0 4)  # Scale (ignore sign)
            (prinst "std" 0 "0(27)")
            (prinst "ld" R "8(27)")  # Value
            (prinst "andi." 0 R "0x02")  # Short?
            (prinst "beq-" "2f")  # No
            (prinst "lfd" 0 "0(27)")  # Get scale in f13
            (prinst "fcfid" 13 0)
            (prinst "andi." 0 R "0x08")  # Value negative?
            (prinst "srdi" R R 4)  # Scale value
            (prinst "beq-" "1f")
            (prinst "neg" R R)  # Negate
            (prinl "1:")
            (prinst "std" R "8(27)")  # Get value
            (prinst "lfd" 0 "8(27)")
            (prinst "fcfid" F 0)
            (prinst "fdiv" F F 13)  # Divide by scale
            (prinst "stfd" F "8(27)")
            (prinst "blr")
            (prinl "2:")  # T or NIL
            (prinst "cmpd" 25 R)  # Nil?
            (prinst "li" R (hex "7FF"))  # inf
            (prinst "bne-" ".+8")
            (prinst "li" R (hex "FFF"))  # -inf
            (prinst "rotrdi" R R 12)
            (prinst "std" R "8(27)")  # Get value
            (prinst "lfd" 0 "8(27)")
            (prinst "blr") ) )
      (prinl)
      (label "begin")
      (prinst "std" 14 "-144(1)")
      (prinst "std" 15 "-136(1)")
      (prinst "std" 16 "-128(1)")
      (prinst "std" 17 "-120(1)")
      (prinst "std" 18 "-112(1)")
      (prinst "std" 19 "-104(1)")
      (prinst "std" 20 "-96(1)")
      (prinst "std" 21 "-88(1)")
      (prinst "std" 22 "-80(1)")
      (prinst "std" 23 "-72(1)")
      (prinst "std" 24 "-64(1)")
      (prinst "std" 25 "-56(1)")
      (prinst "std" 26 "-48(1)")
      (prinst "std" 27 "-40(1)")
      (prinst "std" 28 "-32(1)")
      (prinst "std" 29 "-24(1)")
      (prinst "std" 30 "-16(1)")
      (prinst "std" 31 "-8(1)")
      (prinst "std" 0 "16(1)")
      (prinst "stdu" 1 "-256(1)")
      (prinst "li" 20 0)                   # Init NULL register
      (prinst "li" 21 1)                   # Init ONE register
      (prinst "ld" 22 "Data@got(2)")       # Globals bases
      (prinst "ld" 23 "Code@got(2)")
      (prinst "la" 25 "Nil-Data(22)")      # Nil
      (prinst "mr" 18 8)                   # Z
      (prinst "mr" 17 7)                   # Y
      (prinst "mr" 16 6)                   # X
      (prinst "mr" 15 5)                   # E
      (prinst "mr" 14 4)                   # C
      (prinst "blr")
      (prinl)
      (label "return")
      (prinst "addi" 1 1 256)
      (prinst "ld" 14 "-144(1)")
      (prinst "ld" 15 "-136(1)")
      (prinst "ld" 16 "-128(1)")
      (prinst "ld" 17 "-120(1)")
      (prinst "ld" 18 "-112(1)")
      (prinst "ld" 19 "-104(1)")
      (prinst "ld" 20 "-96(1)")
      (prinst "ld" 21 "-88(1)")
      (prinst "ld" 22 "-80(1)")
      (prinst "ld" 23 "-72(1)")
      (prinst "ld" 24 "-64(1)")
      (prinst "ld" 25 "-56(1)")
      (prinst "ld" 26 "-48(1)")
      (prinst "ld" 27 "-40(1)")
      (prinst "ld" 28 "-32(1)")
      (prinst "ld" 29 "-24(1)")
      (prinst "ld" 30 "-16(1)")
      (prinst "ld" 31 "-8(1)")
      (prinst "ld" 0 "16(1)")
      (prinst "mtlr" 0)
      (prinst "blr") ) )

(asm initMain ()
   (prinst "addis" 2 12 ".TOC.-main@ha")
   (prinst "addi" 2 2 ".TOC.-main@l")
   (prinst "li" 20 0)                 # Init NULL register
   (prinst "li" 21 1)                 # Init ONE register
   (prinst "ld" 22 "Data@got(2)")     # Globals bases
   (prinst "ld" 23 "Code@got(2)")
   (prinst "la" 25 "Nil-Data(22)")    # Nil
   (prinst "ld" 16 "0(4)")            # Get command in X
   (prinst "la" 17 "8(4)")            # argument vector in Y
   (prinst "subi" 3 3 1)              # and pointer to last argument in Z
   (prinst "sldi" 3 3 3)
   (prinst "add" 18 4 3) )

(asm initLib ())

(asm stop ()
   (prinst "mr" 3 15)
   (prinst "bl" "exit")
   (prinst "nop") )

### Optimizer ###
# Replace the the next 'cnt' elements with 'lst'
(de optimize (Lst)  #> (cnt . lst)
   (when (noCC Lst)
      (cons 1 (cons (cons @ (cdar Lst)))) ) )

### Decoration ###
(de prolog (File)
   (when *FPic
      (in "ppc64.symtab"
         (balance '*DataIndex (read))
         (balance '*CodeIndex (read)) ) ) )

(de epilog (File)
   (unless *FPic
      (out "ppc64.symtab"
         (println (sort *DataLabels))
         (println (sort *CodeLabels)) ) ) )

# vi:et:ts=3:sw=3
