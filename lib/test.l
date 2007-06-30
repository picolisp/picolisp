# 28may07abu
# (c) Software Lab. Alexander Burger

(test T (pool (tmp "db")))


# src/main.c

(use (Tim1 Tim2 Dat1 Dat2 T1 T2 D1 D2)
   (until
      (=
         (setq Tim1 (time))
         (setq
            Tim2 (time T)
            Dat1 (date)
            Dat2 (date T)
            T1 (in '(date "+%H %M %S") (list (read) (read) (read)))
            T2 (in '(date "-u" "+%H %M %S") (list (read) (read) (read)))
            D1 (in '(date "+%Y %m %d") (list (read) (read) (read)))
            D2 (in '(date "-u" "+%Y %m %d") (list (read) (read) (read)))
            @ (time) ) ) )
   (test Tim1 (time T1))
   (test Tim1 (apply time T1))
   (test Tim2 (time T2))
   (test Dat1 (date D1))
   (test Dat1 (apply date D1))
   (test Dat2 (date D2)) )

(test (2000 7 15) (date 730622))
(test 730622 (date 2000 7 15))
(test 730622 (date (2000 7 15)))
(test NIL (date NIL))

(test (11 17 23) (time 40643))
(test 40643 (time 11 17 23))
(test 40643 (time (11 17 23)))
(test NIL (time NIL))


# src/apply.c

(test 6 (apply + (1 2 3)))
(test 360 (apply * (5 6) 3 4))
(test 27 (apply '((X Y Z) (* X (+ Y Z))) (3 4 5)))

(test 24 ((quote (N . @) (* N (pass + 6))) 2 1 2 3))

(let L '((1 . a) (2 . b) flg)
   (test L (let X (box) (putl X L) (make (maps link X)))) )

(test '((1 2 3) (2 3) (3)) (make (map link (1 2 3))))

(test (1 2 3) (make (mapc link (1 2 3))))

(test '(((1 2 3) A B C) ((2 3) B C) ((3) C)) (maplist cons (1 2 3) '(A B C)))

(test (5 7 9) (mapcar + (1 2 3) (4 5 6)))
(test (26 38 52 68) (mapcar '((X Y) (+ X (* Y Y))) (1 2 3 4) (5 6 7 8)))

(test (1 2 3 4 5 2 3 4 5 3 4 5 4 5 5) (mapcon copy (1 2 3 4 5)))

(test '(c b a f e d i h g) (mapcan reverse '((a b c) (d e f) (g h i))))

(test (1 2 3) (filter num? (1 A 2 (B) 3 CDE)))

(test (12 19 22) (seek '((X) (> (car X) 9)) (1 5 8 12 19 22)))

(test '(B) (find pair (1 A 2 (B) 3 CDE)))
(test 4 (find > (1 2 3 4 5 6) (6 5 4 3 2 1)))
(test 4 (find '((A B) (> A B)) (1 2 3 4 5 6) (6 5 4 3 2 1)))
(test "Hello"
   (pick '((X) (get X 'str))
      (list (box) (prog1 (box) (put @ 'str "Hello")) (box)) ) )

(test 2 (cnt cdr '((1 . T) (2) (3 4) (5))))

(test 6 (sum val (list (box 1) (box) (box 2) (box 'a) (box 3))))

(let (A 1 B 2 C 3)
   (test 'C (maxi val '(A B C)))
   (test 'A (mini val '(A B C)))
   (test '(A B C) (by val sort '(C A B))) )


# src/flow.c

(let (A 'a I 'i)
   (test '(x y z z a)
      (make (link (for A '(x y z) (link A))) (link A)) )
   (test (1 x 2 y 3 z i a)
      (make (for (I . A) '(x y z) (link I A)) (link I A)) )
   (test '(a b c)
      (make (yoke 'b) (link 'c) (yoke 'a)) )
   (test '((x y z) (y z) (z) (z) a)
      (make (link (for (A '(x y z) A (cdr A)) (link A))) (link A)) )
   (test (1 (x y z) 2 (y z) 3 (z) (z) i a)
      (make (link (for ((I . A) '(x y z) A (cdr A)) (link I A))) (link I A)) ) )
(test NIL (catch NIL (throw)))
(test 'b (catch 'a (throw 'a 'b)))
(test 123 (catch T (throw 'a 123)))


# src/sym.c

(test 1000000000 (fun? 1000000000))
(test NIL (fun? 100000000000000))
(test NIL (fun? 1000000001))
(test '(A B) (fun? '((A B) (* A B))))
(test NIL (fun? '((A B) (* A B) . C)))
(test NIL (fun? (1 2 3 4)))
(test NIL (fun? '((A 2 B) (* A B))))
(test T (fun? '(NIL (* 3 4))))

(test '@ (pat? '@))
(test "@Abc" (pat? "@Abc"))
(test NIL (pat? "ABC"))
(test NIL (pat? 123))

(test NIL (str? 123))
(test NIL (str? '{ABC}))
(test NIL (str? 'abc))
(test "abc" (str? "abc"))

(test '{1} (ext? *DB))
(test NIL (ext? 'abc))
(test NIL (ext? "abc"))
(test NIL (ext? 123))

(test 1 (glue NIL 1))
(test "a" (glue NIL '(a)))
(test "ab" (glue NIL '(a b)))
(test "a,b" (glue "," '(a b)))
(test "a8b" (glue 8 '(a b)))
(test "a123b123c" (glue (1 2 3) '(a b c)))

(test "abc XYZ def 123" (text "abc @1 def @2" 'XYZ 123))
(test "aXYZz" (text "a@3z" 1 2 '(X Y Z)))
(test "a@bc.de" (text "a@@bc.@1" "de"))
(test "10.11.12" (text "@A.@B.@C" 1 2 3 4 5 6 7 8 9 10 11 12))

(test NIL (get (1 2 3) 0))
(test 1 (get (1 2 3) 1))
(test 3 (get (1 2 3) 3))
(test NIL (get (1 2 3) 4))
(test (3) (get (1 2 3) -2))
(test 1 (get '((a (b . 1) (c . 2)) (d (e . 3) (f . 4))) 'a 'b))
(test 4 (get '((a (b . 1) (c . 2)) (d (e . 3) (f . 4))) 'd 'f))

(let (A (box)  B (box A)  C (box (cons A B)))
   (put B 'a A)
   (put C 'b B)
   (put A 'x 1)
   (put B 'a 'y 2)
   (put C 0 -1 'a 'z 3)
   (test 1 (get A 'x))
   (test 2 (with A (: y)))
   (test 2 (get A 'y))
   (test 2 (with B (: 0 y)))
   (test 2 (get B 0 'y))
   (test 3 (with C (: b a z)))
   (test 3 (with C (: 0 1 z)))
   (test 3 (with C (: 0 -1 a z)))
   (test 3 (get C 0 1 'z))
   (test 3 (get C 0 -1 'a 'z))
   (test (3 . z) (prop C 0 -1 'a 'z))
   (test 9 (with C (=: 0 -1 a z (* 3 3))))
   (test (9 . z) (with C (:: 0 -1 a z)))
   (test (putl C 0 -1 'a '((1 . x) (2 . y))) (getl C 'b 0)) )

(test "a" (low? "a"))
(test NIL (low? "A"))
(test NIL (low? 123))
(test NIL (low? "."))

(test "A" (upp? "A"))
(test NIL (upp? "a"))
(test NIL (upp? 123))
(test NIL (upp? "."))


# src/subr.c

(test '(a . b) (cons 'a 'b))
(test '(a b c . d) (cons 'a 'b 'c 'd))

(test (3 4 5 6) (member 3 (1 2 3 4 5 6)))
(test NIL (member 9 (1 2 3 4 5 6)))

(test '(c d e f) (memq 'c '(a b c d e f)))

(test (3 4) (sect (1 2 3 4) (3 4 5 6)))
(test (1 2 3) (sect (1 2 3) (1 2 3)))
(test NIL (sect (1 2 3) (4 5 6)))

(test (1 3 5) (diff (1 2 3 4 5) (2 4)))
(test (1 2 3) (diff (1 2 3) NIL))
(test NIL (diff (1 2 3) (1 2 3)))

(let (@X 1234  @Y (1 2 3 4))
   (test '(a b (c 1234) (((1 2 3 4) . d) e))
      (fill '(a b (c @X) ((@Y . d) e))) ) )
(let X 2 (test (1 2 3) (fill (1 X 3) 'X)))
(let X 2 (test (1 2 3) (fill (1 X 3) '(X))))

(test 123 (num? 123))
(test NIL (num? 'abc))
(test NIL (num? (1 2 3)))


# src/big.c

(test NIL (- NIL 7))
(test -7 (- 7))
(test 7 (- -7))

(test 8 (inc 7))
(test -6 (inc -7))
(test 0 (inc -1))
(test 1 (inc 0))
(test (8 -6 0 1) (let L (7 -7 -1 0) (map inc L) L))

(test 7 (dec 8))
(test -8 (dec -7))
(test -1 (dec 0))
(test (7 -8 -1) (let L (8 -7 0) (map dec L) L))

(test (-2 NIL NIL) (mapcar lt0 (-2 7 0)))

(test (7 NIL 0) (mapcar ge0 (7 -2 0)))

(test (7 NIL NIL) (mapcar gt0 (7 -2 0)))

(test 7 (bit? 7 15 255))
(test 1 (bit? 1 3))
(test NIL (bit? 1 2))


# src/io.c

(test NIL (mark *DB))
(test NIL (mark *DB T))
(test T (mark *DB))
(test T (mark *DB 0))
(test NIL (mark *DB))


# lib.l

(test '((N) (* 7 N))
   ((quote (@X) (curry (@X) (N) (* @X N))) 7) )
(test 21
   (((quote (@X) (curry (@X) (N) (* @X N))) 7) 3) )
(test '((N) (job '((A . 1)) (+ A 7 N)))
   (let (A 1 @X 7) (curry (A @X) (N) (+ A @X N))) )

(test '((@ . 1) (@ . 4) (@ . 9) (@ . 16) (@ . 25) (@ . 36))
   (prog1
      (mapcan
         '((N) (later (cons) (cons *Pid (* N N))))
         (1 2 3 4 5 6) )
      (wait NIL (not (memq NIL @))) ) )

(test '(a b 777 c d e) (insert 3 '(a b c d e) 777))
(test (777 a b c d e) (insert 1 '(a b c d e) 777))
(test '(a b c d e 777) (insert 9 '(a b c d e) 777))

(test '(a b d e) (remove 3 '(a b c d e)))
(test '(b c d e) (remove 1 '(a b c d e)))
(test '(a b c d e) (remove 9 '(a b c d e)))

(test '(a b 777 d e) (place 3 '(a b c d e) 777))
(test (777 b c d e) (place 1 '(a b c d e) 777))
(test '(a b c d e 777) (place 9 '(a b c d e) 777))

(test (2 4 6 1 3 5) (uniq (2 4 6 1 2 3 4 5 6 1 3 5)))

(test '((1 a b c) (2 d e f))
   (group '((1 . a) (1 . b) (1 . c) (2 . d) (2 . e) (2 . f))) )


# lib/misc.l

(locale "DE" "de")
(test "Ja" (val ,"Yes"))
(locale)

(test 32768 (** 2 15))

(test '((b . 2) (a . 3))
   (let L NIL (accu 'L 'a 2) (accu 'L 'b 2) (accu 'L 'a 1) L) )

(test "   a" (align 4 'a))

(test "   a" (center 7 'a))

(test "The^Jquick^Jbrown^Jfox^Jjumps^Jover the^Jlazy dog"
   (wrap 8 (chop "The quick brown fox jumps over the lazy dog")) )

(test "0001" (pad 4 1))

(test "111" (oct (+ 64 8 1)))
(test (+ 64 8 1) (oct "111"))

(test "111" (hex (+ 256 16 1)))
(test (+ 256 16 1) (hex "111"))

(test "1,234,567.89 EUR" (money 123456789 "EUR"))

(test (5 (2 (1) 3 NIL 4) 7 (6) 8 NIL 9)
   (let I NIL (balance 'I (sort (1 4 2 5 3 6 7 9 8))) I) )


(locale "DE" "de")
(test "1.234.567,89 EUR" (money 123456789 "EUR"))
(locale)
