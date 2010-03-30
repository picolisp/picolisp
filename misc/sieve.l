# 25feb10abu
# (c) Software Lab. Alexander Burger

# Sieve of Eratosthenes
(de sieve (N)
   (let Sieve (range 1 N)
      (set Sieve)
      (for I (cdr Sieve)
         (when I
            (for (S (nth Sieve (* I I)) S (nth (cdr S) I))
               (set S) ) ) )
      (filter bool Sieve) ) )

# vi:et:ts=3:sw=3
