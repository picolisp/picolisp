# 15sep04abu
# (c) Software Lab. Alexander Burger

# src/main.c
(test (date) (date NIL))
(test 730622 (date 2000 7 15))
(test 730622 (date (2000 7 15)))
(test (2000 7 15) (date 730622))

# src/flow.c
(let (A 'a I 'i)
   (test '(x y z z a)
      (make (link (for A '(x y z) (link A))) (link A)) )
   (test '(1 x 2 y 3 z i a)
      (make (for (I . A) '(x y z) (link I A)) (link I A)) )
   (test '((x y z) (y z) (z) (z) a)
      (make (link (for (A '(x y z) A (cdr A)) (link A))) (link A)) )
   (test '(1 (x y z) 2 (y z) 3 (z) (z) i a)
      (make (link (for ((I . A) '(x y z) A (cdr A)) (link I A))) (link I A)) ) )

# src/big.c
(test T (- NIL))
(test NIL (- NIL 7))
(test NIL (- T))
(test -7 (- 7))
(test 7 (- -7))

# src/subr.c
(let (@X 1234  @Y (1 2 3 4))
   (test '(a b (c 1234) (((1 2 3 4) . d) e))
      (fill '(a b (c @X) ((@Y . d) e))) ) )

# src/io.c
(call "rm" "-f" "db/test")
(test T (pool "db/test"))
(test NIL (mark *DB))
(test T (mark *DB T))
(test T (mark *DB))
(test NIL (mark *DB 0))
(test NIL (mark *DB))

# lib.l
(test '((1 a b c) (2 d e f))
   (group '((1 . a) (1 . b) (1 . c) (2 . d) (2 . e) (2 . f))) )
