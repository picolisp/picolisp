# 27mar02abu
# (c) Software Lab. Alexander Burger

### Extend Relations ###
(extend +Relation)
# "x" "y" "r" "s"

(dm layout> (X Y R)
   (unless (memq This "Bubbles")
      (push '"Bubbles" This) )
   (=: "r" 6)
   (let A (rand -314159 314159)
      (=: "x"
         (inc 'X (*/ R (ext:Cos A 100000) 100000)) )
      (=: "y"
         (inc 'Y (*/ R (ext:Sin A 100000) 100000)) ) )
   (nor
      (find
         '((Obj)
            (nor
               (== Obj This)
               (with Obj
                  (>
                     (ext:Dist X Y (: "x") (: "y"))
                     (+ 8 (: "r")) ) ) ) )
         "Bubbles" )
      (find
         '((P)
            (> 8
               (ext:Dist X Y
                  (get (car P) "x") (get (car P) "y")
                  (get (cdr P) "x") (get (cdr P) "y") ) ) )
         "Links" ) ) )

(dm draw> (X Y DX DY D)
   (arc (* 2 X) Y 2 T)
   (ellipse (* 2 DX) DY (* 2 (: "r")) (: "r"))
   (poly NIL (* 2 X) Y
      (* 2 (*/ (- D (: "r")) DX D))
      (*/ (- D (: "r")) DY D) )
   (window (* 2 DX) DY 0 3 (ps (: "s") 0 0)) )


(extend +Any)

(dm layout> (X Y R)
   (=: "s" "?")
   (super X Y R) )


(extend +Bag)

(dm layout> (X Y R)
   (and
      (super X Y R)
      (layout (: bag) (: "x") (: "y") (+ 12 (: "r"))) ) )

(dm draw> (X Y DX DY D)
   (arc (* 2 X) Y 2 T)
   (poly NIL (* 2 X) Y (* 2 DX) DY)
   (arc (* 2 DX) DY 2 T)
   (mapc
      '((B)
         (window (* 2 DX) DY 0 0
            (let (DX (- (get B "x") (: "x")) DY (- (get B "y") (: "y")))
               (draw> B 0 0 DX DY (sqrt (+ (* DX DX) (* DY DY)))) ) ) )
      (: bag) ) )


(extend +Number)

(dm layout> (X Y R)
   (=: "s" "N")
   (super X Y R) )


(extend +Symbol)

(dm layout> (X Y R)
   (=: "s" "S")
   (super X Y R) )


(extend +Link)

(dm layout> (X Y R)
   (let Lnk (last (: type))
      (ifn (=: "x" (get Lnk "x"))
         (super X Y R)
         (unless (member (cons (: cls) Lnk) "Links")
            (push '"Links" (cons (: cls) Lnk)) )
         (=: "y" (get Lnk "y"))
         (=: "r" (get Lnk "r")) ) ) )

(dm draw> (X Y DX DY D)
   (arc (* 2 X) Y 2 T)
   (unless (memq (meta (: type) (: slot)) "Mark")
      (poly NIL (* 2 X) Y
         (* 2 (*/ (- D (: "r")) DX D))
         (*/ (- D (: "r")) DY D) ) )
   (push '"Mark" This) )


(extend +List)

(dm draw> (X Y DX DY D)
   (extra X Y DX DY D)
   (arc (* 2 X) Y 4) )


### Extend Entities ###
(extend +Entity)
# "x" "y" "r"

(dm layout> ()
   (unless (memq This "Bubbles")
      (push '"Bubbles" This) )
   (layout
      (mapcan
         '((X)
            (and
               (isa '+Relation (car X))
               (cons (car X)) ) )
         (getl This) )
      (: "x") (: "y") (+ 24 (: "r")) ) )

(dm draw> ()
   (let (X (: "x")  Y (: "y")  R (: "r"))
      (window (* 2 X) Y 0 0
         (ps This 0 0)
         (ellipse 0 0 (* 2 R) R)
         (font (9 . "Helvetica")
            (mapc
               '((P)
                  (when (isa '+Relation (car P))
                     (let
                        (DX (- (get (car P) "x") X)
                           DY (- (get (car P) "y") Y)
                           D (sqrt (+ (* DX DX) (* DY DY)))
                           X1 (*/ R DX D)
                           Y1 (*/ R DY D) )
                        (window (* 2 (- X1 (*/ X1 3 R))) (- Y1 (*/ Y1 6 R)) 0 0
                           (ps (cdr P)
                              (if (<= (abs X1) (abs (/ Y1 6)))
                                 0
                                 (gt0 X1) )
                              (if (<= (abs Y1) (abs (/ X1 6)))
                                 0
                                 (gt0 Y1) ) ) )
                        (draw> (car P) X1 Y1 DX DY D) ) ) )
               (getl This) ) ) ) ) )


### E/R Diagram ###
(de layout (Lst X Y R)
   (do 8
      (NIL Lst T)
      (T (and (layout> (car Lst) X Y R) (layout (cdr Lst) X Y R))
          T ) ) )

(de arrange (Lst)
   (make
      (let (DY (/ 842 (length Lst))  Y (/ DY 2))
         (mapc
            '((L)
               (let (DX (/ 595 2 (length L))  X (/ DX 2))
                  (mapc
                     '((E)
                        (when E
                           (link E)
                           (put E "x" X)
                           (put E "y" Y)
                           (put E "r"
                              (max 30
                                 (sum
                                    '((X) (and (isa '+Relation (car X)) 4))
                                    (getl E) ) ) ) )
                        (inc 'X DX) )
                     L ) )
               (inc 'Y DY) )
            Lst ) ) ) )

(de relate (Lst)
   (psOut NIL "rel"
      (a4)
      (font "Times-Roman")
      (let ("Bubbles" NIL  "Links" NIL  "Mark" NIL)
         (when (layout (setq Lst (arrange Lst)))
            (mapc 'draw> Lst) ) )
      (page) ) )

(de bitburger ()
   (relate
      (quote
         (NIL +Bereich)
         (+Sup +Gruppe)
         (+Artikel)
         (+Kunde +Warenkorb) ) ) )

(de messe1 ()
   (relate '((+Log) (+Artikel +Entn) (+Sup))) )

(de messe2 ()
   (relate
      (quote
         (+Person)
         (+Ansp)
) ) )
