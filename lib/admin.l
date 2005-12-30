# 21nov05abu
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

(de pwForm (Back Fore . Prg)
   (form '(+Form) 300 120
      (append
         (list (list 'back Back) (list 'fore Fore))
         (quote
            (gui 'nm '(+TextField) ,"Name" 20)
            (gui 'pw '(+End +PwField)
               '(act> (: home login))
               ,"Password" 20 ) )
         (and Prg (cons '(-|-) Prg))
         (quote
            (----)
            (gui 'msg '(+Upd +Mono +Label)
               '(set> This
                  (and *Login
                     (pack "'" (get *Login 'nm) ,"' logged in") ) )
               "" "    " )
            (----)
            (row
               (gui 'login '(+Button) "" ,"login"
                  '(if (login (: home nm str) (: home pw str))
                     (prog
                        (msg *Pid " * " (stamp) " " (: home nm str))
                        (upd> (: home msg))
                        (and *Bar (upd> *Bar)) )
                     (msg *Pid " ?! " (val> (: home nm)))
                     (set> (: home msg) ,"Permission denied") ) )
               (gui '(+Able +Button) '*Login "" ,"logout" '(logout)) ) ) ) ) )


### Role ###
(class +Role +Entity)

(rel nm     (+Need +Key +String))               # Role name
(rel perm   (+List +Symbol))                    # Permission list
(rel usr    (+List +Joint) role (+User))        # Associated users

(dm url> ()
   (and (may RoleAdmin) (pack "lib/role.l?*ID=" (ht:Fmt This))) )

(de roleForm (Back Fore)
   (form '(+ObjForm) '(+Role) *ID 600 400
      (append
         (list (list 'back Back) (list 'fore Fore))
         (quote
            (row
               (gui '(+E/R +TextField) '(nm : home obj) ,"Name" 40)
               (stepButton 'nm '+Role) )
            (---- NIL)
            (gui '(+E/R +Array) '(perm : home obj) ,"Permissions" 4
               '((S) (gui '(+Checkbox) (val S)))
               *Perms
               '((L) (mapcar '((S) (memq S L)) *Perms))
               '((L) (mapcan '((F S) (and F (cons S))) L *Perms)) )
            (---- T)
            (gui '(+E/R +ListChart) '(usr : home obj)
               6 (list ,"User")
               '((gui '(+Obj +TextField) '(nm +User) "" 30)) )
            (----)
            (row (choButton '(choRole)) (delButton)) ) ) ) )


### User ###
(class +User +Entity)

(rel nm     (+Need +Key +String))               # User name
(rel pw     (+String))                          # Password
(rel role   (+Joint) usr (+Role))               # User role

(dm url> ()
   (and (may UserAdmin) (pack "lib/user.l?*ID=" (ht:Fmt This))) )

(de userForm (Back Fore)
   (form '(+ObjForm) '(+User) *ID 500 150
      (append
         (list (list 'back Back) (list 'fore Fore))
         (quote
            (row
               (gui '(+E/R +TextField) '(nm : home obj)  ,"Name" 20)
               (stepButton 'nm '+User) )
            (---- NIL)
            (if (may Password)
               (gui '(+E/R +Rsa +Mono +TextField)
                  '(pw : home obj)
                  ,"Password" 12 )
               (txt ,"Password" "----") )
            (gui '(+Able +E/R +Obj +TextField)
               '(may RoleAdmin)
               '(role : home obj)
               '(nm +Role)
               ,"Role" 40 )
            (----)
            (row (choButton '(choUser)) (delButton)) ) ) ) )


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
