# 10jul17abu
# (c) Software Lab. Alexander Burger

(push1 '*JS (allow "@lib/gis.js"))

(symbols 'gis 'pico)

(local) nm
(de nm (Lat Lon)
   (pack
      (round (- Lat 90.0))
      ", "
      (round (- Lon 180.0)) ) )

(local) [lat lon fmt]
(de lat (Lat)
   (format (- Lat 90.0) `*Scl) )

(de lon (Lon)
   (format (- Lon 180.0) `*Scl) )

(de fmt (Lat Str Lon)
   (when (or Lat Lon)
      (pack (lat Lat) Str (lon Lon)) ) )


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

# OpenStreetMap / OpenLayers
(local) [OL-CSS <osm> <poi>]
(de OL-CSS . "https://openlayers.org/en/v4.2.0/css/ol.css")

(de <osm> (Lat Lon Zoom)
   (<div> '(map (id . map)))
   (javascript "https://openlayers.org/en/v4.2.0/build/ol.js"
      "osm('map', " (lat Lat) ", " (lon Lon) ", " Zoom ")" ) )

(de <poi> (Lat Lon Img X Y Txt DY Col Url)
   (javascript NIL
      "poi(" (lat Lat) ", " (lon Lon) ", '"
         (sesId Img) "', " X ", " Y ", '"
         Txt "', " DY ", '" Col "', '"
         (sesId Url) "')" ) )

# Google Maps
(local) [google <google>]
(de google (Ttl Lat Lon Zoom Tar)
   (<href> Ttl
      (pack "https://www.google.com/maps/@" (fmt Lat "," Lon) "," Zoom "z")
      Tar ) )

(de <google> (Lat Lon DX DY)
   (prinl
      "<iframe width=\"" DX "\" height=\"" DY "\" frameborder=\"3\" \
      src=\"https://www.google.com/maps?source=s_q&amp;q="
      (fmt Lat "," Lon)
      "&amp;output=embed\"></iframe>" ) )

# vi:et:ts=3:sw=3
