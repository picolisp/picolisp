# 29nov00abu
# (c) Software Lab. Alexander Burger

(de gbrief (Doc Txt . @)
   (document Doc "11pt,german" "g-brief" '("german")
      (tex "faltmarken")
      (tex "fenstermarken")
      (tex "trennlinien")
      (tex "klassisch")

      (tex "Name" (next))
      (tex "Strasse" (next))
      (tex "Ort" (next))
      (tex "RetourAdresse" (next))

      (tex "Telefon" (next))
      (tex "Telefax" (next))
      (tex "EMail" (next))
      (tex "HTTP" (next))

      (tex "Bank" (next))
      (tex "BLZ" (next))
      (tex "Konto" (next))

      (tex "Postvermerk" (next))
      (texl "Adresse" (next))

      (tex "Betreff" (next))
      (tex "Datum" (datStr (or (next) (date))))

      (tex "IhrZeichen" (next))
      (tex "IhrSchreiben" (next))
      (tex "MeinZeichen" (next))

      (tex "Anrede" (or (next) "Sehr geehrter Herr ,"))
      (tex "Gruss" (or (next) "Mit freundlichen Gr\"u\"sen,"))
      (prinl "{1cm}")
      (tex "Unterschrift" (next))

      (tex "Anlagen" (next))

      (\block "g-brief"
         (prinl Txt) ) ) )
