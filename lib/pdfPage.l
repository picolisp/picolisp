# 16nov18abu
# (c) Software Lab. Alexander Burger

(allow "fonts/" T)
(allow "!mk.svg")
(allow "!fonts.svg")

(setq
   *FontFaces (mapcar
      '((D)
         (cons
            (pack (replace (chop D) "_" " "))
            (let P (pack "fonts/" D "/")
               (mapcar '((F) (pack P F)) (dir P)) ) ) )
      (dir "fonts") )
   *FontFamilies (sort (mapcar car *FontFaces)) )

### Text or Image Window ###
(class +PdfWin)
# x y x2 y2 size font txt img align col bc bw bm

(dm svg> (Edit Ofs Txt2 Img2)
   (let (X (: x)  Y (: y)  DX (- (: x2) X)  DY (- (: y2) Y)  M (or (: bm) 0))
      (inc 'Y Ofs)
      (let
         (Txt (conc (splitHtmlTxt (: txt)) (splitHtmlTxt Txt2))
            Img (and (: img) (cons (tmp (car @)) (cdr @))) )
         (setq DY
            (max
               DY
               (+
                  (/ (: size) 2)
                  (* (: size) (sum length Txt)) ) ) )
         (window X Y DX DY
            (cond
               ((or (: col) (: bc))
                  (width (or (: bw) 1)
                     (rect 0 0 DX DY (: col) (or (: bc) "none")) ) )
               (Edit
                  (width "0.25"
                     (rect 0 0 DX (- (: y2) (: y)) (: col) "gray") ) ) ) )
         (window (+ X M) (+ Y M) (- DX M M) DY
            (and Img (image (car @) (cdr @) 0 0 *DX *DY))
            (and Img2 (image (car @) (cdr @) 0 0 *DX *DY))
            (font (cons (: size) (or (: font) "Courier"))
               (for L (car Txt)
                  (apply ps L (: align)) )
               (for X (cdr Txt)
                  (hline (/ *FontSize 2))
                  (down (*/ *FontSize 2 3))
                  (for L X
                     (apply ps L (: align)) ) ) ) )
         DY ) ) )

(de splitHtmlTxt (Txt)
   (mapcar
      '((L) (split L 0))
      (split (htmlText Txt) T) ) )

(dm in> (X Y)
   (and
      (>= (: x2) X (: x))
      (>= (: y2) Y (: y)) ) )

(dm on> (X Y)
   (or
      (pick  # Corner point
         '((VarX VarY)
            (and
               (>= 4 (abs (- X (get This VarX))))
               (>= 4 (abs (- Y (get This VarY))))
               (cons (prop This VarX) (prop This VarY)) ) )
         '(x x x2 x2)
         '(y y2 y y2) )
      (and  # Horizontal line
         (>= (+ (: x2) 4) X (- (: x) 4))
         (or
            (>= 4 (abs (- Y (: y))))
            (>= 4 (abs (- Y (: y2)))) ) )
      (and  # Vertical line
         (>= (+ (: y2) 4) Y (- (: y) 4))
         (or
            (>= 4 (abs (- X (: x))))
            (>= 4 (abs (- X (: x2)))) ) ) ) )

(dm snap> (Grid)
   (=: x (* Grid (*/ (: x) Grid)))
   (=: y (* Grid (*/ (: y) Grid)))
   (=: x2 (* Grid (*/ (: x2) Grid)))
   (=: y2 (* Grid (*/ (: y2) Grid))) )

(dm move> (DX DY)
   (inc (:: x) DX)
   (inc (:: y) DY)
   (inc (:: x2) DX)
   (inc (:: y2) DY) )


### PDF Page ###
(class +PdfPage)
# ttl dx dy lst sel size font col grid ruler rx ry zoom sx sy cnt prg

(de pdfPage (Sym Cls Ttl DX DY Size Font . Prg)
   (object Sym Cls
      'ttl Ttl
      'dx DX
      'dy DY
      'size Size
      'font Font
      'rx (* 6 (*/ DX 12))
      'ry (* 6 (*/ DY 12))
      'zoom 1
      'sx 0
      'sy 0
      'cnt 0
      'prg Prg ) )

(dm svg> (Z)
   (<svg> (: dx) (: dy) Z
      (<faces>
         (filter
            '((L)
               (find
                  '((This) (= (: font) (car L)))
                  (: lst) ) )
            *FontFaces ) )
      (when (: col)
         (rect 0 0 (: dx) (: dy) @) )
      (font (: font)
         (ifn (: lst)
            (run (: prg))
            (pre> This)
            (let Grp (grp> This (: lst))
               (for X (reverse (car Grp))
                  (svg> (car X) (not (str? Z)) 0 (cadr X) (caddr X)) )
               (let Ofs 0
                  (for G (cdr Grp)
                     (inc 'Ofs (car G))
                     (setq G (by '((L) (; L 1 y)) sort (cdr G)))
                     (let (H 0  Y1 (; G 1 1 y)  Y2)
                        (for L G
                           (let (Y (; L 1 y)  DH (- Y Y1))
                              (when (and Y2 (>= Y Y2) (>= H DH))
                                 (inc 'Ofs (- H DH))
                                 (zero H) )
                              (setq
                                 H (max H
                                    (+
                                       DH
                                       (svg> (car L)
                                          (nor (str? Z) (<> Ofs Y1))
                                          (- Ofs Y1)
                                          (cadr L)
                                          (caddr L) ) ) )
                                 Y2 (max Y2 (; L 1 y2)) ) ) )
                        (inc 'Ofs H) ) ) ) )
            (fin> This) ) ) ) )

(dm html> ()
   (prinl "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
   (svg> This "px") )

(dm pre> ())

(dm grp> (Lst)
   (list (mapcar list Lst)) )

(dm fin> ())

(de x/dot (X)
   (+ (* X (: zoom)) (: sx)) )

(de y/dot (Y)
   (+ (* Y (: zoom)) (: sy)) )

(de dot/x (X)
   (*/ (- X (: sx)) (: zoom)) )

(de dot/y (Y)
   (*/ (- Y (: sy)) (: zoom)) )

(de scrollX (N)
   (=: sx
      (min 0
         (max (- (: dx) (* (: zoom) (: dx)))
            (let G (or (* (: grid) (: zoom)) 1)
               (* G (*/ N G)) ) ) ) ) )

(de scrollY (N)
   (=: sy
      (min 0
         (max (- (: dy) (* (: zoom) (: dy)))
            (let G (or (* (: grid) (: zoom)) 1)
               (* G (*/ N G)) ) ) ) ) )

(de drawSel ()
   (when (: sel)
      (let (X (x/dot (: sel x))  Y (y/dot (: sel y))  X2 (x/dot (: sel x2))  Y2 (y/dot (: sel y2)))
         (csStrokeRect X Y (- X2 X) (- Y2 Y))
         (mapc dec '(X Y X2 Y2) '(3 .))
         (csFillRect X Y 6 6)
         (csFillRect X Y2 6 6)
         (csFillRect X2 Y 6 6)
         (csFillRect X2 Y2 6 6) ) )
   (when (: ruler)
      (let (X (x/dot (: rx))  Y (y/dot (: ry)))
         (csFillText
            (pack (format (*/ (: rx) 254 72) 2) " cm")
            (+ X (if (> X (/ (: dx) 2)) -54 6))
            12 )
         (csFillText
            (pack (format (*/ (: ry) 254 72) 2) " cm")
            2
            (+ Y (if (> Y (/ (: dy) 2)) -4 12)) )
         (csBeginPath)
         (csLine X 0 X (: dy))
         (csLine 0 Y (: dx) Y)
         (csClosePath)
         (csStroke) ) ) )

(de mk.svg (Page)
   (svgOut (svg> Page (; Page zoom))) )

(de drawPage ()
   (inc (:: cnt))
   (csDrawImage (sesId (pack "!mk.svg?" (ht:Fmt This (: cnt))))
      (: sx)
      (: sy)
      (make
         (let? G (* (: grid) (: zoom))
            (csDrawDots 1 1
               (make
                  (for (X G (>= (: dx) X) (+ X G))
                     (for (Y G (>= (: dy) Y) (+ Y G))
                        (link X Y) ) ) ) ) )
         (drawSel) ) ) )

(dm zoom> (N)
   (let Z (: zoom)
      (inc (:: zoom) N)
      (scrollX (*/ (: sx) (: zoom) Z))
      (scrollY (*/ (: sy) (: zoom) Z)) ) )

(dm draw> (Dly F X Y X2 Y2)
   (csLineWidth "0.5")
   (cond
      ((gt0 F)  # Click
         (let (X (dot/x (dec X))  Y (dot/y (dec Y)))
            (if (= 2 F)
               (when (> 8 (: zoom))    # Double
                  (inc (:: zoom))
                  (scrollX (- (/ (: dx) 2) (* X (: zoom))))
                  (scrollY (- (/ (: dy) 2) (* Y (: zoom)))) )
               (=: sel
                  (find
                     '((W) (in> W X Y))
                     (: lst) ) ) ) )
         (drawPage)
         (csPost) )
      ((le0 F)  # Drag
         (let (X1 (dot/x X)  Y1 (dot/y Y))
            (let? G (* (: zoom) (or (: grid) 1))
               (setq
                  X (* G (*/ X G))
                  Y (* G (*/ Y G))
                  X2 (* G (*/ X2 G))
                  Y2 (* G (*/ Y2 G)) ) )
            (when (=0 F)
               (setq *CsMvX X  *CsMvY Y)
               (csDef "page")
               (cond
                  ((setq *Drag
                        (and
                           (: home able)
                           (: sel)
                           (on> @ X1 Y1) ) )
                     (change ,"Drag box"
                        (env
                           '(This)
                           'S (: sel)
                           'X (: sel x)
                           'Y (: sel y)
                           'X2 (: sel x2)
                           'Y2 (: sel y2)
                           'New (setq *DragNew (list (: sel x) (: sel y) (: sel x2) (: sel y2))) )
                        (prog
                           (=: sel S)
                           (=: sel x X)
                           (=: sel y Y)
                           (=: sel x2 X2)
                           (=: sel y2 Y2) )
                        (=: sel S)
                        (=: sel x (car New))
                        (=: sel y (cadr New))
                        (=: sel x2 (caddr New))
                        (=: sel y2 (cadddr New)) )
                     (and (: grid) (snap> (: sel) @))
                     (csPost) )
                  ((setq *Drag
                        (and
                           (: ruler)
                           (if2 (>= 4 (abs (- X1 (: rx)))) (>= 4 (abs (- Y1 (: ry))))
                              (cons (:: rx) (:: ry))
                              (cons (:: rx))
                              (cons NIL (:: ry)) ) ) )
                     (when (: grid)
                        (=: rx (* @ (*/ (: rx) @)))
                        (=: ry (* @ (*/ (: ry) @))) )
                     (csPost) ) ) )
            (cond
               (*Drag
                  (csDraw "page" 0 0)
                  (let (DX (*/ (- X2 *CsMvX) (: zoom))  DY (*/ (- Y2 *CsMvY) (: zoom)))
                     (if (=T *Drag)
                        (move> (: sel) DX DY)
                        (inc (car *Drag) DX)
                        (inc (cdr *Drag) DY) )
                     (when *DragNew
                        (set *DragNew (: sel x))
                        (set (cdr *DragNew) (: sel y))
                        (set (cddr *DragNew) (: sel x2))
                        (set (cdddr *DragNew) (: sel y2)) )
                     (drawSel)
                     (setq *CsMvX X2  *CsMvY Y2) ) )
               ((> (: zoom) 1)
                  (scrollX (+ (: sx) (- X2 *CsMvX)))
                  (scrollY (+ (: sy) (- Y2 *CsMvY)))
                  (drawPage)
                  (setq *CsMvX X2  *CsMvY Y2) )
               ((: home able)
                  (csDraw "page" 0 0)
                  (setq
                     X2 (max X2 (+ X 12))
                     Y2 (max Y2 (+ Y 12)) )
                  (if *DragNew
                     (with @
                        (=: x X)
                        (=: y Y)
                        (=: x2 X2)
                        (=: y2 Y2) )
                     (setq *DragNew
                        (change ,"New box"
                           (env
                              '(This)
                              'New (new '(+PdfWin)
                                 'x X
                                 'y Y
                                 'x2 X2
                                 'y2 Y2
                                 'size (: size)  'font (: font)  'align *Align
                                 'col *BgColor
                                 'bc *BdColor
                                 'bw *BdWidth
                                 'bm *BdMargin )
                              'Old (: lst) )
                           (prog
                              (=: lst Old)
                              (=: sel NIL) )
                           (=: sel (push (:: lst) New)) ) )
                     (csPost) )
                  (csStrokeRect X Y (- X2 X) (- Y2 Y)) ) ) ) )
      (T
         (when *DragNew
            (when (> (: sel x) (: sel x2))
               (xchg (:: sel x) (:: sel x2)) )
            (when (> (: sel y) (: sel y2))
               (xchg (:: sel y) (:: sel y2)) )
            (off *DragNew) )
         (drawPage) ) )
   (csCursor
      (make
         (and
            (: sel)
            (: home able)
            (let (X (x/dot (: sel x))  Y (y/dot (: sel y))  X2 (x/dot (: sel x2))  Y2 (y/dot (: sel y2)))
               (link
                  (list "crosshair"
                     (- X 4) (- Y 4) (+ X 4) (+ Y 4)
                     (- X2 4) (- Y 4) (+ X2 4) (+ Y 4)
                     (- X2 4) (- Y2 4) (+ X2 4) (+ Y2 4)
                     (- X 4) (- Y2 4) (+ X 4) (+ Y2 4) )
                  (list "move"
                     (- X 4) (- Y 4) (+ X 4) (+ Y2 4)
                     (- X2 4) (- Y 4) (+ X2 4) (+ Y2 4)
                     (- X 4) (- Y 4) (+ X2 4) (+ Y 4)
                     (- X 4) (- Y2 4) (+ X2 4) (+ Y2 4) ) ) ) )
         (when (: ruler)
            (let (X (x/dot (: rx))  Y (y/dot (: ry)))
               (link
                  (list "crosshair"
                     (- X 4) (- Y 4) (+ X 4) (+ Y 4) )
                  (list "col-resize"
                     (- X 4) 0 (+ X 4) (: dy) )
                  (list "row-resize"
                     0 (- Y 4) (: dx) (+ Y 4) ) ) ) )
         (link "default") ) ) )

(dm clear> ()
   (=: lst NIL)
   (=: sel NIL)
   (=: col NIL) )

(dm save> (File)
   (unless (= `(char "/") (char File))
      (setq File (pack (pwd) "/" File)) )
   (chdir (tmp)
      (out "pdfPage"
         (pr (: col))
         (for W (: lst)
            (pr (getl W)) ) )
      (apply call
         (extract
            '((This) (car (: img)))
            (: lst) )
         "tar" "cfz" File "pdfPage" ) ) )

(dm load> (File)
   (unless (= `(char "/") (char File))
      (setq File (pack (pwd) "/" File)) )
   (chdir (tmp)
      (call "tar" "xfz" File)
      (=: sel NIL)
      (=: col NIL)
      (=: lst
         (when (info "pdfPage")
            (in "pdfPage"
               (=: col (rd))
               (make
                  (while (rd)
                     (let W (new '(+PdfWin))
                        (putl W @)
                        (link W) ) ) ) ) ) ) ) )

### GUI Components ###
(de pdfCanvas (Sym)
   (unless *PRG
      (put (=: page Sym) 'home This) )
   (<canvas> (pack "$" Sym) (; Sym dx) (; Sym dy))
   (javascript NIL "onload=drawCanvas('$" Sym "', -1)") )

(de pdfGridButton ()
   (gui '(+Rid +Tip +Button)
      '(if (: home page grid) ,"Grid OFF" ,"Grid ON")
      ,"Grid"
      '(with (: home page)
         (when (=: grid (unless (: grid) 6))
            (scrollX (: sx))
            (scrollY (: sy)) ) ) ) )

(de pdfRulerButton ()
   (gui '(+Rid +Tip +Button)
      '(if (: home page ruler) ,"Ruler OFF" ,"Ruler ON")
      ,"Ruler"
      '(=: home page ruler (not (: home page ruler))) ) )

(de pdfFileButton ()
   (gui '(+Rid +Tip +Button) ,"Generate PDF file" "PDF"
      '(url
         (svgPdf (tmp (: home page ttl) ".pdf")
            (svg> (: home page) "pt") ) ) ) )

(de pdfZoomButtons ()
   (gui '(+Rid +Able +Tip +Button) '(> (: home page zoom) 1)
      ,"Zoom out"
      `(char (hex "2014"))
      '(zoom> (: home page) -1) )
   (gui '(+Rid +Able +Tip +Button) '(> 8 (: home page zoom))
      ,"Zoom in"
      "+"
      '(zoom> (: home page) +1) )
   (gui '(+View +TextField) '(pack ,"Zoom" " " (: home page zoom))) )

(de pgRgbPicker ()
   (<grid> 2
      (gui '(+Chg +Upd +RgbPicker)
         '((C)
            (with (: home page)
               (when (or (: col) (<> C "#f0f0f0"))
                  (change ,"Page background color"
                     (env '(This C) 'Old (: col))
                     (=: col Old)
                     (=: col C) ) ) ) )
         '(or (: home page col) "#f0f0f0") )
      (gui '(+Tiny +Able +Tip +Button) '(: home page col) ,"Delete" "x"
         '(with (: home page)
            (change ,"Page background color"
               (env '(This) 'Old (: col))
               (=: col Old)
               (=: col NIL) ) ) ) ) )

(de pdfRgbPicker ()
   (<grid> 2
      (gui '(+Able +Chg +Upd +RgbPicker) '(: home page sel)
         '((C)
            (with (: home page)
               (when (or (: col) (<> C "#f0f0f0"))
                  (change ,"Background color"
                     (env '(This C) 'S (: sel)  'Old (: sel col))
                     (setq *BgColor (put (=: sel S) 'col Old))
                     (setq *BgColor (put (=: sel S) 'col C)) ) ) ) )
         '(or (: home page sel col) "#f0f0f0") )
      (gui '(+Tiny +Able +Tip +Button) '(: home page sel col) ,"Delete" "x"
         '(with (: home page)
            (change ,"Background color"
               (env '(This) 'S (: sel)  'Old (: sel col))
               (setq *BgColor (put (=: sel S) 'col Old))
               (setq *BgColor (put (=: sel S) 'col NIL)) ) ) ) ) )

(de pdfFrontButton ()
   (gui '(+Able +Button)
      '(with (: home page)
          (and (: sel) (n== @ (car (: lst)))) )
      ,"Bring to Front"
      '(with (: home page)
         (change ,"Bring to Front"
            (env '(This) 'S (: sel) 'L (: lst))
            (=: lst L)
            (=: lst (cons S (delete S (: lst)))) ) ) ) )

(de pdfImgField (Fld)
   (<grid> 2
      (gui '(+Able +UpField) '(: home page sel) 12)
      (gui '(+Drop +Button) '(field -1)
         '(if (: home page sel img) ,"Delete Image" ,"Set Image")
         '(cond
            ((: home page sel img)
               (with (: home page)
                  (change ,"Delete Image"
                     (env '(This) 'S (: sel) 'Old (: sel img))
                     (put (=: sel S) 'img Old)
                     (put (=: sel S) 'img NIL) ) ) )
            ((: drop)
               (when (mimetype (: drop) T)
                  (let Img (cons (basename (: drop)) @)
                     (with (: home page)
                        (change ,"Set Image"
                           (env '(This) 'S (: sel) 'Old (: sel img) '(Img))
                           (put (=: sel S) 'img Old)
                           (put (=: sel S) 'img Img) ) ) ) ) ) ) ) ) )

(de pdfBdRgbPicker ()
   (<grid> 2
      (gui '(+Able +Chg +Upd +RgbPicker) '(: home page sel)
         '((C)
            (with (: home page)
               (when (or (: col) (<> C "#f0f0f0"))
                  (change ,"Border color"
                     (env '(This C) 'S (: sel)  'Old (: sel bc))
                     (setq *BdColor (put (=: sel S) 'bc Old))
                     (setq *BdColor (put (=: sel S) 'bc C)) ) ) ) )
         '(or (: home page sel bc) "#f0f0f0") )
      (gui '(+Tiny +Able +Tip +Button) '(: home page sel bc) ,"Delete" "x"
         '(with (: home page)
            (change ,"Border color"
               (env '(This) 'S (: sel)  'Old (: sel bc))
               (setq *BdColor (put (=: sel S) 'bc Old))
               (setq *BdColor (put (=: sel S) 'bc NIL)) ) ) ) ) )

(de pdfBdWidthField ()
   (gui '(+Able +Chg +Upd +NumField) '(: home page sel)
      '((N)
         (with (: home page)
            (change ,"Border width"
               (env '(This N) 'S (: sel) 'Old (: sel bw))
               (setq *BdWidth (put (=: sel S) 'bw Old))
               (setq *BdWidth (put (=: sel S) 'bw N)) ) ) )
      '(: home page sel bw)
      2 ) )

(de pdfBdMarginField ()
   (gui '(+Able +Chg +Upd +NumField) '(: home page sel)
      '((N)
         (with (: home page)
            (change ,"Margin"
               (env '(This N) 'S (: sel) 'Old (: sel bm))
               (setq *BdMargin (put (=: sel S) 'bm Old))
               (setq *BdMargin (put (=: sel S) 'bm N)) ) ) )
      '(: home page sel bm)
      2 ) )

(de pdfFontField (Lst)
   (gui '(+Able +Init +Chg +Upd +TextField) '(: home page sel) (: page font)
      '((F)
         (default F "Serif")
         (with (: home page)
            (change ,"Font"
               (env '(This F) 'S (: sel) 'Old (: sel font))
               (=: home page font (put (=: sel S) 'font Old))
               (=: home page font (put (=: sel S) 'font F)) ) ) )
      '(: home page sel font)
      Lst ) )

(de pdfSizeField ()
   (gui '(+Able +Chg +Upd +NumField) '(: home page sel)
      '((N)
         (default N 12)
         (with (: home page)
            (change ,"Size"
               (env '(This N) 'S (: sel) 'Old (: sel size))
               (=: home page size (put (=: sel S) 'size Old))
               (=: home page size (put (=: sel S) 'size N)) ) ) )
      '(: home page sel size)
      2 ) )

(de pdfAlignRadio ()
   (ht:Prin ,"Left")
   (gui '(+Able +Chg +Upd +Map +Radio) '(: home page sel)
      '((A)
         (with (: home page)
            (change ,"Alignment"
               (env '(This A) 'S (: sel) 'Old (: sel align))
               (setq *Align (put (=: sel S) 'align Old))
               (setq *Align (put (=: sel S) 'align A)) ) ) )
      '(: home page sel align)
      '(("L") ("C" . 0) ("R" . T))
      NIL "L" )
   (<nbsp> 3)
   (ht:Prin ,"Center")
   (gui '(+Able +Radio) '(: home page sel) -1 "C")
   (<nbsp> 3)
   (ht:Prin ,"Right")
   (gui '(+Able +Radio) '(: home page sel) -2 "R") )

(de pdfTextField (DX DY)
   (<tinymce>)
   (gui '(+Able +Chg +Upd +TextField) '(: home page sel)
      '((Txt)
         (with (: home page)
            (change ,"Text"
               (env '(This Txt) 'S (: sel) 'Old (: sel txt))
               (put (=: sel S) 'txt Old)
               (put (=: sel S) 'txt Txt) ) ) )
      '(: home page sel txt)
      DX DY ) )

(de pdfDelButton ()
   (gui '(+Able +Button) '(: home page sel) ,"Delete"
      '(with (: home page)
         (change ,"Delete box"
            (env '(This) 'S (: sel) 'L (: lst))
            (prog (=: lst L) (=: sel S))
            (del S (:: lst))
            (=: sel NIL) ) ) ) )

(de pdfLoadButton (Fld)
   (gui '(+Drop +Button) Fld ,"Load"
      '(when (: drop)
         (load> (: home page) @)
         (=: home undo todo NIL)
         (=: home redo todo NIL) ) ) )

(de pdfSaveButton ()
   (gui '(+Rid +Able +Button) '(: home undo todo) ,"Save"
      '(prog
         (save> (: home page) (tmp (: home page ttl) ".tgz"))
         (url (tmp (: home page ttl) ".tgz")) ) ) )

(de fonts.svg (Page)
   (svgOut
      (<svg> 1120 (* 120 (/ (+ 6 (length *FontFamilies)) 7)) "px"
         (<faces> *FontFaces)
         (for (I . F) *FontFamilies
            (font F
               (let (X (* 160 (% (dec I) 7))  Y (* 120 (/ (dec I) 7)))
                  (font (9 . "serif")
                     (<text> (+ 12 X) (+ 24 Y) F) )
                  (font 24
                     (<text> (+ 12 X) (+ 60 Y) "Abc 123") ) ) ) ) ) ) )

(de pdfPagePanel (Page Box)
   (<grid> 3
      (gui '(+UndoButton)) (pdfGridButton) (pdfZoomButtons)
      (gui '(+RedoButton)) (pdfRulerButton) (pdfFileButton) )
   (--)
   (<table> NIL ,"Page" NIL
      (<row> NIL ,"Background color" (pgRgbPicker))
      (while Page
         (<row> NIL
            (eval (++ Page))
            (eval (++ Page)) ) ) )
   (--)
   (<table> NIL ,"Box" '((NIL) (NIL) (align) NIL (align) NIL)
      (<row> NIL
         ,"Image" (pdfImgField) - - - - - )
      (<row> NIL
         ,"Background color" (pdfRgbPicker) )
      (<row> NIL
         ,"Border color" (pdfBdRgbPicker)
         ,"Width" (pdfBdWidthField)
         ,"Margin" (pdfBdMarginField) )
      (<row> NIL
         ,"Font" (pdfFontField *FontFamilies)
         ,"Size" (pdfSizeField)
         (<href> ,"All Fonts" "!fonts.svg" ,"All Fonts") - )
      (while Box
         (<row> NIL
            (eval (++ Box))
            (eval (++ Box)) ) ) )
   (ht:Prin ,"Alignment")
   (<nbsp> 3)
   (pdfAlignRadio)
   (pdfTextField 48 12)
   (<spread> (gui '(+Rid +Button) ,"Apply") (pdfFrontButton) (pdfDelButton)) )

# vi:et:ts=3:sw=3
