# 28apr03abu
# (c) Software Lab. Alexander Burger

(ifn (call "test" "-w" "fifo/beat")
   (de heartbeat ())

   (de heartbeat @
      (out "fifo/beat"
         (pr
            (cons *Pid
               (cons
                  (+ 300 (time) (* 86400 (date)))
                  (rest) ) ) ) ) )

   (task -54321 54321 (heartbeat))

   (?push '*Bye '(out "fifo/beat" (pr *Pid))) )
