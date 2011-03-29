# 18jan11abu
# (c) Software Lab. Alexander Burger

(when (sys "TERM")
   (setq *Tsm
      (cons
         (in '("tput" "smul") (line T))
         (in '("tput" "rmul") (line T)) ) ) )

# vi:et:ts=3:sw=3
