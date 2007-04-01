# 22jan07abu
# (c) Software Lab. Alexander Burger

(de fact (N)
   (if (=0 N)
      1
      (* N (fact (dec N))) ) )
