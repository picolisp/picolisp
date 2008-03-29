# 27jan08abu
# (c) Software Lab. Alexander Burger

# Standard version (slowest)
(de fibo (N)
   (if (>= 2 N)
      1
      (+ (fibo (dec N)) (fibo (- N 2))) ) )


# Coded in 'C' (faster)
(load "lib/gcc.l")

(gcc "tst" NIL 'cFibo)

static int fibo(int n) {
   if (n <= 2)
      return 1;
   return fibo(n-1) + fibo(n-2);
}

any cFibo(any ex) {
   return boxCnt(fibo(evCnt(ex, cdr(ex))));
}
/**/


# Using a cache (fastest)
(de cachedFibo (N)
   (cache '*Fibo (format N)
      (if (>= 2 N)
         1
         (+ (cachedFibo (dec N)) (cachedFibo (- N 2))) ) ) )
