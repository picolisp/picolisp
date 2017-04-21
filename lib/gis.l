# 10mar17abu
# (c) Software Lab. Alexander Burger

(symbols 'gis 'pico)

(local) nm
(de nm (Lat Lon)
   (pack
      (round (- Lat 90.0))
      ", "
      (round (- Lon 180.0)) ) )

(local) fmt
(de fmt (Lat Str Lon)
   (when (or Lat Lon)
      (pack
         (format (- Lat 90.0) `*Scl)
         Str
         (format (- Lon 180.0) `*Scl) ) ) )


# Latitude Field
(local) +LatField
(class +LatField +Fmt +FixField)

(dm T @
   (pass super
      '((Num) (- Num 90.0))
      '((Lat) (+ Lat 90.0))
      `*Scl ) )

# Longitude Field
(local) +LonField
(class +LonField +Fmt +FixField)

(dm T @
   (pass super
      '((Num) (- Num 180.0))
      '((Lon) (+ Lon 180.0))
      `*Scl ) )

# Clickable position field
(local) [+LatLonField msg obj lt ln]
(class +LatLonField +TextField)

(dm T (Msg . @)
   (=: msg Msg)
   (pass super)
   (=: able) )

(dm set> (X Dn)
   (=: obj (car X))
   (=: lt (cadr X))
   (=: ln (cddr X))
   (super (fmt (: lt) ", " (: ln)) Dn) )

(dm js> ()
   (if (try (: msg) (: obj) (: lt) (: ln))
      (pack
         (fmt (: lt) ", " (: ln))
         "&+"
         (ht:Fmt (sesId (mkUrl @))) )
      (super) ) )

(dm val> ()
   (cons (: obj) (: lt) (: ln)) )

(dm show> ("Var")
   (showFld
      (if (try (: msg) (: obj) (: lt) (: ln))
         (<href>
            (fmt (: lt) ", " (: ln))
            (mkUrl @) )
         (super "Var") ) ) )

# Google Maps
(local) google
(de google (Ttl Lat Lon Zoom Tar)
   (<href> Ttl
      (pack "https://www.google.com/maps/@" (fmt Lat "," Lon) "," Zoom "z")
      Tar ) )

(local) <google>
(de <google> (Lat Lon DX DY)
   (prinl
      "<iframe width=\"" DX "\" height=\"" DY "\" frameborder=\"3\" \
      src=\"https://www.google.com/maps?source=s_q&amp;q="
      (fmt Lat "," Lon)
      "&amp;output=embed\"></iframe>" ) )

# vi:et:ts=3:sw=3
