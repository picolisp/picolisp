# 21may04abu
# (c) Software Lab. Alexander Burger

# *Java

(?push '*Fork '(off *Java))
(?push '*Bye '(and *Java (call "rm" *Java))) )

(de java (Cls Foo Arg)
   (unless *Java
      (call "mkfifo" (setq *Java (pack "fifo/java" *Pid))) )
   (out "fifo/java" (pr *Java Cls Foo Arg))
   (in *Java (rd)) )
