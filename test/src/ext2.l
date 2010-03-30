# 19feb10abu
# (c) Software Lab. Alexander Burger

### ext:Sin ###
(test 0
   (ext:Sin 0 100000) )
(test 100000
   (ext:Sin (/ 314159 2) 100000) )


### ext:Cos ###
(test 100000
   (ext:Cos 0 100000) )
(test -10000000
   (ext:Cos 31415926 10000000) )


### ext:Tan ###
(test 0
   (ext:Tan 0 10000000) )
(test -1
   (ext:Tan 31415926 10000000) )


### ext:Atan ###
(test 0
   (ext:Atan 0 10000000 10000000) )
(test 15707963
   (ext:Atan 10000000 0 10000000) )

# vi:et:ts=3:sw=3
