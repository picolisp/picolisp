# 24nov16abu
# (c) Software Lab. Alexander Burger

### PDF-Print ###
(dm (ps> . +Ord) ()
   (pdf *A4-DX *A4-DY (tmp ,"Order" (: nr) ".pdf")
      (font (11 . "serif"))
      (width "0.5")
      (let (I 0  Fmt (14 6 200 80 80 80))
         (for
            (Lst (: pos)
               (page
                  (image "@img/7fachLogo.png" "image/png" 420 0 120)
                  (ifn (=1 *Page)
                     (indent 60
                        (down 40)
                        (font 9 (ps (text ,"Page @1" *Page)))
                        (down 80)
                        (hline 0 470 -8) )
                     (window 380 120 120 30
                        (font 21 (ps 0 ,"Order")) )
                     (brief NIL 8 "7fach GmbH, Bawaria"
                        (ps)
                        (with (: cus)
                           (ps
                              (pack
                                 (and (: sal) (pack (: sal nm) " "))
                                 (: nm2) " " (: nm) ) )
                           (ps (: str))
                           (ps (pack (: plz) " " (: ort))) ) )
                     (window 360 280 240 60
                        (let Fmt (80 12 60)
                           (table Fmt ,"Customer" ":" (ps NIL (: cus nr)))
                           (table Fmt ,"Order" ":" (ps NIL (: nr)))
                           (table Fmt ,"Date" ":" (ps (datStr (: dat)))) ) )
                     (down 360) )
                  (indent 60
                     (hline 0 470 -8)
                     (bold
                        (table Fmt NIL NIL
                           (ps ,"Item")
                           (ps T ,"Price")
                           (ps T ,"Quantity")
                           (ps T ,"Total") ) )
                     (hline 4 470 -8)
                     (loop
                        (down 4)
                        (with (++ Lst)
                           (table Fmt
                              (ps T (inc 'I)) NIL
                              (ps (: itm nm))
                              (ps T (money (: pr)))
                              (ps T (: cnt))
                              (ps T (money (sum> This))) ) )
                        (NIL Lst
                           (hline 4 470 -8)
                           (down 4)
                           (table Fmt NIL NIL NIL NIL NIL (ps T (money (sum> This))))
                           (hline 4 470 -8)
                           NIL )
                        (T (>= *Pos 720)
                           (hline 4 470 -8)
                           (down 12)
                           (font 9 (ps (text ,"Continued on page @1" (inc *Page))))
                           T ) ) ) ) ) ) ) ) )

# vi:et:ts=3:sw=3
