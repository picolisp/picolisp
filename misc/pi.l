# 03feb01abu
# (c) Software Lab. Alexander Burger

##############################
# Iterative calculation of PI:
#  S = 0
#  P = 2
#  Loop
#     S = sqrt(S+2)
#     P = 2*P/S
##############################

(de pi (Scl N)
   (let (S 0  N2 (* 2 Scl)  P N2)
      (do N
         (setq P
            (*/
               N2
               P
               (setq S (sqrt (* Scl (+ S N2)))) ) ) )
      P ) )

(test 3141592653589793238462644194157096587006
   (pi 1000000000000000000000000000000000000000 1000) )
