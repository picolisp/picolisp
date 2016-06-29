# 01jun16abu
# (c) Software Lab. Alexander Burger

# Architecture
(on *LittleEndian)
(off *AlignedCode)

# Register assignments
(de *Registers
   (A . "%rax") (C . "%rdx") (E . "%rbx")
   (B . "%al") (D "%rax" . "%rdx")
   (X . "%r13") (Y . "%r14") (Z . "%r15")
   (L . "%rbp") (S . "%rsp")
   (zscx . zscx) (zsc . zscx) (x . zscx) )

# NULL: %r12
# Temporary: %r10 %r11
# Block operations: %rcx %rsi %rdi
# C arguments: %rdi %rsi %rdx %rcx %r8 %r9

# Addressing modes
(de byteReg (Reg)
   (cdr
      (assoc Reg
         (quote
            ("%rax" . "%al")
            ("%al" . "%al")
            ("%rdx" . "%dl")
            ("%rbx" . "%bl")
            ("%r12" . "%r12b")
            ("%r13" . "%r13b")
            ("%r14" . "%r14b")
            ("%r15" . "%r15b")
            ("%rbp" . "%bpl")
            ("%rsp" . "%spl") ) ) ) )

(de byteVal (Adr)
   (if (= "%r12" Adr)
      "$0"  # %r12b needs 3 bytes
      (or
         (byteReg Adr)  # Register
         Adr ) ) )  # Byte address

(de lowByte (Adr)
   (or
      (byteReg Adr)  # Register
      Adr ) )  # Word address

(de highWord (S)
   (cond
      ((= `(char "(") (char S))
         (pack "8" S) )
      ((>= `(char "9") (char S) `(char "0"))
         (pack "8+" S) )
      (T (pack S "+8")) ) )

(de immediate (Src)
   (setq Src (chop Src))
   (when (= "$" (pop 'Src))
      (and (= "~" (car Src)) (pop 'Src))
      (format Src) ) )

(de target (Adr F)
   (if
      (or
         (not *FPic)
         (= `(char ".") (char Adr))     # Local label ".1"
         (let A (split (chop Adr) "_")  # Local jump "foo_22"
            (and
               (cdr A)
               (= *Label (pack (glue "_" (head -1 A))))
               (format (last A)) ) ) )
      Adr
      (ifn F
         (pack Adr "@plt")
         (prinst "mov" (pack Adr "@GOTPCREL(%rip)") "%r10")
         "(%r10)") ) )

(de src (Src S)
   (cond
      ((=0 S)  # Immediate
         (if (= "0" Src) "%r12" (pack "$" Src)) )
      ((not S) Src)  # Register
      ((=T S)  # Direct
         (if (and *FPic (not (pre? "(" Src)))
            (pack Src "@GOTPCREL(%rip)")
            (pack "$" Src) ) )
      ((not (car S))  # Indexed
         (ifn (and *FPic (=T (cdr S)))
            (pack (cdr Src) "(" (car Src) ")")
            (prinst "add" (pack (cdr Src) "@GOTPCREL(%rip)") (car Src))
            (pack "(" (car Src) ")") ) )
      ((=T (car S))  # Indirect
         (ifn *FPic
            (if (cdr S)
               (pack (car Src) "+" (cdr Src))
               (car Src) )
            (prinst "mov" (pack (car Src) "@GOTPCREL(%rip)") "%r10")
            (pack (cdr Src) "(%r10)") ) )
      (T  # Combined
         (prinst "mov" (src (car Src) (car S)) "%r10")
         (ifn (and *FPic (=T (cdr S)))
            (pack (cdr Src) "(%r10)")
            (prinst "add" (pack (cdr Src) "@GOTPCREL(%rip)") "%r10")
            "(%r10)" ) ) ) )

(de lea (Src S Reg)
   (cond
      ((not S) (prinst "mov" Src Reg))          # Register
      ((=T S) (prinst "mov" (src Src T) Reg))   # Direct
      ((not (car S))
         (cond
            ((and *FPic (=T (cdr S)))
               (prinst "add" (pack (cdr Src) "@GOTPCREL(%rip)") (car Src))
               (prinst "mov" (pack "(" (car Src) ")") Reg) )
            ((cdr Src)
               (prinst "lea" (pack (cdr Src) "(" (car Src) ")") Reg) )
            (T (prinst "mov" (car Src) Reg)) ) )
      ((=T (car S))
         (ifn *FPic
            (prinst "lea"
               (if (cdr S)
                  (pack (car Src) "+" (cdr Src))
                  (car Src) )
               Reg )
            (prinst "mov" (pack (car Src) "@GOTPCREL(%rip)") Reg)
            (prinst "lea" (pack (cdr Src) "(%r10)") Reg) ) )
      (T
         (if (cdr S)
            (prinst "lea" (src Src S) Reg)
            (prinst "mov" (src (car Src) (car S)) Reg) ) ) ) )

