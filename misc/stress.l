# 17dec04abu
# (c) Software Lab. Alexander Burger

(load "lib/too.l")

(class +A +Entity)
(rel key    (+Key +Number))                     # Key  1 .. 999
(rel dat    (+Ref +Number))                     # Data 1 .. 999

(de rnd ()
   (rand 1 999) )

(de modify (N)
   (do N
      (dbSync)
      (let (D (rnd)  X (db 'key '+A (rnd)))
         (inc *DB (- D (get X 'dat)))
         (put> X 'dat D) )
      (commit 'upd) ) )

(de verify ()
   (dbCheck)
   (let N 0
      (scan (tree 'dat '+A)
         '((K V)
            (unless (= (car K) (get V 'dat))
               (quit "dat mismatch" K) )
            (inc 'N (car K)) ) )
      (or
         (= N (val *DB))
         (quit "val mismatch" (- N (val *DB))) ) ) )

(de main ()
   (seed (in "/dev/urandom" (rd 8)))
   (call 'rm "-f" "db/test")
   (pool "db/test")
   (unless (val *DB)
      (set *DB 0)
      (for (N 1 (<= N 999) (inc N))
         (let D (rnd)
            (new T '(+A)  'key N  'dat D)
            (inc *DB D) ) )
      (commit) ) )

(de go (N)
   (do (or N 6)
      (let Pids
         (make
            (do 20
               (rand)
               (if (fork)
                  (link @)
                  (modify 600)
                  (bye) ) ) )
         (while (find '((P) (kill P 0)) Pids)
            (wait 1000) )
         (rollback)
         (when (dbck)
            (quit 'dbck @) )
         (verify) ) ) )
