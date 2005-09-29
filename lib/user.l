# 30jul05abu
# (c) Software Lab. Alexander Burger

(must "User" UserAdmin)

(html ,"User"
   (<id> ,"User" (: nm))
   <hr>
   (form '(+ObjForm) '(+User) *ID 500 150
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
         (row
            (choButton '(choUser))
            (delButton) ) ) )
   <hr> )