(de dst (Dst D)
   (cond
      ((not D) Dst)                             # Register
      ((not (car D))
         (ifn (and *FPic (=T (cdr D)))
            (pack (cdr Dst) "(" (car Dst) ")")
            (prinst "add" (pack (cdr Dst) "@GOTPCREL(%rip)") (car Dst))
            (pack "(" (car Dst) ")") ) )
      ((=T (car D))
         (ifn *FPic
            (if (cdr D)
               (pack (car Dst) "+" (cdr Dst))
               (car Dst) )
            (prinst "mov" (pack (car Dst) "@GOTPCREL(%rip)") "%r11")
            (pack (cdr Dst) "(%r11)") ) )
      (T
         (prinst "mov" (dst (car Dst) (car D)) "%r11")
         (ifn (and *FPic (=T (cdr D)))
            (pack (cdr Dst) "(%r11)")
            (prinst "add" (pack (cdr Dst) "@GOTPCREL(%rip)") "%r11")
            "(%r11)" ) ) ) )

(de dstSrc (Cmd Dst Src)
   (cond
      ((= "%al" Dst)
         (prinst Cmd (byteVal Src) "%al") )
      ((= "%al" Src)
         (prinst Cmd "%al" (byteVal Dst)) )
      ((and (immediate Src) (not (>= 2147483647 @ -2147483648)))
         (prinst "mov" Src "%r10")
         (prinst Cmd "%r10" Dst) )
      ((or (pre? "%" Src) (pre? "%" Dst))
         (prinst Cmd Src Dst) )
      ((pre? "$" Src)
         (prinst (pack Cmd "q") Src Dst) )
      (T
         (prinst "mov" Src "%r10")
         (prinst Cmd "%r10" Dst) ) ) )

(de dstSrcByte (Cmd Dst Src)
   (if (>= 255 (immediate Src) 0)
      (prinst (pack Cmd "b") Src (lowByte Dst))
      (dstSrc Cmd Dst Src) ) )

(de dstDst (Cmd Dst Dst2)
   (cond
      ((= "%al" Dst)
         (prinst Cmd (byteVal Dst2) "%al") )
      ((= "%al" Dst2)
         (prinst Cmd "%al" (byteVal Dst)) )
      ((or (pre? "%" Dst) (pre? "%" Dst2))
         (prinst Cmd Dst2 Dst) )
      ((sub? "%r10" Dst2)
         (prinst "mov" Dst "%r11")
         (prinst Cmd "%r11" Dst2)
         (prinst "mov" "%r11" Dst) )
      (T
         (prinst "mov" Dst "%r10")
         (prinst Cmd "%r10" Dst2)
         (prinst "mov" "%r10" Dst) ) ) )

(de dstShift (Cmd Dst Src)
   (if (pre? "$" Src)
      (prinst (pack Cmd (unless (pre? "%" Dst) "q")) Src Dst)
      (prinst "mov" (byteVal Src) "%cl")
      (prinst (pack Cmd (unless (pre? "%" Dst) "q")) "%cl" Dst) ) )

