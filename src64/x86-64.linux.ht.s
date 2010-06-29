/* 11jun10 */

   .data

   .globl  HtOK
HtOK:
   .balign  8
   .asciz   "<b>"
   .balign  8
   .asciz   "</b>"
   .balign  8
   .asciz   "<i>"
   .balign  8
   .asciz   "</i>"
   .balign  8
   .asciz   "<u>"
   .balign  8
   .asciz   "</u>"
   .balign  8
   .asciz   "<p>"
   .balign  8
   .asciz   "</p>"
   .balign  8
   .asciz   "<pre>"
   .balign  8
   .asciz   "</pre>"
   .balign  8
   .asciz   "<div "
   .balign  8
   .asciz   "</div>"
   .balign  8
   .asciz   "<br>"
   .balign  8
   .asciz   "<hr>"
HtOkEnd:
HtLt:
   .asciz   "&lt;"
HtGt:
   .asciz   "&gt;"
HtAmp:
   .asciz   "&amp;"
HtQuot:
   .asciz   "&quot;"
HtNbsp:
   .asciz   "&nbsp;"
HtEsc:
   .ascii   " \"#%&:;<=>?_"

   .text

   .balign  16
   .globl  findHtOkY_FE
findHtOkY_FE:
   push     %r13
   mov      HtOK@GOTPCREL(%rip), %r13
.1:
   push     %r13
   push     %r14
.2:
   mov      (%r13), %al
   cmp      (%r14), %al
   jnz      .3
   inc      %r13
   cmp      %r12b, (%r13)
   jnz      .4
   cld
   xor      %rcx, %rcx
   not      %rcx
   mov      %r14, %rdi
   xchg     %al, %r12b
   repnz scasb
   xchg     %al, %r12b
   not      %rcx
   dec      %rcx
   mov      %rcx, %rdx
   mov      $62, %al
   cld
   mov      %r14, %rdi
   mov      %rdx, %rcx
   repnz scasb
   cmovzq   %rdi, %r14
   cmovzq   %rcx, %rdx
   cmovzq   %r14, %rbx
   pop      %r14
   pop      %r13
   pop      %r13
   ret
.4:
   inc      %r14
   cmp      %r12b, (%r14)
   jnz      .2
.3:
   pop      %r14
   pop      %r13
   add      $8, %r13
   cmp      HtOkEnd@GOTPCREL(%rip), %r13
   jbe      .1
   pop      %r13
   ret

   .balign  16
   nop
   nop
   .globl  Prin
Prin:
   push     %r13
   push     %r14
   push     %r15
   mov      8(%rbx), %r13
.5:
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   testb    $0x06, %bl
   jnz      Prin_20
   testb    $0x0E, %bl
   jz       Prin_20
   testb    $0x08, -8(%rbx)
   jz       .6
Prin_20:
   call     prinE_E@plt
   jmp      .7
.6:
   push     %rbx
   call     bufStringE_SZ@plt
   mov      %rsp, %r14
.8:
   cmp      %r12b, (%r14)
   jz       .9
   call     findHtOkY_FE@plt
   jnz      .10
.11:
   mov      (%r14), %al
   call     envPutB@plt
   inc      %r14
   cmp      %rbx, %r14
   jnz      .11
   jmp      .8
.10:
   mov      (%r14), %al
   cmp      $60, %al
   jnz      .13
   mov      HtLt@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .14
.13:
   cmp      $62, %al
   jnz      .15
   mov      HtGt@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .14
.15:
   cmp      $38, %al
   jnz      .17
   mov      HtAmp@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .14
.17:
   cmp      $34, %al
   jnz      .19
   mov      HtQuot@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .14
.19:
   cmp      $255, %al
   jnz      .21
   mov      $239, %al
   call     envPutB@plt
   mov      $191, %al
   call     envPutB@plt
   mov      $191, %al
   call     envPutB@plt
   jmp      .14
.21:
   mov      %rax, %rdx
   call     envPutB@plt
   testb    $128, %dl
   jz       .14
   inc      %r14
   mov      (%r14), %al
   call     envPutB@plt
   testb    $32, %dl
   jz       .14
   inc      %r14
   mov      (%r14), %al
   call     envPutB@plt
