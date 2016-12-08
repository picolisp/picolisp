# 24nov16abu
# (c) Software Lab. Alexander Burger

# "*Glyph" "*PgX" "*PgY"
# "*DX" "*DY" "*Pos" "*Fonts" "*Size" "*Font" "*Pag" "*Lim" "*FF" "*UL"

(de *A4-DX . 595)
(de *A4-DY . 842)

(de *A5-DX . 420)
(de *A5-DY . 595)

(once
   (balance '"*Glyph"
      (sort
         (make
            (in "@lib/glyphlist.txt"
               (use (L C)
                  (while (setq L (line))
                     (unless (or (= "#" (car L)) (member " " L))
                        (setq
                           L (split L ";")
                           C (char (hex (pack (cadr L)))) )
                        (set (link C) (pack (car L))) ) ) ) ) ) ) ) )

(de glyph (C)
   (val (car (idx '"*Glyph" C))) )

(de pdf (Nm . Prg)
   (let Ps (tmp Nm ".ps")
      (out Ps (run Prg 1))
      (ps2pdf Ps (tmp Nm ".pdf")) ) )

(de psOut (How Nm . Prg)
   (ifn Nm
      (out (list "lpr" (pack "-P" How)) (run Prg 1))
      (let (Ps (tmp Nm ".ps")  Pdf (tmp Nm ".pdf"))
         (out Ps (run Prg 1))
         (cond
            ((not How) (url (ps2pdf Ps Pdf) "PDF"))
            ((=0 How) (url (ps2pdf Ps Pdf)))
            ((=T How) (httpEcho (ps2pdf Ps Pdf) "application/pdf" 1))
            ((fun? How) (How Ps) (ps2pdf Ps Pdf))
            (T (call "lpr" (pack "-P" How) Ps) (ps2pdf Ps Pdf)) )
         Pdf ) ) )

(de ps2pdf (Ps Pdf)
   (if (= *OS "Darwin")
      (call "pstopdf" Ps)
      (call "ps2pdf"
         (pack "-dDEVICEWIDTHPOINTS=" "*PgX")
         (pack "-dDEVICEHEIGHTPOINTS=" "*PgY")
         Ps Pdf ) )
   Pdf )

(de psHead (DX DY Ttl)
   (prinl "%!PS-Adobe-2.0")
   (and Ttl (prinl "%%Title: " @))
   (prinl "%%Creator: PicoLisp")
   (prinl "%%BoundingBox: 0 0 "
      (setq "*DX" DX "*PgX" DX) " "
      (setq "*DY" DY "*PgY" DY) )
   (in "@lib/head.ps" (echo))
   (zero "*Pos")
   (off "*Fonts" "*Lim" "*UL")
   (setq "*Size" 12) )

(de a4 (Ttl)
   (psHead *A4-DX *A4-DY Ttl) )

(de a4L (Ttl)
   (psHead *A4-DY *A4-DX Ttl) )

(de a5 (Ttl)
   (psHead *A5-DX *A5-DY Ttl) )

(de a5L (Ttl)
   (psHead *A5-DY *A5-DX Ttl) )

(de _font ()
   (prinl "/" "*Font" " findfont  " "*Size" " scalefont  setfont") )

(de font ("F" . "Prg")
   (use "N"
      (cond
         ((pair "F")
            (setq "N" (++ "F")) )
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

(de bold "Prg"
   (let "*Font" (pack "*Font" "-Bold")
      (_font)
      (psEval "Prg") )
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
   (poly F
      (pack X1 " currentlinewidth 2 div sub") Y1
      X2 Y1
      X2 Y2
      X1 Y2
      X1 Y1 ) )

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
   (fmtPs (chop "X"))
   (?ul1)
   (prinl " glyphArrayShow")
   (?ul2) )

(de _ps ("L")
   ("?ff")
   (fmtPs "L")
   (ifn "H"
      (prin " 0")
      (prin " dup glyphArrayWidth " "*DX" " exch sub" (and (=0 "H") " 2 div")) )
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
   (prin " moveto")
   (?ul1)
   (prinl " glyphArrayShow")
   (?ul2) )

(de escPs (C)
   (and (sub? C "\\()") (prin "\\"))
   (prin C) )

(de fmtPs (Lst)
   (prin "[")
   (while Lst
      (if (>= (car Lst) `(char 128))
         (prin "/" (or (glyph (++ Lst)) ".notdef"))
         (prin "(")
         (escPs (++ Lst))
         (while (and Lst (>= `(char 127) (car Lst)))
            (escPs (++ Lst)) )
         (prin ")") )
      (and Lst (space)) )
   (prin "]") )

(de ?ul1 ()
   (and "*UL" (prin " currentpoint " "*UL" " sub 3 -1 roll")) )

(de ?ul2 ()
   (when "*UL"
      (prinl "currentpoint " "*UL" " sub")
      (prinl "gsave  newpath 4 -2 roll moveto lineto stroke grestore") ) )

(de psAlign ("Lst" "H" "V")
   ("?ff")
   (prinl 0)
   (when "H"
      (use ("*Size" "*Font")
         (for X "Lst"
            (cond
               ((atom X)
                  (fmtPs (chop X))
                  (prinl " glyphArrayWidth add") )
               ((== 'F (car X))
                  (ifn (cdr X)
                     (prinl "exch setfont")
                     (prinl "currentfont exch")
                     (font @) ) ) ) ) )
      (prinl "*DX" " exch sub" (and (=0 "H") " 2 div")) )
   (prin
      (-
         "*PgY"
         (cond
            ((not "V")
               (inc '"*Pos" "*Size") )
            ((=0 "V")
               (setq "*Pos" (+ (/ "*Size" 4) (/ "*DY" 2))) )
            (T (setq "*Pos" "*DY")) ) ) )
   (prinl " moveto")
   (use ("*Size" "*Font")
      (for X "Lst"
         (if (atom X)
            (ps+ X)
            (casq (++ X)
               (F
                  (ifn X
                     (prinl "setfont")
                     (prinl "currentfont")
                     (font X) ) )
               (C
                  (ifn X
                     (prinl "setrgbcolor")
                     (prinl "currentrgbcolor")
                     (color (car X) (cadr X) (caddr X)) ) )
               (U (setq "*UL" X))
               (S (prinl "currentpoint " X " add moveto"))
               (H (hline (car X) (cadr X) (caddr X))) ) ) ) ) )

(de pos (N)
   (if N (+ N "*Pos") "*Pos") )

(de down (N)
   (inc '"*Pos" (or N "*Size")) )

(de table ("Lst" . "Prg")  #> Y
   ("?ff")
   (let ("PosX" 0  "Max" "*Size")
      (mapc
         '(("N" "X")
            (when
               (or
                  (nT (car (pair "X")))
                  (setq "X" (run (cdr "X"))) )
               (window "PosX" "*Pos" "N" "Max"
                  (if (atom "X") (ps (eval "X")) (eval "X"))
                  (inc '"PosX" "N")
                  (setq "Max" (max "*Pos" "Max")) ) ) )
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

(de border (Y Y2)
   (rect 0 (or Y 0) "*DX" (or Y2 "*DY")) )

(de psEval ("Prg")
   (while "Prg"
      (if (atom (car "Prg"))
         (ps (eval (++ "Prg")))
         (eval (++ "Prg")) ) ) )

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
            (prin " " (++ "*Fonts")) )
         (prinl)
         (prinl "%%EOF") ) ) )

(de pages (Lst . Prg)
   (setq "*Pag" Lst  "*Lim" (++ "*Pag")  "*FF" Prg) )

(de "?ff" ()
   (when (and "*Lim" (>= "*Pos" "*Lim"))
      (off "*Lim")
      (run "*FF")
      (setq "*Lim" (++ "*Pag")) ) )

(de noff "Prg"
   (let "*Lim" NIL
      (psEval "Prg") ) )

(de eps (Eps X Y DX DY)
   (prinl "save " (or X 0) " " (- "*PgY" (or Y 0)) " translate")
   (when DX
      (prinl DX " 100. div " (or DY DX) " 100. div scale") )
   (in Eps (echo))
   (prinl "restore") )

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

# vi:et:ts=3:sw=3
