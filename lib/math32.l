# 18may10abu
# (c) Software Lab. Alexander Burger

(de pow (X Y)
   (ext:Pow X Y 1.0) )

(de exp (X)
   (ext:Exp X 1.0) )

(de log (X)
   (and (gt0 X) (ext:Log X 1.0)) )

(de sin (A)
   (ext:Sin A 1.0) )

(de cos (A)
   (ext:Cos A 1.0) )

(de tan (A)
   (ext:Tan A 1.0) )

(de asin (A)
   (ext:Asin A 1.0) )

(de acos (A)
   (ext:Acos A 1.0) )

(de atan (A)
   (ext:Atan A 1.0) )

(de atan2 (X Y)
   (ext:Atan2 X Y 1.0) )

# vi:et:ts=3:sw=3
