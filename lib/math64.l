# 22feb10abu
# (c) Software Lab. Alexander Burger

(load "lib/native.l")

(de log (X)
   (and (gt0 X) ("log" X 1.0)) )

(gcc "math" NIL
   (exp (X) "Exp" 'N X 1.0)
   ("log" (X) "Log" 'N X 1.0)
   (sin (A) "Sin" 'N A 1.0)
   (cos (A) "Cos" 'N A 1.0)
   (tan (A) "Tan" 'N A 1.0)
   (atan (X Y) "Atan" 'N X Y 1.0) )

#include <math.h>

long Exp(long x, int scl) {
   return round((double)scl * exp((double)x / (double)scl));
}

long Log(long x, int scl) {
   return round((double)scl * log((double)x / (double)scl));
}

long Sin(long a, int scl) {
   return round((double)scl * sin((double)a / (double)scl));
}

long Cos(long a, int scl) {
   return round((double)scl * cos((double)a / (double)scl));
}

long Tan(long a, int scl) {
   return round((double)scl * tan((double)a / (double)scl));
}

long Atan(long x, long y, int scl) {
   return round((double)scl * atan2((double)x / (double)scl, (double)y / (double)scl));
}
/**/

# vi:et:ts=3:sw=3
