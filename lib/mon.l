# 13apr03abu
# (c) Software Lab. Alexander Burger

# *Vis *Mon

(?push '*Bye
   '(tell 'wentAway *Pid) )

(de visit (Vis . @)
   (pass tell 'visited *Pid (lit Vis)) )

(de visited (Pid Vis . Lst)
   (let (Tim (time)  Txt (glue " " Lst))
      (when *Login
         (if (assoc Pid *Vis)
            (let X @
               (set (cdr X) Vis)
               (and
                  (<> Txt (cdr (caddr X)))
                  (con (cdr X) (cons (cons Tim Txt) (cddr X))) ) )
            (and *Mon (beep> *Mon))
            (push '*Vis (list Pid Vis (cons Tim Txt))) )
         (and *Mon (upd> *Mon)) ) ) )

(de wentAway (Pid)
   (when *Login
      (setq *Vis (delete (assoc Pid *Vis) *Vis))
      (and *Mon (upd> *Mon)) ) )


### Monitor Form ###
(class +MonForm +Form)

(dm start> ()
   (setq *Mon This)
   (super) )
