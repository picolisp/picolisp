# 15mar10abu
# (c) Software Lab. Alexander Burger

(load "@lib/simul.l")

(de life (DX DY . Init)
   (let Grid (grid DX DY)
      (for This Init
         (=: life T) )
      (loop
         (disp Grid NIL
            '((This) (if (: life) "X " "  ")) )
         (wait 1000)
         (for Col Grid
            (for This Col
               (let N  # Count neighbors
                  (cnt
                     '((Dir) (get (Dir This) 'life))
                     (quote
                        west east south north
                        ((X) (south (west X)))
                        ((X) (north (west X)))
                        ((X) (south (east X)))
                        ((X) (north (east X))) ) )
                  (=: next  # Next generation
                     (if (: life)
                        (>= 3 N 2)
                        (= N 3) ) ) ) ) )
         (for Col Grid  # Update
            (for This Col
               (=: life (: next)) ) ) ) ) )

# Blinker (period 2)
'(life 5 5  b3 c3 d3)

# Glider
'(life 9 9  a7 b7 b9 c7 c8)

# Pulsar (period 3)
(life 17 17
   b6 b12
   c6 c12
   d6 d7 d11 d12 
   f2 f3 f4 f7 f8 f10 f11 f14 f15 f16
   g4 g6 g8 g10 g12 g14
   h6 h7 h11 h12
   j6 j7 j11 j12
   k4 k6 k8 k10 k12 k14
   l2 l3 l4 l7 l8 l10 l11 l14 l15 l16
   n6 n7 n11 n12 
   o6 o12
   p6 p12 )

# vi:et:ts=3:sw=3
