# 28may08abu
# (c) Software Lab. Alexander Burger

### Unit Tests ###
# $(pwd)/p dbg.l lib/test.l

(test T (pool (tmp "db")))

(load
   "test/src/main.l"
   "test/src/apply.l"
   "test/src/flow.l"
   "test/src/sym.l"
   "test/src/subr.l"
   "test/src/big.l"
   "test/src/io.l"
   "test/src/net.l" )

(load "test/lib.l")
(load "test/lib/misc.l")

(load "test/lib/lint.l")

# vi:et:ts=3:sw=3
