# 22nov07abu
# (c) Software Lab. Alexander Burger

### alarm ###
(let N 6
   (alarm 1 (inc 'N))
   (test 6 N)
   (wait 2000)
   (test 7 N)
   (alarm 0) )


### protect ###
(test NIL (pipe (prog (kill *Pid) (pr 7)) (rd)))
(test 7 (pipe (protect (kill *Pid) (pr 7)) (rd)))


### env ###
(test NIL (env))
(test '((A . 1) (B . 2))
   (let (A 1 B 2)
      (env) ) )
(test '((B . 2) (A . 1))
   (let (A 1 B 2)
      (env '(A B)) ) )
(test '((Y . 8) (B . 2) (A . 1) (X . 7))
   (let (A 1 B 2)
      (env 'X 7 '(A B) 'Y 8) ) )


### up ###
(test 1
   (let N 1
      ((quote (N) (up N)) 2) ) )
(test 7
   (let N 1
      ((quote (N) (up N 7)) 2)
      N ) )


### args next arg rest ####
(test '(T 1 1 (2 3))
   (let foo '(@ (list (args) (next) (arg) (rest)))
      (foo 1 2 3) ) )


### usec ###
(let U (usec)
   (wait 400)
   (test 4 (*/ (- (usec) U) 100000)) )


### pwd ###
(test (path '@) (pack (pwd) '/))


### cd ###
(cd "test")
(test (path "@test") (pwd))
(cd "..")


### info ###
(test '(T . @) (info "test"))
(test (5 . @)
   (out (tmp "info") (prinl "info"))
   (info (tmp "info")) )


### dir ###
(call 'mkdir "-p" (tmp "dir"))
(out (tmp "dir/a"))
(out (tmp "dir/b"))
(out (tmp "dir/c"))

(test '("a" "b" "c") (sort (dir (tmp "dir"))))


### argv ###
(test '("abc" "123")
   (pipe
      (call "bin/picolisp" "-prog (println (argv)) (bye)" "abc" 123)
      (read) ) )
(test '("abc" "123")
   (pipe
      (call "bin/picolisp" "-prog (argv A B) (println (list A B)) (bye)" "abc" 123)
      (read) ) )


### opt ###
(test '("abc" "123")
   (pipe
      (call "bin/picolisp" "-prog (println (list (opt) (opt))) (bye)" "abc" 123)
      (read) ) )
(test "abc"
   (pipe
      (call "bin/picolisp" "-de f () (println (opt))" "-f" "abc" "-bye")
      (read) ) )



### date time ###
(use (Tim1 Tim2 Dat1 Dat2 T1 T2 D1 D2)
   (until
      (=
         (setq Tim1 (time))
         (prog
            (setq
               Tim2 (time T)
               Dat1 (date)
               Dat2 (date T)
               T1 (in '(date "+%H %M %S") (list (read) (read) (read)))
               T2 (in '(date "-u" "+%H %M %S") (list (read) (read) (read)))
               D1 (in '(date "+%Y %m %d") (list (read) (read) (read)))
               D2 (in '(date "-u" "+%Y %m %d") (list (read) (read) (read))) )
            (time) ) ) )
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

# vi:et:ts=3:sw=3
