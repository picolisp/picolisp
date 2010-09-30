# 02aug10abu
# (c) Software Lab. Alexander Burger

(setq
   "Dbl1" (0 . 1.0)
   "Dbl2" (0 . 1.0) )

(de pow (X Y)
   (set "Dbl1" X  "Dbl2" Y)
   (native "@" "pow" 1.0 "Dbl1" "Dbl2") )

(de exp (X)
   (set "Dbl1" X)
   (native "@" "exp" 1.0 "Dbl1") )

(de log (X)
   (when (gt0 (set "Dbl1" X))
      (native "@" "log" 1.0 "Dbl1") ) )

(de sin (A)
   (set "Dbl1" A)
   (native "@" "sin" 1.0 "Dbl1") )

(de cos (A)
   (set "Dbl1" A)
   (native "@" "cos" 1.0 "Dbl1") )

(de tan (A)
   (set "Dbl1" A)
   (native "@" "tan" 1.0 "Dbl1") )

(de asin (A)
   (set "Dbl1" A)
   (native "@" "asin" 1.0 "Dbl1") )

(de acos (A)
   (set "Dbl1" A)
   (native "@" "acos" 1.0 "Dbl1") )

(de atan (A)
   (set "Dbl1" A)
   (native "@" "atan" 1.0 "Dbl1") )

(de atan2 (X Y)
   (set "Dbl1" X  "Dbl2" Y)
   (native "@" "atan2" 1.0 "Dbl1" "Dbl2") )

# vi:et:ts=3:sw=3
