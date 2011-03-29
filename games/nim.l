# 08feb11abu
# (c) Software Lab. Alexander Burger

(load "@lib/simul.l")

# Nim
(de nim Pos
   (game T NIL
      '((Flg)  # Moves
         (make
            (for (I . N) Pos
               (do N
                  (link
                     (cons (cons I N) I (- N)) )
                  (dec 'N) ) ) ) )
      '((Mov)  # Move
         (dec (nth Pos (car Mov)) (cdr Mov)) )
      '((Flg)  # Cost
         (let N (apply + Pos)
            (if (=0 N) -100 N) ) ) ) )

### Test ###
(test
   '(-100 ((1 . 4) 1 . -4) ((2 . 4) 2 . -4) ((3 . 4) 3 . -4))
   (nim 4 4 4) )

# vi:et:ts=3:sw=3
