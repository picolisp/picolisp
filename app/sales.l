# 24mar07abu
# (c) Software Lab. Alexander Burger

(must "Sales" Report)

(menu
   (<h3> NIL ,"Sales")
   (form NIL
      (<grid> "-.-"
         ,"Date" NIL
         (prog
            (gui 'from '(+DateField) 10)
            (prin " - ")
            (gui 'till '(+DateField) 10) )
         ,"Customer" (gui '(+ChoButton) '(choCuSu (field 1)))
         (gui 'cus '(+Obj +TextField) '(nm +CuSu) 30) )
      (----)
      (gui '(+Button) ,"Show Report"
         '(appendix
            (<table> 'chart NIL
               '((align) (NIL ,"Date") (NIL ,"Customer") NIL (NIL ,"Zip") (NIL ,"City") (align ,"Total"))
               (let Sum 0
                  (pilog
                     (quote
                        @Rng (cons (val> (: from)) (or (val> (: till)) T))
                        @Cus (val> (: cus))
                        (select (@Ord)
                           ((dat +Ord @Rng) (cus +Ord @Cus))
                           (range @Rng @Ord dat)
                           (same @Cus @Ord cus) ) )
                     (with @Ord
                        (let N (sum> This)
                           (<row> (alternating)
                              (htObj (: nr) This)
                              (htObj (datStr (: dat)) This)
                              (htObj (: cus nm) (: cus))
                              (ht:Prin (: cus nm2))
                              (ht:Prin (: cus plz))
                              (ht:Prin (: cus ort))
                              (prin (money N)) )
                           (inc 'Sum N) ) ) )
                  (<row> NIL
                     (<strong> ,"Total") - - - - -
                     (<strong> (prin (money Sum))) ) ) ) ) ) ) )
