# 07jan13abu
# Mansur Mamkin <mmamkin@mail.ru>

# System macros
(code 'errno_A 0)
   call __error  # Get address of 'errno'
   ld A (A)  # Load value
   ret

(code 'errnoC 0)
   call __error  # Get address of 'errno'
   ld (A) C  # Store new value
   ret

#define>_WSTATUS(x)<--->(_W_INT(x) & 0177)
#define>_WSTOPPED<----->0177<--><------>/* _WSTATUS if process is stopped */
#define>WIFSTOPPED(x)<->(_WSTATUS(x) == _WSTOPPED)
#define>WIFSIGNALED(x)<>(_WSTATUS(x) != _WSTOPPED && _WSTATUS(x) != 0)
#define>WTERMSIG(x)<--->(_WSTATUS(x))

(code 'wifstoppedS_F 0)  # WIFSTOPPED
   ld A (S I)  # Get status
   and B `(oct "0177")
   cmp B `(oct "0177")  # (((status) & 0177) == 0177)
   ret

(code 'wifsignaledS_F 0)  # WIFSIGNALED
   ld A (S I)  # Get status
   and B `(oct "0177")  # ((((status) & 0177) != 0177) && ((status) & 0177) != 0)
   cmp B `(oct "0177")
   if ne
      nul B
   end
   ret

(code 'wtermsigS_A 0)  # WTERMSIG
   ld A (S I)  # Get status
   and B `(oct "0177")  # ((status) & 0177)
   zxt
   ret

# vi:et:ts=3:sw=3
