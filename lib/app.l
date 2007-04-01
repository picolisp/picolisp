# 15feb07abu
# (c) Software Lab. Alexander Burger

# Exit on error
(de *Err
   (prinl *Pid " ! " (stamp) " [" *Adr " " (host *Adr) "] " *Agent)
   (show This)
   (for "X" '(*Gate *Agent *Host *Port *Url *SesId *ConId *ID)
      (println "X" (val "X")) )
   (and (get *Top 'focus) (println 'focus (get @ 'ix)))
   (for "X" (env)
      (unless (== (car "X") (cdr "X"))
         (println (car "X") (cdr "X")) ) )
   (rollback)
   (when *Top
      (alert "Sorry!"
         (list
            (pack "(" *Msg ")")
            "An internal error occurred."
            "Connection will be closed." ) ) ) )

# User identification
(de user (Pid1 Pid2 Nm To)
   (nond
      (Pid1 (tell 'user *Pid))
      (Pid2
         (tell 'user Pid1 *Pid
            (with *Login (lit (cons (: nm) (: name))))
            (/ (- *Timeout (cadr (assoc -1 *Run))) 60000) ) )
      ((<> *Pid Pid1) (println Pid2 Nm To)) ) )

# Timestamp
(msg *Pid " + " (stamp))
(flush)

# Extend 'app' function
(conc (last app)
   '((msg *Pid " + " (stamp) " [" *Adr " " (host *Adr) "] " *Agent)) )

# Bye message
(push1 '*Bye '(and *SesId (msg *Pid " - " (stamp))))
