# 19may06abu
# (c) Software Lab. Alexander Burger

(ifn (info "fifo/beat")
   (de heartbeat ()
      (sync) )

   (de heartbeat @
      (sync)
      (out "fifo/beat"
         (pr
            (cons *Pid
               (cons
                  (+ 300 (time T) (* 86400 (date T)))  # Busy period 5 minutes
                  (rest) ) ) ) ) )

   (task -54321 0 (heartbeat))

   (?push '*Bye '(out "fifo/beat" (pr *Pid))) )
