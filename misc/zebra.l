# 19may02abu
# (c) Software Lab. Alexander Burger

# Prolog (Giannesini/Kanoui, Pasero, van Caneghem) p.95

# (? (haus @Farbe @Person @Getraenk @Haustier @Zigaretten))
(be haus (@Farbe @Person @Getraenk @Haustier @Zigaretten)
   (permute (Rot Blau Gruen Gelb Weiss) @Farbe)
   (equal @Farbe (@ Blau . @))
   (nach @Farbe Weiss @Farbe Gruen)

   (permute (Norweger Englaender Spanier Japaner Ukrainer) @Person)
   (equal @Person (Norweger . @))
   (platz @Person Englaender @Farbe Rot)

   (permute (Tee Kaffee Milch Wasser Wein) @Getraenk)
   (equal @Getraenk (@ @ Milch . @))
   (platz @Getraenk Kaffee @Farbe Gruen)
   (platz @Getraenk Tee @Person Ukrainer)

   (permute (Hund Schnecken Fuchs Pferd Zebra) @Haustier)
   (platz @Haustier Hund @Person Spanier)

   (permute (Kurmark Lord Marlboro HB Ernte23) @Zigaretten)
   (platz @Zigaretten Kurmark @Haustier Schnecken)
   (platz @Zigaretten Lord @Farbe Gelb)
   (platz @Zigaretten HB @Getraenk Wein)
   (platz @Zigaretten Ernte23 @Person Japaner)
   (neben @Zigaretten Marlboro @Haustier Fuchs)
   (neben @Zigaretten Lord @Haustier Pferd)

   (@ mapc println
      (-> @Farbe)
      (-> @Person)
      (-> @Haustier)
      (-> @Getraenk)
      (-> @Zigaretten) ) )

(be platz ((@A . @X) @A (@B . @Y) @B))
(be platz ((@ . @X) @A (@ . @Y) @B)
   (platz @X @A @Y @B) )

(be nach ((@A . @X) @A (@ @B . @Y) @B))
(be nach ((@ . @X) @A (@ . @Y) @B)
   (nach @X @A @Y @B) )

(be vor ((@ @A . @X) @A (@B . @Y) @B))
(be vor ((@ . @X) @A (@ . @Y) @B)
   (vor @X @A @Y @B) )

(be neben (@X @A @Y @B) (vor @X @A @Y @B))
(be neben (@X @A @Y @B) (nach @X @A @Y @B))
