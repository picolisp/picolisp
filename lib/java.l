# 30apr07abu
# (c) Software Lab. Alexander Burger

# *Java

(push1 '*Fork '(off *Java))
(push1 '*Bye '(and *Java (call 'rm *Java))) )

(de java (Cls X . @)
   (unless *Java
      (unless (call 'test "-p" "fifo/java")
         (quit "No JVM") )
      (call 'mkfifo (setq *Java (pack "fifo/java" *Pid))) )
   (out "fifo/java"
      (if (lst? X)
         (pr *Java Cls X (next) (rest))
         (pr *Java Cls X (rest)) ) )
   (in *Java (if (rd) (rd) (quit "JVM Error" (rd)))) )