### Instruction set ###
(de alignSection (Align)
   (prinst ".balign" 16)
   ((; 'skip asm) Align) )

(asm nop ()
   (prinst "nop") )

(asm align (N)
   (prinst ".balign" N) )

(asm skip (N)
   (if (== 'data *Section)
      (or (=0 N) (prinst ".space" N))
      (do N (prinst "nop")) ) )

# Move data
(asm ld (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (cond
      ((= "%al" Dst)
         (prinst "mov" (byteVal Src) "%al") )
      ((= "%al" Src)
         (prinst "mov" "%al" (byteVal Dst)) )
      ((pair Dst)
         (prinst "mov" Src (car Dst))
         (prinst "mov" (if (=0 S) "%r12" (highWord Src)) (cdr Dst)) )
      ((pair Src)
         (prinst "mov" (car Src) Dst)
         (prinst "mov" (cdr Src) (highWord Dst)) )
      ((or (pre? "%" Src) (pre? "%" Dst))
         (prinst "mov" Src Dst) )
      ((and
            (pre? "$" Src)
            (let N (immediate Src)
               (or (not N) (>= 2147483647 N -2147483648)) ) )
         (prinst "movq" Src Dst) )
      (T
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) ) ) )

(asm ld2 (Src S)
   (prinst "movzwq" (src Src S) "%rax") )

(asm ld4 (Src S)
   (prinst "mov" (src Src S) "%eax") )  # Clears upper word of %rax

(de _cmov (Cmd Jmp)
   (setq Dst (dst Dst D)  Src (src Src S))
   (when (pre? "$" Src)
      (prinst "mov" Src "%r10")
      (setq Src "%r10") )
   (if (pre? "%" Dst)
      (prinst Cmd Src Dst)
      (warn "Using suboptimal emulation code")
      (prinst Jmp "1f")
      (if (pre? "%"  Src)
         (prinst "mov" Src Dst)
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) )
      (prinl "1:") ) )

(asm ldz (Dst D Src S)
   (_cmov "cmovzq" "jnz") )

(asm ldnz (Dst D Src S)
   (_cmov "cmovnzq" "jz") )

(asm lea (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (if (pre? "%" Dst)
      (prinst "lea" Src Dst)
      (prinst "lea" Src "%r10")
      (prinst "mov" "%r10" Dst) ) )

(asm st2 (Dst D)
   (prinst "mov" "%ax" (dst Dst D)) )

(asm st4 (Dst D)
   (prinst "mov" "%eax" (dst Dst D)) )

(asm xchg (Dst D Dst2 D2)
   (dstDst "xchg" (dst Dst D) (src Dst2 D2)) )

(asm movn (Dst D Src S Cnt C)
   (lea Dst D "%rdi")
   (lea Src S "%rsi")
   (prinst "mov" (src Cnt C) "%rcx")
   (prinst "cld")
   (prinst "rep movsb") )

(asm mset (Dst D Cnt C)
   (setq Dst (dst Dst D))
   (prinst (if (pre? "%" Dst) "mov" "lea") Dst "%rdi")
   (prinst "mov" (src Cnt C) "%rcx")
   (prinst "cld")
   (prinst "rep stosb") )

(asm save (Src S End E Dst D)
   (lea Src S "%rsi")
   (lea End E "%rcx")
   (lea Dst D "%rdi")
   (prinst "sub" "%rsi" "%rcx")
   (prinst "shr" "$3" "%rcx")
   (prinst "cld")
   (prinst "rep movsq") )

(asm load (Dst D End E Src S)
   (lea Dst D "%rdi")
   (lea End E "%rcx")
   (lea Src S "%rsi")
   (prinst "sub" "%rdi" "%rcx")
   (prinst "shr" "$3" "%rcx")
   (prinst "cld")
   (prinst "rep movsq") )

# Arithmetics
(asm add (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (ifn (pair Dst)
      (dstSrc "add" Dst Src)
      (prinst "add" Src (car Dst))
      (prinst "adc" "%r12" (cdr Dst)) ) )

(asm addc (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (ifn (pair Dst)
      (dstSrc "adc" Dst Src)
      (prinst "adc" Src (car Dst))
      (prinst "adc" "%r12" (cdr Dst)) ) )

(asm sub (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (ifn (pair Dst)
      (dstSrc "sub" Dst Src)
      (prinst "sub" Src (car Dst))
      (prinst "sbb" "%r12" (cdr Dst)) ) )

(asm subb (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (ifn (pair Dst)
      (dstSrc "sbb" Dst Src)
      (prinst "sbb" Src (car Dst))
      (prinst "sbb" "%r12" (cdr Dst)) ) )

(asm inc (Dst D)
   (if (pre? "%" (setq Dst (dst Dst D)))
      (prinst "inc" Dst)
      (prinst "incq" Dst) ) )

(asm dec (Dst D)
   (if (pre? "%" (setq Dst (dst Dst D)))
      (prinst "dec" Dst)
      (prinst "decq" Dst) ) )

(asm not (Dst D)
   (if (pre? "%" (setq Dst (dst Dst D)))
      (prinst "not" Dst)
      (prinst "notq" Dst) ) )

(asm neg (Dst D)
   (if (pre? "%" (setq Dst (dst Dst D)))
      (prinst "neg" Dst)
      (prinst "negq" Dst) ) )

(asm and (Dst D Src S)
   (dstSrc "and" (dst Dst D) (src Src S)) )

(asm or (Dst D Src S)
   (dstSrcByte "or" (dst Dst D) (src Src S)) )

(asm xor (Dst D Src S)
   (dstSrcByte "xor" (dst Dst D) (src Src S)) )

(asm off (Dst D Src S)
   (dstSrcByte "and" (dst Dst D) (src Src S)) )

(asm test (Dst D Src S)
   (dstSrcByte "test" (dst Dst D) (src Src S)) )

(asm shl (Dst D Src S)
   (dstShift "shl" (dst Dst D) (src Src S)) )

(asm shr (Dst D Src S)
   (dstShift "shr" (dst Dst D) (src Src S)) )

(asm rol (Dst D Src S)
   (dstShift "rol" (dst Dst D) (src Src S)) )

(asm ror (Dst D Src S)
   (dstShift "ror" (dst Dst D) (src Src S)) )

(asm rxl (Dst D Src S)
   (dstShift "rcl" (dst Dst D) (src Src S)) )

(asm rxr (Dst D Src S)
   (dstShift "rcr" (dst Dst D) (src Src S)) )

(asm mul (Src S)
   (ifn (pre? "$" (setq Src (src Src S)))
      (prinst "mulq" Src)
      (prinst "mov" Src "%r10")
      (prinst "mul" "%r10") ) )

(asm div (Src S)
   (ifn (pre? "$" (setq Src (src Src S)))
      (prinst "divq" Src)
      (prinst "mov" Src "%r10")
      (prinst "div" "%r10") ) )

(asm zxt ()  # 8 bit -> 64 bit
   (prinst "movzx" "%al" "%rax") )

(asm eq ()
   (prinst "or" "%r12" "%r12") )

(asm gt ()
   (prinst "cmp" "%r12" "%rsp") )

(asm lt ()
   (prinst "cmp" "%rsp" "%r12") )

(asm setx ()
   (prinst "stc") )

(asm clrx ()
   (prinst "clc") )

# Comparisons
(asm cmp (Dst D Src S)
   (dstSrc "cmp" (dst Dst D) (src Src S)) )

(asm cmpn (Dst D Src S Cnt C)
   (setq Dst (dst Dst D))
   (prinst (if (pre? "%" Dst) "mov" "lea") Dst "%rsi")
   (lea Src S "%rdi")
   (prinst "mov" (src Cnt C) "%rcx")
   (prinst "cld")
   (prinst "repz cmpsb") )

(asm slen (Dst D Src S)
   (setq Dst (dst Dst D))
   (prinst "cld")
   (prinst "xor" "%rcx" "%rcx")
   (prinst "not" "%rcx")
   (lea Src S "%rdi")
   (prinst "xchg" "%al" "%r12b")
   (prinst "repnz scasb")
   (prinst "xchg" "%al" "%r12b")
   (prinst "not" "%rcx")
   (prinst "dec" "%rcx")
   (prinst "mov" "%rcx" Dst) )

(asm memb (Src S Cnt C)
   (prinst "cld")
   (lea Src S "%rdi")
   (setq Cnt (src Cnt C))
   (prinst "mov" Cnt "%rcx")
   (prinst "repnz scasb")
   (unless S (prinst "cmovzq" "%rdi" Src))
   (unless C (prinst "cmovzq" "%rcx" Cnt)) )

(asm null (Src S)
   (prinst "cmp" "%r12" (src Src S)) )

(asm nulp (Src S)
   (prinst "cmp" "%r12" (src Src S)) )

(asm nul4 ()
   (prinst "cmp" "%r12d" "%eax") )

# Byte addressing
(asm set (Dst D Src S)
   (setq Dst (dst Dst D)  Src (src Src S))
   (cond
      ((= "%r12" Src)
         (prinst "mov" "%r12b" (lowByte Dst)) )
      ((or (pre? "$" Src) (pre? "%" Src) (pre? "%" Dst))
         (prinst "movb" Src Dst) )
      (T
         (prinst "mov" Src "%r10b")
         (prinst "mov" "%r10b" Dst) ) ) )

(asm nul (Src S)
   (prinst "cmp" "%r12b" (src Src S)) )

# Types
(asm cnt (Src S)
   (prinst "testb" "$0x02" (lowByte (src Src S))) )

(asm big (Src S)
   (prinst "testb" "$0x04" (lowByte (src Src S))) )

(asm num (Src S)
   (prinst "testb" "$0x06" (lowByte (src Src S))) )

(asm sym (Src S)
   (prinst "testb" "$0x08" (lowByte (src Src S))) )

(asm atom (Src S)
   (prinst "testb" "$0x0E" (lowByte (src Src S))) )

# Flow control
(asm call (Adr A)
   (nond
      (A  # Absolute
         (prinst "call" (target Adr)) )
      ((=T A)  # Ignore SUBR
         (prinst "call" (pack "*" Adr)) )
      (NIL  # Indirect
         (prinst "mov" (target Adr T) "%r10")
         (prinst "call" "*%r10") ) ) )

(asm jmp (Adr A)
   (nond
      (A (prinst "jmp" (target Adr)))
      ((=T A)  # Ignore SUBR
         (prinst "jmp" (pack "*" Adr)) )
      (NIL
         (prinst "mov" (target Adr T) "%r10")
         (prinst "jmp" "*%r10") ) ) )

(asm tos (Dst D)
   (setq Dst (dst Dst D))
   (if (pre? "%" Dst)
      (prinst "pop" Dst)
      (prinst "popq" Dst) ) )

(de _jmp (Opc Opc2)
   (ifn A
      (prinst Opc (target Adr))
      (prinst Opc2 "1f")
      (ifn (=T A)  # Ignore SUBR
         (prinst "jmp" (pack "*" Adr))
         (prinst "mov" (target Adr T) "%r10")
         (prinst "jmp" "*%r10") )
      (prinl "1:") ) )

(asm jz (Adr A)
   (_jmp "jz" "jnz") )

(asm jeq (Adr A)
   (_jmp "jz" "jnz") )

(asm jnz (Adr A)
   (_jmp "jnz" "jz") )

(asm jne (Adr A)
   (_jmp "jnz" "jz") )

(asm js (Adr A)
   (_jmp "js" "jns") )

(asm jns (Adr A)
   (_jmp "jns" "js") )

(asm jsz (Adr A)
   (_jmp "jle" "jg") )

(asm jnsz (Adr A)
   (_jmp "jg" "jle") )

(asm jc (Adr A)
   (_jmp "jc" "jnc") )

(asm jb (Adr A)
   (_jmp "jc" "jnc") )

(asm jx (Adr A)
   (_jmp "jc" "jnc") )

(asm jlt (Adr A)
   (_jmp "jc" "jnc") )

(asm jnc (Adr A)
   (_jmp "jnc" "jc") )

(asm jnb (Adr A)
   (_jmp "jnc" "jc") )

(asm jnx (Adr A)
   (_jmp "jnc" "jc") )

(asm jge (Adr A)
   (_jmp "jnc" "jc") )

(asm jle (Adr A)
   (_jmp "jbe" "ja") )

(asm jgt (Adr A)
   (_jmp "ja" "jbe") )

(asm ret ()
   (unless
      (and
         (seek '((L) (== (cadr L) *Statement)) *Program)
         (not (memq (caar @) '`(cons ': (cddr *Transfers)))) )
      (prinst "rep") )
   (prinst "ret") )

(asm catch ())

(asm throw ()
   ((get 'ret 'asm)) )

# Floating point
(asm ldd ()
   (prinst "movsd" "(%rdx)" "%xmm0") )

(asm ldf ()
   (prinst "movss" "(%rdx)" "%xmm0") )

(asm fixnum ()
   (prinst "shr" "$4" "%rbx")                # Normalize scale
   (prinst "jc" "1f")                        # Jump if negative
   (prinst "cvtsi2sd" "%rbx" "%xmm7")        # Mulitply double with scale
   (prinst "mulsd" "%xmm7" "%xmm0")
   (prinst "cvtsd2si" "%xmm0" "%rbx")        # Convert to integer
   (prinst "jmp" "2f")
   (prinl "1:")
   (prinst "cvtsi2ss" "%rbx" "%xmm7")        # Mulitply float with scale
   (prinst "mulss" "%xmm7" "%xmm0")
   (prinst "cvtss2si" "%xmm0" "%rbx")        # Convert to integer
   (prinl "2:")
   (prinst "or" "%rbx" "%rbx")               # Negative?
   (prinst "js" "3f")                        # Yes: Skip
   (prinst "shl" "$4" "%rbx")                # Make positive short
   (prinst "orb" "$2" "%bl")
   (prinst "jmp" "5f")
   (prinl "3:")
   (prinst "neg" "%rbx")                     # Negate
   (prinst "js" "4f")                        # Still negative: Overflow
   (prinst "shl" "$4" "%rbx")                # Make negative short
   (prinst "orb" "$10" "%bl")
   (prinst "jmp" "5f")
   (prinl "4:")                              # Infinite/NaN
   (prinst "mov" "$Nil" "%rbx")              # Preload NIL
   (prinst "xorpd" "%xmm7" "%xmm7")          # Float value negative?
   (prinst "ucomisd" "%xmm7" "%xmm0")
   (prinst "jc" "5f")                        # Yes: Skip
   (prinst "mov" "$TSym" "%rbx")             # Load T
   (prinl "5:") )

(asm float ()
   (prinst "mov" "%rax" "%r10")              # Normalize scale
   (prinst "shr" "$4" "%r10")                # Negative?
   (prinst "jc" "3f")                        # Yes: Skip
   (prinst "testb" "$0x02" "(%r13)")         # Short fixnum?
   (prinst "jz" "2f")                        # No: Skip
   (prinst "cvtsi2sd" "%r10" "%xmm7")        # Convert scale
   (prinst "mov" "(%r13)" "%r10")            # Normalize fixnum
   (prinst "shr" "$4" "%r10")                # Negative?
   (prinst "jnc" "1f")                       # No: Skip
   (prinst "neg" "%r10")                     # Else negate
   (prinl "1:")
   (prinst "cvtsi2sd" "%r10" "%xmm0")        # Convert fixnum to double
   (prinst "divsd" "%xmm7" "%xmm0")          # Divide by scale
   (prinst "jmp" "4f")                       # Done
   (prinl "2:")
   (prinst "cmpq" "$Nil" "(%r13)")           # Minus infinite?
   (prinst "mov" "$0x7FF0000000000000" "%r10")
   (prinst "jnz" "1f")                       # No: Skip
   (prinst "mov" "$0xFFF0000000000000" "%r10")
   (prinl "1:")
   (prinst "push" "%r10")
   (prinst "movsd" "(%rsp)" "%xmm0")
   (prinst "add" "$8" "%rsp")
   (prinst "jmp" "4f")                       # Done
   (prinl "3:")
   (prinst "testb" "$0x02" "(%r13)")         # Short fixnum?
   (prinst "jz" "2f")                        # No: Skip
   (prinst "cvtsi2ss" "%r10" "%xmm7")        # Convert scale
   (prinst "mov" "(%r13)" "%r10")            # Normalize fixnum
   (prinst "shr" "$4" "%r10")                # Negative?
   (prinst "jnc" "1f")                       # No: Skip
   (prinst "neg" "%r10")                     # Else negate
   (prinl "1:")
   (prinst "cvtsi2ss" "%r10" "%xmm0")        # Convert fixnum to float
   (prinst "divss" "%xmm7" "%xmm0")          # Divide by scale
   (prinst "jmp" "4f")                       # Done
   (prinl "2:")
   (prinst "cmpq" "$Nil" "(%r13)")           # Minus infinite?
   (prinst "mov" "$0x7F800000" "%r10")
   (prinst "jnz" "1f")
   (prinst "mov" "$0xFF800000" "%r10")
   (prinl "1:")
   (prinst "push" "%r10")
   (prinst "movss" "(%rsp)" "%xmm0")
   (prinst "add" "$8" "%rsp")
   (prinl "4:") )

(asm std ()
   (prinst "movsd" "%xmm0" "(%r15)") )

(asm stf ()
   (prinst "movss" "%xmm0" "(%r15)") )

# C-Calls
(asm cc (Adr A Arg M)
   (unless (== 'cc (caar (seek '((L) (== (cadr L) *Statement)) *Program)))
      (prinst "mov" "%rdx" "%r12") )
   (let Reg '("%rdi" "%rsi" "%rdx" "%rcx" "%r8" "%r9")
      (if (lst? Arg)
         (let Lea NIL
            (mapc
               '((Src S)
                  (if (== '& Src)
                     (on Lea)
                     (unless (and (=0 S) (= "0" Src))  # Keep for 'xor' later
                        (setq Src
                           (src
                              (recur (Src)
                                 (cond
                                    ((= "%rdx" Src) "%r12")
                                    ((atom Src) Src)
                                    (T (cons (recurse (car Src)) (recurse (cdr Src)))) ) )
                              S ) ) )
                     (cond
                        ((and (=0 S) (= "0" Src))
                           (prinst "xor" (car Reg) (pop 'Reg)) )
                        ((= "$pop" Src)
                           (prinst "pop" (pop 'Reg)) )
                        (T (prinst (if Lea "lea" "mov") Src (pop 'Reg))) )
                     (off Lea) ) )
               (head 6 Arg)
               (head 6 M) )
            (prinst "push" "%rbp")
            (prinst "mov" "%rsp" "%rbp")
            (when (nth Arg 7)  # Maximally 6 args in registers
               (prinst "sub" (pack "$" (* 8 (length @))) "%rsp") )
            (prinst "andb" "$~15" "%spl")  # Align stack
            (let Ofs 0
               (mapc  # 'Src' not lea or stack-relative here!
                  '((Src S)
                     (unless (and (=0 S) (= "0" Src))  # Keep for 'xor' later
                        (setq Src
                           (src
                              (recur (Src)
                                 (cond
                                    ((= "%rdx" Src) "%r12")
                                    ((atom Src) Src)
                                    (T (cons (recurse (car Src)) (recurse (cdr Src)))) ) )
                              S ) ) )
                     (ifn (and (=0 S) (= "0" Src))
                        (prinst "movq" Src (pack Ofs "(%rsp)"))
                        (prinst "xor" "%rax" "%rax")
                        (prinst "movq" "%rax" (pack Ofs "(%rsp)")) )
                     (inc 'Ofs 8) )
                  (nth Arg 7)
                  (nth M 7) ) )
            # Don't use SSE registers in varargs for static calls
            (when (member Adr '("printf" "fprintf" "snprintf" "open" "fcntl"))
               (prinst "xor" "%al" "%al") ) )
         (prinst "mov" "%rsp" "%rax")     # A on arguments
         (prinst "push" "%rbp")           # Link
         (prinst "mov" "%rsp" "%rbp")
         (prinst "mov" Arg "%rbx")
         (prinst "sub" "%rax" "%rbx")     # Size of arguments
         (prinst "shr" "$1" "%rbx")       # Take half
         (prinst "sub" "%rbx" "%rsp")     # Allocate space
         (prinst "andb" "$~15" "%spl")    # Align stack
         (prinst "mov" "%rsp" "%rbx")     # E on stack space
         (prinst "lea" "5f(%rip)" "%r11")
         (mapc
            '((R X)
               (prinl "1:")
               (prinst "cmp" "%rax" Arg)
               (prinst "jz" "9f")
               (prinst "mov" "(%rax)" "%r10")
               (prinst "add" "$16" "%rax")
               (prinst "or" "%r10" "%r10")
               (prinst "jz" "7f")
               (prinst "call" "*%r11")
               (prinst "jmp" "1b")
               (prinl "5:")
               (unless (= R "%r9")
                  (prinst "lea" "(5f-5b)(%r11)" "%r11") )
               (prinst "shr" "$4" "%r10")
               (prinst "jc" "3f")
               (prinst "testb" "$0x02" "-8(%rax)")
               (prinst "jz" "2f")
               (prinst "cvtsi2sd" "%r10" "%xmm7")
               (prinst "mov" "-8(%rax)" "%r10")
               (prinst "shr" "$4" "%r10")
               (prinst "jnc" "1f")
               (prinst "neg" "%r10")
               (prinl "1:")
               (prinst "cvtsi2sd" "%r10" X)
               (prinst "divsd" "%xmm7" X)
               (prinst "ret")
               (prinl "2:")
               (prinst "cmpq" "$Nil" "-8(%rax)")
               (prinst "mov" "$0x7FF0000000000000" "%r10")
               (prinst "jnz" "1f")
               (prinst "mov" "$0xFFF0000000000000" "%r10")
               (prinl "1:")
               (prinst "mov" "%r10" "-8(%rax)")
               (prinst "movsd" "-8(%rax)" X)
               (prinst "ret")
               (prinl "3:")
               (prinst "testb" "$0x02" "-8(%rax)")
               (prinst "jz" "2f")
               (prinst "cvtsi2ss" "%r10" "%xmm7")
               (prinst "mov" "-8(%rax)" "%r10")
               (prinst "shr" "$4" "%r10")
               (prinst "jnc" "1f")
               (prinst "neg" "%r10")
               (prinl "1:")
               (prinst "cvtsi2ss" "%r10" X)
               (prinst "divss" "%xmm7" X)
               (prinst "ret")
               (prinl "2:")
               (prinst "cmpq" "$Nil" "-8(%rax)")
               (prinst "mov" "$0x7F800000" "%r10")
               (prinst "jnz" "1f")
               (prinst "mov" "$0xFF800000" "%r10")
               (prinl "1:")
               (prinst "mov" "%r10" "-8(%rax)")
               (prinst "movss" "-8(%rax)" X)
               (prinst "ret")
               (prinl "7:")
               (prinst "mov" "-8(%rax)" R) )
            Reg
            '("%xmm0" "%xmm1" "%xmm2" "%xmm3" "%xmm4" "%xmm5") )
         (prinl "1:")
         (prinst "cmp" "%rax" Arg)
         (prinst "jz" "9f")
         (prinst "mov" "8(%rax)" "%r10")
         (prinst "add" "$16" "%rax")
         (prinst "mov" "%r10" "(%rbx)")
         (prinst "add" "$8" "%rbx")
         (prinst "jmp" "1b")
         (prinl "9:")
         # Maximally 6 SSE registers in varargs for dynamic calls
         (prinst "mov" "$6" "%al") ) )
   ((get 'call 'asm) Adr A)
   (prinst "mov" "%rbp" "%rsp")
   (prinst "pop" "%rbp")
   (unless (== 'cc (caadr (memq *Statement *Program)))
      (prinst "mov" "%r12" "%rdx")
      (prinst "xor" "%r12" "%r12") ) )

(asm func ())

(asm begin ()
   (prinst "call" "begin") )

(asm return ()
   (prinst "jmp" "return") )

# Stack Manipulations
(asm push (Src S)
   (setq Src (src Src S))
   (cond
      ((== 'zscx Src) (prinst "pushf"))
      ((pre? "%" Src) (prinst "push" Src))
      (T (prinst "pushq" Src)) ) )

(asm pop (Dst D)
   (setq Dst (dst Dst D))
   (cond
      ((== 'zscx Dst) (prinst "popf"))
      ((pre? "%" Dst) (prinst "pop" Dst))
      (T (prinst "popq" Dst)) ) )

(asm link ()
   (prinst "push" "%rbp")
   (prinst "mov" "%rsp" "%rbp") )

(asm tuck (Src S)
   (setq Src (src Src S))
   (prinst "mov" "(%rsp)" "%rbp")
   (if (or (pre? "$" Src) (pre? "%" Src))
      (prinst "movq" Src "(%rsp)")
      (prinst "mov" Src "%r10")
      (prinst "mov" "%r10" "(%rsp)") ) )

(asm drop ()
   (prinst "mov" "(%rbp)" "%rsp")
   (prinst "pop" "%rbp") )

# Evaluation
(asm eval ()
   (prinst "test" "$0x06" "%bl")       # Number?
   (prinst "jnz" "1f")                 # Yes: Skip
   (prinst "test" "$0x08" "%bl")       # Symbol?
   (prinst "cmovnzq" "(%rbx)" "%rbx")  # Yes: Get value
   (prinst "jnz" "1f")                 # and skip
   (prinst "call" (target 'evListE_E)) # Else evaluate list
   (prinl "1:") )

(asm eval+ ()
   (prinst "test" "$0x06" "%bl")       # Number?
   (prinst "jnz" "1f")                 # Yes: Skip
   (prinst "test" "$0x08" "%bl")       # Symbol?
   (prinst "cmovnzq" "(%rbx)" "%rbx")  # Yes: Get value
   (prinst "jnz" "1f")                 # and skip
   (prinst "push" "%rbp")              # Else 'link'
   (prinst "mov" "%rsp" "%rbp")
   (prinst "call" (target 'evListE_E)) # Evaluate list
   (prinst "pop" "%rbp")
   (prinl "1:") )

(asm eval/ret ()
   (prinst "test" "$0x06" "%bl")       # Number?
   (prinst "jnz" "ret")                # Yes: Return
   (prinst "test" "$0x08" "%bl")       # Symbol?
   (prinst "jz" 'evListE_E)            # No: Evaluate list
   (prinst "mov" "(%rbx)" "%rbx")      # Get value
   (prinst "ret") )

(asm exec (Reg)
   (prinl "1:")                        # do
   (prinst "mov"                       # ld E (R)
      (pack "(" Reg ")")
      "%rbx" )
   (prinst "test" "$0x0E" "%bl")       # atom E
   (prinst "jnz" "2f")
   (prinst "call" (target 'evListE_E)) # evList
   (prinl "2:")
   (prinst "mov"                       # ld R (R CDR)
      (pack "8(" Reg ")")
      Reg )
   (prinst "testb"                     # atom R
      "$0x0E"
      (byteReg Reg) )
   (prinst "jz" "1b") )                # until nz

(asm prog (Reg)
   (prinl "1:")                        # do
   (prinst "mov"                       # ld E (R)
      (pack "(" Reg ")")
      "%rbx" )
   (prinst "test" "$0x06" "%bl")       # eval
   (prinst "jnz" "2f")
   (prinst "test" "$0x08" "%bl")
   (prinst "cmovnzq" "(%rbx)" "%rbx")
   (prinst "jnz" "2f")
   (prinst "call" (target 'evListE_E))
   (prinl "2:")
   (prinst "mov"                       # ld R (R CDR)
      (pack "8(" Reg ")")
      Reg )
   (prinst "testb"                     # atom R
      "$0x0E"
      (byteReg Reg) )
   (prinst "jz" "1b") )                # until nz

# System
(asm initData ())

(asm initCode ()
   (unless *FPic
      (label "begin")
      (prinst "pop" "%r10")         # Get return address
      (prinst "push" "%r15")        # Z
      (prinst "mov" "%r9" "%r15")
      (prinst "push" "%r14")        # Y
      (prinst "mov" "%r8" "%r14")
      (prinst "push" "%r13")        # X
      (prinst "mov" "%rcx" "%r13")
      (prinst "push" "%r12")
      (prinst "xor" "%r12" "%r12")  # NULL register
      (prinst "push" "%rbx")
      (prinst "mov" "%rdx" "%rbx")  # E
      (prinst "mov" "%rsi" "%rdx")  # C
      (prinst "mov" "%rdi" "%rax")  # A
      (prinst "jmp" "*%r10")        # Return
      (prinl)
      (label "return")
      (prinst "pop" "%rbx")
      (prinst "pop" "%r12")
      (prinst "pop" "%r13")
      (prinst "pop" "%r14")
      (prinst "pop" "%r15")
      (prinst "ret") ) )

(asm initMain ()
   (prinst "xor" "%r12" "%r12")  # Init NULL register
   (prinst "mov" "(%rsi)" "%r13")  # Get command in X
   (prinst "lea" "8(%rsi)" "%r14")  # argument vector in Y
   (prinst "lea" "-8(%rsi,%rdi,8)" "%r15") )  # pointer to last argument in Z

(asm initLib ())

(asm stop ()
   (prinst "mov" "%rbx" "%rdi")  # Return 'E'
   (prinst "jmp" "exit") )

### Optimizer ###
# Replace the the next 'cnt' elements with 'lst'
(de optimize (Lst))  #> (cnt . lst)

### Decoration ###
(de prolog (File))

(de epilog (File))

# vi:et:ts=3:sw=3
