# 27feb13abu
# (c) Software Lab. Alexander Burger

(on *Dbg)

(if (info (pil "editor"))
   (load (pil "editor"))
   (load "@lib/led.l" "@lib/edit.l") )

(load "@lib/debug.l" "@lib/lint.l" "@lib/sq.l")

(noLint 'later (loc "@Prg" later))

# vi:et:ts=3:sw=3