.14:
   inc      %r14
   jmp      .8
.9:
   mov      %r15, %rsp
   pop      %rbx
.7:
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       .5
   pop      %r15
   pop      %r14
   pop      %r13
   ret

   .balign  16
   .globl  putHexB
putHexB:
   mov      %rax, %rbx
   mov      $37, %al
   call     envPutB@plt
   mov      %rbx, %rax
   shr      $4, %al
   and      $15, %al
   cmp      $9, %al
   jbe      .25
   add      $7, %al
.25:
   add      $48, %al
   call     envPutB@plt
   mov      %rbx, %rax
   and      $15, %al
   cmp      $9, %al
   jbe      .26
   add      $7, %al
.26:
   add      $48, %al
   jmp      envPutB@plt

   .balign  16
   .globl  htFmtE
htFmtE:
   cmp      Nil@GOTPCREL(%rip), %rbx
   jz       .27
   testb    $0x06, %bl
   jz       .28
   mov      $43, %al
   call     envPutB@plt
   jmp      prinE@plt
.28:
   push     %r13
   testb    $0x0E, %bl
   jnz      .29
   mov      %rbx, %r13
.30:
   mov      $95, %al
   call     envPutB@plt
   mov      (%r13), %rbx
   call     htFmtE@plt
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       .30
   jmp      .31
.29:
   mov      -8(%rbx), %r13
   call     nameX_X@plt
   cmp      $2, %r13
   jz       .31
   testb    $0x08, -8(%rbx)
   jz       .33
   mov      $45, %al
   call     envPutB@plt
   call     prExtNmX@plt
   jmp      .31
.33:
   push     %r14
   mov      Intern@GOTPCREL(%rip), %r14
   call     isInternEXY_F@plt
   mov      %r12, %rdx
   jnz      .35
   mov      $36, %al
   call     envPutB@plt
   jmp      .39
.35:
   call     symByteCX_FACX@plt
   cmp      $36, %al
   jz       htFmtE_40
   cmp      $43, %al
   jz       htFmtE_40
   cmp      $45, %al
   jnz      .37
htFmtE_40:
   call     putHexB@plt
   jmp      .39
.37:
   call     envPutB@plt
.39:
   call     symByteCX_FACX@plt
   jz       .40
   cld
   mov      HtEsc@GOTPCREL(%rip), %rdi
   mov      $12, %rcx
   repnz scasb
   jnz      .41
   call     putHexB@plt
   jmp      .39
.41:
   mov      %rax, %rbx
   call     envPutB@plt
   testb    $128, %bl
   jz       .39
   call     symByteCX_FACX@plt
   call     envPutB@plt
   testb    $32, %bl
   jz       .39
   call     symByteCX_FACX@plt
   call     envPutB@plt
   jmp      .39
.40:
   pop      %r14
.31:
   pop      %r13
.27:
   rep
   ret

   .balign  16
   nop
   nop
   .globl  Fmt
Fmt:
   push     %r13
   push     %r14
   push     %r15
   mov      8(%rbx), %r13
   push     %rbp
   mov      %rsp, %rbp
.45:
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   push     %rbp
   mov      %rsp, %rbp
   call     evListE_E@plt
   pop      %rbp
1:
   push     %rbx
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       .45
   lea      -8(%rbp), %r14
   mov      %rsp, %r15
   push     %rbp
   mov      %rsp, %rbp
   call     begString@plt
   mov      (%r14), %rbx
   call     htFmtE@plt
.46:
   cmp      %r15, %r14
   jz       .47
   mov      $38, %al
   call     envPutB@plt
   sub      $8, %r14
   mov      (%r14), %rbx
   call     htFmtE@plt
   jmp      .46
.47:
   call     endString_E@plt
   mov      (%rbp), %rsp
   pop      %rbp
   pop      %r15
   pop      %r14
   pop      %r13
   ret

   .balign  16
   .globl  getHexX_A
