# 10dec07abu
# (c) Software Lab. Alexander Burger

### apply ###
(test 6 (apply + (1 2 3)))
(test 360 (apply * (5 6) 3 4))
(test 27 (apply '((X Y Z) (* X (+ Y Z))) (3 4 5)))


### pass ###
(test 24 ((quote (N . @) (* N (pass + 6))) 2 1 2 3))


### maps ###
(let L '((1 . a) (2 . b) flg)
   (test L (let X (box) (putl X L) (make (maps link X)))) )


### map ###
(test '((1 2 3) (2 3) (3)) (make (map link (1 2 3))))


### mapc ###
(test (1 2 3) (make (mapc link (1 2 3))))


### maplist ###
(test '(((1 2 3) A B C) ((2 3) B C) ((3) C)) (maplist cons (1 2 3) '(A B C)))


### mapcar ###
(test (5 7 9) (mapcar + (1 2 3) (4 5 6)))
(test (26 38 52 68) (mapcar '((X Y) (+ X (* Y Y))) (1 2 3 4) (5 6 7 8)))


### mapcon ###
(test (1 2 3 4 5 2 3 4 5 3 4 5 4 5 5) (mapcon copy (1 2 3 4 5)))


### mapcan ###
(test '(c b a f e d i h g) (mapcan reverse '((a b c) (d e f) (g h i))))


### filter ###
(test (1 2 3) (filter num? (1 A 2 (B) 3 CDE)))


### seek ###
(test (12 19 22) (seek '((X) (> (car X) 9)) (1 5 8 12 19 22)))


### find ###
(test '(B) (find pair (1 A 2 (B) 3 CDE)))
(test 4 (find > (1 2 3 4 5 6) (6 5 4 3 2 1)))
(test 4 (find '((A B) (> A B)) (1 2 3 4 5 6) (6 5 4 3 2 1)))


### pick ###
(test "Hello"
   (pick '((X) (get X 'str))
      (list (box) (prog1 (box) (put @ 'str "Hello")) (box)) ) )


### cnt ###
(test 2 (cnt cdr '((1 . T) (2) (3 4) (5))))


### sum ###
(test 6 (sum val (list (box 1) (box) (box 2) (box 'a) (box 3))))


### maxi mini ###
(let (A 1 B 2 C 3)
   (test 'C (maxi val '(A B C)))
   (test 'A (mini val '(A B C)))
   (test '(A B C) (by val sort '(C A B))) )


### fish ###
(test (1 2 3)
   (fish gt0 '(a -2 (1 b (-3 c 2)) 3 d -1)) )
(test '(a b c d)
   (fish sym? '(a -2 (1 b (-3 c 2)) 3 d -1)) )


### by ###
(test '(A B C)
   (let (A 1 B 2 C 3)
      (by val sort '(C A B)) ) )
(test '((3 11 9 5 7 1) (6 2 4 10 12 8))
   (by '((N) (bit? 1 N))
      group
      (3 11 6 2 9 5 4 10 12 7 8 1) ) )

# vi:et:ts=3:sw=3
