# 11feb06abu
# (c) Software Lab. Alexander Burger

# *Login *Perms

### Login ###
(de login (Nm Pw)
   (and
      (db 'nm '+User Nm 'pw Pw)
      (timeout (setq *Login @  *Timeout `(* 4 60 60 1000))) ) )

(de logout ()
   (off *Login)
   (msg *Pid " / " (stamp))
   (timeout (setq *Timeout `(* 15 60 1000))) )


### Role ###
(class +Role +Entity)

(rel nm     (+Need +Key +String))               # Role name
(rel perm   (+List +Symbol))                    # Permission list
(rel usr    (+List +Joint) role (+User))        # Associated users


### User ###
(class +User +Entity)

(rel nm     (+Need +Key +String))               # User name
(rel pw     (+String))                          # Password
(rel role   (+Joint) usr (+Role))               # User role


### Permission management ###
(de permission Lst
   (while Lst
      (queue '*Perms (car Lst))
      (def (pop 'Lst) (pop 'Lst)) ) )

(de may Args
   (mmeq Args (get *Login 'role 'perm)) )

(de must Args
   (unless
      (if (cdr Args)
         (mmeq @ (get *Login 'role 'perm))
         *Login )
      (quit "No permission" (car Args)) ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
