# 25mar03abu
# (c) Software Lab. Alexander Burger

# Lisp
(de hanoi (N)
   (move N 'left 'center 'right) )

(de move (N A B C)
   (unless (=0 N)
      (move (- N 1) A C B)
      (println 'Move 'disk 'from 'the A 'to 'the B 'pole)
      (move (- N 1) C B A) ) )

# Pilog
(be hanoi (@N)
   (move @N left center right) )

(be move (0 @ @ @) T)

(be move (@N @A @B @C)
   (@M - (-> @N) 1)
   (move @M @A @C @B)
   (@ println 'Move 'disk 'from 'the (-> @A) 'to 'the (-> @B) 'pole)
   (move @M @C @B @A) )
