# 12jun06abu
# (c) Software Lab. Alexander Burger

(and
   (sys "TERM")
   (setq "*S" (in '("tput" "smul") (line T)))
   (in '("tput" "rmul") (line T))
   (setq *Tsm (cons "*S" @)) )

(load "@lib/misc.l" "@lib/btree.l" "@lib/db.l" "@lib/pilog.l")

# vim:syntax=picolisp:ts=3:sw=3:expandtab
