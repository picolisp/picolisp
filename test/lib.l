# 27sep07abu
# (c) Software Lab. Alexander Burger

### task ###
(test (3 . 4)
   (let (*Run NIL  *A NIL  *B NIL)
      (task -10 0 (setq *A 3))
      (task (port T 4444) (eval (udp @)))
      (udp "localhost" 4444 '(setq *B 4))
      (wait NIL (and *A *B))
      (cons *A *B) ) )


### timeout ###
(test '((-1 3600000 (bye)))
   (let *Run NIL
      (timeout 3600000)
      *Run ) )


### macro ###
(test 6
   (let (@A 1  @B 2  @C 3)
      (macro (* @A @B @C)) ) )


### later ###
(test '((@ . 1) (@ . 4) (@ . 9) (@ . 16) (@ . 25) (@ . 36))
   (prog1
      (mapcan
         '((N) (later (cons) (cons *Pid (* N N))))
         (1 2 3 4 5 6) )
      (wait NIL (full @)) ) )


### recur recurse ###
(test 720
   (let N 6
      (recur (N)
         (if (=0 N)
            1
            (* N (recurse (dec N))) ) ) ) )


### curry ###
(test '((N) (* 7 N))
   ((quote (@X) (curry (@X) (N) (* @X N))) 7) )
(test 21
   (((quote (@X) (curry (@X) (N) (* @X N))) 7) 3) )
(test '((N) (job '((A . 1)) (+ A 7 N)))
   (let (A 1 @X 7) (curry (A @X) (N) (+ A @X N))) )


### getd ###
(test car (getd 'car))
(test '(("X") (and (sym? "X") (fun? (val "X")) (val "X")))
   (getd 'getd) )
(test NIL (getd 1))


### expr subr undef ###
(let foo car
   (test 7 (foo (7)))
   (test T (== 'pass (caadr (expr 'foo))))
   (test car (subr 'foo))
   (test car (undef 'foo))
   (test NIL (val 'foo)) )


### redef ###
(let foo inc
   (redef foo (N) (inc (foo N)))
   (test 3 (foo 1)) )


### daemon patch ###
(let foo car
   (daemon 'foo (msg 'daemon))
   (test T (= '(msg 'daemon) (cadr (getd 'foo))))
   (patch foo 'daemon 'patch)
   (test T (= '(msg 'patch) (cadr (getd 'foo)))) )


### scl ###
(test 123 (scl 0 (any "123.45")))
(test 1235 (scl 1 (any "123.45")))
(test 123450 (scl 3 (any "123.45")))


### rc ###
(let F (tmp "rc")
   (rc F 'a 123)
   (rc F 'b "test")
   (rc F 'c (1 2 3))
   (test '((c 1 2 3) (b . "test") (a . 123))
      (in F (read)) )
   (test 123 (rc F 'a))
   (test "test" (rc F 'b))
   (test (1 2 3) (rc F 'c)) )


### insert ###
(test '(a b 777 c d e) (insert 3 '(a b c d e) 777))
(test (777 a b c d e) (insert 1 '(a b c d e) 777))
(test '(a b c d e 777) (insert 9 '(a b c d e) 777))


### remove ###
(test '(a b d e) (remove 3 '(a b c d e)))
(test '(b c d e) (remove 1 '(a b c d e)))
(test '(a b c d e) (remove 9 '(a b c d e)))


### place ###
(test '(a b 777 d e) (place 3 '(a b c d e) 777))
(test (777 b c d e) (place 1 '(a b c d e) 777))
(test '(a b c d e 777) (place 9 '(a b c d e) 777))


### uniq ###
(test (2 4 6 1 3 5) (uniq (2 4 6 1 2 3 4 5 6 1 3 5)))


### group ###
(test '((1 a b c) (2 d e f))
   (group '((1 . a) (1 . b) (1 . c) (2 . d) (2 . e) (2 . f))) )


### loc ###
(let (X 'foo  bar '((A B) (foo B A)))
   (test "foo" (zap 'foo))
   (test "foo" (str? "foo"))
   (test T (== X (loc "foo" bar))) )


### class ###
(off "+A" "+B" "+C")
(test '"+A" (class "+A" "+B" "+C"))
(test '"+A" *Class)
(test '("+B" "+C") "+A")


### object ###
(off "Obj")
(test '"Obj"
   (object '"Obj" '("+A" "+B" "+C")  'a 1 'b 2 'c 3) )
(test '((3 . c) (2 . b) (1 . a)) (getl '"Obj"))


### extend var var: ###
(test '"+B" (extend "+B"))
(test T (== *Class '"+B"))

(test 1 (var a . 1))
(test 2 (var b . 2))
(test '((2 . b) (1 . a)) (getl '"+B"))

(with '"Obj"
   (test 1 (var: a))
   (test 2 (var: b)) )

# vi:et:ts=3:sw=3
