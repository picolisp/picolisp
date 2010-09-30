# 01jul10abu
# (c) Software Lab. Alexander Burger

# "tmp+" "tmp-"

(unless (info (tmp "+"))
   (call 'mkfifo (setq "tmp+" (tmp "+")))
   (call 'mkfifo (setq "tmp-" (tmp "-"))) )
(hear (open "tmp+"))

# (boss 'sym ['any ..])
(de boss @
   (out "tmp+" (pr (rest))) )

(de reply Exe  #> any
   (out "tmp-" (pr (eval Exe))) )
