# 20jan03abu
# (c) Software Lab. Alexander Burger

# Bye message
(push '*Bye
   '(and *Login (msg *Pid " - " (stamp))) )

# Exit on error
(de *Err
   (out NIL
      (prinl *Pid " ! " (stamp))
      (show This)
      (mapc
         '(("X") (println "X" (val "X")))
         '(*Gate *Host *Port *AppPort *SesId *ConId) )
      (and (get *Top 'focus) (println 'focus (get @ 'ix)))
      (mapc
         '(("X") (println "X" (val "X")))
         (env) ) )
   (rollback)
   (when *Top
      (alert `(_ "Sorry!")
         (list
            (pack "(" *Msg ")")
            `(_ "An internal error occurred.")
            `(_ "Connection will be closed.") ) ) )
   (bye) )

# User identification
(de user (Pid1 Pid2 Nm)
   (cond
      ((not Pid1) (tell 'user *Pid))
      ((not Pid2)
         (tell 'user Pid1 *Pid
            (with *Login (lit (cons (: nm) (: name)))) ) )
      ((= *Pid Pid1) (println Pid2 Nm)) ) )

# Timestamp
(msg *Pid " + " (stamp))
(flush)
