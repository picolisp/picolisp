# 31dec13abu
# (c) Software Lab. Alexander Burger

(load "@lib/simul.l")

(seed (in "/dev/urandom" (rd 8)))

(let Grid (grid 26 26)
   (for Col Grid
      (for This Col
         (=: life (rand T)) ) )
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
            (=: life (: next)) ) ) ) )

# vi:et:ts=3:sw=3
