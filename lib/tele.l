# 26nov03abu
# (c) Software Lab. Alexander Burger

### Java Remote Control ###
(allow "java/tele.jar")

(de tele (Port @Var . @Prg)
   (unless (find '((L) (memq @Var (cadr L))) *Key)
      (let @S (port Port)
         (macro
            (task @S
               (setq @Var (accept @S))
               (task @S)
               (close @S)
               (task @Var . @Prg) ) ) ) ) )
