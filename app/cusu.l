# 24mar07abu
# (c) Software Lab. Alexander Burger

(must "Customer/Supplier" Customer)

(menu
   (ifn *ID
      (<p> NIL
         (<h3> NIL ,"Select" " " ,"Customer/Supplier")
         (form 'dialog (choCuSu T)) )
      (<h3> NIL ,"Customer/Supplier")
      (form NIL
         (<spread>
            (<h3> NIL (<id> (: nm)))
            (delButton '(may Delete)
               '(text ,"Customer/Supplier No. @1" (: top 1 obj nr)) )
            (choButton '(choCuSu T))
            (stepBtn 'nr '+CuSu) )
         (<tab>
            (,"Name"
               (<grid> 2
                  ,"Number" (gui '(+E/R +NumField) '(nr : home obj) 10)
                  ,"Name" (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Name" 40)
                  ,"Name 2" (gui '(+E/R +TextField) '(nm2 : home obj) 40) ) )
            (,"Address"
               (<grid> 2
                  ,"Street" (gui '(+E/R +TextField) '(str : home obj) 40)
                  NIL NIL
                  ,"Zip" (gui '(+E/R +TextField) '(plz : home obj) 10)
                  ,"City" (gui '(+E/R +TextField) '(ort : home obj) 40)
                  ,"Country" (gui '(+E/R +TextField) '(cty : home obj) 40) ) )
            (,"Contact"
               (<grid> 2
                  ,"Phone" (gui '(+E/R +TelField) '(tel : home obj) 40)
                  ,"Fax" (gui '(+E/R +TelField) '(fax : home obj) 40)
                  ,"Mobile" (gui '(+E/R +TelField) '(mob : home obj) 40)
                  ,"EMail" (gui '(+E/R +MailField) '(em : home obj) 40) ) )
            (,"Memo"
               (<br> (gui '(+BlobField) '(txt : home obj) 60 8)) ) )
         (<spread> NIL (editButton)) ) ) )
