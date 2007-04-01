# 24mar07abu
# (c) Software Lab. Alexander Burger

(must "Inventory" Report)

(menu
   (<h3> NIL ,"Inventory")
   (form NIL
      (<grid> "-.-"
         ,"Number" NIL
         (prog
            (gui 'from '(+NumField) 10)
            (prin " - ")
            (gui 'till '(+NumField) 10) )
         ,"Description" NIL (gui 'nm '(+TextField) 30)
         ,"Supplier" (gui '(+ChoButton) '(choCuSu (field 1)))
         (gui 'sup '(+Obj +TextField) '(nm +CuSu) 30) )
      (----)
      (gui '(+Button) ,"Show Report"
         '(appendix
            (<table> 'chart NIL
               (quote
                  (align)
                  (NIL ,"Description")
                  (align ,"Inventory")
                  (NIL ,"Supplier")
                  NIL
                  (NIL ,"Zip")
                  (NIL ,"City")
                  (align ,"Price") )
               (pilog
                  (quote
                     @Rng (cons (val> (: from)) (or (val> (: till)) T))
                     @Nm (val> (: nm))
                     @Sup (val> (: sup))
                     (select (@Item)
                        ((nr +Item @Rng) (nm +Item @Nm) (sup +Item @Sup))
                        (range @Rng @Item nr)
                        (tolr @Nm @Item nm)
                        (same @Sup @Item sup) ) )
                  (with @Item
                     (<row> (alternating)
                        (htObj (: nr) This)
                        (htObj (: nm) This)
                        (ht:Prin (cnt> This))
                        (htObj (: sup nm) (: sup))
                        (ht:Prin (: sup nm2))
                        (ht:Prin (: sup plz))
                        (ht:Prin (: sup ort))
                        (prin (money (: pr))) ) ) ) ) ) ) ) )
