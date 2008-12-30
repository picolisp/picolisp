# 17oct08abu
# (c) Software Lab. Alexander Burger

### ext:Snx ###
(test "PSLSFSNTSNNLSF"
   (ext:Snx "Pico Lisp is not Common Lisp") )
(test "PSLSFSNT"
   (ext:Snx "Pico Lisp is not Common Lisp" 8) )


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


### ext:Dist ###
(test 5000
   (ext:Dist 3000 4000) )
(test 5000
   (ext:Dist 2000 3000 5000 7000) )
(test 10000
   (ext:Dist 0 0 10000 -10000 10000 10000) )
(test 7071
   (ext:Dist 0 10000 0 0 10000 10000) )


### ext:Ulaw ###
(test (32 47 63 78 255 206 191 175 160)
   (mapcar 'ext:Ulaw (-8000 -4000 -2000 -1000 0 1000 2000 4000 8000)) )


### ext:Base64 ###
(test "TQ=="
   (pipe (ext:Base64 77) (line T)) )
(test "AQID"
   (pipe (ext:Base64 1 2 3) (line T)) )

# vi:et:ts=3:sw=3
