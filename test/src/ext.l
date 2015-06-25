# 26apr15abu
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

(test (77)
   (pipe
      (prinl "TQ==")
      (make (while (ext:Base64) (link @))) ) )
(test (1 2 3)
   (pipe
      (prinl "AQID")
      (make (while (ext:Base64) (link @))) ) )

(let F (tmp "base64")
   (out F
      (pipe
         (prin "Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark")
         (while (ext:Base64 (rd 1) (rd 1) (rd 1))) ) )

   (test "UG9seWZvbiB6d2l0c2NoZXJuZCBhw59lbiBNw6R4Y2hlbnMgVsO2Z2VsIFLDvGJlbiwgSm9naHVydCB1bmQgUXVhcms="
      (in F (line T)) )

   (test "Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark"
      (pipe
         (in F (while (ext:Base64) (wr @)))
         (line T) ) ) )

# vi:et:ts=3:sw=3
