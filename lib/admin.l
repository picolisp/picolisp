# 08mar07abu
# (c) Software Lab. Alexander Burger

(load "lib/adm.l")

(dm (url> . +Role) ()
   (and (may RoleAdmin) (pack "lib/role.l?*ID=" (ht:Fmt This))) )

(dm (url> . +User) ()
   (and (may UserAdmin) (pack "lib/user.l?*ID=" (ht:Fmt This))) )


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
                  '(ifn (login (: home nm str) (: home pw str))
                     (set> (: home msg) ,"Permission denied")
                     (upd> (: home msg))
                     (and *Bar (upd> *Bar)) ) )
               (gui '(+Able +Button) '*Login "" ,"logout"
                  '(prog
                     (logout)
                     (upd> (: home msg))
                     (and *Bar (upd> *Bar)) ) ) ) ) ) ) )

(de roleForm (Back Fore)
   (form '(+ObjForm) '(+Role) *ID 800 400
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

(de userForm (Back Fore)
   (form '(+ObjForm) '(+User) *ID 600 150
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

### GUI ###
(de choRole ()
   (choDialog ,"Role" '(nm +Role)) )

(de choUser ()
   (choDialog ,"User" '(nm +User)) )
