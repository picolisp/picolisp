# 21may03abu
# (c) Software Lab. Alexander Burger

# *Login *Perms

### Login ###
(de login (Nm Pw)
   (and
      (db 'nm '+User Nm 'pw Pw)
      (setq *Login @) ) )

(de pwForm ()
   (form '(+Form) 360 120
      (quote
         (gui 'nm '(+TextField) "Name" 20)
         (gui 'pw '(+Chk +End +PwField)
            '(unless (login (val> (: home nm)) (val> (: home pw)))
               (msg *Pid " ?! " (val> (: home nm)))
               `(_ "Permission denied") )
            '(prog
               (msg *Pid " + " (stamp) " " (val> (: home nm)))
               (flush)
               (upd> (: home msg))
               (upd> *Bar) )
            `(_ "Password") 20 )
         (----)
         (gui 'msg '(+Upd +Label)
            '(set> This
               (and *Login
                  (pack "'" (get *Login 'nm) `(_ "' logged in")) ) )
            ""
            "                                        " ) ) ) )


### Role ###
(class +Role +Entity)

(rel nm     (+Need +Key +String))               # Role name
(rel perm   (+List +Symbol))                    # Permission list
(rel usr    (+List +Joint) role (+User))        # Associated users

(dm url> ()
   (and (may T RoleAdmin) (pack "lib/role.l?*ID=" This)) )


### User ###
(class +User +Entity)

(rel nm     (+Need +Key +String))               # User name
(rel pw     (+String))                          # Password
(rel role   (+Joint) usr (+Role))               # User role

(dm url> ()
   (and (may T UserAdmin) (pack "lib/user.l?*ID=" This)) )


### Permission management ###
(de permission Lst
   (while Lst
      (queue '*Perms (car Lst))
      (def (pop 'Lst) (pop 'Lst)) ) )

(de may (Flg . Args)
   (and
      Flg
      (find
         '((X)
            (memq X (get *Login 'role 'perm)) )
         Args ) ) )

(de must Args
   (unless
      (find
         '((X)
            (memq X (get *Login 'role 'perm)) )
         (cdr Args) )
      (quit "No permission" (car Args)) ) )


### GUI ###
(de choRole ()
   (choDialog `(_ "Role") '(nm +Role)) )

(de choUser ()
   (choDialog `(_ "User") '(nm +User)) )
