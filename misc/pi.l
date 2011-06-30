# 16jun11abu
# (c) Software Lab. Alexander Burger

##############################
# Iterative calculation of PI:
#  S = 0
#  P = 2
#  Loop
#     S = sqrt(S+2)
#     P = 2*P/S
##############################

(de pi (N Eps)
   (default N *Scl  Eps 100)
   (let (Scl (** 10 N)  S 0  N2 (* 2 Scl)  P N2  P2 0)
      (while (> (- P P2) Eps)
         (setq
            P2 P
            S (sqrt (* Scl (+ S N2)))
            P (*/ N2 P S) ) ) ) )

(test 3141592653589793238462643383279502884197169399375105820975043
   (pi 60) )
