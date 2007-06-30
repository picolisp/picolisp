# 25jun07abu
# (c) Software Lab. Alexander Burger

# The Shape base class
(class +Shape)
# x y

(dm T (X Y)
   (=: x X)
   (=: y Y) )

(dm move> (DX DY)
   (inc (:: x) DX)
   (inc (:: y) DY) )


# The Rectangle class
(class +Rectangle +Shape)
# dx dy

(dm T (X Y DX DY)
   (super X Y)
   (=: dx DX)
   (=: dy DY) )

(dm area> ()
   (* (: dx) (: dy)) )

(dm perimeter> ()
   (* 2 (+ (: dx) (: dy))) )

(dm draw> ()
   (drawRect (: x) (: y) (: dx) (: dy)) ) # Hypothetical function 'drawRect'


# The Circle class
(class +Circle +Shape)
# r

(dm T (X Y R)
   (super X Y)
   (=: r R) )

(dm area> ()
   (*/ (: r) (: r) 31415927 10000000) )

(dm perimeter> ()
   (*/ 2 (: r) 31415927 10000000) )

(dm draw> ()
   (drawCircle (: x) (: y) (: r)) )       # Hypothetical function 'drawCircle'


# The Fixed prefix class
(class +Fixed)

(dm move> (DX DY))  # A do-nothing method

# vi:et:ts=3:sw=3
