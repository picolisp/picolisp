# 25jun07abu
# (c) Software Lab. Alexander Burger

(must "Order" Order)

(menu
   (ifn *ID
      (<p> NIL
         (<h3> NIL ,"Select" " " ,"Order")
         (form 'dialog (choOrd T)) )
      (<h3> NIL ,"Order")
      (form NIL
         (<h2> NIL (<id> (: nr)))
         (panel T ,"Order No. @1" '(may Delete) '(choOrd T) 'nr '+Ord)
         (<grid> 4
            ,"Date" NIL
            (gui '(+E/R +DateField) '(dat : home obj) 10)
            (gui '(+View +TextField)
               '(text ,"(@1 Positions)" (length (: home obj pos))) )
            ,"Customer" (gui '(+ChoButton) '(choCuSu (field 1)))
            (gui '(+E/R +Obj +TextField) '(cus : home obj) '(nm +CuSu) 30)
            (gui '(+Lock +/R +TextField) '(ort : home obj cus) 30) )
         (----)
         (gui '(+Set +E/R +Chart) '((L) (filter bool L)) '(pos : home obj) 8
            '((Pos I)
               (with Pos
                  (list I NIL (: itm) (or (: pr) (: itm pr)) (: cnt) (sum> Pos)) ) )
            '((L D)
               (cond
                  (D
                     (put!> D 'itm (caddr L))
                     (put!> D 'pr (cadddr L))
                     (put!> D 'cnt (get L 5))
                     (and (get D 'itm) D) )
                  ((caddr L)
                     (new! '(+Pos)
                        'ord (: home obj)
                        'itm (caddr L) ) ) ) ) )
         (<table> NIL NIL
            '((align) NIL (NIL ,"Item") (NIL ,"Price") (NIL ,"Quantity") (NIL ,"Total") (btn) (btn))
            (do 8
               (<row> NIL
                  (gui 1 '(+NumField))
                  (gui 2 '(+ChoButton) '(choItem (field 1)))
                  (gui 3 '(+Obj +TextField) '(nm +Item) 30)
                  (gui 4 '(+FixField) 2 12)
                  (gui 5 '(+NumField) 8)
                  (gui 6 '(+Lock +FixField) 2 12)
                  (gui 7 '(+DelRowButton))
                  (gui 8 '(+BubbleButton)) ) )
            (<row> NIL NIL NIL (scroll 8) NIL NIL
               (gui '(+View +FixField) '(sum> (: home obj)) 2 12) ) )
         (<spread>
            (gui '(+Rid +Button) ,"PDF-Print"
               '(psOut 0 "print" (ps> (: home obj))) )
            (editButton T) ) ) ) )

# vi:et:ts=3:sw=3
