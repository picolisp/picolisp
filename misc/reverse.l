# 19dec05abu
# (c) Software Lab. Alexander Burger

(setq *Port (port 6789))

(loop
   (setq *Sock (listen *Port))
   (NIL (fork) (close *Port))
   (close *Sock) )

(in *Sock
   (until (eof)
      (out *Sock
         (prinl (flip (line))) ) ) )

(bye)
