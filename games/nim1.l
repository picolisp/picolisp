# 11sep04abu
# (c) Software Lab. Alexander Burger

(load "lib/simul.l")

# Nim
(de nim (N)
   (game T N N
      '((Flg Pos) (nth (3 2 1) (max 1 (- 4 Pos))))
      '((Flg Pos Mov) (- Pos Mov))
      '((Flg Pos) (if (=0 Pos) -100 0)) ) )

(test
   '(-100 (1 . 4) (1 . 3) (3 . 0))
   (nim 5) )

(test
   '(-100 (1 . 12) (1 . 11) (3 . 8) (1 . 7) (3 . 4) (1 . 3) (3 . 0))
   (nim 13) )
