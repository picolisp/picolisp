# 04feb05abu
# (c) Software Lab. Alexander Burger

(app)

(html "Dateiübertragung"
   (<head> "Dateiübertragung")

   (let? D (dir (tmp))
      (<table> T "Übertragene Dateien" '((- "Dateiname") (+ "Dateigrösse"))
         (for F D
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
