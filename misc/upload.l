# 14sep04abu
# (c) Software Lab. Alexander Burger

(app)

(html "Dateiübertragung"
   (<head> "Dateiübertragung")

   (when (dir (tmp))
      (<table> T "Übertragene Dateien" '((- "Dateiname") (+ "Dateigrösse"))
         (for F (dir (tmp))
            (<row> F (car (info (tmp F)))) ) ) )

   (when *UpFile
      (prinl "<p>")
      (println *UpFile (car (info (tmp *UpFile))))
      (off *UpFile) )

   (<post> "misc/upload.l"
      (<submit> "Send")
      (<upload> 30 "Filename" '*UpFile) )

   #(new '(+Form) 120 30 '((gui '(+Label) "Dummy" "Label")))
)
