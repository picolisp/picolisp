# 22jul03abu
# (c) Software Lab. Alexander Burger

(ifn (info "fifo/beat")
   (de heartbeat ())

   (de heartbeat @
      (out "fifo/beat"
         (pr
            (cons *Pid
               (cons
                  (+ 300 (time) (* 86400 (date)))  # Busy period 5 minutes
                  (rest) ) ) ) ) )

   (task -54321 0 (heartbeat))

   (?push '*Bye '(out "fifo/beat" (pr *Pid))) )
