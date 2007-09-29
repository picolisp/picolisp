# 26sep07abu
# (c) Software Lab. Alexander Burger

### port listen connect ###
(test '(a b c)
   (if (fork)
      (let P (port 4444)
         (prog1
            (in (listen P) (rd))
            (close P) ) )
      (wait 400)
      (and (connect "localhost" 4444) (out @ (pr '(a b c))))
      (bye) ) )


### udp ###
(test '(a b c)
   (ifn (fork)
      (prog
         (wait 400)
         (udp "localhost" 4444 '(a b c))
         (bye) )
      (udp (port T 4444)) ) )

# vi:et:ts=3:sw=3
