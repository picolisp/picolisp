# 04may05abu
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
   (timeout (setq *Timeout `(* 15 60 1000)))
   (upd> (: home msg))
   (and *Bar (upd> *Bar)) )

(de pwForm Prg
   (form '(+Form) 450 150
      (append
         (quote
            (gui 'nm '(+TextField) ,"Name" 20)
            (gui 'pw '(+Chk +End +PwField)
               '(let? Nm (val> (: home nm))
                  (unless (login Nm (val> (: home pw)))
                     (msg *Pid " ?! " Nm)
                     ,"Permission denied" ) )
               '(when (val> (: home nm))
                  (msg *Pid " * " (stamp) " " @)
                  (upd> (: home msg))
                  (and *Bar (upd> *Bar)) )
               ,"Password" 20 ) )
         (and Prg (cons '(-|-) Prg))
         (quote
            (----)
            (gui 'msg '(+Upd +Mono +Label)
               '(set> This
                  (and *Login
                     (pack "'" (get *Login 'nm) ,"' logged in") ) ) )
            (gui '(+Able +Button) '*Login "" ,"logout"
               '(logout) ) ) ) ) )


### Role ###
(class +Role +Entity)

(rel nm     (+Need +Key +String))               # Role name
(rel perm   (+List +Symbol))                    # Permission list
(rel usr    (+List +Joint) role (+User))        # Associated users

(dm url> ()
   (and (may RoleAdmin) (pack "lib/role.l?*ID=" (ht:Fmt This))) )


### User ###
(class +User +Entity)

(rel nm     (+Need +Key +String))               # User name
(rel pw     (+String))                          # Password
(rel role   (+Joint) usr (+Role))               # User role

(dm url> ()
   (and (may UserAdmin) (pack "lib/user.l?*ID=" (ht:Fmt This))) )


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


### GUI ###
(de choRole ()
   (choDialog ,"Role" '(nm +Role)) )

(de choUser ()
   (choDialog ,"User" '(nm +User)) )
