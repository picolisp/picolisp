/* 14sep09 */

   .data

   .global  HtOK
HtOK:
   .balign  8
   .string  "<b>"
   .balign  8
   .string  "</b>"
   .balign  8
   .string  "<i>"
   .balign  8
   .string  "</i>"
   .balign  8
   .string  "<u>"
   .balign  8
   .string  "</u>"
   .balign  8
   .string  "<p>"
   .balign  8
   .string  "</p>"
   .balign  8
   .string  "<pre>"
   .balign  8
   .string  "</pre>"
   .balign  8
   .string  "<div "
   .balign  8
   .string  "</div>"
   .balign  8
   .string  "<font "
   .balign  8
   .string  "</font>"
   .balign  8
   .string  "<img "
   .balign  8
   .string  "</img>"
   .balign  8
   .string  "<br>"
   .balign  8
   .string  "<hr>"
HtOkEnd:
HtLt:
   .string  "&lt;"
HtGt:
   .string  "&gt;"
HtAmp:
   .string  "&amp;"
HtQuot:
   .string  "&quot;"
HtNbsp:
   .string  "&nbsp;"
HtEsc:
   .ascii   " \"#%&:;<=>?_"

   .text

   .balign  16
   .global  findHtOkY_FE
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
   add      $1, %r13
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
   add      $1, %r14
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
   .global  Prin
Prin:
   push     %r13
   push     %r14
   push     %r15
   mov      8(%rbx), %r13
.5:
   testb    $0x0E, %r13b
   jnz      .6
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
   jz       .7
Prin_20:
   call     prinE@plt
   jmp      .8
.7:
   call     bufStringE_SZ@plt
   mov      %rsp, %r14
.9:
   cmp      %r12b, (%r14)
   jz       .10
   call     findHtOkY_FE@plt
   jnz      .11
.12:
   mov      (%r14), %al
   call     envPutB@plt
   add      $1, %r14
   cmp      %rbx, %r14
   jnz      .12
   jmp      .9
.11:
   mov      (%r14), %al
   cmp      $60, %al
   jnz      .14
   mov      HtLt@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .15
.14:
   cmp      $62, %al
   jnz      .16
   mov      HtGt@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .15
.16:
   cmp      $38, %al
   jnz      .18
   mov      HtAmp@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .15
.18:
   cmp      $34, %al
   jnz      .20
   mov      HtQuot@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   jmp      .15
.20:
   cmp      $255, %al
   jnz      .22
   mov      $239, %al
   call     envPutB@plt
   mov      $191, %al
   call     envPutB@plt
   mov      $191, %al
   call     envPutB@plt
   jmp      .15
.22:
   mov      %rax, %rdx
   call     envPutB@plt
   testb    $128, %dl
   jz       .15
   add      $1, %r14
   mov      (%r14), %al
   call     envPutB@plt
   testb    $32, %dl
   jz       .15
   add      $1, %r14
   mov      (%r14), %al
   call     envPutB@plt
.15:
   add      $1, %r14
   jmp      .9
.10:
   mov      %r15, %rsp
.8:
   mov      8(%r13), %r13
   jmp      .5
.6:
   mov      TSym@GOTPCREL(%rip), %rbx
   pop      %r15
   pop      %r14
   pop      %r13
   ret

   .balign  16
   .global  putHexB
putHexB:
   mov      %rax, %rbx
   mov      $37, %al
   call     envPutB@plt
   mov      %rbx, %rax
   shr      $4, %al
   and      $15, %al
   cmp      $9, %al
   jbe      .26
   add      $7, %al
.26:
   add      $48, %al
   call     envPutB@plt
   mov      %rbx, %rax
   and      $15, %al
   cmp      $9, %al
   jbe      .27
   add      $7, %al
.27:
   add      $48, %al
   jmp      envPutB@plt

   .balign  16
   .global  htFmtE
htFmtE:
   cmp      Nil@GOTPCREL(%rip), %rbx
   jz       .28
   testb    $0x06, %bl
   jz       .29
   mov      $43, %al
   call     envPutB@plt
   jmp      prinE@plt
.29:
   push     %r13
   testb    $0x0E, %bl
   jnz      .30
   mov      %rbx, %r13
.31:
   mov      $95, %al
   call     envPutB@plt
   mov      (%r13), %rbx
   call     htFmtE@plt
   mov      8(%r13), %r13
   testb    $0x0E, %r13b
   jz       .31
   jmp      .32
