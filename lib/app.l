# 01dec03abu
# (c) Software Lab. Alexander Burger

# Exit on error
(de *Err
   (out NIL
      (prinl *Pid " ! " (stamp) " [" *Adr " " (host *Adr) "]")
      (show This)
      (mapc
         '(("X") (println "X" (val "X")))
         '(*Gate *Agent *Host *Port *Url *SesId *ConId) )
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
(de user (Pid1 Pid2 Nm To)
   (cond
      ((not Pid1) (tell 'user *Pid))
      ((not Pid2)
         (tell 'user Pid1 *Pid
            (with *Login (lit (cons (: nm) (: name))))
            (/ (- *Timeout (cadr (assoc -1 *Key))) 60000) ) )
      ((= *Pid Pid1) (println Pid2 Nm To)) ) )

# Timestamp
(msg *Pid " + " (stamp))
(flush)

# Extend 'app' function
(conc (last app)
   '((msg *Pid " + " (stamp))) )

# Bye message
(?push '*Bye
   '(and *SesId (msg *Pid " - " (stamp))) )
