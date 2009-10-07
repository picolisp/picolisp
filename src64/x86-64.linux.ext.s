/* 29aug09 */

   .data

   .global  SnxTab
SnxTab:
   .byte    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 0, 0, 0, 0, 0, 0, 0, 0, 70, 83, 84, 0, 70, 83, 0, 0, 83, 83, 76, 78, 78, 0, 70, 83, 82, 83, 84, 0, 70, 70, 83, 0, 83, 0, 0, 0, 0, 0, 0, 0, 70, 83, 84, 0, 70, 83, 0, 0, 83, 83, 76, 78, 78, 0, 70, 83, 82, 83, 84, 0, 70, 70, 83, 0, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83, 0, 0, 0, 0, 0, 0, 0, 0, 84, 78, 0, 0, 0, 0, 0, 83, 0, 0, 0, 0, 0, 0, 0, 83, 0, 0, 0, 0, 0, 0, 0, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 78

   .text

   .balign  16
   nop
   nop
   .global  Snx
Snx:
   push     %r13
   push     %r14
   mov      %rbx, %r13
   mov      8(%rbx), %r14
   call     evSymY_E@plt
   cmp      Nil@GOTPCREL(%rip), %rbx
   jz       .1
   mov      -8(%rbx), %rbx
   call     nameE_E@plt
   push     %rbp
   mov      %rsp, %rbp
   push     %rbx
   push     %rbp
   mov      %rsp, %rbp
   mov      8(%r14), %r14
   testb    $0x0E, %r14b
   mov      $24, %r10
   cmovnzq  %r10, %rbx
   jnz      .2
   call     evCntXY_FE@plt
.2:
   mov      (%rsp), %rbp
   movq     $2, (%rsp)
   mov      %rsp, %r13
   push     %rbp
   mov      %rsp, %rbp
   pushq    $4
   push     %r13
   mov      16(%rbp), %r13
   mov      %r12, %rdx
.3:
   call     symCharCX_FACX@plt
   jz       Snx_90
   cmp      $48, %rax
   jc       .3
   cmp      $97, %rax
   jc       .4
   cmp      $122, %rax
   jbe      Snx_40
.4:
   cmp      $128, %rax
   jz       Snx_40
   cmp      $224, %rax
   jc       .5
   cmp      $255, %rax
   ja       .5
Snx_40:
   andb     $~32, %al
.5:
   push     %rax
   xchg     16(%rsp), %rdx
   xchg     8(%rsp), %r13
   call     charSymACX_CX@plt
   xchg     8(%rsp), %r13
   xchg     16(%rsp), %rdx
.7:
   call     symCharCX_FACX@plt
   jz       Snx_90
   cmp      $32, %rax
   jbe      .7
   sub      $48, %rax
   jc       Snx_60
   cmp      $194, %rax
   jnc      Snx_60
   mov      SnxTab@GOTPCREL(%rip), %r14
   add      %rax, %r14
   mov      (%r14), %al
   movzx    %al, %rax
   or       %rax, %rax
   jnz      .10
Snx_60:
   mov      %r12, (%rsp)
   jmp      .7
.10:
   cmp      (%rsp), %rax
   jz       .7
   sub      $1, %rbx
   jz       Snx_90
   mov      %rax, (%rsp)
   xchg     16(%rsp), %rdx
   xchg     8(%rsp), %r13
   call     charSymACX_CX@plt
   xchg     8(%rsp), %r13
   xchg     16(%rsp), %rdx
   jmp      .7
Snx_90:
   mov      8(%rbp), %r13
   call     consSymX_E@plt
   mov      (%rbp), %rsp
   pop      %rbp
.1:
   pop      %r14
   pop      %r13
   ret

   .balign  16
   nop
   nop
   .global  Ulaw
Ulaw:
   push     %r13
   mov      %rbx, %r13
   mov      8(%rbx), %r10
   mov      (%r10), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   testb    $0x02, %bl
   jz       cntErrEX@plt
   mov      %r12, %r13
   shr      $4, %rbx
   jnc      .13
   mov      $128, %r13
.13:
   cmp      $32636, %rbx
   mov      $32635, %r10
   cmovncq  %r10, %rbx
   add      $132, %rbx
   mov      %rbx, %rax
   add      %rax, %rax
   mov      $7, %rdx
.14:
   test     $32768, %rax
   jnz      .15
   add      %rax, %rax
   sub      $1, %rdx
   jnz      .14
.15:
   mov      %rdx, %rax
   add      $3, %rax
   mov      %al, %cl
   shr      %cl, %rbx
   and      $15, %rbx
   shl      $4, %rdx
   or       %rdx, %rbx
   or       %r13, %rbx
   not      %rbx
   and      $255, %rbx
   shl      $4, %rbx
   orb      $2, %bl
   pop      %r13
   ret

   .data

   .global  Chr64
Chr64:
   .ascii   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

   .text

   .balign  16
   nop
   nop
   .global  Base64
Base64:
   push     %r13
   push     %r14
   push     %r15
   mov      %rbx, %r13
   mov      8(%rbx), %r14
   mov      (%r14), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   cmp      Nil@GOTPCREL(%rip), %rbx
   jz       .16
   shr      $4, %rbx
   mov      %rbx, %r15
   shr      $2, %rbx
   call     chr64E@plt
   mov      8(%r14), %r14
   mov      (%r14), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   cmp      Nil@GOTPCREL(%rip), %rbx
   jnz      .17
   mov      %r15, %rbx
   and      $3, %rbx
   shl      $4, %rbx
   call     chr64E@plt
   mov      $61, %al
   call     envPutB@plt
   mov      $61, %al
   call     envPutB@plt
   mov      Nil@GOTPCREL(%rip), %rbx
   jmp      .16
.17:
   shr      $4, %rbx
   and      $3, %r15
   shl      $4, %r15
   mov      %rbx, %rax
   shr      $4, %rax
   or       %r15, %rax
   mov      %rbx, %r15
   call     chr64A@plt
   mov      8(%r14), %r14
   mov      (%r14), %rbx
   test     $0x06, %bl
   jnz      1f
   test     $0x08, %bl
   cmovnzq  (%rbx), %rbx
   jnz      1f
   call     evListE_E@plt
1:
   cmp      Nil@GOTPCREL(%rip), %rbx
   jnz      .19
   mov      %r15, %rax
   and      $15, %rax
   shl      $2, %rax
   call     chr64A@plt
   mov      $61, %al
   call     envPutB@plt
   mov      Nil@GOTPCREL(%rip), %rbx
   jmp      .16
.19:
   shr      $4, %rbx
   mov      %rbx, %rax
   shr      $6, %rax
   and      $15, %r15
   shl      $2, %r15
   or       %r15, %rax
   call     chr64A@plt
   and      $63, %rbx
   call     chr64E@plt
   mov      TSym@GOTPCREL(%rip), %rbx
.16:
   pop      %r15
   pop      %r14
   pop      %r13
   ret

   .global  chr64E
chr64E:
   mov      %rbx, %rax

   .global  chr64A
chr64A:
   add      Chr64@GOTPCREL(%rip), %rax
   mov      (%rax), %al
   jmp      envPutB@plt
