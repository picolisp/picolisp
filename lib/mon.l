# 19may04abu
# (c) Software Lab. Alexander Burger

# *Visitors *Monitor

(?push '*Bye '(tell 'wentAway *Pid))

(de visit (Vis . @)
   (pass tell 'visited *Pid (lit Vis)) )

(de visited (Pid Vis . Lst)
   (let (Tim (time)  Txt (glue " " Lst))
      (when *Login
         (if (assoc Pid *Visitors)
            (let X @
               (set (cdr X) Vis)
               (and
                  (<> Txt (cdr (caddr X)))
                  (con (cdr X) (cons (cons Tim Txt) (cddr X))) ) )
            (and *Monitor (beep> *Monitor))
            (push '*Visitors (list Pid Vis (cons Tim Txt))) )
         (and *Monitor (upd> *Monitor)) ) ) )

(de wentAway (Pid)
   (when *Login
      (del (assoc Pid *Visitors) '*Visitors)
      (and *Monitor (upd> *Monitor)) ) )


### Monitor Form ###
(class +MonForm +Form)

(dm start> ()
   (setq *Monitor This)
   (super) )
