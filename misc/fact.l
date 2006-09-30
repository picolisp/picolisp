# 02sep06abu
# (c) Software Lab. Alexander Burger

(de fact (N)
   (if (=0 N)
      1
      (* N (fact (dec N))) ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
