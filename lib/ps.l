# 17jan06abu
# (c) Software Lab. Alexander Burger

# "*PgX" "*PgY"
# "*DX" "*DY" "*Pos" "*Fonts" "*Size" "*Font" "*Pag" "*Lim" "*FF" "*UL"

(de pdf ("Nm" . "Prg")
   (let ("Ps" (tmp "Nm" ".ps") "Pdf" (tmp "Nm" ".pdf"))
      (out (list "bin/lat1" "Ps") (prEval "Prg"))
      (_pdf)
      "Pdf" ) )

(de psOut ("How" "Nm" . "Prg")
   (ifn "Nm"
      (out (list "bin/lat1" "-lpr" (pack "-P" "How")) (prEval "Prg"))
      (let ("Ps" (tmp "Nm" ".ps") "Pdf" (tmp "Nm" ".pdf"))
         (out (list "bin/lat1" "Ps") (prEval "Prg"))
         (cond
            ((not "How") (_pdf) (url "Pdf" "PDF"))
            ((=0 "How") (_pdf) (url "Pdf"))
            ((=T "How") (_pdf) (httpEcho "Pdf" "application/pdf" 1))
            ((fun? "How") ("How" "Ps") (_pdf))
            (T (call 'lpr (pack "-P" "How") "Ps") (_pdf)) )
         "Pdf" ) ) )

(de _pdf ()
   (call 'ps2pdf
      (pack "-dDEVICEWIDTHPOINTS=" "*PgX")
      (pack "-dDEVICEHEIGHTPOINTS=" "*PgY")
      "Ps" "Pdf" ) )

(de psHead (DX DY)
   (prinl "%!PS-Adobe-1.0")
   (prinl "%%Creator: Pico Lisp")
   (prinl "%%BoundingBox: 0 0 "
      (setq "*DX" DX "*PgX" DX) " "
      (setq "*DY" DY "*PgY" DY) )
   (prinl "%%DocumentFonts: (atend)")
   (prinl "/PicoEncoding")
   (prinl "   ISOLatin1Encoding  dup length array  copy ")
   (prinl "   dup 164  /Euro  put")
   (prinl "def")
   (prinl "/isoLatin1 {")
   (prinl "   dup dup findfont  dup length  dict begin")
   (prinl "      {1 index /FID ne {def} {pop pop} ifelse} forall")
   (prinl "      /Encoding PicoEncoding def  currentdict")
   (prinl "   end  definefont")
   (prinl "} def")
   (zero "*Pos")
   (off "*Fonts" "*Lim" "*UL")
   (setq "*Size" 12) )

(de a4 ()
   (psHead 595 842) )

(de a4L ()
   (psHead 842 595) )

(de a5 ()
   (psHead 420 595) )

(de a5L ()
   (psHead 595 420) )

(de _font ()
   (prinl "/" "*Font" " findfont  " "*Size" " scalefont  setfont") )

(de font ("F" . "Prg")
   (use "N"
      (cond
         ((pair "F")
            (setq "N" (pop '"F")) )
         ((num? "F")
            (setq "N" "F"  "F" "*Font") )
         (T (setq "N" "*Size")) )
      (unless (member "F" "*Fonts")
         (push '"*Fonts" "F")
         (prinl "/" "F" " isoLatin1 def") )
      (ifn "Prg"
         (setq "*Size" "N"  "*Font" "F")
         (let ("*Size" "N" "*Font" "F")
            (_font)
            (psEval "Prg") ) ) )
   (_font) )

(de width ("N" . "Prg")
   (and "Prg" (prinl "currentlinewidth"))
   (prinl "N" " setlinewidth")
   (when "Prg"
      (psEval "Prg")
      (prinl "setlinewidth") ) )

(de gray ("N" . "Prg")
   (and "Prg" (prinl "currentgray"))
   (prinl (- 100 "N") " 100 div setgray")
   (when "Prg"
      (psEval "Prg")
      (prinl "setgray") ) )

(de color ("R" "G" "B" . "Prg")
   (and "Prg" (prinl "currentrgbcolor"))
   (prinl "R" " 100 div " "G" " 100 div " "B" " 100 div setrgbcolor")
   (when "Prg"
      (psEval "Prg")
      (prinl "setrgbcolor") ) )

(de poly (F X Y . @)
   (prin "newpath " X " " (- "*PgY" Y) " moveto  ")
   (while (args)
      (if (pair (next))
         (for P (arg)
            (prin (car P) " " (- "*PgY" (cdr P)) " lineto  ") )
         (prin (arg) " " (- "*PgY" (next)) " lineto  ") ) )
   (prinl (if F "fill" "stroke")) )

(de rect (X1 Y1 X2 Y2 F)
   (poly F X1 Y1  X2 Y1  X2 Y2  X1 Y2  X1 Y1) )

(de arc (X Y R F A B)
   (prinl
      "newpath "
      X " " (- "*PgY" Y) " " R " "
      (or A 0) " "
      (or B 360) " arc "
      (if F "fill" "stroke") ) )

(de ellipse (X Y DX DY F A B)
   (prinl "matrix currentmatrix")
   (prinl
      "newpath "
      X " " (- "*PgY" Y) " translate "
      DX " " DY " scale 0 0 1 "
      (or A 0) " "
      (or B 360) " arc" )
   (prinl "setmatrix " (if F "fill" "stroke")) )


(de indent (X DX)
   (prinl X " 0 translate")
   (dec '"*DX" X)
   (and DX (dec '"*DX" DX)) )

(de window ("*X" "*Y" "*DX" "*DY" . "Prg")
   ("?ff")
   (prinl "gsave")
   (prinl "*X" " " (- "*Y") " translate")
   (let "*Pos" 0
      (psEval "Prg") )
   (prinl "grestore") )

(de ?ps ("X" "H" "V")
   (and "X" (ps "X" "H" "V")) )

(de ps ("X" "H" "V")
   (cond
      ((not "X") (inc '"*Pos" "*Size"))
      ((num? "X") (_ps (chop "X")))
      ((pair "X") (_ps "X"))
      (T (mapc _ps (split (chop "X") "^J"))) ) )

(de ps+ ("X")
   (?ul1)
   (prinl
      "("
      (escPs (if (atom "X") (chop "X") "X"))
      ") show" )
   (?ul2) )

(de _ps ("L")
   ("?ff")
   (setq "L" (escPs "L"))
   (cond
      ((not "H")
         (prin 0) )
      ((=0 "H")
         (prin "*DX" " (" "L" ") stringwidth pop sub 2 div") )
      (T (prin "*DX" " (" "L" ") stringwidth pop sub")) )
   (prin
      " "
      (-
         "*PgY"
         (cond
            ((not "V")
               (inc '"*Pos" "*Size") )
            ((=0 "V")
               (setq "*Pos" (+ (/ "*Size" 4) (/ "*DY" 2))) )
            (T (setq "*Pos" "*DY")) ) ) )
   (prin " moveto ")
   (?ul1)
   (prinl "(" "L" ") show")
   (?ul2) )

(de escPs (L)
   (mapcan
      '((C)
         (if (sub? C "\\()")
            (list "\\" C)
            (list C) ) )
      L ) )

(de ?ul1 ()
   (and "*UL" (prinl "currentpoint " "*UL" " sub")) )

(de ?ul2 ()
   (when "*UL"
      (prinl "currentpoint " "*UL" " sub")
      (prinl "gsave")
      (prinl "newpath 4 -2 roll moveto lineto stroke")
      (prinl "grestore") ) )

(de pos (N)
   (if N (+ N "*Pos") "*Pos") )

(de down (N)
   (inc '"*Pos" (or N "*Size")) )

(de table ("Lst" . "Prg")  #> Y
   ("?ff")
   (let ("PosX" 0  "Max" "*Size")
      (mapc
         '(("N" "X")
            (window "PosX" "*Pos" "N" "Max"
               ((if (atom "X") ps eval) "X")
               (inc '"PosX" "N")
               (setq "Max" (max "*Pos" "Max")) ) )
         "Lst"
         "Prg" )
      (inc '"*Pos" "Max") ) )

(de underline ("*UL" . "Prg")
   (psEval "Prg") )

(de hline (Y X2 X1)
   (inc 'Y "*Pos")
   (poly NIL (or X2 "*DX") Y (or X1 0) Y) )

(de vline (X Y2 Y1)
   (poly NIL X (or Y2 "*DY") X (or Y1 0)) )

(de border (Y)
   (rect 0 (or Y 0) "*DX" "*Pos") )

(de psEval ("Prg")
   (while "Prg"
      ((if (atom (car "Prg")) ps eval)
         (pop '"Prg") ) ) )

(de page (Flg)
   (when (=T Flg)
      (prinl "gsave") )
   (prinl "showpage")
   (zero "*Pos")
   (cond
      ((=T Flg)
         (prinl "grestore") )
      ((=0 Flg)
         (setq "*DX" "*PgX"  "*DY" "*PgY"  "*Lim") )
      (T (prin "%%DocumentFonts:")
         (while "*Fonts"
            (prin " " (pop '"*Fonts")) )
         (prinl)
         (prinl "%%EOF") ) ) )

(de pages (Lst . Prg)
   (setq "*Pag" Lst  "*Lim" (pop '"*Pag")  "*FF" Prg) )

(de "?ff" ()
   (when (and "*Lim" (>= "*Pos" "*Lim"))
      (off "*Lim")
      (run "*FF")
      (setq "*Lim" (pop '"*Pag")) ) )

(de noff "Prg"
   (let "*Lim" NIL
      (psEval "Prg") ) )

(de eps (Eps X Y DX DY)
   (prinl "gsave " (or X 0) " " (- "*PgY" (or Y 0)) " translate")
   (when DX
      (prinl DX " 100. div " (or DY DX) " 100. div scale") )
   (in Eps (echo))
   (prinl "grestore") )

(====)

(de brief ("F" "Fnt" "Abs" . "Prg")
   (when "F"
      (poly NIL 10 265  19 265)           # Faltmarken
      (poly NIL 10 421  19 421) )
   (poly NIL 50 106  50 103  53 103)      # Fenstermarken
   (poly NIL 50 222  50 225  53 225)
   (poly NIL 288 103  291 103  291 106)
   (poly NIL 288 225  291 225  291 222)
   (poly NIL 50 114  291 114)             # Absender
   (window 60 102 220 10
      (font "Fnt" (ps "Abs" 0)) )
   (window 65 125 210 90
      (psEval "Prg") ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
