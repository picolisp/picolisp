# 25jan03abu
# (c) Software Lab. Alexander Burger

(queue '*Bye
   '(when *Tmp
      (call "rm" "-rf" *Tmp) ) )

(de tmp @
   (unless *Tmp
      (call "mkdir" "-p" (setq *Tmp (pack "tmp/" *Pid "/"))) )
   (pass pack *Tmp) )

(de tmp? (F)
   (and *Tmp (pre? *Tmp F) (not (sub? "/../" F))) )
