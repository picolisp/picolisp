# 18jun08abu
# (c) Software Lab. Alexander Burger

(de qsh (Pw Tty)
   (off *Run)
   (when (and (= Pw (in ".pw" (line T))) (ctty Tty))
      (pr *Pid)
      (flush)
      (load "@dbg.l")
      (off *Err)
      (quit) ) )

# vi:et:ts=3:sw=3
