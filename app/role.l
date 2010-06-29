# 22apr10abu
# (c) Software Lab. Alexander Burger

(must "Role Administration" RoleAdmin)

(menu ,"Role Administration"
   (ifn *ID
      (prog
         (<h3> NIL ,"Select" " " ,"Role")
         (form 'dialog (choDlg NIL ,"Roles" '(nm +Role))) )
      (<h3> NIL ,"Role Administration")
      (form NIL
         (<h2> NIL (<id> (: nm)))
         (panel T (pack ,"Role" " '@1'") '(may Delete) '(choDlg NIL ,"Roles" '(nm +Role)) 'nm '+Role)
         (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Role" 30 ,"Name")
         (<table> NIL NIL NIL
            (gui '(+E/R +Fmt +Chart)
               '(perm : home obj)
               '((Val) (mapcar '((S) (list S (memq S Val))) *Perms))
               '((Lst) (extract '((L P) (and (cadr L) P)) Lst *Perms))
               2 )
            (do (length *Perms)
               (<row> NIL
                  (gui 1 '(+Set +TextField) '((Sym) (val (val Sym))))
                  (gui 2 '(+Checkbox)) ) ) )
         (gui '(+/R +Chart) '(usr : home obj) 1 list)
         (<table> 'chart ,"User" NIL
            (do 8
               (<row> (alternating)
                  (gui 1 '(+Obj +TextField) '(nm +User)) ) ) )
         (<spread> (scroll 8 T) (editButton T)) ) ) )

# vi:et:ts=3:sw=3
