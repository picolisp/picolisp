# 14mar02abu
# (c) Software Lab. Alexander Burger

(must "Rolle" RoleAdmin)

(html "Rolle"
   (<id> "Rolle" (: nm))
   <hr>
   (new '(+ObjForm) '(+Role) *ID 800 500
      (quote
         (gui '(+E/R +TextField) '(nm : home obj)  "Bezeichnung" 40)
         (----)
         (gui '(+E/R +Array) '(perm : home obj) "Berechtigungen" 4
            '((S) (gui '(+Checkbox) (val S)))
            *Perms
            '((L) (mapcar '((S) (memq S L)) *Perms))
            '((L) (mapcan '((F S) (and F (cons S))) L *Perms)) )
         (---- T)
         (gui '(+E/R +ListChart) '(usr : home obj)
            6 '("Benutzer")
            '((gui '(+Obj +TextField) '(nm +User) "" 30)) )
         (----)
         (row
            (choButton '(choRole))
            (delButton) ) ) )
   <hr> )
