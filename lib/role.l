# 14jun03abu
# (c) Software Lab. Alexander Burger

(must `(_ "Role") RoleAdmin)

(html `(_ "Role")
   (<id> `(_ "Role") (: nm))
   <hr>
   (form '(+ObjForm) '(+Role) *ID 800 500
      (quote
         (row
            (gui '(+E/R +TextField) '(nm : home obj) `(_ "Name") 40)
            (stepButton 'nm '+Role) )
         (----)
         (gui '(+E/R +Array) '(perm : home obj) `(_ "Permissions") 4
            '((S) (gui '(+Checkbox) (val S)))
            *Perms
            '((L) (mapcar '((S) (memq S L)) *Perms))
            '((L) (mapcan '((F S) (and F (cons S))) L *Perms)) )
         (---- T)
         (gui '(+E/R +ListChart) '(usr : home obj)
            6 (list `(_ "User"))
            '((gui '(+Obj +TextField) '(nm +User) "" 30)) )
         (----)
         (row
            (choButton '(choRole))
            (delButton) ) ) )
   <hr> )
