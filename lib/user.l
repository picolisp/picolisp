# 20jan03abu
# (c) Software Lab. Alexander Burger

(must `(_ "User") UserAdmin)

(html `(_ "User")
   (<id> `(_ "User") (: nm))
   <hr>
   (new '(+ObjForm) '(+User) *ID 800 120
      (quote
         (gui '(+E/R +TextField) '(nm : home obj)  `(_ "Name") 20)
         (row
            (if (may T Password)
               (gui '(+E/R +Rsa +Mono +TextField)
                  '(pw : home obj)
                  `(_ "Password") 12 )
               (txt `(_ "Password") "----") )
            (gui '(+Able +E/R +Obj +TextField)
               '(may T RoleAdmin)
               '(role : home obj)
               '(nm +Role)
               `(_ "Role") 40 ) )
         (----)
         (row
            (choButton '(choUser))
            (delButton) ) ) )
   <hr> )
