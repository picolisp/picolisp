# 15may13abu
# (c) Software Lab. Alexander Burger

(allow "!jsDraw" )
(push1 '*JS (allow "@lib/plio.js") (allow "@lib/canvas.js"))

(de canvasCommands Lst
   (for (Opc . L) Lst
      (def (car L)
         (list
            (cdr L)
            (list 'link
               (if (cdr L)
                  (cons 'list Opc @)
                  (list Opc) ) ) ) ) ) )

(canvasCommands  # In sync with "@lib/canvas.js"
   ### Functions ###
   (csFillText Str X Y)
   (csStrokeLine X1 Y1 X2 Y2)
   (csClearRect X Y DX DY)
   (csStrokeRect X Y DX DY)
   (csFillRect X Y DX DY)
   (csBeginPath)
   (csClosePath)
   (csMoveTo X Y)
   (csLineTo X Y)
   (csBezierCurveTo X1 Y1 X2 Y2 X Y)
   (csLine X1 Y1 X2 Y2)
   (csRect X Y DX DY)
   (csArc X Y R A B F)
   (csStroke)
   (csFill)
   (csClip)
   (csDrawImage Img DX DY)
   (csTranslate X Y)
   (csRotate A)
   (csScale X Y)
   (csSave)
   (csRestore)
   ### Variables ###
   (csFillStyle V)
   (csStrokeStyle V)
   (csGlobalAlpha V)
   (csLineWidth V)
   (csLineCap V)
   (csLineJoin V)
   (csMiterLimit V)
   (csGlobalCompositeOperation V) )

(de canvas (Id DX DY)
   (prinl
      "<canvas id=\"" Id
      "\" width=\"" DX
      "\" height=\"" DY
      "\">" Id
      "</canvas>" ) )

(de jsDraw (Id)
   (http1 "application/octet-stream" 0)
   (let Lst (drawCanvas Id)
      (prinl "Content-Length: " (bytes Lst) "^M")
      (prinl "^M")
      (pr Lst) ) )

# vi:et:ts=3:sw=3
