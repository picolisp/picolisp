# 25jan08abu
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
         ,"Customer" (gui '(+ChoButton) '(choCuSu (field 1)))
         (gui '(+Var +Obj +TextField) '*SalCus '(nm +CuSu) 30) )
      (----)
      (gui '(+ShowButton) NIL
         '(csv ,"Sales"
            (<table> 'chart NIL
               '((align) (NIL ,"Date") (NIL ,"Customer") NIL (NIL ,"Zip") (NIL ,"City") (align ,"Total"))
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
                           (inc 'Sum N) ) ) )
                  (<row> NIL
                     (<strong> ,"Total") - - - - -
                     (<strong> (prin (money Sum))) ) ) ) ) ) ) )

# vi:et:ts=3:sw=3
