# 19may04abu
# (c) Software Lab. Alexander Burger

# *Boss

(unless *Boss
   (call "mkfifo" (setq *Boss (pack "fifo/boss" *Pid)))
   (hear (open *Boss)) )

(?push '*Fork '(del '(call "rm" *Boss) '*Bye))
(?push '*Bye '(call "rm" *Boss))

# (boss 'sym ['any ..])
(de boss @
   (out *Boss (pr (rest))) )
