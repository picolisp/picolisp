# 29may02abu
# (c) Software Lab. Alexander Burger

# System
(test (date) (date NIL))
(test 730622 (date 2000 7 15))
(test 730622 (date (2000 7 15)))
(test (2000 7 15) (date 730622))

# DB
(call "rm" "-f" "db/test")
(test T (pool "db/test"))
(test NIL (mark *DB))
(test T (mark *DB T))
(test T (mark *DB))
(test NIL (mark *DB 0))
(test NIL (mark *DB))

# Subr
(let (@X 1234  @Y (1 2 3 4))
   (test '(a b (c 1234) (((1 2 3 4) . d) e))
      (fill '(a b (c @X) ((@Y . d) e))) ) )

# List
(test '((1 a b c) (2 d e f))
   (group '((1 . a) (1 . b) (1 . c) (2 . d) (2 . e) (2 . f))) )
