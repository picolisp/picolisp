# 15sep09abu
# (c) Software Lab. Alexander Burger

# Byte order
(on *LittleEndian)

# Register assignments
(de *Registers
   (A . "%rax") (C . "%rdx") (E . "%rbx")
   (B . "%al") (D "%rax" . "%rdx")
   (X . "%r13") (Y . "%r14") (Z . "%r15")
   (L . "%rbp") (S . "%rsp")
   (F . T) )
# NULL: %r12
# Temporary: %r10 %r11
# Block operations: %rcx %rsi %rdi
# C arguments: %rdi %rsi %rdx %rcx %r8 %r9

(de picfun (Adr)
   (if *FPic (pack Adr "@plt") Adr) )

(de picvar (Adr)
   (if *FPic 
      (pack Adr "@GOTPCREL(%rip)")
      (pack '$ Adr) ) )

(de byteReg (Reg)
   (cdr
      (assoc Reg
         (quote
            ("%rax" . "%al")
            ("%al" . "%al")
            ("%rdx" . "%dl")
            ("%rbx" . "%bl")
            ("%r13" . "%r13b")
            ("%r14" . "%r14b")
            ("%r15" . "%r15b")
            ("%rbp" . "%bpl")
            ("%rsp" . "%spl") ) ) ) )

(de byteVal (Adr Mode)
   (if Mode
      Adr  # Byte address
      (byteReg Adr) ) )  # Register

(de lowByte (Adr Mode)
   (if Mode
      Adr  # Word address
      (byteReg Adr) ) )  # Register

(de highWord (S)
   (cond
      ((= `(char "(") (char S))
         (pack "8" S) )
      ((>= `(char "9") (char S) `(char "0"))
         (pack "8+" S) )
      (T (pack S "+8")) ) )

(de dstSrc (Cmd Dst D Src S)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (while (pair S)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'S))) )
   (cond
      ((= "%al" Dst)
         (prinst Cmd
            (if (= "$0" Src) "%r12b" (byteVal Src S))
            "%al" ) )
      ((= "%al" Src)
         (prinst Cmd "%al" (byteVal Dst D)) )
      ((= "$0" Src)
         (prinst Cmd "%r12" Dst) )
      ((and (num? S) (not (>= 2147483647 S -2147483648)))
         (prinst "mov" Src "%r10")
         (prinst Cmd "%r10" Dst) )
      ((nand D S)
         (prinst Cmd Src Dst) )
      ((num? S)
         (prinst (pack Cmd "q") Src Dst) )
      (T
         (prinst "mov" Src "%r10")
         (prinst Cmd "%r10" Dst) ) ) )

(de dstSrcByte (Cmd Dst D Src S)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (while (pair S)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'S))) )
   (cond
      ((= "$0" Src)
         (prinst Cmd "%r12b" (lowByte Dst D)) )
      ((>= 255 S 0)
         (prinst (pack Cmd "b") Src (lowByte Dst D)) )
      (T (dstSrc Cmd Dst D Src S)) ) )

(de dstDst (Cmd Dst D Dst2 D2)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (cond
      ((= "%al" Dst)
         (prinst Cmd (byteVal Dst2 D2) "%al") )
      ((= "%al" Dst2)
         (prinst Cmd "%al" (byteVal Dst D)) )
      ((nand D D2)
         (prinst Cmd Dst2 Dst) )
      (T
         (prinst "mov" Dst "%r10")
         (prinst Cmd "%r10" Dst2)
         (prinst "mov" "%r10" Dst) ) ) )

(de dstShift (Cmd Dst D Src S)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (while (pair S)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'S))) )
   (if (num? S)
      (prinst (pack Cmd (and D "q")) Src Dst)
      (prinst "mov" (byteVal Src S) "%cl")
      (prinst (pack Cmd (and D "q")) "%cl" Dst) ) )


### Instruction set ###
(asm nop ()
   (prinst "nop") )

# Move data
(asm ld (Dst D Src S)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (while (pair S)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'S))) )
   (cond
      ((= "%al" Dst)
         (prinst "mov" (byteVal Src S) "%al") )  # %r12b needs 3 bytes
      ((= "%al" Src)
         (prinst "mov" "%al" (byteVal Dst D)) )
      ((pair Dst)
         (prinst "mov" (if (= "$0" Src) "%r12" Src) (car Dst))
         (prinst "mov" (if (= "$0" Src) "%r12" (highWord Src)) (cdr Dst)) )
      ((pair Src)
         (prinst "mov" (car Src) Dst)
         (prinst "mov" (cdr Src) (highWord Dst)) )
      ((= "$0" Src)
         (prinst "mov" "%r12" Dst) )
      ((nand D S)
         (prinst "mov" Src Dst) )
      ((sub? "GOTPCREL" Src)  # (PIC)
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) )
      ((num? S)
         (prinst "movq" Src Dst) )
      (T
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) ) ) )

(asm ld2 (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "movswq" Src "%rax") )

(asm ld4 (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "movslq" Src "%rax") )

(asm ldc (Dst D Src S)
   (when (num? S)
      (if (= "$0" Src)
         (setq Src "%r12")
         (prinst "mov" Src "%r10")
         (setq Src "%r10") )
      (off S) )
   (if (and (flg? S) (not D))
      (prinst "cmovcq" Src Dst)
      (warn "Using suboptimal emulation code")
      (prinst "jnc" "1f")
      (if (or (num? S) (not Src))
         (prinst "movq" Src Dst)
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) )
      (prinl "1:") ) )

(asm ldnc (Dst D Src S)
   (when (num? S)
      (if (= "$0" Src)
         (setq Src "%r12")
         (prinst "mov" Src "%r10")
         (setq Src "%r10") )
      (off S) )
   (if (and (flg? S) (not D))
      (prinst "cmovncq" Src Dst)
      (warn "Using suboptimal emulation code")
      (prinst "jc" "1f")
      (if (or (num? S) (not Src))
         (prinst "movq" Src Dst)
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) )
      (prinl "1:") ) )

(asm ldz (Dst D Src S)
   (when (num? S)
      (if (= "$0" Src)
         (setq Src "%r12")
         (prinst "mov" Src "%r10")
         (setq Src "%r10") )
      (off S) )
   (if (and (flg? S) (not D))
      (prinst "cmovzq" Src Dst)
      (warn "Using suboptimal emulation code")
      (prinst "jnz" "1f")
      (if (or (num? S) (not Src))
         (prinst "movq" Src Dst)
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) )
      (prinl "1:") ) )

(asm ldnz (Dst D Src S)
   (when (num? S)
      (if (= "$0" Src)
         (setq Src "%r12")
         (prinst "mov" Src "%r10")
         (setq Src "%r10") )
      (off S) )
   (if (and (flg? S) (not D))
      (prinst "cmovnzq" Src Dst)
      (warn "Using suboptimal emulation code")
      (prinst "jz" "1f")
      (if (or (num? S) (not Src))
         (prinst "movq" Src Dst)
         (prinst "mov" Src "%r10")
         (prinst "mov" "%r10" Dst) )
      (prinl "1:") ) )

(asm lea (Dst D Src S)
   (while (pair S)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'S))) )
   (ifn D
      (prinst "lea" Src Dst)
      (prinst "lea" Src "%r11")
      (while (pair D)
         (prinst "mov" Dst "%r10")
         (setq Dst (indexed "%r10" (pop 'D))) )
      (prinst "mov" "%r11" Dst) ) )

(asm st2 (Dst Mode)
   (while (pair Mode)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'Mode))) )
   (prinst "movw" "%ax" Dst) )

(asm st4 (Dst Mode)
   (while (pair Mode)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'Mode))) )
   (prinst "movl" "%eax" Dst) )

(asm xchg (Dst D Dst2 D2)
   (dstDst "xchg" Dst D Dst2 D2) )

(asm movm (Dst D Src S End E)
   (prinst (if (atom D) "lea" "mov") Dst "%rdi")
   (prinst (if (atom S) "lea" "mov") Src "%rsi")
   (prinst "lea" End "%rcx")
   (prinst "sub" "%rsi" "%rcx")
   (prinst "cld")
   (prinst "rep movsb") )

(asm movn (Dst D Src S Cnt C)
   (prinst (if (atom D) "lea" "mov") Dst "%rdi")
   (prinst (if (atom S) "lea" "mov") Src "%rsi")
   (prinst "mov" Cnt "%rcx")
   (prinst "cld")
   (prinst "rep movsb") )

(asm mset (Dst D Cnt C)
   (prinst (if (atom D) "lea" "mov") Dst "%rdi")
   (prinst "mov" Cnt "%rcx")
   (prinst "cld")
   (prinst "rep stosb") )


# Arithmetics
(asm add (Dst D Src S)
   (ifn (pair Dst)
      (dstSrc "add" Dst D Src S)
      (while (pair S)
         (prinst "mov" Src "%r10")
         (setq Src (indexed "%r10" (pop 'S))) )
      (prinst "add" Src (car Dst))
      (prinst "adc" "%r12" (cdr Dst)) ) )

(asm addc (Dst D Src S)
   (ifn (pair Dst)
      (dstSrc "adc" Dst D Src S)
      (while (pair S)
         (prinst "mov" Src "%r10")
         (setq Src (indexed "%r10" (pop 'S))) )
      (prinst "adc" Src (car Dst))
      (prinst "adc" "%r12" (cdr Dst)) ) )


(asm sub (Dst D Src S)
   (ifn (pair Dst)
      (dstSrc "sub" Dst D Src S)
      (while (pair S)
         (prinst "mov" Src "%r10")
         (setq Src (indexed "%r10" (pop 'S))) )
      (prinst "sub" Src (car Dst))
      (prinst "sbb" "%r12" (cdr Dst)) ) )

(asm subc (Dst D Src S)
   (ifn (pair Dst)
      (dstSrc "sbb" Dst D Src S)
      (while (pair S)
         (prinst "mov" Src "%r10")
         (setq Src (indexed "%r10" (pop 'S))) )
      (prinst "sbb" Src (car Dst))
      (prinst "sbb" "%r12" (cdr Dst)) ) )

(asm not (Dst Mode)
   (if Mode
      (prinst "notq" Dst)
      (prinst "not" Dst) ) )

(asm neg (Dst Mode)
   (if Mode
      (prinst "negq" Dst)
      (prinst "neg" Dst) ) )

(asm and (Dst D Src S)
   (dstSrc "and" Dst D Src S) )

(asm or (Dst D Src S)
   (dstSrcByte "or" Dst D Src S) )

(asm xor (Dst D Src S)
   (dstSrcByte "xor" Dst D Src S) )

(asm off (Dst D Src S)
   (dstSrcByte "and" Dst D Src S) )

(asm test (Dst D Src S)
   (dstSrcByte "test" Dst D Src S) )

(asm shl (Dst D Src S)
   (dstShift "shl" Dst D Src S) )

(asm shr (Dst D Src S)
   (dstShift "shr" Dst D Src S) )

(asm rol (Dst D Src S)
   (dstShift "rol" Dst D Src S) )

(asm ror (Dst D Src S)
   (dstShift "ror" Dst D Src S) )

(asm rcl (Dst D Src S)
   (dstShift "rcl" Dst D Src S) )

(asm rcr (Dst D Src S)
   (dstShift "rcr" Dst D Src S) )

(asm mul (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (ifn (num? Mode)
      (prinst "mulq" Src)
      (prinst "mov" Src "%r10")
      (prinst "mul" "%r10") ) )

(asm div (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (ifn (num? Mode)
      (prinst "divq" Src)
      (prinst "mov" Src "%r10")
      (prinst "div" "%r10") ) )

(asm zxt ()  # 8 bit -> 64 bit
   (prinst "movzx" "%al" "%rax") )

(asm sxt ()  # 8 bit -> 64 bit
   (prinst "movsx" "%al" "%rax") )

(asm int ()  # 32 bit -> 64 bit
   (prinst "movsx" "%eax" "%rax") )


(asm setc ()
   (prinst "stc") )

(asm clrc ()
   (prinst "clc") )

(asm setz ()
   (prinst "or" "%r12" "%r12") )

(asm clrz ()
   (prinst "cmp" "%rsp" "%r12") )


# Comparisons
(asm cmp (Dst D Src S)
   (dstSrc "cmp" Dst D Src S) )

(asm cmp4 (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "cmp" Src "%eax") )

(asm cmpm (Dst D Src S End E)
   (prinst (if (=T D) "lea" "mov") Dst "%rsi")
   (prinst (if (=T S) "lea" "mov") Src "%rdi")
   (prinst "lea" End "%rcx")
   (prinst "sub" "%rsi" "%rcx")
   (prinst "cld")
   (prinst "repnz cmpsb") )

(asm cmpn (Dst D Src S Cnt C)
   (prinst (if (=T D) "lea" "mov") Dst "%rsi")
   (prinst (if (=T S) "lea" "mov") Src "%rdi")
   (prinst "mov" Cnt "%rcx")
   (prinst "cld")
   (prinst "repnz cmpsb") )

(asm slen (Dst D Src S)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (prinst "cld")
   (prinst "xor" "%rcx" "%rcx")
   (prinst "not" "%rcx")
   (prinst (if (=T S) "lea" "mov") Src "%rdi")
   (prinst "xchg" "%al" "%r12b")
   (prinst "repnz scasb")
   (prinst "xchg" "%al" "%r12b")
   (prinst "not" "%rcx")
   (prinst "dec" "%rcx")
   (prinst "mov" "%rcx" Dst) )

(asm memb (Src S Cnt C)
   (prinst "cld")
   (prinst (if (=T S) "lea" "mov") Src "%rdi")
   (prinst "mov" Cnt "%rcx")
   (prinst "repnz scasb")
   (unless S (prinst "cmovzq" "%rdi" Src))
   (unless C (prinst "cmovzq" "%rcx" Cnt)) )

(asm null (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "cmp" "%r12" Src) )

(asm zero (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "cmpq" "$2" Src) )

(asm nul4 ()
   (prinst "cmp" "%r12d" "%eax") )


# Byte addressing
(asm set (Dst D Src S)
   (while (pair D)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'D))) )
   (while (pair S)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'S))) )
   (cond
      ((= "$0" Src)
         (prinst "mov" "%r12b" Dst) )
      ((nand D S)
         (prinst "movb" Src Dst) )
      ((num? S)
         (prinst "movb" Src Dst) )
      (T
         (prinst "mov" Src "%r10b")
         (prinst "mov" "%r10b" Dst) ) ) )

(asm nul (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "cmp" "%r12b" Src) )


# Types
(asm cnt (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "testb" "$0x02" (lowByte Src Mode)) )

(asm big (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "testb" "$0x04" (lowByte Src Mode)) )

(asm num (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "testb" "$0x06" (lowByte Src Mode)) )

(asm sym (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "testb" "$0x08" (lowByte Src Mode)) )

(asm atom (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "testb" "$0x0E" (lowByte Src Mode)) )


# Flow Control
(asm call (Adr Mode)
   (nond
      (Mode (prinst "call" Adr))
      ((=T Mode) (prinst "call" (pack "*" Adr)))
      (NIL
         (prinst "mov" Adr "%r10")
         (prinst "call" "*%r10") ) ) )

(asm jmp (Adr Mode)
   (nond
      (Mode (prinst "jmp" Adr))
      ((=T Mode) (prinst "jmp" (pack "*" Adr)))
      (NIL
         (prinst "mov" Adr "%r10")
         (prinst "jmp" "*%r10") ) ) )

(de _jmp (Opc Opc2)
   (ifn Mode
      (prinst Opc Adr)
      (prinst Opc2 "1f")
      (ifn (=T Mode)
         (prinst "jmp" (pack "*" Adr))
         (prinst "mov" Adr "%r10")
         (prinst "jmp" "*%r10") )
      (prinl "1:") ) )

(asm jz (Adr Mode)
   (_jmp "jz" "jnz") )

(asm jeq (Adr Mode)
   (_jmp "jz" "jnz") )

(asm jnz (Adr Mode)
   (_jmp "jnz" "jz") )

(asm jne (Adr Mode)
   (_jmp "jnz" "jz") )

(asm js (Adr Mode)
   (_jmp "js" "jns") )

(asm jns (Adr Mode)
   (_jmp "jns" "js") )

(asm jsz (Adr Mode)
   (_jmp "jle" "jg") )

(asm jnsz (Adr Mode)
   (_jmp "jg" "jle") )

(asm jc (Adr Mode)
   (_jmp "jc" "jnc") )

(asm jlt (Adr Mode)
   (_jmp "jc" "jnc") )

(asm jnc (Adr Mode)
   (_jmp "jnc" "jc") )

(asm jge (Adr Mode)
   (_jmp "jnc" "jc") )

(asm jcz (Adr Mode)
   (_jmp "jbe" "ja") )

(asm jle (Adr Mode)
   (_jmp "jbe" "ja") )

(asm jncz (Adr Mode)
   (_jmp "ja" "jbe") )

(asm jgt (Adr Mode)
   (_jmp "ja" "jbe") )

(asm cc (Adr A Arg M)
   (unless (== 'cc (caar (seek '((L) (== (cadr L) *Statement)) *Program)))
      (prinst "mov" "%rdx" "%r12") )
   (let Reg '("%rdi" "%rsi" "%rdx" "%rcx" "%r8" "%r9")
      (if (lst? Arg)
         (let  Lea NIL
            (when (nth Arg 7)
               (setq  # Maximally 6 args in registers
                  Arg (append (head 6 Arg) (reverse (tail -6 Arg)))
                  M (append (head 6 M) (reverse (tail -6 M))) ) )
            (mapc
               '((Src Mode)
                  (use (@A @Z)
                     (when (match '(@A ~(chop "%rdx") @Z) (chop Src))
                        (setq Src (pack @A "%r12" @Z)) ) )
                  (while (pair Mode)
                     (prinst "mov" Src "%r10")
                     (setq Src (indexed "%r10" (pop 'Mode))) )
                  (if (= "$&" Src)
                     (on Lea)
                     (cond
                        ((not Reg)  # 'Src' not stack-relative here!
                           (ifn Lea
                              (prinst "pushq" Src)
                              (prinst "lea" Src "%rax")
                              (prinst "pushq" "%rax") ) )
                        ((= "$0" Src)
                           (prinst "xor" (car Reg) (pop 'Reg)) )
                        ((= "$pop" Src)
                           (prinst "pop" (pop 'Reg)) )
                        (T (prinst (if Lea "lea" "mov") Src (pop 'Reg))) )
                     (off Lea) ) )
               Arg
               M )
            # Don't use SSE registers if varargs
            (when (member Adr '("printf" "fprintf" "sprintf"))
               (prinst "xor" "%rax" "%rax") ) )
         (for R Reg
            (prinst "cmp" "%rsp" Arg)
            (prinst "jz" "1f")
            (prinst "pop" R) )
         (prinl "1:")
         # Don't use SSE registers if varargs
         (prinst "xor" "%rax" "%rax") ) )
   ((get 'call 'asm) Adr A)
   (if (lst? Arg)
      (when (gt0 (- (length Arg) 6))
         (prinst "lea" (pack (* @ 8) "(%rsp)") "%rsp") )
      (prinst "mov" Arg "%rsp") )
   (unless (== 'cc (caadr (memq *Statement *Program)))
      (prinst "mov" "%r12" "%rdx")
      (prinst "xor" "%r12" "%r12") ) )

(asm ret ()
   (unless
      (and
         (seek '((L) (== (cadr L) *Statement)) *Program)
         (not (memq (caar @) '`(cons ': (cdr *Transfers)))) )
      (prinst "rep") )
   (prinst "ret") )

(asm begin (N)
   (prinst "push" "%rbx")
   (prinst "push" "%r12")
   (prinst "xor" "%r12" "%r12")  # NULL register
   (when (>= N 6)                                  # Z
      (prinst "push" "%r15")
      (prinst "mov" "%r9" "%r15") )
   (when (>= N 5)                                  # Y
      (prinst "push" "%r14")
      (prinst "mov" "%r8" "%r14") )
   (when (>= N 4)                                  # X
      (prinst "push" "%r13")
      (prinst "mov" "%rcx" "%r13") )
   (and (>= N 3) (prinst "mov" "%rdx" "%rbx"))     # E
   (and (>= N 2) (prinst "mov" "%rsi" "%rdx"))     # C
   (and (>= N 1) (prinst "mov" "%rdi" "%rax")) )   # A

(asm return (N)
   (and (>= N 4) (prinst "pop" "%r13"))
   (and (>= N 5) (prinst "pop" "%r14"))
   (and (>= N 6) (prinst "pop" "%r15"))
   (prinst "pop" "%r12")
   (prinst "pop" "%rbx")
   (prinst "ret") )


# Stack Manipulations
(asm push (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (cond
      ((=T Src) (prinst "pushf"))
      ((not Mode) (prinst "push" Src))
      ((= "$0" Src) (prinst "push" "%r12"))
      (T (prinst "pushq" Src)) ) )

(asm pop (Dst Mode)
   (while (pair Mode)
      (prinst "mov" Dst "%r11")
      (setq Dst (indexed "%r11" (pop 'Mode))) )
   (cond
      ((=T Dst) (prinst "popf"))
      ((not Mode) (prinst "pop" Dst))
      (T (prinst "popq" Dst)) ) )

(asm link ()
   (prinst "push" "%rbp")
   (prinst "mov" "%rsp" "%rbp") )

(asm tuck (Src Mode)
   (while (pair Mode)
      (prinst "mov" Src "%r10")
      (setq Src (indexed "%r10" (pop 'Mode))) )
   (prinst "mov" "(%rsp)" "%rbp")
   (if (nT Mode)  # Register or immediate
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
   (prinst "call" (picfun 'evListE_E)) # Else evaluate list
   (prinl "1:") )

(asm eval+ ()
   (prinst "test" "$0x06" "%bl")       # Number?
   (prinst "jnz" "1f")                 # Yes: Skip
   (prinst "test" "$0x08" "%bl")       # Symbol?
   (prinst "cmovnzq" "(%rbx)" "%rbx")  # Yes: Get value
   (prinst "jnz" "1f")                 # and skip
   (prinst "push" "%rbp")              # Else 'link'
   (prinst "mov" "%rsp" "%rbp")
   (prinst "call" (picfun 'evListE_E)) # Evaluate list
   (prinst "pop" "%rbp")
   (prinl "1:") )

(asm eval/ret ()
   (prinst "test" "$0x06" "%bl")       # Number?
   (prinst "jnz" "ret")                # Yes: Return
   (prinst "test" "$0x08" "%bl")       # Symbol?
   (prinst "jz" 'evListE_E)            # No: Evaluate list
   (prinst "movq" "(%rbx)" "%rbx")     # Get value
   (prinst "ret") )

(asm exec (Reg)
   (prinl "1:")                        # do
   (prinst "mov"                       # ld E (R)
      (pack "(" Reg ")")
      "%rbx" )
   (prinst "test" "$0x0E" "%bl")       # atom E
   (prinst "jnz" "2f")
   (prinst "call" (picfun 'evListE_E)) # evList
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
   (prinst "call" (picfun 'evListE_E))
   (prinl "2:")
   (prinst "mov"                       # ld R (R CDR)
      (pack "8(" Reg ")")
      Reg )
   (prinst "testb"                     # atom R
      "$0x0E"
      (byteReg Reg) )
   (prinst "jz" "1b") )                # until nz


# System
(asm init ()
   (prinst "xor" "%r12" "%r12")  # Init NULL register
   (prinst "mov" "(%rsi)" "%r10")  # Get command
   (prinst "movq" "%r10" "AV0")
   (prinst "lea" "8(%rsi)" "%r10")  # Get argument vector
   (prinst "mov" "%r10" "AV") )


### Optimizer ###
# Replace the the next 'cnt' elements with 'lst'
(de optimize (L))  #> (cnt . lst)

# vi:et:ts=3:sw=3
