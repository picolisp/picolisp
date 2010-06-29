# 14apr10abu
# (c) Software Lab. Alexander Burger

(on *Dbg)

(when (sys "TERM")
   (setq *Tsm
      (cons
         (in '("tput" "smul") (line T))
         (in '("tput" "rmul") (line T)) ) ) )

(load "@lib/debug.l" "@lib/led.l" "@lib/edit.l" "@lib/lint.l" "@lib/sq.l")

(noLint 'later (loc "@Prg" later))

# vi:et:ts=3:sw=3
