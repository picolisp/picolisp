# 26oct01abu
# (c) Software Lab. Alexander Burger

(unless *Java
   (call "mkfifo" (setq *Java (pack "fifo/" *Pid)))
   (push '*Bye '(call "rm" *Java)) )

(de java (Cls Foo Arg)
   (out "fifo/java"
      (pr *Java Cls Foo Arg) )
   (in *Java
      (rd) ) )
