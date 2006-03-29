# 20feb06abu
# (c) Software Lab. Alexander Burger

(let? S (in '("tput" "smul") (line T))
   (when (in '("tput" "rmul") (line T))
      (setq *Tsm (cons S @)) ) )

(load "@lib/misc.l" "@lib/tree.l" "@lib/db.l" "@lib/pilog.l")

# vim:syntax=picolisp:ts=3:sw=3:expandtab
