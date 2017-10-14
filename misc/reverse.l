# 11oct17abu
# (c) Software Lab. Alexander Burger

(setq *Port (port 6789))

(loop
   (setq *Sock (listen *Port))
   (unless (fork)
      (close *Port)
      (in *Sock
         (until (eof)
            (out *Sock
               (prinl (flip (line))) ) ) )
      (bye) )
   (close *Sock) )
