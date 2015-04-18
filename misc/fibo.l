# 25mar15abu
# (c) Software Lab. Alexander Burger

# Standard version
(de fibo (N)
   (if (>= 2 N)
      1
      (+ (fibo (dec N)) (fibo (- N 2))) ) )

# Non-recursive
(de fib (N)
   (let (A 0  B 1)
      (do N
         (prog1 B (setq B (+ A B) A @)) ) ) )

# Parallelized version
(de fibo+ (D N)  # Uses 2**D processes
   (cond
      ((>= 1 (dec 'N)) 1)
      ((ge0 (dec 'D))
         (let (A NIL B NIL)
            (later 'A (fibo+ D N))
            (later 'B (fibo+ D (dec N)))
            (wait NIL (and A B))
            (+ A B) ) )
      (T
         (+
            (fibo+ D N)
            (fibo+ D (dec N)) ) ) ) )


# Using a cache (fastest)
(de cachedFibo (N)
   (cache '(NIL) N
      (if (>= 2 N)
         1
         (+ (cachedFibo (dec N)) (cachedFibo (- N 2))) ) ) )


# Coded in 'C'
`(== 64 64)  # Only in the 64-bit version

(load "@lib/native.l")

(gcc "fibo" NIL
   (cFibo (N) "Fibo" 'I N) )

int Fibo(int n) {
   if (n <= 2)
      return 1;
   return Fibo(n-1) + Fibo(n-2);
}
/**/

# vi:et:ts=3:sw=3
