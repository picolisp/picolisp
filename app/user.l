# 23mar07abu
# (c) Software Lab. Alexander Burger

(must "User Administration" UserAdmin)

(menu
   (ifn *ID
      (prog
         (<h3> NIL ,"Select" " " ,"User")
         (form 'dialog (choDlg T ,"User" '(nm +User))) )
      (<h3> NIL ,"User Administration")
      (form NIL
         (<spread>
            (<h3> NIL (<id> (: nm)))
            (delButton '(may Delete)
               '(text ,"User '@1'" (: top 1 obj nm)) )
            (choButton '(choDlg T ,"User" '(nm +User)))
            (stepBtn 'nm '+User) )
         (<grid> 2
            ,"Login Name" (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"User" 30)
            ,"Password"
            (if (may Password)
               (gui '(+E/R +TextField) '(pw : home obj) 30)
               (prin "----") )
            ,"Role"
            (gui '(+Able +E/R +Obj +TextField)
               '(may RoleAdmin)
               '(role : home obj)
               '(nm +Role)
               (collect 'nm '+Role NIL T 'nm) )
            ,"Full Name" (gui '(+E/R +TextField) '(nam : home obj) 40)
            ,"Phone" (gui '(+E/R +TelField) '(tel : home obj) 40)
            ,"EMail" (gui '(+E/R +MailField) '(em : home obj) 40) )
         (<spread> NIL (editButton)) ) ) )
