# 12sep06abu
# (c) Software Lab. Alexander Burger

# *Java

(?push '*Fork '(off *Java))
(?push '*Bye '(and *Java (call 'rm *Java))) )

(de java (Cls X . @)
   (unless *Java
      (call 'mkdir "-p" "fifo")
      (unless (call 'test "-p" "fifo/java")
         (quit "No JVM") )
      (call 'mkfifo (setq *Java (pack "fifo/java" *Pid))) )
   (out "fifo/java"
      (if (lst? X)
         (pr *Java Cls X (next) (rest))
         (pr *Java Cls X (rest)) ) )
   (in *Java (if (rd) (rd) (quit (rd)))) )
