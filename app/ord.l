# 25may15abu
# (c) Software Lab. Alexander Burger

(must "Order" Order)

(menu ,"Order"
   (idForm ,"Order" '(choOrd) 'nr '+Ord T '(may Delete) '((: nr))
      (<grid> 4
         ,"Date" NIL
         (gui '(+E/R +DateField) '(dat : home obj) 10)
         (gui '(+View +TextField)
            '(text ,"(@1 Positions)" (length (: home obj pos))) )
         ,"Customer" (choCuSu 0)
         (gui '(+E/R +Obj +TextField) '(cus : home obj) '(nm +CuSu) 30)
         (gui '(+View +TextField) '(field -1 'obj 'ort) 30) )
      (--)
      (gui '(+Set +E/R +Chart) '((L) (filter bool L)) '(pos : home obj) 8
         '((Pos I)
            (with Pos
               (list I NIL (: itm) (or (: pr) (: itm pr)) (: cnt) (sum> Pos)) ) )
         '((L D)
            (cond
               (D
                  (put!> D 'itm (caddr L))
                  (put!> D 'pr (cadddr L))
                  (put!> D 'cnt (; L 5))
                  (and (; D itm) D) )
               ((caddr L)
                  (new! '(+Pos) 'itm @) ) ) ) )
      (<table> NIL NIL
         '(("align em2") (btn) (NIL ,"Item") (NIL ,"Price") (NIL ,"Quantity") (NIL ,"Total"))
         (do 8
            (<row> NIL
               (gui 1 '(+NumField))
               (choItem 2)
               (gui 3 '(+Obj +TextField) '(nm +Item) 30)
               (gui 4 '(+FixField) 2 12)
               (gui 5 '(+NumField) 8)
               (gui 6 '(+Sgn +Lock +FixField) 2 12)
               (gui 7 '(+DelRowButton))
               (gui 8 '(+BubbleButton)) ) )
         (<row> NIL NIL NIL (scroll 8 T) NIL NIL
            (gui '(+Sgn +View +FixField) '(sum> (: home obj)) 2 12) ) )
      (<spread>
         (gui '(+Rid +Button) ,"PDF-Print"
            '(if (check> (: home obj))
               (note ,"Can't print order" (uniq @))
               (url (ps> (: home obj))) ) )
         (editButton T) ) ) )

# vi:et:ts=3:sw=3
