# 28jun02abu
# (c) Software Lab. Alexander Burger

# *D2dField

(load "lib/draw.l")

(de tstPage ()
   (app)
   (html "DrawField"
      (<head> "Draw test")
      (new '(+Form) 700 500
         (quote
            (gui 'draw '(+SelectView +Mono +DrawField) "Draw" 600 400)
            (----)
            (row
               (gui '(+ClsField) '(: home draw) "Mode"
                  (quote
                     ("Select"      +SelectView +Mono +DrawField)
                     ("Line Input"  +LineFactory +Mono +DrawField)
                     ("Rect Input"  +RectFactory +Mono +DrawField)
                     ("Oval Input"  +OvalFactory +Mono +DrawField)
                     ("Text Input"  +TextFactory +Mono +DrawField) ) )
               (gui '(+Button) " " "Nix" '(println 'Nix))
               ) ) )
      <hr> ) )

(de go ()
   (server 8080 "@tstPage") )

(de tst ()
   (siz> (get *Top 'fields 1) 1200 800)
   (line> (get *Top 'fields 1) 100 100 300 200)
   (link> (get *Top 'fields 1)
      (comp> (get *Top 'fields 1)
         (list
            (oval> (get *Top 'fields 1) 300 100 100 50)
            (text> (get *Top 'fields 1) 312 130 "Hello world") ) )
      350 150
      (rect> (get *Top 'fields 1) 300 200 50 50)
      350 200 ) )
