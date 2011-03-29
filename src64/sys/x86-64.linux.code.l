# 19may10abu
# (c) Software Lab. Alexander Burger

# System macros
(code 'errno_A 0)
   call __errno_location  # Get address of 'errno'
   ld A (A)  # Load value
   ret

(code 'errnoC 0)
   call __errno_location  # Get address of 'errno'
   ld (A) C  # Store new value
   ret

(code 's_isdirS_F 0)  # S_ISDIR
   ld4 (S `(+ I ST_MODE))  # Get 'st_mode' from 'stat'
   and A `S_IFMT
   cmp A `S_IFDIR
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
