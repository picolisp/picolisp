# 08feb03abu
# (c) Software Lab. Alexander Burger

(app)

(html "Dateiübertragung"
   (<head> "Dateiübertragung")

   (when (dir (tmp))
      (<table> T "Übertragene Dateien" '((- "Dateiname") (+ "Dateigrösse"))
         (mapc
            '((F) (<row> F (car (info (tmp F)))))
            (dir (tmp)) ) ) )

   (when *UpFile
      (prinl "<p>")
      (println *UpFile (car (info (tmp *UpFile))))
      (off *UpFile) )

   (<post> "misc/upload.l"
      (<submit> "Send")
      (<upload> 30 "Filename" '*UpFile) )

   #(new '(+Form) 120 30 '((gui '(+Label) "Dummy" "Label")))
)
