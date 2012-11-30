# 30sep12abu
# (c) Software Lab. Alexander Burger

# System macros
(code 'errno_A 0)
   call __errno_location  # Get address of 'errno'
   ld4 (A)  # Load value
   ret

(code 'errnoC 0)
   call __errno_location  # Get address of 'errno'
   xchg A C
   st4 (C)  # Store new value
   ret

(code 'wifstoppedS_F 0)  # WIFSTOPPED
   ld A (S I)  # Get status
   cmp B `(hex "7F")  # (((status) & 0xff) == 0x7f)
   ret

(code 'wifsignaledS_F 0)  # WIFSIGNALED
   ld A (S I)  # Get status
   and B `(hex "7F")  # (((status) & 0x7f) + 1) >> 1) > 0)
   inc B
   shr B 1
   ret

(code 'wtermsigS_A 0)  # WTERMSIG
   ld A (S I)  # Get status
   and B `(hex "7F")  # ((status) & 0x7f)
   zxt
   ret

# vi:et:ts=3:sw=3
