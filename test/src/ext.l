# 12nov09abu
# (c) Software Lab. Alexander Burger

### ext:Snx ###
(test "PSLSFSNTSNNLSF"
   (ext:Snx "PicoLisp is not Common Lisp") )
(test "PSLSFSNT"
   (ext:Snx "PicoLisp is not Common Lisp" 8) )


### ext:Ulaw ###
(test (32 47 63 78 255 206 191 175 160)
   (mapcar 'ext:Ulaw (-8000 -4000 -2000 -1000 0 1000 2000 4000 8000)) )


### ext:Base64 ###
(test "TQ=="
   (pipe (ext:Base64 77) (line T)) )
(test "AQID"
   (pipe (ext:Base64 1 2 3) (line T)) )

# vi:et:ts=3:sw=3
