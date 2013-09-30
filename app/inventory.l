# 15sep13abu
# (c) Software Lab. Alexander Burger

(must "Inventory" Report)

(menu ,"Inventory"
   (<h3> NIL ,"Inventory")
   (form NIL
      (<grid> "-.-"
         ,"Number" NIL
         (prog
            (gui '(+Var +NumField) '*InvFrom 10)
            (prin " - ")
            (gui '(+Var +NumField) '*InvTill 10) )
         ,"Description" NIL (gui '(+Var +TextField) '*InvNm 30)
         ,"Supplier" (choCuSu 0)
         (gui '(+Var +Obj +TextField) '*InvSup '(nm +CuSu) 30) )
      (--)
      (gui '(+ShowButton) NIL
         '(csv ,"Inventory"
            (<table> 'chart NIL
               (<!>
                  (quote
                     (align)
                     (NIL ,"Description")
                     (align ,"Inventory")
                     (NIL ,"Supplier")
                     NIL
                     (NIL ,"Zip")
                     (NIL ,"City")
                     (align ,"Price") ) )
               (catch NIL
                  (pilog
                     (quote
                        @Rng (cons *InvFrom (or *InvTill T))
                        @Nm *InvNm
                        @Sup *InvSup
                        (select (@Item)
                           ((nr +Item @Rng) (nm +Item @Nm) (sup +Item @Sup))
                           (range @Rng @Item nr)
                           (part @Nm @Item nm)
                           (same @Sup @Item sup) ) )
                     (with @Item
                        (<row> (alternating)
                           (<+> (: nr) This)
                           (<+> (: nm) This)
                           (<+> (cnt> This))
                           (<+> (: sup nm) (: sup))
                           (<+> (: sup nm2))
                           (<+> (: sup plz))
                           (<+> (: sup ort))
                           (<-> (money (: pr))) ) )
                     (at (0 . 10000) (or (flush) (throw))) ) ) ) ) ) ) )

# vi:et:ts=3:sw=3
