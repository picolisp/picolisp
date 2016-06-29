# 15apr16abu
# (c) Software Lab. Alexander Burger

(must "Customer/Supplier" Customer)

(menu ,"Customer/Supplier"
   (idForm ,"Customer/Supplier" '(choCuSu) 'nr '+CuSu T '(may Delete)
      '((: nr) " -- " (: nm))
      (<hr>)
      (<tab>
         (,"Name"
            (<grid> 3
               ,"Number" NIL (gui '(+E/R +NumField) '(nr : home obj) 10)
               ,"Salutation" (choSal 0)
               (gui '(+E/R +Obj +TextField) '(sal : home obj) '(nm +Sal) 20)
               ,"Name" NIL (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Name" 40)
               ,"Name 2" NIL (gui '(+E/R +TextField) '(nm2 : home obj) 40) ) )
         (,"Address"
            (<grid> 2
               ,"Street" (gui '(+E/R +TextField) '(str : home obj) 40)
               NIL NIL
               ,"Zip" (gui '(+E/R +TextField) '(plz : home obj) 10)
               ,"City" (gui '(+E/R +TextField) '(ort : home obj) 40) ) )
         (,"Contact"
            (<grid> 2
               ,"Phone" (gui '(+E/R +TelField) '(tel : home obj) 40)
               ,"Fax" (gui '(+E/R +TelField) '(fax : home obj) 40)
               ,"Mobile" (gui '(+E/R +TelField) '(mob : home obj) 40)
               ,"EMail" (gui '(+E/R +MailField) '(em : home obj) 40) ) )
         ((pack (and (: obj txt) "@ ") ,"Memo")
            (gui '(+BlobField) '(txt : home obj) 60 8) ) )
      (<hr>)
      (<spread> NIL (editButton T)) ) )

# vi:et:ts=3:sw=3
