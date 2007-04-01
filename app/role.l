# 23mar07abu
# (c) Software Lab. Alexander Burger

(must "Role Administration" RoleAdmin)

(menu
   (ifn *ID
      (prog
         (<h3> NIL ,"Select" " " ,"Role")
         (form 'dialog (choDlg T ,"Role" '(nm +Role))) )
      (<h3> NIL ,"Role Administration")
      (form NIL
         (<spread>
            (<h3> NIL (<id> (: nm)))
            (delButton '(may Delete)
               '(text ,"Role '@1'" (: top 1 obj nm)) )
            (choButton '(choDlg T ,"Role" '(nm +Role)))
            (stepBtn 'nm '+Role) )
         (<grid> 2
            ,"Name" (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Role" 30)
            (gui '(+E/R +Fmt +Chart)
               '(perm : home obj)
               '((Val) (mapcar '((S) (list S (memq S Val))) *Perms))
               '((Lst) (mapcan '((L P) (and (cadr L) (cons P))) Lst *Perms))
               2 )
            (do (length *Perms)
               (<row> NIL
                  (gui 1 '(+Set +TextField) '((Sym) (val (val Sym))))
                  (gui 2 '(+Checkbox)) ) ) )
         (gui '(+/R +Chart) '(usr : home obj) 1 list car)
         (<table> 'chart ,"User" NIL
            (do 6
               (<row> (alternating)
                  (gui 1 '(+Obj +TextField) '(nm +User)) ) ) )
         (<spread> (scroll 6) (editButton)) ) ) )
