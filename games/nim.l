# 13sep04abu
# (c) Software Lab. Alexander Burger

(load "lib/simul.l")

# Nim
(de nim @
   (game T (pass +) (rest)
      '((Flg Pos)
         (make
            (for (I . N) Pos
               (while (gt0 N)
                  (link (cons I N))
                  (dec 'N) ) ) ) )
      '((Flg Pos Mov)
         (place (car Mov) Pos
            (- (get Pos (car Mov)) (cdr Mov)) ) )
      '((Flg Pos)
         (let N (apply + Pos)
            (if (=0 N) -100 N) ) ) ) )

(test
   '(-100 ((1 . 4) 0 4 4) ((2 . 4) 0 0 4) ((3 . 4) 0 0 0))
   (nim 4 4 4) )