.30:
   mov      -8(%rbx), %r13
   call     nameX_X@plt
   cmp      $2, %r13
   jz       .32
   testb    $0x08, -8(%rbx)
   jz       .34
   mov      $45, %al
   call     envPutB@plt
   call     prExtNmX@plt
   jmp      .32
.34:
   push     %r14
   mov      Intern@GOTPCREL(%rip), %r14
   call     isInternEXY_F@plt
   mov      %r12, %rdx
   jnz      .36
   mov      $36, %al
   call     envPutB@plt
   jmp      .40
.36:
   call     symByteCX_FACX@plt
   cmp      $36, %al
   jz       htFmtE_40
   cmp      $43, %al
   jz       htFmtE_40
   cmp      $45, %al
   jnz      .38
htFmtE_40:
   call     putHexB@plt
   jmp      .40
.38:
   call     envPutB@plt
.40:
   call     symByteCX_FACX@plt
   jz       .41
   cld
   mov      HtEsc@GOTPCREL(%rip), %rdi
   mov      $12, %rcx
   repnz scasb
   jnz      .42
   call     putHexB@plt
   jmp      .40
.42:
   mov      %rax, %rbx
   call     envPutB@plt
   testb    $128, %bl
   jz       .40
   call     symByteCX_FACX@plt
   call     envPutB@plt
   testb    $32, %bl
   jz       .40
   call     symByteCX_FACX@plt
   call     envPutB@plt
   jmp      .40
.41:
   pop      %r14
.32:
   pop      %r13
.28:
   rep
   ret

   .balign  16
   nop
   nop
   .global  Fmt
Fmt:
   push     %r13
   push     %r14
   push     %r15
   mov      8(%rbx), %r13
   push     %rbp
   mov      %rsp, %rbp
.46:
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
   jz       .46
   lea      -8(%rbp), %r14
   mov      %rsp, %r15
   push     %rbp
   mov      %rsp, %rbp
   call     begString@plt
   mov      (%r14), %rbx
   call     htFmtE@plt
.47:
   cmp      %r15, %r14
   jz       .48
   mov      $38, %al
   call     envPutB@plt
   sub      $8, %r14
   mov      (%r14), %rbx
   call     htFmtE@plt
   jmp      .47
.48:
   call     endString_E@plt
   mov      (%rbp), %rsp
   pop      %rbp
   pop      %r15
   pop      %r14
   pop      %r13
   ret

   .balign  16
   .global  getHexX_A
getHexX_A:
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   sub      $48, %al
   cmp      $9, %al
   jbe      .49
   and      $223, %al
   sub      $7, %al
.49:
   mov      8(%r13), %r13
   ret

   .balign  16
   .global  getUnicodeX_FAX
getUnicodeX_FAX:
   mov      %r13, %rbx
   mov      %r12, %rdx
.50:
   mov      8(%r13), %r13
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   cmp      $48, %al
   jc       .51
   cmp      $57, %al
   ja       .51
   sub      $48, %al
   push     %rax
   mov      %rdx, %rax
   mov      $10, %r10
   mul      %r10
   pop      %rdx
   add      %rax, %rdx
   jmp      .50
.51:
   cmp      $59, %al
   jnz      .52
   mov      8(%r13), %r13
   mov      %rdx, %rax
   cmp      %r12, %rax
   jnz      Ret@plt
.52:
   mov      %rbx, %r13
   or       %r12, %r12
   ret

   .balign  16
   .global  headCX_FX
headCX_FX:
   mov      %r13, %rbx
.53:
   add      $1, %rdx
   cmp      %r12b, (%rdx)
   jz       .54
   mov      (%r13), %r10
   mov      -8(%r10), %rax
   call     firstByteA_B@plt
   cmp      (%rdx), %al
   jnz      .54
   mov      8(%r13), %r13
   jmp      .53
.54:
   cmovnzq  %rbx, %r13
   ret

   .balign  16
   nop
   nop
   .global  Pack
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
.55:
   testb    $0x0E, %r13b
   jnz      .56
   mov      (%r13), %rbx
   mov      -8(%rbx), %rax
   call     firstByteA_B@plt
   cmp      $37, %al
   jnz      .57
   mov      8(%r13), %r13
   call     getHexX_A@plt
   shl      $4, %rax
   mov      %rax, %rdx
   call     getHexX_A@plt
   or       %rdx, %rax
   call     envPutB@plt
   jmp      .55
