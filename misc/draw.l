# 27may05abu
# (c) Software Lab. Alexander Burger
# ./p dbg.l misc/draw.l -go

# *D2dField

(load "lib/http.l" "lib/html.l" "lib/gui.l" "lib/draw.l")

(de tstPage ()
   (app)
   (html "DrawField"
      (<head> "Draw test")
      (form '(+Form) 700 500
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

(de tst (N)
   (siz> (get *Top 'draw) 1200 800)
   (line> (get *Top 'draw) 100 100 300 200)
   (let
      (Oval (oval> (get *Top 'draw) 300 100 100 50)
         Rect (rect> (get *Top 'draw) 300 200 50 50)
         Text (text> (get *Top 'draw) 312 130 "Hello world") )
      (case N
         (1
            (link> (get *Top 'draw)
               (comp> (get *Top 'draw) (list Oval Text))
               350 150
               Rect 350 200 ) )
         (2
            (link> (get *Top 'draw) Oval 300 125 Text 312 130)
            (link> (get *Top 'draw)
               (comp> (get *Top 'draw) (list Oval Text))
               350 150
               Rect 350 200 ) )
 ) ) )
