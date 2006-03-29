# 14jan06abu
# (c) Software Lab. Alexander Burger

(de fact (N)
   (if (=0 N)
      1
      (* N (fact (- N 1))) ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
