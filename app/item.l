# 03oct16abu
# (c) Software Lab. Alexander Burger

(must "Item" Item)

(menu ,"Item"
   (idForm ,"Item" '(choItem) 'nr '+Item T '(may Delete) '((: nr) " -- " (: nm))
      (<grid> 4
         ,"Number" NIL (gui '(+E/R +NumField) '(nr : home obj) 10) NIL
         ,"Description" NIL (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Item" 30) NIL
         ,"Supplier" (choCuSu 0)
         (gui '(+E/R +Obj +TextField) '(sup : home obj) '(nm +CuSu) 30)
         (gui '(+View +TextField) '(: home obj sup ort) 30)
         ,"Inventory" NIL (gui '(+E/R +NumField) '(inv : home obj) 12)
         (gui '(+View +NumField) '(cnt> (: home obj)) 12)
         ,"Price" NIL (gui '(+E/R +FixField) '(pr : home obj) 2 12) )
      (--)
      (<grid> 2
         ,"Memo" (gui '(+BlobField) '(txt : home obj) 60 8)
         ,"Picture"
         (prog
            (gui '(+Able +UpField) '(not (: home obj jpg)) 30)
            (gui '(+Drop +Button) '(field -1)
               '(if (: home obj jpg) ,"Uninstall" ,"Install")
               '(cond
                  ((: home obj jpg)
                     (ask ,"Uninstall Picture?"
                        (put!> (: home top 1 obj) 'jpg NIL) ) )
                  ((: drop) (blob! (: home obj) 'jpg @)) ) ) ) )
      (<spread> NIL (editButton T))
      (gui '(+Upd +Img)
         '(and (: home obj jpg) (allow (blob (: home obj) 'jpg)))
         ,"Picture" ) ) )

# vi:et:ts=3:sw=3
