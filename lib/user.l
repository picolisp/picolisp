# 14mar02abu
# (c) Software Lab. Alexander Burger

(must "Benutzer" UserAdmin)

(html "Benutzer"
   (<id> "Benutzer" (: nm))
   <hr>
   (new '(+ObjForm) '(+User) *ID 800 120
      (quote
         (gui '(+E/R +TextField) '(nm : home obj)  "Name" 20)
         (row
            (if (may T Password)
               (gui '(+E/R +Rsa +Mono +TextField)
                  '(pw : home obj)
                  "Passwort" 12 )
               (txt "Passwort" "----") )
            (gui '(+Able +E/R +Obj +TextField)
               '(may T RoleAdmin)
               '(role : home obj)
               '(nm +Role)
               "Rolle" 40 ) )
         (----)
         (row
            (choButton '(choUser))
            (delButton) ) ) )
   <hr> )
