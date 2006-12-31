# 13oct06abu
# (c) Software Lab. Alexander Burger

# *Boss

(unless *Boss
   (call 'mkdir "-p" "fifo")
   (call 'mkfifo (setq *Boss (pack "fifo/boss" *Pid)))
   (hear (open *Boss)) )

(push1 '*Fork '(del '(call 'rm *Boss) '*Bye))
(push1 '*Bye '(call 'rm *Boss))

# (boss 'sym ['any ..])
(de boss @
   (out *Boss (pr (rest))) )
