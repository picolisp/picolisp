# 05jan12abu
# (c) Software Lab. Alexander Burger

(must "Sales" Report)

(menu ,"Sales"
   (<h3> NIL ,"Sales")
   (form NIL
      (<grid> "-.-"
         ,"Date" NIL
         (prog
            (gui '(+Var +DateField) '*SalFrom 10)
            (prin " - ")
            (gui '(+Var +DateField) '*SalTill 10) )
         ,"Customer" (choCuSu 0)
         (gui '(+Var +Obj +TextField) '*SalCus '(nm +CuSu) 30) )
      (--)
      (gui '(+ShowButton) NIL
         '(csv ,"Sales"
            (<table> 'chart NIL
               (<!>
                  (quote
                     (align)
                     (NIL ,"Date")
                     (NIL ,"Customer")
                     NIL
                     (NIL ,"Zip")
                     (NIL ,"City")
                     (align ,"Total") ) )
               (catch NIL
                  (let Sum 0
                     (pilog
                        (quote
                           @Rng (cons *SalFrom (or *SalTill T))
                           @Cus *SalCus
                           (select (@Ord)
                              ((dat +Ord @Rng) (cus +Ord @Cus))
                              (range @Rng @Ord dat)
                              (same @Cus @Ord cus) ) )
                        (with @Ord
                           (let N (sum> This)
                              (<row> (alternating)
                                 (<+> (: nr) This)
                                 (<+> (datStr (: dat)) This)
                                 (<+> (: cus nm) (: cus))
                                 (<+> (: cus nm2))
                                 (<+> (: cus plz))
                                 (<+> (: cus ort))
                                 (<-> (money N)) )
                              (inc 'Sum N) ) )
                        (at (0 . 10000) (or (flush) (throw))) )
                     (<row> 'nil
                        (<strong> ,"Total") - - - - -
                        (<strong> (prin (money Sum))) ) ) ) ) ) ) ) )

# vi:et:ts=3:sw=3
