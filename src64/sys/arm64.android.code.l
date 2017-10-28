# 27may16abu
# (c) Software Lab. Alexander Burger

# System macros
(code 'errno_A 0)
   call __errno  # Get address of 'errno'
   ld4 (A)  # Load value
   ret

(code 'errnoC 0)
   call __errno  # Get address of 'errno'
   xchg A C
   st4 (C)  # Store new value
   ret

(code 'wifstoppedS_F 0)  # WIFSTOPPED
   ld4 (S)  # Get status
   and B `(hex "7F")  # (((status) & 0x7f) == 0x7f)
   cmp B `(hex "7F")
   ret

(code 'wifsignaledS_F 0)  # WIFSIGNALED
   ld4 (S)  # Get status
   and B `(hex "7F")  # (((status) & 0x7f) + 1) >> 1) > 0)
   inc B
   shr B 1
   ret

(code 'wtermsigS_A 0)  # WTERMSIG
   ld4 (S)  # Get status
   and B `(hex "7F")  # ((status) & 0x7f)
   zxt
   ret

# vi:et:ts=3:sw=3
