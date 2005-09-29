# 30jul05abu
# (c) Software Lab. Alexander Burger

(must "Role" RoleAdmin)

(html ,"Role"
   (<id> ,"Role" (: nm))
   <hr>
   (form '(+ObjForm) '(+Role) *ID 600 400
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
         (row
            (choButton '(choRole))
            (delButton) ) ) )
   <hr> )
