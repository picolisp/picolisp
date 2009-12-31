# 07nov09abu
# (c) Software Lab. Alexander Burger
# Fannkuch benchmark (http://shootout.alioth.debian.org)

(de fannkuch (N)
   (let (Lst (range 1 N)  L Lst  Max)
      (recur (L)  # Permute
         (if (cdr L)
            (do (length L)
               (recurse (cdr L))
               (rot L) )
            (zero N)  # For each permutation
            (for (P (copy Lst)  (> (car P) 1)  (flip P (car P)))
               (inc 'N) )
            (setq Max (max N Max)) ) )
      Max ) )

# Parallelized version
(de fannkuch+ (N)
   (let (Res (need N)  Lst (range 1 N)  L Lst  Max)
      (for (R Res R (cdr R))
         (later R
            (let L (cdr Lst)
               (recur (L)  # Permute
                  (if (cdr L)
                     (do (length L)
                        (recurse (cdr L))
                        (rot L) )
                     (zero N)  # For each permutation
                     (for (P (copy Lst)  (> (car P) 1)  (flip P (car P)))
                        (inc 'N) )
                     (setq Max (max N Max)) ) )
               Max ) )
         (rot Lst) )
      (wait NIL (full Res))
      (apply max Res) ) )

# vi:et:ts=3:sw=3