.57:
   mov      8(%r13), %r13
   cmp      $38, %al
   jz       .59
   call     outNameE@plt
   jmp      .55
.59:
   mov      HtLt@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .61
   mov      $60, %al
   call     envPutB@plt
   jmp      .55
.61:
   mov      HtGt@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .63
   mov      $62, %al
   call     envPutB@plt
   jmp      .55
.63:
   mov      HtAmp@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .65
   mov      $38, %al
   call     envPutB@plt
   jmp      .55
.65:
   mov      HtQuot@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .67
   mov      $34, %al
   call     envPutB@plt
   jmp      .55
.67:
   mov      HtNbsp@GOTPCREL(%rip), %rdx
   call     headCX_FX@plt
   jnz      .69
   mov      $32, %al
   call     envPutB@plt
   jmp      .55
.69:
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
   jmp      .55
Pack_40:
   mov      $38, %al
   call     envPutB@plt
   jmp      .55
.56:
   call     endString_E@plt
   mov      (%rbp), %rsp
   pop      %rbp
   pop      %r13
   ret

   .balign  16
   nop
   nop
   .global  Read
Read:
   push     %r13
   mov      %rbx, %r13
   mov      8(%rbx), %r10
   mov      (%r10), %rbx
   call     evCntEX_FE@plt
   jle      .73
   mov      Chr@GOTPCREL(%rip), %rax
   mov      (%rax), %rax
   cmp      %r12, %rax
   jnz      .74
   call     envGet_A@plt
.74:
   cmp      %r12, %rax
   js       .73
   call     getChar_A@plt
   cmp      $128, %rax
   jc       .76
   sub      $1, %rbx
   cmp      $2048, %rax
   jc       .76
   sub      $1, %rbx
.76:
   sub      $1, %rbx
   js       .73
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
.79:
   cmp      %r12, %rbx
   jnz      .80
   mov      8(%rbp), %rbx
   jmp      .81
.80:
   call     envGet_A@plt
   cmp      %r12, %rax
   jns      .82
   mov      Nil@GOTPCREL(%rip), %rbx
   jmp      .81
.82:
   call     getChar_A@plt
   cmp      $128, %rax
   jc       .83
   sub      $1, %rbx
   cmp      $2048, %rax
   jc       .83
   sub      $1, %rbx
.83:
   sub      $1, %rbx
   jns      .85
   mov      Nil@GOTPCREL(%rip), %rbx
   jmp      .81
.85:
   call     mkCharA_A@plt
   call     consA_C@plt
   mov      %rax, (%rdx)
   mov      Nil@GOTPCREL(%rip), %r10
   mov      %r10, 8(%rdx)
   mov      %rdx, 8(%r13)
   mov      %rdx, %r13
   jmp      .79
.81:
   mov      Chr@GOTPCREL(%rip), %rax
   mov      %r12, (%rax)
   mov      (%rbp), %rsp
   pop      %rbp
   pop      %r13
   ret
.73:
   mov      Nil@GOTPCREL(%rip), %rbx
   pop      %r13
   ret

   .data

   .balign  16
   .global  Chunk
Chunk:
   .quad    0
   .quad    0
   .quad    0
   .skip    4000
Newlines:
   .string  "0\r\n\r\n"

   .text

   .balign  16
   .global  chrHexX_AF
chrHexX_AF:
   mov      (%r13), %al
   cmp      $48, %al
   jc       .86
   cmp      $57, %al
   ja       .86
   sub      $48, %al
   ret
.86:
   and      $223, %al
   cmp      $65, %al
   jc       .88
   cmp      $70, %al
   ja       .88
   sub      $55, %al
   ret
.88:
   mov      %r12, %rax
   sub      $1, %rax
   ret

   .balign  16
   .global  chunkSize
chunkSize:
   push     %r13
   push     %r14
   mov      Chr@GOTPCREL(%rip), %r13
   mov      Chunk@GOTPCREL(%rip), %r14
   cmp      %r12, (%r13)
   jnz      .90
   mov      8(%r14), %rax
   call     *%rax
.90:
   call     chrHexX_AF@plt
   mov      %rax, (%r14)
   jc       chunkSize_90
.92:
   mov      8(%r14), %rax
   call     *%rax
   call     chrHexX_AF@plt
   jc       .94
   mov      (%r14), %rdx
   shl      $4, %rdx
   or       %rax, %rdx
   mov      %rdx, (%r14)
   jmp      .92
