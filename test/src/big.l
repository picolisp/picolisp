# 28may08abu
# (c) Software Lab. Alexander Burger

### format ###
(test "123456789" (format 123456789))
(test "12346" (format 12345.6789))
(test "1234567.89" (format 123456789 2))
(test "1234567,89" (format 123456789 2 ","))
(test "1.234.567,89" (format 123456789 2 "," "."))
(test 123456789 (format "123456789"))
(test 12345678900 (format "1234567.89" 4))
(test NIL (format "1.234.567,89"))
(test 12345678900 (format "1234567,89" 4 ","))
(test NIL (format "1.234.567,89" 4 ","))
(test 12345678900 (format "1.234.567,89" 4 "," "."))


### + ###
(test 6 (+ 1 2 3))
(test 0 (+ 1 2 -3))
(test NIL (+ NIL 7))


### - ###
(test -7 (- 7))
(test 7 (- -7))
(test 6 (- 7 2 -1))
(test NIL (- NIL 7))


### inc ###
(test 8 (inc 7))
(test -6 (inc -7))
(test 0 (inc -1))
(test 1 (inc 0))
(test (8 -6 0 1) (let L (7 -7 -1 0) (map inc L) L))
(test NIL (inc NIL))
(let N 0
   (test 1 (inc 'N))
   (test 1 N)
   (test 8 (inc 'N 7))
   (test 8 N) )
(let L (1 2 3 4)
   (test 3 (inc (cdr L)))
   (test (1 3 3 4) L) )


### dec ###
(test 7 (dec 8))
(test -8 (dec -7))
(test -1 (dec 0))
(test (7 -8 -1) (let L (8 -7 0) (map dec L) L))
(test NIL (dec NIL))
(let N 7
   (test 6 (dec 'N))
   (test 6 N)
   (test 3 (dec 'N 3))
   (test 3 N) )


### * ###
(test 6 (* 1 2 3))
(test -60 (* -5 3 2 2))
(test NIL (* NIL 7))


### */ ###
(test 6 (*/ 3 4 2))
(test -247 (*/ 1234 -2 10))
(test 17 (*/ 100 6))
(test NIL (*/ 3 4 NIL))


### / ###
(test 4 (/ 12 3))
(test -5 (/ 60 -3 2 2))
(test NIL (/ 10 NIL))


### % ###
(test 2 (% 17 5))
(test -2 (% -17 5))
(test 1 (% 5 2))
(test 5 (% 15 10))
(test 1 (% 15 10 2))
(test NIL (% NIL 7))


### >> ###
(test 4 (>> 1 8))
(test 2 (>> 3 16))
(test 128 (>> -3 16))
(test -32 (>> -1 -16))


### lt0 ###
(test -2 (lt0 -2))
(test NIL (lt0 7))
(test NIL (lt0 0))


### ge0 ###
(test 7 (ge0 7))
(test NIL (ge0 -2))
(test 0 (ge0 0))


### gt0 ###
(test 7 (gt0 7))
(test NIL (gt0 -2))
(test NIL (gt0 0))


### abs ###
(test 7 (abs -7))
(test 7 (abs 7))
(test NIL (abs NIL))


### bit? ###
(test 7 (bit? 7 15 255))
(test 1 (bit? 1 3))
(test NIL (bit? 1 2))


### & ###
(test 2 (& 6 3))
(test 1 (& 7 3 1))
(test NIL (& 7 NIL))


### | ###
(test 3 (| 1 2))
(test 15 (| 1 2 4 8))
(test NIL (| NIL 1))


### x| ###
(test 5 (x| 2 7))
(test 4 (x| 2 7 1))
(test NIL (x| NIL 1))


### sqrt ###
(test 8 (sqrt 64))
(test 31 (sqrt 1000))
(test 100000000000000000000
   (sqrt 10000000000000000000000000000000000000000) )
(test NIL (sqrt NIL))


### seed rand ###
(test 2015582081 (seed "init string"))
(test -706917003 (rand))
(test 1224196082 (rand))
(test 8 (rand 3 9))
(test 5 (rand 3 9))

# vi:et:ts=3:sw=3