# 19jul13abu
# (c) Software Lab. Alexander Burger

(be mapcar (@ NIL NIL))
(be mapcar (@P (@X . @L) (@Y . @M))
   (call @P @X @Y)
   (mapcar @P @L @M) )

# Contributed by Clemens Hinze <cle-picolisp@qiao.in-berlin.de>
(be findall (@Pat @P @Res)
   (^ @Res
      (solve
         (-> @P)
         (or @Pat (fill (-> @Pat))) ) ) )

# vi:et:ts=3:sw=3
