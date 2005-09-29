# 17aug05abu
# (c) Software Lab. Alexander Burger

(de fact (N)
   (if (=0 N)
      1
      (* N (fact (dec N))) ) )

(de fibo (N)
   (if (< N 2)
      1
      (+ (fibo (dec N)) (fibo (- N 2))) ) )

(de cachedFibo (N)
   (cache '*Fibo (format N)
      (if (< N 2)
         1
         (+ (cachedFibo (dec N)) (cachedFibo (- N 2))) ) ) )
