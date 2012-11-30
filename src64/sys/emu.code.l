# 13oct12abu
# (c) Software Lab. Alexander Burger

# System macros
(push '*SysFun
   "void errno_A(void) {A.n = (uint64_t)errno;}" )

(code 'errno_A 0)
   cc errno_A()  # Get 'errno' into A
   ret


(push '*SysFun
   "void errnoC(void) {errno = (int)C.n;}" )

(code 'errnoC 0)
   cc errnoC()  # Store 'errno'
   ret


(push '*SysFun
   '"void wifstoppedS_F(void) {Result = !WIFSTOPPED(*(int*)(S.p + 8));}" )

(code 'wifstoppedS_F 0)  # WIFSTOPPED
   cc wifstoppedS_F()
   ret


(push '*SysFun
   '"void wifsignaledS_F(void) {Result = WIFSIGNALED(*(int*)(S.p + 8));}" )

(code 'wifsignaledS_F 0)  # WIFSIGNALED
   cc wifsignaledS_F()
   ret


(push '*SysFun
   '"int wtermsigS_A(void) {return WTERMSIG(*(int*)(S.p + 8));}" )

(code 'wtermsigS_A 0)  # WTERMSIG
   cc wtermsigS_A()
   ret

# vi:et:ts=3:sw=3
