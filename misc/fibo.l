# 27oct04abu
# (c) Software Lab. Alexander Burger

(de fact (N)
   (if (=0 N)
      1
      (* N (fact (- N 1))) ) )

(de fibo (N)
   (if (< N 2)
      1
      (+
         (fibo (- N 1))
         (fibo (- N 2)) ) ) )

(de cachedFibo (N)
   (cache '*Fibo (format N)
      (if (< N 2)
         1
         (+
            (cachedFibo (- N 1))
            (cachedFibo (- N 2)) ) ) ) )
