# 16jun11abu
# (c) Software Lab. Alexander Burger

# Spigot algorithm (Jeremy Gibbons)

# Print next digit of PI (unbounded)
(de piDigit ()
   (job '((Q . 1) (R . 0) (S . 1) (K . 1) (N . 3) (L . 3))
      (while (>= (- (+ R (* 4 Q)) S) (* N S))
         (mapc set '(Q R S K N L)
            (list
               (* Q K)
               (* L (+ R (* 2 Q)))
               (* S L)
               (inc K)
               (/ (+ (* Q (+ 2 (* 7 K))) (* R L)) (* S L))
               (+ 2 L) ) ) )
      (prog1 N
         (let M (- (/ (* 10 (+ R (* 3 Q))) S) (* 10 N))
            (setq Q (* 10 Q)  R (* 10 (- R (* N S)))  N M) ) ) ) )

# Print _all_ digits of PI
(prin (piDigit) ".")
(loop
   (prin (piDigit))
   (flush) )

# vi:et:ts=3:sw=3
