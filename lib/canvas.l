# 05nov13abu
# (c) Software Lab. Alexander Burger

(allow "!jsDraw" )
(push1 '*JS (allow "@lib/plio.js") (allow "@lib/canvas.js"))

# Canvas Commands
(for (Opc . L)
   (quote  # In sync with "@lib/canvas.js"
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
      (csDrawDots DX DY Lst)
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
   (def (car L)
      (list
         (cdr L)
         (list 'link
            (if (cdr L)
               (cons 'list Opc @)
               (list Opc) ) ) ) ) )

(de <canvas> (Id DX DY Alt)
   (prin
      "<canvas id=\"" Id
      "\" width=\"" DX
      "\" height=\"" DY
      "\" onclick=\"drawCanvas(this.id, -128, event.layerX-this.offsetLeft, event.layerY-this.offsetTop)\"" )
   (dfltCss "canvas")
   (prinl ">" Alt "</canvas>" ) )

(de jsDraw (Id Dly X Y)
   (http1 "application/octet-stream" 0)
   (let Lst (drawCanvas Id Dly X Y)
      (prinl "Content-Length: " (bytes Lst) "^M^J^M")
      (pr Lst) ) )

# vi:et:ts=3:sw=3
