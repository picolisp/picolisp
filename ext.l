# 16nov09abu
# (c) Software Lab. Alexander Burger

(when (sys "TERM")
   (setq *Tsm
      (cons
         (in '("tput" "smul") (line T))
         (in '("tput" "rmul") (line T)) ) ) )

(load "@lib/misc.l" "@lib/btree.l" "@lib/db.l" "@lib/pilog.l")

# vi:et:ts=3:sw=3
