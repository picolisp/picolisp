# 08jun10abu
# (c) Software Lab. Alexander Burger

### PDF-Print ###
(dm (ps> . +Ord) ()
   (a4 (pack "Order" (: nr)))
   (font (12 . "Helvetica"))
   (eps "img/7fach.eps" 340 150 75)
   (window 380 120 120 30
      (font (21 . "Times-Roman") (ps ,"Order" 0)) )
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
         (table Fmt ,"Customer" ":" (ps (: cus nr)))
         (table Fmt ,"Order" ":" (ps (: nr)))
         (table Fmt ,"Date" ":" (ps (datStr (: dat)))) ) )
   (down 360)
   (indent 60 60)
   (let (Page 1  Fmt (14 6 200 80 80 80))
      (width "0.5"
         (hline 0 470 -8)
         (font "Helvetica-Bold"
            (table Fmt NIL NIL
               (ps ,"Item")
               (ps ,"Price" T)
               (ps ,"Quantity" T)
               (ps ,"Total" T) ) )
         (hline 4 470 -8)
         (pages 720
            (hline 0 470 -8)
            (down 12)
            (font 9 (ps (text ,"Continued on page @1" (inc 'Page))))
            (page T)
            (eps "img/7fach.eps" 340 150 75)
            (down 40)
            (font 9 (ps (text ,"Page @1" Page)))
            (down 80)
            (hline 0 470 -8) )
         (for (I . This) (: pos)
            (down 4)
            (table Fmt
               (ps I T) NIL
               (ps (: itm nm))
               (ps (money (: pr)) T)
               (ps (: cnt) T)
               (ps (money (sum> This)) T) ) )
         (pages)
         (hline 4 470 -8)
         (down 4)
         (table Fmt NIL NIL NIL NIL NIL (ps (money (sum> This)) T))
         (hline 4 470 -8) ) )
   (page) )

# vi:et:ts=3:sw=3
