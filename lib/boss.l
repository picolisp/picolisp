# 26apr02abu
# (c) Software Lab. Alexander Burger

(unless (num? "Boss")
   (let F (pack "boss" *Pid)
      (call "mkfifo" F)
      (hear (setq "Boss" (open F)))
      (call "rm" F) ) )

# (boss 'sym ['any ..])
(de boss @
   (out "Boss" (pr (rest))) )
