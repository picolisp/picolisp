# 10apr01abu
# (c) Software Lab. Alexander Burger

(setq *Port (port 6789))

(do NIL
   (setq *Sock (listen *Port))
   (NIL (fork) (close *Port))
   (close *Sock) )

(in *Sock
   (whilst (line)
      (out *Sock
         (prinl (reverse @)) ) ) )

(bye)
