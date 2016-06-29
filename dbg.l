# 19mar16abu
# (c) Software Lab. Alexander Burger

(on *Dbg)

(if (info (pil "editor"))
   (load (pil "editor"))
   (load "@lib/led.l" "@lib/edit.l") )

(load "@lib/debug.l" "@lib/lint.l" "@lib/sq.l" "@lib/too.l")

(noLint 'pretty 'Z)
(noLint '_pretty 'Z)

### @lib/form.l ###
`(bool (getd 'form))

(noLint 'gui)
(noLint 'choDlg 'gui)
(noLint 'jsForm 'action)

# vi:et:ts=3:sw=3
