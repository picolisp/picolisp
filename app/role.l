# 25jan08abu
# (c) Software Lab. Alexander Burger

(must "Role Administration" RoleAdmin)

(menu ,"Role Administration"
   (ifn *ID
      (prog
         (<h3> NIL ,"Select" " " ,"Role")
         (form 'dialog (choDlg T ,"Roles" '(nm +Role))) )
      (<h3> NIL ,"Role Administration")
      (form NIL
         (<h2> NIL (<id> (: nm)))
         (panel T ,"Role '@1'" '(may Delete) '(choDlg T ,"Roles" '(nm +Role)) 'nm '+Role)
         (<table> NIL NIL NIL
            (<row> NIL
               ,"Name"
               (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Role" 30) )
            (gui '(+E/R +Fmt +Chart)
               '(perm : home obj)
               '((Val) (mapcar '((S) (list S (memq S Val))) *Perms))
               '((Lst) (mapcan '((L P) (and (cadr L) (cons P))) Lst *Perms))
               2 )
            (do (length *Perms)
               (<row> NIL
                  (gui 1 '(+Set +TextField) '((Sym) (val (val Sym))))
                  (gui 2 '(+Checkbox)) ) ) )
         (gui '(+/R +Chart) '(usr : home obj) 1 list)
         (<table> 'chart ,"User" NIL
            (do 6
               (<row> (alternating)
                  (gui 1 '(+Obj +TextField) '(nm +User)) ) ) )
         (<spread> (scroll 6) (editButton T)) ) ) )

# vi:et:ts=3:sw=3
