# 21jan13abu
# (c) Software Lab. Alexander Burger

(must "User Administration" UserAdmin)

(menu ,"User Administration"
   (idForm ,"User" ,"Users" 'nm '+User T '(may Delete) '((: nm))
      (<grid> 2
         ,"Login Name" (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"User" 30)
         ,"Password"
         (gui '(+Tip +Able +E/R +Fmt +TextField)
            '(and (may Password) (val> This))
            '(may Password)
            '(pw : home obj)
            '((V) (and V "****"))
            '((V)
               (if (= V "****")
                  (: home obj pw)
                  (passwd V (: home obj pw)) ) )
            30 )
         ,"Role"
         (gui '(+Able +E/R +Obj +TextField)
            '(may RoleAdmin)
            '(role : home obj)
            '(nm +Role)
            T )
         ,"Full Name" (gui '(+E/R +TextField) '(nam : home obj) 40)
         ,"Phone" (gui '(+E/R +TelField) '(tel : home obj) 40)
         ,"EMail" (gui '(+E/R +MailField) '(em : home obj) 40) )
      (<spread> NIL (editButton T)) ) )

# vi:et:ts=3:sw=3
