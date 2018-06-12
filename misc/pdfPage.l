# 08feb16abu
# (c) Software Lab. Alexander Burger

(allowed ()
   "!work" "@lib.css" )

(scl 2)
(load
   "@lib/http.l" "@lib/xhtml.l" "@lib/form.l"
   "@lib/canvas.l" "@lib/svg.l" "@lib/tinymce.l"
   "lib/pdfPage.l" )

(setq
   *Title "MyPage"
   *Css '("@lib.css" . "canvas {border: 1px solid}") )

(pdfPage 'myPage '(+PdfPage)
   *Title *A4-DX *A4-DY 24 "Tangerine"
   (image "img/7fachLogo.png" "image/png"
      (/ (- (: dx) 318) 2)
      (/ (- (: dy) 130) 2)
      318
      130 ) )

(de drawCanvas (This Dly F X Y X2 Y2)
   (make
      (draw> This Dly F X Y X2 Y2) ) )

(de work ()
   (app)
   (action
      (html 0 *Title *Css NIL
         (<ping> 7)
         (form NIL
            (<layout>
               ((620 NIL "margin: 6px")
                  (<div> @
                     (pdfCanvas 'myPage) )
                  ((NIL 60 "margin: 12px")
                     (<div> @
                        (pdfPagePanel)
                        (--)
                        (<h2> NIL ,"File")
                        (gui '(+UpField) 12)
                        (pdfLoadButton '(field -1))
                        (<nbsp> 7)
                        (pdfSaveButton) ) ) ) ) ) ) ) )
(de main ()
   #{(locale "DE" "de")}# )

(de go ()
   (retire 10)
   (server (or (format (sys "PORT")) 8080) "!work") )

# vi:et:ts=3:sw=3
