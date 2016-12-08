# 31jul16abu
# (c) Software Lab. Alexander Burger

# Architecture
(in '("./sysdefs")
   (case (read)
      ("L" (on *LittleEndian))
      ("B" (off *LittleEndian))
      (T (quit "Bad endianess")) )
   (case (read)
      (32 (off *Bits64))
      (64 (on *Bits64))
      (T (quit "Bad wordsize")) ) )

(off *AlignedCode)

# Register assignments
(de *Registers
   (A . "A") (C . "C") (E . "E")
   (B . "A.b[0]") (D "A" . "C")
   (X . "X") (Y . "Y") (Z . "Z")
   (L . "L") (S . "S")
   (zscx . zscx) (zsc . zscx) (x . x) )

# Emulator specific
(off *AsmData *AsmCode *AsmOpcodes *Labels *SysFun)
(off *BaseData *BaseCode *BaseOpcodes)
(zero *AsmPos *OpOffs)

# Direct address expressions
(de directExpr (Str)
   (let (Lst (str Str "_")  A (_aggr))
      (or
         (num? A)
         (pack "(uint8_t*)" (text (cdr A) (car A))) ) ) )

(de _aggr ()
   (let X (_prod)
      (while (member (car Lst) '("+" "-"))
         (let (Op (intern (pop 'Lst))  Y (_prod))
            (if2 (pair X) (pair Y)
               (if (= '+ Op)
                  (quit "Bad direct expression")
                  (setq X (- (car X) (car Y))) )
               (set X (Op (car X) Y))
               (setq X (cons (Op X (car Y))))
               (and (sym? X) (or (baseCode X) (absCode X)) (setq X @))
               (and (sym? Y) (or (baseCode Y) (absCode Y)) (setq Y @))
               (setq X (Op X Y)) ) ) )
      X ) )

(de _prod ()
   (let X (_term)
      (while (member (car Lst) '("*" "/"))
         (setq X ((intern (pop 'Lst)) X (_term))) )
      X ) )

(de _term ()
   (let X (pop 'Lst)
      (cond
         ((num? X) X)
         ((and *FPic (get *BaseData X))
            (cons @ "Data+@1") )
         ((get *AsmData X)
            (cons (car @) (if *FPic "LibData+@1" "Data+@1")) )
         ((baseCode X)
            (cons @ "(Code+@1)") )
         ((absCode X)
            (cons @ (if *FPic "(LibCode+@1)" "(Code+@1)")) )
         ((= "+" X) (_term))
         ((= "-" X) (- (_term)))
         ((= "(" X) (prog1 (_aggr) (pop 'Lst)))
         (T (quit "Bad term" X)) ) ) )

(de sysFun (S O)
   (cond
      ((=0 O) (pack "(void(*)())" S))
      ((absCode S)
         (push1 '*SysFun
            (pack
               "void fun"
               @
               "(long a, long c, long e, long x, long y, long z) {begin("
               @
               ", a, c, e, x, y, z);}" ) )
         (pack "(void(*)())fun" @) )
      (T (quit "Bad function address" S)) ) )

# Addressing modes
(de op.p (Arg M)
   (cond
      ((=0 M) (pack "(uint8_t*)" Arg)) # Immediate
      ((not M) (pack Arg ".p"))        # Register
      ((get Arg 'sys) @)
      ((=T M)                          # Direct
         (let E (directExpr Arg)
            (if (num? E)
               (pack "(uint8_t*)" E)
               (pack "(" E ")") ) ) )
      ((get Arg 1 'sys) @)
      ((=T (cdr M))
         (let E (directExpr (cdr Arg))
            (pack
               "(*(ptr)("
               ((if (num? E) op.p op.n) (car Arg) (car M))
               " + "
               E
               ")).p" ) ) )
      ((cdr Arg)
         (pack "(*(ptr)(" (op.p (car Arg) (car M)) " + " @ ")).p") )
      (T (pack "(*(ptr)" (op.p (car Arg) (car M)) ").p")) ) )

(de op.n (Arg M)
   (cond
      ((=0 M)                          # Immediate
         (let N (format Arg)
            (if (>= N `(** 2 31))
               (pack "0x" (hex N) "LL")
               Arg ) ) )
      ((not M)                         # Register
         (if (= "A.b[0]" Arg)
            Arg
            (pack Arg ".n") ) )
      ((=T M)                          # Direct
         (if (get Arg 'sys)
            (pack "(uint64_t)(unsigned long)" (sysFun @ T))
            (let E (directExpr Arg)
               (if (num? E)
                  (pack "(uint64_t)" E)
                  (pack "((uint64_t)(unsigned long)(" E "))") ) ) ) )
      ((=T (cdr M))
         (let E (directExpr (cdr Arg))
            (pack
               "((ptr)("
               ((if (num? E) op.p op.n) (car Arg) (car M))
               " + "
               E
               "))->n" ) ) )
      ((cdr Arg)
         (pack "((ptr)(" (op.p (car Arg) (car M)) " + " @ "))->n") )
      (T (pack "((ptr)" (op.p (car Arg) (car M)) ")->n")) ) )

(de op.i (S O)
   (if (and (format (setq S (op.n S O))) (>= 32767 (abs @)))
      S
      (pack "(int)" S) ) )

(de op.b (Arg M)
   (cond
      ((=0 M) Arg)                     # Immediate
      ((not M)                         # Register
         (if (= "A.b[0]" Arg)
            Arg
            (pack Arg ".b[0]") ) )
      ((=T M)                          # Direct
         (let E (directExpr Arg)
            (if (num? E)
               (pack "(uint8_t)" E)
               (pack "*(" E ")") ) ) )
      ((=T (cdr M))
         (let E (directExpr (cdr Arg))
            (pack
               "*("
               ((if (num? E) op.p op.n) (car Arg) (car M))
               " + "
               E
               ")" ) ) )
      ((cdr Arg)
         (pack "*(" (op.p (car Arg) (car M)) " + " @ ")") )
      (T (pack "*" (op.p (car Arg) (car M)))) ) )

(de op.a (Arg M)
   (cond
      ((=0 M) (quit "Can't take address" Arg))  # Immediate
      ((flg? M) (op.p Arg M))                   # Register or Direct
      ((=T (cdr M))
         (let E (directExpr (cdr Arg))
            (pack
               "("
               ((if (num? E) op.p op.n) (car Arg) (car M))
               " + "
               E
               ")" ) ) )
      ((cdr Arg)
         (pack "(" (op.p (car Arg) (car M)) " + " @ ")") )
      (T (op.p (car Arg) (car M))) ) )

(de highWord (Arg M)
   (if (atom M)                        # Immediate, Register or Direct
      0
      (if (cdr Arg)
         (pack "((ptr)(" (op.p (car Arg) (car M)) " + " @ " + 8))->n")
         (pack "((ptr)(" (op.p (car Arg) (car M)) " + 8))->n") ) ) )

### Instruction set ###
(de alignSection (Align)
   (if (== 'data *Section)
      (when (gt0 (% (asmDataLength) 16))
         (conc (car *AsmData) (need (- 16 @) 0)) )
      (setq Align (/ Align 2))
      (until (= Align (& *AsmPos 7))
         (addCode '(NIL '(nop))) ) ) )

(de fmtInstruction (Lst)
   (replace (chop (str Lst)) "\"") )

(de opcode ("X" "Args" "Body")
   (cond
      ((= "X" '(nop)) 0)
      ((index "X" *BaseOpcodes) @)
      ((assoc "X" *AsmOpcodes) (+ *OpOffs (index @ *AsmOpcodes)))
      (T
         (queue '*AsmOpcodes
            (cons "X"
               ~(as *Dbg
                  (pack
                     "fprintf(stderr, \"%ld: %s\\n\", Code<=PC && PC<Code+32767? PC-Code-1 : 0, \""
                     (fmtInstruction "X")
                     "\");" ) )
               (mapcar '((S) (apply text "Args" S)) "Body") ) )
         (+ *OpOffs (length *AsmOpcodes)) ) ) )

(de addCode (C)
   (if (and *AsmCode (not (caar @)))
      (set (car *AsmCode) C)
      (push '*AsmCode (cons C)) )
   (inc '*AsmPos) )

(de genCode Args
   (addCode (cons (env (pop 'Args)) Args)) )

(de baseCode (Adr)
   (and *FPic (get *BaseCode Adr)) )

(de absCode (Lbl)
   (val (car (idx '*Labels Lbl))) )

(de relCode (Adr)
   (- (absCode Adr) 1 *AsmPos) )


(asm nop ()
   (addCode '(NIL '(nop))) )

(asm align (N)
   (if (== 'data *Section)
      (when (gt0 (% (asmDataLength) N))
         (conc (car *AsmData) (need (- N @) 0)) )
      (setq N (/ N 2))
      (while (gt0 (% *AsmPos N))
         (addCode '(NIL '(nop))) ) ) )

(asm skip (N)
   (if (== 'data *Section)
      (conc (car *AsmData) (need N 0))
      (do (/ N 2) (addCode '(NIL '(nop)))) ) )

# Move data
(asm ld (Dst D Src S)
   (cond
      ((= "A.b[0]" Dst)
         (genCode (Dst Src S) (list 'ld Dst Src) ((op.b Src S))
            "A.b[0] = @1;" ) )
      ((= "A.b[0]" Src)
         (genCode (Dst Src D) (list 'ld Dst Src) ((op.b Dst D))
            "@1 = A.b[0];" ) )
      ((and (not D) (pair Dst))
         (genCode (Src S) (list 'ld 'D Src) ((op.n Src S) (highWord Src S))
            "A.n = @1,  C.n = @2;" ) )
      ((and (not S) (pair Src))
         (genCode (Dst D) (list 'ld Dst 'D) ((op.n Dst D) (highWord Dst D))
            "@1 = A.n,  @2 = C.n;" ) )
      (T
         (genCode (Dst D Src S) (list 'ld Dst Src) ((op.n Dst D) (op.n Src S))
            "@1 = @2;" ) ) ) )

(asm ld2 (Src S)
   (genCode (Src S) (list 'ld2 Src) ((op.a Src S))
      "A.n = (uint64_t)*(uint16_t*)@1;" ) )

(asm ld4 (Src S)
   (genCode (Src S) (list 'ld4 Src) ((op.a Src S))
      "A.n = (uint64_t)*(uint32_t*)@1;" ) )

(asm ldz (Dst D Src S)
   (genCode (Dst D Src S) (list 'ldz Dst Src) ((op.n Dst D) (op.n Src S))
      "if (!Result)"
      "   @1 = @2;" ) )

(asm ldnz (Dst D Src S)
   (genCode (Dst D Src S) (list 'ldnz Dst Src) ((op.n Dst D) (op.n Src S))
      "if (Result)"
      "   @1 = @2;" ) )

(asm lea (Dst D Src S)
   (genCode (Dst D Src S) (list 'lea Dst Src) ((op.n Dst D) (op.a Src S))
      "@1 = (uint64_t)(unsigned long)@2;" ) )

(asm st2 (Dst D)
   (genCode (Dst D) (list 'st2 Dst) ((op.a Dst D))
      "*(uint16_t*)@1 = (uint16_t)A.l;" ) )

(asm st4 (Dst D)
   (genCode (Dst D) (list 'st4 Dst) ((op.a Dst D))
      "*(uint32_t*)@1 = A.l;" ) )

(asm xchg (Dst D Dst2 D2)
   (genCode (Dst D Dst2 D2) (list 'xchg Dst Dst2) ((op.n Dst D) (op.n Dst2 D2))
      "tmp.n = @1,  @1 = @2,  @2 = tmp.n;" ) )

(asm movn (Dst D Src S Cnt C)
   (genCode (Dst D Src S Cnt C) (list 'movn Dst Src Cnt) ((op.a Dst D) (op.a Src S) (op.i Cnt C))
      "memmove(@1, @2, @3);" ) )

(asm mset (Dst D Cnt C)
   (genCode (Dst D Cnt C) (list 'mset Dst Cnt) ((op.a Dst D) (op.i Cnt C))
      "memset(@1, (int)A.b[0], @2);" ) )

(asm save (Src S End E Dst D)
   (genCode (Dst D Src S End E) (list 'save Dst Src End) ((op.a Dst D) (op.a Src S) (op.a End E))
      "memmove(@1, @2, @3 - @2);" ) )

(asm load (Dst D End E Src S)
   (genCode (Dst D Src S End E) (list 'load Dst Src End) ((op.a Dst D) (op.a Src S) (op.a End E))
      "memmove(@1, @2, @3 - @1);" ) )

# Arithmetics
(asm add (Dst D Src S)
   (cond
      ((= Dst "S")
         (genCode (Dst D Src S) (list 'add Dst Src) ((op.n Dst D) (op.n Src S))
            "@1 += @2;" ) )
      ((or D (atom Dst))
         (genCode (Dst D Src S) (list 'add Dst Src) ((op.n Dst D) (op.n Src S))
            "Carry = (Result = @1 += (tmp.n = @2)) < tmp.n;" ) )
      (T
         (genCode (Src S) (list 'add 'D Src) ((op.n Src S))
            "Carry = (A.n += @1) < @1 && ++C.n == 0;"
            "Result = C.n;" ) ) ) )  # 'z' only for upper word

(asm addc (Dst D Src S)
   (if (or D (atom Dst))
      (genCode (Dst D Src S) (list 'addc Dst Src) ((op.n Dst D) (op.n Src S))
         "if ((tmp.n = @2 + Carry) == 0)"
         "   Result = @1;"
         "else"
         "   Carry = (Result = @1 += tmp.n) < tmp.n;" )
      (genCode (Src S) (list 'addc 'D Src) ((op.n Src S))
         "if ((tmp.n = @1 + Carry) == 0)"
         "   Carry = (C.n += Carry) == 0;"
         "else if ((A.n += tmp.n) < tmp.n)"
         "   Carry = ++C.n == 0;"
         "else"
         "   Carry = 0;"
         "Result = C.n;" ) ) )  # 'z' only for upper word

(asm sub (Dst D Src S)
   (if (= Dst "S")
      (genCode (Dst D Src S) (list 'sub Dst Src) ((op.n Dst D) (op.n Src S))
         "@1 -= @2;" )
      (genCode (Dst D Src S) (list 'sub Dst Src) ((op.n Dst D) (op.n Src S))
         "Carry = (Result = @1 -= (tmp.n = @2)) > MAX64 - tmp.n;" ) ) )

(asm subb (Dst D Src S)
   (genCode (Dst D Src S) (list 'subb Dst Src) ((op.n Dst D) (op.n Src S))
      "if ((tmp.n = @1 - Carry) > MAX64 - Carry)"
      "   Result = @1 = MAX64 - @2;"
      "else"
      "   Carry = (Result = @1 = tmp.n - @2) > MAX64 - @2;" ) )

(asm inc (Dst D)
   (genCode (Dst D) (list 'inc Dst) ((op.n Dst D))
      "Result = ++@1;" ) )

(asm dec (Dst D)
   (genCode (Dst D) (list 'dec Dst) ((op.n Dst D))
      "Result = --@1;" ) )

(asm not (Dst D)
   (genCode (Dst D) (list 'not Dst) ((op.n Dst D))
      "Result = @1 = ~@1;" ) )

(asm neg (Dst D)
   (genCode (Dst D) (list 'neg Dst) ((op.n Dst D))
      "Result = @1 = -@1;" ) )

(asm and (Dst D Src S)
   (if (or (= Dst "A.b[0]") (= Src "A.b[0]"))
      (genCode (Dst D Src S) (list 'and Dst Src) ((op.b Dst D) (op.b Src S))
         "Result = @1 &= @2;" )
      (genCode (Dst D Src S) (list 'and Dst Src) ((op.n Dst D) (op.n Src S))
         "Result = @1 &= @2;" ) ) )

(asm or (Dst D Src S)
   (if (or (= Dst "A.b[0]") (= Src "A.b[0]"))
      (genCode (Dst D Src S) (list 'or Dst Src) ((op.b Dst D) (op.b Src S))
         "Result = @1 |= @2;" )
      (genCode (Dst D Src S) (list 'or Dst Src) ((op.n Dst D) (op.n Src S))
         "Result = @1 |= @2;" ) ) )

(asm xor (Dst D Src S)
   (if (or (= Dst "A.b[0]") (= Src "A.b[0]"))
      (genCode (Dst D Src S) (list 'xor Dst Src) ((op.b Dst D) (op.b Src S))
         "Result = @1 \^= @2;" )
      (genCode (Dst D Src S) (list 'xor Dst Src) ((op.n Dst D) (op.n Src S))
         "Result = @1 \^= @2;" ) ) )

(asm off (Dst D Src S)
   (genCode (Dst D Src S) (list 'off Dst (pack (cdr (chop Src)))) ((op.n Dst D) (op.n Src S))
      "Result = @1 &= @2;" ) )

(asm test (Dst D Src S)
   (if (or (= Dst "A.b[0]") (= Src "A.b[0]"))
      (genCode (Dst D Src S) (list 'test Dst Src) ((op.b Dst D) (op.b Src S))
         "Result = @1 & @2;" )
      (genCode (Dst D Src S) (list 'test Dst Src) ((op.n Dst D) (op.n Src S))
         "Result = @1 & @2;" ) ) )

(asm shl (Dst D Src S)
   (genCode (Dst D Src S) (list 'shl Dst Src) ((op.n Dst D) (op.n Src S))
      "Carry = @1 >> 64 - @2 & 1;"
      "Result = @1 <<= @2;" ) )

(asm shr (Dst D Src S)
   (genCode (Dst D Src S) (list 'shr Dst Src) ((op.n Dst D) (op.n Src S))
      "Carry = @1 >> @2 - 1 & 1;"
      "Result = @1 >>= @2;" ) )

(asm rol (Dst D Src S)
   (if (=0 S)
      (genCode (Dst D Src) (list 'rol Dst Src) ((op.n Dst D) Src)
         "@1 = @1 << @2 | @1 >> (64 - @2);" )
      (genCode (Dst D Src S) (list 'rol Dst Src) ((op.n Dst D) (op.i Src S))
         "i = @2,  @1 = @1 << i | @1 >> (64 - i);" ) ) )

(asm ror (Dst D Src S)
   (if (=0 S)
      (genCode (Dst D Src) (list 'ror Dst Src) ((op.n Dst D) Src)
         "@1 = @1 >> @2 | @1 << (64 - @2);" )
      (genCode (Dst D Src S) (list 'ror Dst Src) ((op.n Dst D) (op.i Src S))
         "i = @2,  @1 = @1 >> i | @1 << (64 - i);" ) ) )

(asm rxl (Dst D Src S)
   (genCode (Dst D Src S) (list 'rxl Dst Src) ((op.n Dst D) (op.i Src S))
      "@1 = @1 << @2 | @1 >> (64 - @2);"
      "i = @1 & 1,  @1 = @1 & ~1 | Carry,  Carry = i;" ) )

(asm rxr (Dst D Src S)
   (genCode (Dst D Src S) (list 'rxr Dst Src) ((op.n Dst D) (op.i Src S))
      "i = @1 & 1,  @1 = @1 & ~1 | Carry,  Carry = i;"
      "@1 = @1 >> @2 | @1 << (64 - @2);" ) )

(asm mul (Src S)
   (genCode (Src S) (list 'mul Src) ((op.n Src S))
      "mul2(@1);" ) )

(asm div (Src S)
   (genCode (Src S) (list 'div Src) ((op.n Src S))
      "div2(@1);" ) )

(asm zxt ()  # 8 bit -> 64 bit
   (genCode NIL '(zxt) NIL
      "A.n &= 0xFF;" ) )

(asm eq ()
   (genCode NIL '(eq) NIL
      "Carry = 0,  Result = 0;" ) )

(asm gt ()
   (genCode NIL '(gt) NIL
      "Carry = 0,  Result = 1;" ) )

(asm lt ()
   (genCode NIL '(lt) NIL
      "Carry = 1,  Result = 1;" ) )

(asm setx ()
   (genCode NIL '(setx) NIL
      "Carry = 1;" ) )

(asm clrx ()
   (genCode NIL '(clrx) NIL
      "Carry = 0;" ) )

# Comparisons
(asm cmp (Dst D Src S)
   (cond
      ((or (= Dst "A.b[0]") (= Src "A.b[0]"))
         (genCode (Dst D Src S) (list 'cmp Dst Src) ((op.b Dst D) (op.b Src S))
            "Carry = (Result = @1 - @2) > MAX64 - @2;" ) )
      ((and (= Dst "S") (= Src '(StkLimit)))
         (genCode (Dst D Src S) (list 'cmp Dst Src) ((op.n Dst D) (op.n Src S))
            "if (S.p < Stack + 4064)"
            "   emuStkErr();"
            "Carry = (Result = @1 - @2) > MAX64 - @2;" ) )
      (T
         (genCode (Dst D Src S) (list 'cmp Dst Src) ((op.n Dst D) (op.n Src S))
            "Carry = (Result = @1 - @2) > MAX64 - @2;" ) ) ) )

(asm cmpn (Dst D Src S Cnt C)
   (genCode (Dst D Src S Cnt C) (list 'cmpn Dst Src Cnt) ((op.a Dst D) (op.a Src S) (op.i Cnt C))
      "Result = (uint64_t)memcmp(@1, @2, @3);" ) )

(asm slen (Dst D Src S)
   (genCode (Dst D Src S) (list 'slen Dst Src) ((op.n Dst D) (op.a Src S))
      "@1 = (uint64_t)strlen(@2);" ) )

(asm memb (Src S Cnt C)
   (cond
      (S
         (genCode (Src S Cnt C) (list 'memb Src Cnt) ((op.a Src S) (op.i Cnt C))
            "Result = !(uint64_t)(unsigned long)memchr(@1, (int)A.b[0], @2);" ) )
      (C
         (genCode (Src S Cnt C) (list 'memb Src Cnt) ((op.a Src S) (op.i Cnt C) Cnt)
            "if (!(Result = !(tmp.p = (uint8_t*)memchr(@1, (int)A.b[0], @2))))"
            "   @1 = tmp.p + 1;" ) )
      (T
         (genCode (Src S Cnt C) (list 'memb Src Cnt) ((op.a Src S) (op.i Cnt C) Cnt)
            "if (!(Result = !(tmp.p = (uint8_t*)memchr(@1, (int)A.b[0], @2))))"
            "   @3.n -= tmp.p - @1 + 1,  @1 = tmp.p + 1;" ) ) ) )

(asm null (Src S)
   (genCode (Src S) (list 'null Src) ((op.n Src S))
      "Carry = 0,  Result = @1;" ) )

(asm nulp (Src S)
   (genCode (Src S) (list 'nulp Src) ((op.i Src S))
      "Result = @1;" ) )

(asm nul4 ()
   (genCode NIL '(nul4) NIL
      "Carry = 0,  Result = (int32_t)A.l;" ) )

# Byte addressing
(asm set (Dst D Src S)
   (genCode (Dst D Src S) (list 'set Dst Src) ((op.b Dst D) (op.b Src S))
      "@1 = @2;" ) )

(asm nul (Src S)
   (genCode (Src S) (list 'nul Src) ((op.b Src S))
      "Carry = 0,  Result = @1;" ) )

# Types
(asm cnt (Src S)
   (genCode (Src S) (list 'cnt Src) ((op.b Src S))
      "Result = @1 & 2;" ) )

(asm big (Src S)
   (genCode (Src S) (list 'big Src) ((op.b Src S))
      "Result = @1 & 4;" ) )

(asm num (Src S)
   (genCode (Src S) (list 'num Src) ((op.b Src S))
      "Result = @1 & 6;" ) )

(asm sym (Src S)
   (genCode (Src S) (list 'sym Src) ((op.b Src S))
      "Result = @1 & 8;" ) )

(asm atom (Src S)
   (genCode (Src S) (list 'atom Src) ((op.b Src S))
      "Result = @1 & 14;" ) )

# Flow control
(de localAddr (Adr)
   (or
      (pre? "." Adr)  # Local label ".1"
      (and
         (cdr (setq Adr (split (chop Adr) "_")))  # Local jump "foo_22"
         (= *Label (pack (glue "_" (head -1 Adr))))
         (format (last Adr)) ) ) )

(asm call (Adr A)
   (nond
      (A  # Absolute
         (cond
            ((baseCode Adr)
               (genCode (Adr) (list 'call Adr) ((baseCode Adr))
                  "S.p -= 8,  *(uint16_t**)S.p = PC;"
                  "PC = Code + @1;" ) )
            (*FPic
               (genCode (Adr) (list 'call Adr) ((absCode Adr))
                  "S.p -= 8,  *(uint16_t**)S.p = PC;"
                  "PC = LibCode + @1;" ) )
            (T
               (genCode (Adr) (list 'call Adr) ((absCode Adr))
                  "S.p -= 8,  *(uint16_t**)S.p = PC;"
                  "PC = Code + @1;" ) ) ) )
      ((=T A)  # Indexed: Ignore SUBR
         (genCode (Adr A) (list 'call (list Adr)) (Adr)
            "S.p -= 8,  *(uint16_t**)S.p = PC;"
            "PC = (uint16_t*)@1.p;" ) )
      (NIL  # Indirect
         (genCode (Adr A) (list 'call (list Adr)) ((op.p Adr A))
            "S.p -= 8,  *(uint16_t**)S.p = PC;"
            "PC = *(uint16_t**)@1;" ) ) ) )

(asm jmp (Adr A)
   (nond
      (A  # Absolute
         (cond
            ((localAddr Adr)
               (genCode (Adr) (list 'jmp (relCode Adr)) ((relCode Adr))
                  "PC += @1;" ) )
            ((baseCode Adr)
               (genCode (Adr) (list 'jmp Adr) ((baseCode Adr))
                  "PC = Code + @1;" ) )
            (*FPic
               (genCode (Adr) (list 'jmp Adr) ((absCode Adr))
                  "PC = LibCode + @1;" ) )
            (T
               (genCode (Adr) (list 'jmp Adr) ((absCode Adr))
                  "PC = Code + @1;" ) ) ) )
      ((=T A)  # Indexed: Ignore SUBR
         (genCode (Adr A) (list 'jmp (list Adr)) (Adr)
            "PC = (uint16_t*)@1.p;" ) )
      (NIL  # Indirect
         (genCode (Adr A) (list 'jmp (list Adr)) ((op.p Adr A))
            "PC = *(uint16_t**)@1;" ) ) ) )

(asm tos (Dst D)
   (genCode (Dst D) (list 'pop Dst) ((op.n Dst D))
      "@1 = ((ptr)S.p)->n,  S.p += 8;" ) )

(de _jmp (Opc Test)
   (nond
      (A  # Absolute
         (cond
            ((localAddr Adr)
               (genCode (Adr Opc Test) (list Opc (relCode Adr)) ((relCode Adr) Test)
                  "if (@2)"
                  "   PC += @1;" ) )
            ((baseCode Adr)
               (genCode (Adr Opc Test) (list Opc Adr) ((baseCode Adr) Test)
                  "if (@2)"
                  "   PC = Code + @1;" ) )
            (*FPic
               (genCode (Adr Opc Test) (list Opc Adr) ((absCode Adr) Test)
                  "if (@2)"
                  "   PC = LibCode + @1;") )
            (T
               (genCode (Adr Opc Test) (list Opc Adr) ((absCode Adr) Test)
                  "if (@2)"
                  "   PC = Code + @1;" ) ) ) )
      ((=T A)  # Indexed: Ignore SUBR
         (genCode (Adr Opc Test) (list Opc Adr) (Adr Test)
            "if (@2)"
            "   PC = (uint16_t*)@1.p;" ) )
      (NIL  # Indirect
         (genCode (Adr A Opc Test) (list Opc (list Adr)) ((op.p Adr A) Test)
            "if (@2)"
            "   PC = (uint16_t**)@1;" ) ) ) )

(asm jz (Adr A)
   (_jmp "jz" "!Result") )

(asm jeq (Adr A)
   (_jmp "jeq" "!Result") )

(asm jnz (Adr A)
   (_jmp "jnz" "Result") )

(asm jne (Adr A)
   (_jmp "jne" "Result") )

(asm js (Adr A)
   (_jmp "js" "(int64_t)Result < 0") )

(asm jns (Adr A)
   (_jmp "jns" "(int64_t)Result >= 0") )

(asm jsz (Adr A)
   (_jmp "jsz" "(int64_t)Result <= 0") )

(asm jnsz (Adr A)
   (_jmp "jnsz" "(int64_t)Result > 0") )

(asm jc (Adr A)
   (_jmp "jc" "Carry") )

(asm jb (Adr A)
   (_jmp "jb" "Carry") )

(asm jx (Adr A)
   (_jmp "jx" "Carry") )

(asm jlt (Adr A)
   (_jmp "jlt" "Carry") )

(asm jnc (Adr A)
   (_jmp "jnc" "!Carry") )

(asm jnb (Adr A)
   (_jmp "jnb" "!Carry") )

(asm jnx (Adr A)
   (_jmp "jnx" "!Carry") )

(asm jge (Adr A)
   (_jmp "jge" "!Carry") )

(asm jle (Adr A)
   (_jmp "jle" "!Result || Carry") )

(asm jgt (Adr A)
   (_jmp "jgt" "Result && !Carry") )

(asm ret ()
   (genCode NIL '(ret) NIL
      "PC = *(uint16_t**)S.p,  S.p += 8;" ) )

(asm catch ())

(asm throw ()
   ((get 'ret 'asm)) )

# Floating point
(asm ldd ()
   (genCode NIL '(ldd) NIL
      "A.d = *(double*)C.p;" ) )

(asm ldf ()
   (genCode NIL '(ldf) NIL
      "A.f = *(float*)C.p;" ) )

(asm fixnum ()
   (genCode NIL '(fixnum) ((directExpr "TSym") (directExpr "Nil"))
      "if (E.b[0] & 8)"
      "   A.d = A.f * (float)(E.n >> 4);"
      "else"
      "   A.d = A.d * (double)(E.n >> 4);"
      "if (isinf(A.d) == 1 || A.d > (double)0xFFFFFFFFFFFFFFFLL)"
      "   E.p = @1;"
      "else if (isnan(A.d) || isinf(A.d) == -1 || A.d < (double)-0xFFFFFFFFFFFFFFFLL)"
      "   E.p = @2;"
      "else if (A.d >= 0)"
      "   E.n = (uint64_t)(A.d + 0.5) << 4 | 2;"
      "else"
      "   E.n = (uint64_t)(0.5 - A.d) << 4 | 10;" ) )

(asm float ()
   (genCode NIL '(float) ((directExpr "Nil"))
      "if (A.b[0] & 8) {"
      "   if (((ptr)X.p)->n & 2) {"
      "      tmp.f = (float)(((ptr)X.p)->n >> 4) / (float)(A.n >> 4);"
      "      if (((ptr)X.p)->n & 8)"
      "         tmp.f = -tmp.f;"
      "   }"
      "   else"
      "      tmp.f = X.p == @1? -INFINITY : INFINITY;"
      "}"
      "else {"
      "   if (((ptr)X.p)->n & 2) {"
      "      tmp.d = (double)(((ptr)X.p)->n >> 4) / (double)(A.n >> 4);"
      "      if (((ptr)X.p)->n & 8)"
      "         tmp.d = -tmp.d;"
      "   }"
      "   else"
      "      tmp.d = X.p == @1? -INFINITY : INFINITY;"
      "}" ) )

(asm std ()
   (genCode NIL '(std) NIL
      "*(double*)Z.p = tmp.d;" ) )

(asm stf ()
   (genCode NIL '(stf) NIL
      "*(float*)Z.p = tmp.f;" ) )

# C-Calls
(de *C-Params  # Function return value and parameters
   (getpid           i)
   (getenv           p  p)
   (setenv           i  p p i)
   (isatty           i  i)
   (tcgetattr        i  i "struct termios")
   (tcsetattr        i  i i "struct termios")
   (tcsetpgrp        -  i i)
   (signal           p  i f)
   (sigfillset       -  "sigset_t")
   (sigemptyset      -  "sigset_t")
   (sigaddset        -  "sigset_t" i)
   (sigprocmask      -  i "sigset_t" "sigset_t")
   (sigaction        -  i "struct sigaction" "struct sigaction")
   (gettimeofday     -  -2 "struct timezone")
   (malloc           p  i)
   (realloc          p  p i)
   (fork             i)
   (setsid           i)
   (getpgrp          i)
   (setpgid          -  i i)
   (execvp           i  p 0)
   (kill             i  i i)
   (raise            -  i)
   (alarm            i  i)
   (waitpid          i  i "int" i)
   (free             -  p)
   (stat             i  p "struct stat")
   (lstat            i  p "struct stat")
   (fcntl            i  i i p)
   (pipe             i  "int")
   (socketpair       i  i i i "int")
   (select           i  i "fd_set" "fd_set" "fd_set" (2 . -2))
   (open             i  p i i)
   (dup              i  i)
   (dup2             -  i i)
   (read             n  i p i)
   (write            n  i p i)
   (lseek            n  i n i)
   (pread            n  i p i n)
   (pwrite           n  i p i n)
   (close            i  i)
   (fopen            p  p p)
   (freopen          p  p p p)
   (getc_unlocked    i  "FILE")
   (putc_unlocked    -  i "FILE")
   (fread            i  p i i "FILE")
   (fwrite           i  p i i "FILE")
   (fileno           i  "FILE")
   (fseek            i  "FILE" n i)
   (ftruncate        i  i n)
   (fflush           -  "FILE")
   (fsync            i i)
   (feof             i  "FILE")
   (fclose           -  "FILE")
   (socket           i  i i i)
   (setsockopt       i  i i i p i)
   (htons            i  i)
   (ntohs            i  i)
   (inet_ntop        -  i p p i)
   (bind             i  i "struct sockaddr" i)
   (listen           i  i i)
   (getsockname      i  i "struct sockaddr" "socklen_t")
   (getaddrinfo      i  p p "struct addrinfo" "struct addrinfo*")
   (getnameinfo      i  "struct sockaddr" i p i p i i)
   (freeaddrinfo     -  "struct addrinfo")
   (accept           i  i "struct sockaddr" "socklen_t")
   (connect          i  i "struct sockaddr" i)
   (recv             i  i p i i)
   (sendto           -  i p i i "struct sockaddr" i)
   (strdup           p  p)
   (dlopen           p  p i)
   (dlsym            p  "void" p)
   (getcwd           p  p)
   (chdir            i  p)
   (opendir          p  p)
   (readdir          p  "DIR")
   (closedir         -  "DIR")
   (time             -  "time_t")
   (times            -  "struct tms")
   (usleep           -  i)
   (gmtime           p  "time_t")
   (localtime        p  "time_t")
   (printf           -  p)
   (fprintf          -  "FILE" p)
   (snprintf         -  p i p p)
   (strerror         p  i)
   (dlerror          p)
   (exit             -  i)
   # src64/sys/emu.code.l
   (errno_A          -)
   (errnoC           -)
   (wifstoppedS_F    -)
   (wifsignaledS_F   -)
   (wtermsigS_A      n) )

(de ccArg (P S O P2)
   (and (pair P) (setq P (car @)))
   (and (pair P2) (setq P2 (car @)))
   (case P
      (p (op.p S O))
      (n (op.n S O))
      (i (op.i S O))
      (f (sysFun S O))
      (lea
         (pack
            (and
               P2
               (n== 'p P2)
               (if (num? P2)
                  "(void*)"
                  (pack "(" P2 "*)") ) )
            (op.a S O) ) )
      (T
         (nond
            (P (op.i S O))
            ((num? P) (pack "(" P "*)" (op.p S O)))
            ((ge0 P) (pack "(void*)" (op.p S O)))
            (NIL (pack "argv(" @ ", (ptr)" (op.p S O) ")")) ) ) ) )

(de _genCC Body
   (addCode
      (cons
         (env '(Adr A Arg M Par))
         '(list 'cc Adr Arg)
         (list
            'Adr
            (list 'glue ", " Args)
            (list 'extract
               ''((A P)
                  (when (lt0 (fin P))
                     (pack " retv(" (abs @) ","
                        (if (pre? "argv(" A)
                           (member " " (chop A))
                           (pack " " A ")") )
                        ";" ) ) )
               Args
               '(cdr Par) ) )
         Body ) ) )

(de _natCC (I N Typ Arg)
   (if (=0 N)
      (link
         (pack
            (need (inc I) "   ")
            (case (car (setq Typ (reverse Typ)))
               (float "A.f = (*(float")
               (double "A.d = (*(double")
               (T "A.n = (*(uint64_t") )
            " (*)("
            (glue "," Typ)
            "))@1.p)("
            (glue ", " (reverse Arg))
            ");" ) )
      (let N (dec N)
         (link
            (pack
               (need (inc I) "   ")
               "if (((ptr)(S.p + "
               (* 16 I)
               "))->n == 0)" ) )
         (_natCC (inc I) N
            (cons 'long Typ)
            (cons
               (pack "((ptr)(S.p + " (+ 8 (* 16 I)) "))->n")
               Arg ) )
         (link
            (pack
               (need (inc I) "   ")
               "else if (((ptr)(S.p + "
               (* 16 I)
               "))->n & 8)" ) )
         (_natCC (inc I) N
            (cons 'float Typ)
            (cons
               (pack "(float)dbl(" (* 16 I) ")")
               Arg ) )
         (link (pack (need (inc I) "   ") "else"))
         (_natCC (inc I) N
            (cons 'double Typ)
            (cons
               (pack "dbl(" (* 16 I) ")")
               Arg ) ) ) ) )

(asm cc (Adr A Arg M)
   (if (lst? Arg)
      (let
         (Par (cdr (assoc Adr *C-Params))
            Args
            '(let (P (cdr Par)  Lea)
               (mapcan
                  '((S O)
                     (cond
                        ((== '& S) (on Lea))
                        ((== 'pop S)
                           (cons
                              (pack
                                 "(S.p += 8, "
                                 (ccArg (pop 'P) '("S" . -8) '(NIL . 0))
                                 ")" ) ) )
                        (Lea
                           (off Lea)
                           (cons (ccArg 'lea S O (pop 'P))) )
                        (T (cons (ccArg (pop 'P) S O))) ) )
                  Arg
                  M ) ) )
         (case (car Par)
            (- (_genCC "@1(@2);@3"))
            (p (_genCC "A.n = (uint64_t)(uintptr_t)(uint8_t*)@1(@2);@3"))
            (n (_genCC "A.n = (uint64_t)@1(@2);@3"))
            (i (_genCC "A.n = (uint64_t)(uint32_t)@1(@2);@3"))
            (T (quit "Unknown C function" Adr)) ) )
      (addCode
         (cons
            (env '(Adr Arg))
            '(list 'cc (list Adr) Arg)
            '(Adr Arg)
            (make
               (link "if ((tmp.p = S.p) == @2.p)")
               (_natCC 0 0)
               (for N 6
                  (link "else if ((tmp.p += 16) == @2.p) {")
                  (_natCC 0 N)
                  (link "}") )
               (link
                  "else"
                  "   A.n = (*(uint64_t (*)(long,long,long,long,long,long,long,long))Y.p)(((ptr)(S.p + 8))->n, ((ptr)(S.p + 24))->n, ((ptr)(S.p + 40))->n, ((ptr)(S.p + 56))->n, ((ptr)(S.p + 72))->n, ((ptr)(S.p + 88))->n, ((ptr)(S.p + 104))->n, ((ptr)(S.p + 120))->n);" ) ) ) ) ) )

(asm func ()
   (genCode NIL '(func) ((directExpr "cbl1"))
      "E.n = (uint64_t)(unsigned long)(void(*)())cbl[(E.p-@1)/2];" ) )

(asm begin ())

(asm return ()
   (genCode NIL '(return) NIL
      "return;" ) )  # Terminate 'run'

# Stack Manipulations
(asm push (Src S)
   (case Src
      (zscx
         (genCode NIL '(push f) NIL
            "S.p -= 8,  ((ptr)S.p)->n = (Result & ~1) | (Result & 0xFFFFFFFF) << 1 | Carry;" ) )
      (x
         (genCode NIL '(push x) NIL
            "S.p -= 8,  ((ptr)S.p)->n = Carry;" ) )
      ("S"
         (genCode (Src S) '(push S) NIL
            "tmp.n = S.n,  S.p -= 8,  ((ptr)S.p)->n = tmp.n;" ) )
      (T
         (genCode (Src S) (list 'push Src) ((op.n Src S))
            "S.p -= 8,  ((ptr)S.p)->n = @1;" ) ) ) )

(asm pop (Dst D)
   (casq Dst
      (zscx
         (genCode NIL '(pop f) NIL
            "Carry = ((ptr)S.p)->n & 1,  Result = ((ptr)S.p)->n & ~1,  S.p += 8;" ) )
      (x
         (genCode NIL '(pop x) NIL
            "Carry = ((ptr)S.p)->n, S.p += 8;" ) )
      (T
         (genCode (Dst D) (list 'pop Dst) ((op.n Dst D))
            "@1 = ((ptr)S.p)->n,  S.p += 8;" ) ) ) )

(asm link ()
   (genCode NIL '(link) NIL
      "S.p -= 8,  ((ptr)S.p)->n = L.n,  L.p = S.p;" ) )

(asm tuck (Src S)
   (genCode (Src S) (list 'tuck Src) ((op.n Src S))
      "L.p = ((ptr)S.p)->p, ((ptr)S.p)->n = @1;" ) )

(asm drop ()
   (genCode NIL '(drop) NIL
      "S.p = ((ptr)L.p)->p,  L.p = ((ptr)S.p)->p,  S.p += 8;" ) )

# Evaluation
(asm eval ()
   (genCode NIL '(eval) ((absCode "evListE_E"))
      "if (!(E.b[0] & 6))"
      "   if (E.b[0] & 8)"
      "      E = *(ptr)E.p;"
      "   else {"
      "      S.p -= 8,  *(uint16_t**)S.p = PC;"
      "      PC = Code + @1;"
      "   }" ) )

(asm eval+ ()
   (genCode NIL '(eval+) ((absCode "evListE_E"))
      "if ((E.b[0] & 6))"                       # Number?
      "   ++PC;"                                # Yes: Skip
      "else if (E.b[0] & 8) {"                  # Symbol?
      "   E = *(ptr)E.p;"                       # Yes: Get value
      "   ++PC;"                                # and skip
      "}"
      "else {"                                  # Else 'link'
      "   S.p -= 8,  ((ptr)S.p)->n = L.n,  L.p = S.p;"
      "   S.p -= 8,  *(uint16_t**)S.p = PC;"
      "   PC = Code + @1;"                      # Evaluate list
      "}" )
   (genCode NIL '(<eval+>) NIL
      "L.p = ((ptr)S.p)->p,  S.p += 8;" ) )     # pop L

(asm eval/ret ()
   (genCode NIL '(eval/ret) ((absCode "evListE_E"))
      "if (E.b[0] & 14) {"
      "   if (!(E.b[0] & 6))"
      "      E = *(ptr)E.p;"
      "   PC = *(uint16_t**)S.p,  S.p += 8;"
      "}"
      "else"
      "   PC = Code + @1;" ) )

(asm exec (Reg)
   (genCode (Reg) (list 'exec Reg) ((absCode "evListE_E") Reg)
      "E = *(ptr)@2.p;"                         # ld E (R)
      "@2.p = ((ptr)(@2.p + 8))->p;"            # ld R (R CDR)
      "if (!(@2.b[0] & 14))"                    # atom R
      "   --PC;"                                # No: Loop
      "if (!(E.b[0] & 14)) {"                   # eval
      "   S.p -= 8,  *(uint16_t**)S.p = PC;"
      "   PC = Code + @1;"
      "}" ) )

(asm prog (Reg)
   (genCode (Reg) (list 'prog Reg) ((absCode "evListE_E") Reg)
      "E = *(ptr)@2.p;"                         # ld E (R)
      "@2.p = ((ptr)(@2.p + 8))->p;"            # ld R (R CDR)
      "if (!(@2.b[0] & 14))"                    # atom R
      "   --PC;"                                # No: Loop
      "if (!(E.b[0] & 6)) {"                    # eval
      "   if (E.b[0] & 8)"
      "      E = *(ptr)E.p;"
      "   else {"
      "      S.p -= 8,  *(uint16_t**)S.p = PC;"
      "      PC = Code + @1;"
      "   }"
      "}" ) )

# System
(asm initData ())

(asm initCode ())

(asm initMain ())  # Done explicitly in 'main'

(asm initLib ()
   (genCode NIL '(initLib) NIL
      "A.n = (uint64_t)(unsigned long)*(uint8_t**)A.p;" ) )

(asm stop ()
   (genCode NIL '(stop) NIL
      "exit((int)E.n);" ) )

### Optimizer ###
# Replace the the next 'cnt' elements with 'lst'
(de optimize (Lst))  #> (cnt . lst)

### Decoration ###
(de prolog (File)
   (if *FPic
      (in "emu.symtab"
         (setq
            *BaseData (read)
            *BaseCode (read)
            *BaseOpcodes (make (while (read) (chain @)))
            *OpOffs (length *BaseOpcodes) ) ) )
   (mapc prinl
      (quote
         NIL
         "#include <stdio.h>"
         "#include <stdint.h>"
         "#include <stdlib.h>"
         "#include <unistd.h>"
         "#include <limits.h>"
         "#include <string.h>"
         "#include <math.h>"
         "#include <errno.h>"
         "#include <fcntl.h>"
         "#include <dirent.h>"
         "#include <termios.h>"
         "#include <signal.h>"
         "#include <dlfcn.h>"
         "#include <time.h>"
         "#include <sys/types.h>"
         "#include <sys/time.h>"
         "#include <sys/times.h>"
         "#include <sys/stat.h>"
         "#include <sys/wait.h>"
         "#include <netdb.h>"
         "#include <arpa/inet.h>"
         "#include <netinet/in.h>"
         "#include <sys/socket.h>"
         NIL
         "#define MAX8 ((uint8_t)-1)"
         "#define MAX64 ((uint64_t)-1)"
         "#define STACK (8 * 1024 * 1024)"
         NIL
         "typedef union op {"
         "   uint64_t n;" ) )
   (if (or *LittleEndian *Bits64)
      (prinl "   uint8_t *p;")
      (mapc prinl
         (quote
            "   struct {"
            "      uint32_t u;"
            "      uint8_t *p;"
            "   };" ) ) )
   (prinl "   uint8_t b[8];")
   (if *LittleEndian
      (prinl "   struct {uint32_t l, h;};")
      (prinl "   struct {uint32_t h, l;};") )
   (prinl "   float f;")
   (prinl "   double d;")
   (prinl "} op, *ptr;")
   (prinl)
   (mapc prinl
      (if *FPic
         (quote
            "extern uint16_t Code[];"
            "static uint16_t LibCode[];"
            NIL
            "extern uint16_t *PC;"
            "extern uint8_t *Stack;"
            "extern op A, C, E, X, Y, Z, L, S;"
            "extern uint64_t Result;"
            "extern int Carry;"
            "extern void mul2(uint64_t);"
            "extern void div2(uint64_t);"
            "extern uint64_t begin(int,long,long,long,long,long,long);"
            "extern void *argv(int,ptr);"
            "extern void retv(int,ptr);"
            NIL
            "extern op Data[];"
            NIL
            "static op LibData[] = {" )
         (quote
            "uint16_t Code[];"
            NIL
            "uint16_t *PC;"
            "uint8_t *Stack;"
            "op A, C, E, X, Y, Z, L, S;"
            "uint64_t Result;"
            "int Carry;"
            NIL
            "void emuStkErr(void) {"
            "   fprintf(stderr, \"Emulator stack error\\n\");"
            "   exit(-99);"
            "}"
            NIL
            "static void run(int);"
            NIL
            "void mul2(uint64_t src) {"
            "   uint32_t h = src >> 32;"
            "   uint32_t l = (uint32_t)src;"
            "   op a, b;"
            NIL
            "   a.n = (uint64_t)A.l * l;"
            "   b.n = (uint64_t)A.h * l;"
            "   C.n = (uint64_t)b.h + ((a.h += b.l) < b.l);"
            "   b.n = (uint64_t)A.l * h;"
            "   C.n += (uint64_t)b.h + ((a.h += b.l) < b.l);"
            "   C.n += (uint64_t)A.h * h;"
            "   A.n = a.n;"
            "}"
            NIL
            "void div2(uint64_t src) {"
            "   uint64_t vn0, vn1, q1, q0, rhat;"
            "   int s;"
            NIL
            "   if (C.n >= src)"
            "      A.n = C.n = MAX64;"                         # Overflow
            "   else {"
            "      s = 0;"
            "      while ((int64_t)src > 0) {"                 # Normalize
            "         C.n = (C.n << 1) + ((int64_t)A.n < 0);"  # Shift dividend left
            "         A.n <<= 1;"
            "         src <<= 1;"                              # and divisor
            "         ++s;"
            "      }"
            "      vn1 = src >> 32;"                           # Split divisor into high
            "      vn0 = (uint32_t)src;"                       # and low 32 bits
            "      q1 = C.n / vn1;"                            # First quotient digit
            "      rhat = C.n - q1 * vn1;"
            NIL
            "      while (q1 >> 32  ||  q1 * vn0 > (rhat << 32) + A.h) {"
            "         --q1;"
            "         if ((rhat += vn1) >> 32)"
            "            break;"
            "      }"
            "      C.n = (C.n << 32) + A.h - q1 * src;"
            "      q0 = C.n / vn1;"                            # Second quotient digit
            "      rhat = C.n - q0 * vn1;"
            NIL
            "      while (q0 >> 32  ||  q0 * vn0 > (rhat << 32) + A.l) {"
            "         --q0;"
            "         if ((rhat += vn1) >> 32)"
            "            break;"
            "      }"
            "      C.n = ((C.n << 32) + A.l - q0 * src) >> s;" # Remainder
            "      A.n = (q1 << 32) + q0;"                     # Quotient
            "   }"
            "}"
            NIL
            "uint64_t begin(int i, long a, long c, long e, long x, long y, long z) {"
            "   uint64_t res;"
            NIL
            "   S.p -= 8,  *(uint16_t**)S.p = PC;"
            "   S.p -= 8,  ((ptr)S.p)->l = Carry;"
            "   S.p -= 8,  ((ptr)S.p)->n = Result;"
            "   S.p -= 8,  *(ptr)S.p = Z,  Z.n = z;"
            "   S.p -= 8,  *(ptr)S.p = Y,  Y.n = y;"
            "   S.p -= 8,  *(ptr)S.p = X,  X.n = x;"
            "   S.p -= 8,  *(ptr)S.p = E,  E.n = e;"
            "   S.p -= 8,  *(ptr)S.p = C,  C.n = c;"
            "   S.p -= 8,  *(ptr)S.p = A,  A.n = a;"
            "   run(i);"
            "   res = A.n;"
            "   A = *(ptr)S.p,  S.p += 8;"
            "   C = *(ptr)S.p,  S.p += 8;"
            "   E = *(ptr)S.p,  S.p += 8;"
            "   X = *(ptr)S.p,  S.p += 8;"
            "   Y = *(ptr)S.p,  S.p += 8;"
            "   Z = *(ptr)S.p,  S.p += 8;"
            "   Result = ((ptr)S.p)->n,  S.p += 8;"
            "   Carry = ((ptr)S.p)->l,  S.p += 8;"
            "   PC = *(uint16_t**)S.p,  S.p += 8;"
            "   return res;"
            "}"
            NIL
            "void *argv(int i, ptr p) {"
            "   if (p) {"
            "      if (i == 0)"
            "         while (((uint8_t**)p)[i] = p[i].p)"
            "            ++i;"
            "      else"
            "         while (--i >= 0)"
            "            ((uint8_t**)p)[i] = p[i].p;"
            "   }"
            "   return p;"
            "}"
            NIL
            "void retv(int i, ptr p) {"
            "   if (p)"
            "      while (--i >= 0)"
            "         p[i].n = (uint64_t)(unsigned long)((uint8_t**)p)[i];"
            "}"
            NIL
            "op Data[] __attribute__((aligned(16))) = {" ) ) ) )

(de prOpcode (I X)
   (prinl
      (align 7 X)
      ",  // "
      (align 7 (dec I))
      ": "
      (if (=0 X)
         "nop"
         (fmtInstruction
            (or
               (get *BaseOpcodes X)
               (get *AsmOpcodes (- X *OpOffs) 1) ) ) ) ) )

(de epilog (File)
   (setq
      *AsmData (flip *AsmData)
      *AsmCode (flip *AsmCode) )
   (let *AsmPos 0
      (for X *AsmCode
         (set X
            (job (env (caar X))
               (opcode
                  (eval (cadar X))
                  (mapcar eval (caddar X))
                  (cdddar X) ) ) )
         (inc '*AsmPos) ) )
   (let Bytes NIL
      (for D *AsmData
         (prin
            "   /* "
            (align -10 (car D))
            (align 5 (cadr D))
            " */" )
         (and Bytes (cddr D) (space 8))
         (for (I . X) (cddr D)
            (cond
               ((pair X)
                  (and Bytes (quit "Unaligned word" (car D)))
                  (prin " {.n = " (car X) "},") )
               ((sym? X)
                  (and Bytes (quit "Unaligned word" (car D)))
                  (cond
                     ((pre? ".+" X)
                        (let N (+ (cadr D) (format (cddr (chop X))))
                           (for ((J . L) (cddr D)  (> I J)  (cdr L))
                              (NIL (> I J))  # Temporary (only for 3.1.1 and older)
                              (inc 'N (if (num? (car L)) 1 8)) )
                           (prin
                              " {.p = (uint8_t*)"
                              (and *FPic "Lib")
                              "Data+"
                              N
                              "}," ) ) )
                     ((asoq X *AsmData)
                        (let N @
                           (prin
                              " {.p = (uint8_t*)"
                              (and *FPic "Lib")
                              "Data+"
                              (cadr N)
                              "}," ) ) )
                     ((absCode X)
                        (let N @
                           (prin
                              " {.p = (uint8_t*)("
                              (and *FPic "Lib")
                              "Code+"
                              N
                              ")}," ) ) )
                     (T (quit "No value" X)) ) )
               (Bytes
                  (prin (and (> I 1) ", ") X)
                  (when (= 8 (inc 'Bytes))
                     (prin "}},")
                     (off Bytes) ) )
               (T
                  (prin " {.b = {" X)
                  (one Bytes) ) ) )
         (and Bytes (cddr D) (prin ","))
         (prinl) )
      (when Bytes
         (space 26)
         (prinl "}}") ) )
   (prinl "};")
   (prinl)
   (unless *FPic
      (for I 24
         (sysFun (pack "cbl" I) T) ) )
   (when *SysFun
      (mapc prinl (flip @))
      (prinl) )
   (unless *FPic
      (prinl
         "static void (*cbl[])() = {"
         (glue ","
            (make
               (for I 24
                  (link (pack "fun" (absCode (pack "cbl" I)))) ) ) )
         "};" )
      (prinl)
      (prinl "long lisp(char *p, long a, long b, long c, long d, long e) {")
      (prinl "   return (long)begin(" (absCode "lisp") ", (long)p, a, b, c, d, e);")
      (prinl "}")
      (prinl) )
   (prinl
      (and *FPic "static ")
      "uint16_t "
      (and *FPic "Lib")
      "Code[] = {" )
   (for (I . X) *AsmCode
      (for C (cdr X)
         (unless (pre? "." C)  # Omit local labels
            (prinl "          // " C ":") ) )
      (prOpcode I (car X)) )
   (prinl "};")
   (prinl)
   (when *FPic
      (for S (by val sort (idx '*Labels))
         (unless (pre? "." S)  # Omit local labels
            (prinl "uint16_t *" S " = LibCode + " (val S) ";") ) )
      (prinl) )
   (if *FPic
      (mapc prinl
         (quote
            "extern void (*FirstLib)(void);"
            "static void (*NextLib)(void);"
            NIL
            "static void opcodes(void) {"
            "   op i, tmp;"
            NIL
            "   switch (PC[-1]) {" ) )
      (mapc prinl
         (quote
            "double dbl(int i) {"
            "   uint64_t s = ((ptr)(S.p + i))->n;"
            NIL
            "   if (s & 2) {"
            "      uint64_t m =  ((ptr)(S.p + i + 8))->n;"
            "      double d = (double)(m >> 4) / (double)(s >> 4);"
            "      return m & 8? -d : d;"
            "   }" ) )
      (prinl
            "   return ((ptr)(S.p + i))->p == "
            (directExpr "Nil")
            "? -INFINITY : INFINITY;" )
      (mapc prinl
         (quote
            "}"
            NIL
            "void (*FirstLib)(void);"
            NIL
            "static void run(int i) {"
            "   op tmp;"
            NIL
            "   PC = Code + i;"
            "   for (;;) {"
            "      switch (*PC++) {"
            "      case 0:  // nop"
            "         break;" ) ) )
   (for (C . L) *AsmOpcodes
      (prinl
         (unless *FPic "   ")
         "   case "
         (+ *OpOffs C)
         ":  // "
         (fmtInstruction (car L)) )
      (for S (cdr L)
         (prinl
            (unless *FPic "   ")
            "      "
            S ) )
      (prinl
         (unless *FPic "   ")
         "      break;" ) )
   (prinl
      (unless *FPic "   ")
      "   default:" )
   (if *FPic
      (mapc prinl
         (quote
            "      if (NextLib)"
            "         (*NextLib)();" ) )
      (mapc prinl
         (quote
            "         if (FirstLib)"
            "            (*FirstLib)();" ) ) )
   (for S
      (quote
         "      else {"
         "         fprintf(stderr, \"Bad instruction\\n\");"
         "         exit(112);"
         "      }"
         "   }"
         ~(as (and *Dbg (not *FPic))
            "   fprintf(stderr, \"   %llX %llX %llX  %llX %llX %llX  %d%d%d  %llX %llX\\n\","
            "      A.n, C.n, E.n, X.n, Y.n, Z.n,"
            "      !Result, (int64_t)Result<0, Carry,"
            "      L.n, S.n );" ) )
      (prinl
         (unless *FPic "   ")
         S ) )
   (unless *FPic (prinl "   }"))
   (prinl "}")
   (when *FPic
      (mapc prinl
         (quote
            NIL
            "static void __attribute__((constructor)) linkOpcodes(void) {"
            "   NextLib = FirstLib,  FirstLib = opcodes;"
            "}" ) ) )
   (unless *FPic
      (mapc prinl
         (quote
            NIL
            "int main(int ac, char *av[]) {"
            "   int i;"
            NIL
            "   Y.p = malloc((ac + 1) * sizeof(op));"
            "   i = 0; do"
            "      ((ptr)Y.p)[i].n = (uint64_t)(unsigned long)av[i];"
            "   while (++i < ac);"
            "   ((ptr)Y.p)[i].n = 0;"
            "   X.p = ((ptr)Y.p)->p,  Y.p += 8;"
            "   Z.p = Y.p + (ac - 2) * sizeof(op);"
            "   if ((Stack = malloc(STACK)) == NULL)"
            "      emuStkErr();"
            "   S.p = Stack + STACK;" ) )
      (prinl (pack "   run(" (absCode "main") ");"))
      (prinl "   return 0;")
      (prinl "}") )
   (if *FPic
      (out "+emu.symtab"
         (println (mapcar car *AsmOpcodes)) )
      (out "emu.symtab"
         (println
            (mapcar '((D) (cons (car D) (cadr D)))
               *AsmData ) )
         (println
            (make
               (for (I . X) *AsmCode
                  (for Lbl (cdr X)
                     (unless (pre? "." Lbl)
                        (link (cons Lbl (dec I))) ) ) ) ) )
         (println (mapcar car *AsmOpcodes)) ) ) )

# vi:et:ts=3:sw=3