getHexX_A:
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   sub      $48, %al
   cmp      $9, %al
   jbe      .48
   and      $223, %al
   sub      $7, %al
.48:
   mov      8(%r13), %r13
   ret

   .balign  16
   .globl  getUnicodeX_FAX
getUnicodeX_FAX:
   mov      %r13, %rbx
   mov      %r12, %rdx
.49:
   mov      8(%r13), %r13
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   cmp      $48, %al
   jc       .50
   cmp      $57, %al
   ja       .50
   sub      $48, %al
   push     %rax
   mov      %rdx, %rax
   mov      $10, %r10
   mul      %r10
   pop      %rdx
   add      %rax, %rdx
   jmp      .49
.50:
   cmp      $59, %al
   jnz      .51
   mov      8(%r13), %r13
   mov      %rdx, %rax
   cmp      %r12, %rax
   jnz      Ret@plt
.51:
   mov      %rbx, %r13
   or       %r12, %r12
   ret

   .balign  16
   .globl  headCX_FX
headCX_FX:
   mov      %r13, %rbx
.52:
   inc      %rdx
   cmp      %r12b, (%rdx)
   jz       .53
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   cmp      (%rdx), %al
   jnz      .53
   mov      8(%r13), %r13
   jmp      .52
.53:
   cmovnzq  %rbx, %r13
   ret

   .balign  16
   nop
   nop
   .globl  Pack
Pack:
   push     %r13
   mov      8(%rbx), %r10
   mov      (%r10), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   push     %rbp
   mov      %rsp, %rbp
   push     %rbx
   push     %rbp
   mov      %rsp, %rbp
   mov      %rbx, %r13
   call     begString@plt
.54:
   testb    $0x0E, %r13b
   jnz      .55
   mov      (%r13), %rbx
   mov      -8(%rbx), %rax
   call     firstByteA_B@plt
   cmp      $37, %al
   jnz      .56
   mov      8(%r13), %r13
   call     getHexX_A@plt
   shl      $4, %rax
   mov      %rax, %rdx
   call     getHexX_A@plt
   or       %rdx, %rax
   call     envPutB@plt
   jmp      .54
.56:
   mov      8(%r13), %r13
   cmp      $38, %al
   jz       .58
   call     outNameE@plt
   jmp      .54
.58:
   mov      HtLt@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .60
   mov      $60, %al
   call     envPutB@plt
   jmp      .54
.60:
   mov      HtGt@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .62
   mov      $62, %al
   call     envPutB@plt
   jmp      .54
.62:
   mov      HtAmp@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .64
   mov      $38, %al
   call     envPutB@plt
   jmp      .54
.64:
   mov      HtQuot@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .66
   mov      $34, %al
   call     envPutB@plt
   jmp      .54
.66:
   mov      HtNbsp@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .68
   mov      $32, %al
   call     envPutB@plt
   jmp      .54
.68:
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   cmp      $35, %al
   jnz      Pack_40
   call     getUnicodeX_FAX@plt
   jz       Pack_40
   call     mkCharA_A@plt
   mov      %rax, %rbx
   call     outNameE@plt
   jmp      .54
Pack_40:
   mov      $38, %al
   call     envPutB@plt
   jmp      .54
.55:
   call     endString_E@plt
   mov      (%rbp), %rsp
   pop      %rbp
   pop      %r13
   ret

   .balign  16
   nop
   nop
   .globl  Read
Read:
   push     %r13
   mov      %rbx, %r13
   mov      8(%rbx), %r10
   mov      (%r10), %rbx
   call     evCntEX_FE@plt
   jle      .72
   mov      Chr@GOTPCREL(%rip), %r10
   mov      (%r10), %rax
   cmp      %r12, %rax
   jnz      .73
   call     envGet_A@plt
.73:
   cmp      %r12, %rax
   js       .72
   call     getChar_A@plt
   cmp      $128, %rax
   jc       .75
   dec      %rbx
   cmp      $2048, %rax
   jc       .75
   dec      %rbx