.94:
   cmpq     $10, (%r13)
   jz       .95
   cmp      %r12, (%r13)
   js       chunkSize_90
   mov      8(%r14), %rax
   call     *%rax
   jmp      .94
.95:
   mov      8(%r14), %rax
   call     *%rax
   cmp      %r12, (%r14)
   jnz      chunkSize_90
   mov      8(%r14), %rax
   call     *%rax
   mov      %r12, (%r13)
chunkSize_90:
   pop      %r14
   pop      %r13
   ret

   .balign  16
   .global  getChunked_A
getChunked_A:
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   cmp      %r12, (%r14)
   jg       .97
   mov      $-1, %rax
   mov      Chr@GOTPCREL(%rip), %r14
   mov      %rax, (%r14)
   jmp      .98
.97:
   mov      8(%r14), %rax
   call     *%rax
   subq     $1, (%r14)
   jnz      .98
   mov      8(%r14), %rax
   call     *%rax
   mov      8(%r14), %rax
   call     *%rax
   call     chunkSize@plt
.98:
   pop      %r14
   ret

   .balign  16
   nop
   nop
   .global  In
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
   jnz      .100
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
   jmp      .101
.100:
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   mov      EnvGet_A@GOTPCREL(%rip), %rax
   mov      (%rax), %r10
   mov      %r10, 8(%r14)
   mov      getChunked_A@GOTPCREL(%rip), %r10
   mov      %r10, (%rax)
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
   mov      EnvGet_A@GOTPCREL(%rip), %rax
   mov      8(%r14), %r10
   mov      %r10, (%rax)
   mov      Chr@GOTPCREL(%rip), %rax
   mov      %r12, (%rax)
   pop      %r14
.101:
   pop      %r13
   ret

   .balign  16
   .global  outHexA
outHexA:
   cmp      $15, %rax
   jbe      .102
   push     %rax
   shr      $4, %rax
   call     outHexA@plt
   pop      %rax
   and      $15, %al
.102:
   cmp      $9, %al
   jbe      .103
   add      $39, %al
.103:
   add      $48, %al
   jmp      envPutB@plt

   .balign  16
   .global  wrChunkY
wrChunkY:
   mov      EnvPutB@GOTPCREL(%rip), %r13
   mov      16(%r14), %r10
   mov      %r10, (%r13)
   mov      (%r14), %rax
   call     outHexA@plt
   mov      $13, %al
   call     envPutB@plt
   mov      $10, %al
   call     envPutB@plt
   lea      24(%r14), %r13
.104:
   mov      (%r13), %al
   call     envPutB@plt
   add      $1, %r13
   subq     $1, (%r14)
   jnz      .104
   mov      $13, %al
   call     envPutB@plt
   mov      $10, %al
   call     envPutB@plt
   mov      EnvPutB@GOTPCREL(%rip), %r13
   mov      (%r13), %r10
   mov      %r10, 16(%r14)
   mov      putChunkedB@GOTPCREL(%rip), %r10
   mov      %r10, (%r13)
   ret

   .balign  16
   .global  putChunkedB
putChunkedB:
   push     %r13
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   lea      24(%r14), %r13
   add      (%r14), %r13
   mov      %al, (%r13)
   addq     $1, (%r14)
   cmpq     $4000, (%r14)
   jnz      .105
   call     wrChunkY@plt
.105:
   pop      %r14
   pop      %r13
   ret

   .balign  16
   nop
   nop
   .global  Out
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
   jnz      .106
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
   jmp      .107
.106:
   push     %r14
   mov      Chunk@GOTPCREL(%rip), %r14
   mov      %r12, (%r14)
   mov      EnvPutB@GOTPCREL(%rip), %rax
   mov      (%rax), %r10
   mov      %r10, 16(%r14)
   mov      putChunkedB@GOTPCREL(%rip), %r10
   mov      %r10, (%rax)
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
   jz       .108
   call     wrChunkY@plt
.108:
   mov      EnvPutB@GOTPCREL(%rip), %rax
   mov      16(%r14), %r10
   mov      %r10, (%rax)
   mov      Newlines@GOTPCREL(%rip), %rdx
   call     outStringC@plt
   pop      %r14
.107:
   mov      OutFile@GOTPCREL(%rip), %rax
   mov      (%rax), %rax
   call     flushA_F@plt
   pop      %r13
   ret