.75:
   sub      $1, %rbx
   js       .72
   call     mkCharA_A@plt
   call     consA_X@plt
   mov      %rax, (%r13)
   mov      Nil@GOTPCREL(%rip), %r10
   mov      %r10, 8(%r13)
   push     %rbp
   mov      %rsp, %rbp
   push     %r13
   push     %rbp
   mov      %rsp, %rbp
.78:
   cmp      %r12, %rbx
   jnz      .79
   mov      8(%rbp), %rbx
   jmp      .80
.79:
   call     envGet_A@plt
   cmp      %r12, %rax
   jns      .81
   mov      Nil@GOTPCREL(%rip), %rbx
   jmp      .80
.81:
   call     getChar_A@plt
   cmp      $128, %rax
   jc       .82
   dec      %rbx
   cmp      $2048, %rax
   jc       .82
   dec      %rbx
.82:
   sub      $1, %rbx
   jns      .84
   mov      Nil@GOTPCREL(%rip), %rbx
   jmp      .80
.84:
   call     mkCharA_A@plt
   call     consA_C@plt
   mov      %rax, (%rdx)
   mov      Nil@GOTPCREL(%rip), %r10
   mov      %r10, 8(%rdx)
   mov      %rdx, 8(%r13)
   mov      %rdx, %r13
   jmp      .78
.80:
   mov      Chr@GOTPCREL(%rip), %r11
   mov      %r12, (%r11)
   mov      (%rbp), %rsp
   pop      %rbp
   pop      %r13
   ret
.72:
   mov      Nil@GOTPCREL(%rip), %rbx
   pop      %r13
   ret

   .data

   .balign  16
   .globl  Chunk
Chunk:
   .quad    0
   .quad    0
   .quad    0
   .space   4000
Newlines:
   .asciz   "0\r\n\r\n"

   .text

   .balign  16
   .globl  chrHex_AF
chrHex_AF:
   mov      Chr@GOTPCREL(%rip), %r10
   mov      (%r10), %al
   cmp      $48, %al
   jc       .85
   cmp      $57, %al
   ja       .85
   sub      $48, %al
   ret
.85:
   and      $223, %al
   cmp      $65, %al
   jc       .87
   cmp      $70, %al
   ja       .87
   sub      $55, %al
   ret
.87:
   mov      %r12, %rax
   sub      $1, %rax
   ret

   .balign  16
   .globl  chunkSize
chunkSize:
   push     %r13
   mov      Chunk@GOTPCREL(%rip), %r13
   mov      Chr@GOTPCREL(%rip), %r10
   cmp      %r12, (%r10)
   jnz      .89
   mov      8(%r13), %rax
   call     *%rax
.89:
   call     chrHex_AF@plt
   mov      %rax, (%r13)
   jc       chunkSize_90
.91:
   mov      8(%r13), %rax
   call     *%rax
   call     chrHex_AF@plt
   jc       .93
   mov      (%r13), %rdx
   shl      $4, %rdx
   or       %rax, %rdx
   mov      %rdx, (%r13)
   jmp      .91
.93:
   mov      Chr@GOTPCREL(%rip), %r11
   cmpq     $10, (%r11)
   jz       .94
   mov      Chr@GOTPCREL(%rip), %r10
   cmp      %r12, (%r10)
   js       chunkSize_90
   mov      8(%r13), %rax
   call     *%rax
   jmp      .93
.94:
   mov      8(%r13), %rax
   call     *%rax
   cmp      %r12, (%r13)
   jnz      chunkSize_90
   mov      8(%r13), %rax
   call     *%rax
   mov      Chr@GOTPCREL(%rip), %r11
   mov      %r12, (%r11)
chunkSize_90:
   pop      %r13
   ret

   .balign  16
   .globl  getChunked_A
getChunked_A:
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   cmp      %r12, (%r14)
   jg       .96
   mov      $-1, %rax
   mov      Chr@GOTPCREL(%rip), %r11
   mov      %rax, (%r11)
   jmp      .97
.96:
   mov      8(%r14), %rax
   call     *%rax
   decq     (%r14)
   jnz      .97
   mov      8(%r14), %rax
   call     *%rax
   mov      8(%r14), %rax
   call     *%rax
   call     chunkSize@plt
.97:
   pop      %r14
   ret

   .balign  16
   nop
   nop
   .globl  In
In:
   push     %r13
   mov      8(%rbx), %r13
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   mov      8(%r13), %r13
   cmp      Nil@GOTPCREL(%rip), %rbx
   jnz      .99
1:
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      2f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      2f
   call     evListE_E@plt
2:
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       1b
   jmp      .100
.99:
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   mov      Get_A@GOTPCREL(%rip), %r10
   mov      (%r10), %r10
   mov      %r10, 8(%r14)
   mov      Get_A@GOTPCREL(%rip), %r11
   mov      getChunked_A@GOTPCREL(%rip), %r10
   mov      %r10, (%r11)
   call     chunkSize@plt
1:
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      2f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      2f
   call     evListE_E@plt
2:
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       1b
   mov      Get_A@GOTPCREL(%rip), %r11
   mov      8(%r14), %r10
   mov      %r10, (%r11)
   mov      Chr@GOTPCREL(%rip), %r11
   mov      %r12, (%r11)
   pop      %r14
.100:
   pop      %r13
   ret

   .balign  16
   .globl  outHexA
outHexA:
   cmp      $15, %rax
   jbe      .101
   push     %rax
   shr      $4, %rax
   call     outHexA@plt
   pop      %rax
   and      $15, %al
.101:
   cmp      $9, %al
   jbe      .102
   add      $39, %al
.102:
   add      $48, %al
   jmp      envPutB@plt

   .balign  16
   .globl  wrChunkY
wrChunkY:
   mov      PutB@GOTPCREL(%rip), %r11
   mov      16(%r14), %r10
   mov      %r10, (%r11)
   mov      (%r14), %rax
   call     outHexA@plt
   mov      $13, %al
   call     envPutB@plt
   mov      $10, %al
   call     envPutB@plt
   lea      24(%r14), %r13
.103:
   mov      (%r13), %al
   call     envPutB@plt
   inc      %r13
   decq     (%r14)
   jnz      .103
   mov      $13, %al
   call     envPutB@plt
   mov      $10, %al
   call     envPutB@plt
   mov      PutB@GOTPCREL(%rip), %r10
   mov      (%r10), %r10
   mov      %r10, 16(%r14)
   mov      PutB@GOTPCREL(%rip), %r11
   mov      putChunkedB@GOTPCREL(%rip), %r10
   mov      %r10, (%r11)
   ret

   .balign  16
   .globl  putChunkedB
putChunkedB:
   push     %r13
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   lea      24(%r14), %r13
   add      (%r14), %r13
   mov      %al, (%r13)
   incq     (%r14)
   cmpq     $4000, (%r14)
   jnz      .104
   call     wrChunkY@plt
.104:
   pop      %r14
   pop      %r13
   ret

   .balign  16
   nop
   nop
   .globl  Out
Out:
   push     %r13
   mov      8(%rbx), %r13
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   mov      8(%r13), %r13
   cmp      Nil@GOTPCREL(%rip), %rbx
   jnz      .105
1:
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      2f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      2f
   call     evListE_E@plt
2:
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       1b
   jmp      .106
.105:
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   mov      %r12, (%r14)
   mov      PutB@GOTPCREL(%rip), %r10
   mov      (%r10), %r10
   mov      %r10, 16(%r14)
   mov      PutB@GOTPCREL(%rip), %r11
   mov      putChunkedB@GOTPCREL(%rip), %r10
   mov      %r10, (%r11)
1:
   mov      (%r13), %rbx
   test     $0x06, %bl
   jnz      2f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      2f
   call     evListE_E@plt
2:
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       1b
   cmp      %r12, (%r14)
   jz       .107
   call     wrChunkY@plt
.107:
   mov      PutB@GOTPCREL(%rip), %r11
   mov      16(%r14), %r10
   mov      %r10, (%r11)
   mov      Newlines@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   pop      %r14
.106:
   mov      OutFile@GOTPCREL(%rip), %r10
   mov      (%r10), %rax
   call     flushA_F@plt
   pop      %r13
   ret
