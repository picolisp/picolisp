# 23aug03abu
# (c) Software Lab. Alexander Burger

### 2D-Shapes ###
(class +Graf)
# home link

(dm T (Home)
   (=: home Home) )

(dm len> ()
   (+ 1 (length (: link))) )

(dm pr> ()
   (mapc
      '((X)
         (pr `(char "L") (caadr X) (cdadr X) (caddr X) (cdddr X)) )
      (: link) ) )

(dm mov> (DX DY)
   (mapc
      '((X)
         (inc (cadr X) DX)
         (con (cadr X) (+ DY (cdadr X))) )
      (: link) ) )

(dm +link> (Obj P1 P2)
   (=: link
      (cons (cons Obj (cons P1 P2)) (: link)) ) )

(dm -link> (Obj)
   (=: link
      (delq (asoq Obj (: link)) (: link)) ) )


# Line
(class +GLine +Graf)
# x1 x2 y1 y2

(dm T (Home X1 Y1 X2 Y2)
   (super Home)
   (=: x1 X1)
   (=: y1 Y1)
   (=: x2 X2)
   (=: y2 Y2) )

(dm pr> ()
   (pr `(char "L") (: x1) (: y1) (: x2) (: y2))
   (super) )

(dm dist> (X Y)
   (ext:Dist X Y (: x1) (: y1) (: x2) (: y2)) )

(dm mov> (DX DY)
   (inc (:: x1) DX)
   (inc (:: y1) DY)
   (inc (:: x2) DX)
   (inc (:: y2) DY)
   (super DX DY) )


# Rect
(class +GRect +Graf)
# x y dx dy

(dm T (Home X Y DX DY)
   (super Home)
   (=: x X)
   (=: y Y)
   (=: dx DX)
   (=: dy DY) )

(dm pr> ()
   (pr `(char "R") (: x) (: y) (: dx) (: dy))
   (super) )

(dm dist> (X Y)
   (let (X2 (+ (: x) (: dx))  Y2 (+ (: y) (: dy)))
      (min
         (ext:Dist X Y (: x) (: y) X2 (: y))
         (ext:Dist X Y X2 (: y) X2 Y2)
         (ext:Dist X Y X2 Y2 (: x) Y2)
         (ext:Dist X Y (: x) Y2 (: x) (: y)) ) ) )

(dm mov> (DX DY)
   (inc (:: x) DX)
   (inc (:: y) DY)
   (super DX DY) )


# Oval
(class +GOval +Graf)
# x y dx dy

(dm T (Home X Y DX DY)
   (super Home)
   (=: x X)
   (=: y Y)
   (=: dx DX)
   (=: dy DY) )

(dm pr> ()
   (pr `(char "O") (: x) (: y) (: dx) (: dy))
   (super) )

(dm dist> (X Y)
   (let (A (>> 1 (: dx))  B (>> 1 (: dy)))
      (setq
         X (* B (- X (: x) A))
         Y (* A (- Y (: y) B)) )
      (abs
         (/
            (- (ext:Dist X Y) (* A B))
            (ext:Dist A B) ) ) ) )

(dm mov> (DX DY)
   (inc (:: x) DX)
   (inc (:: y) DY)
   (super DX DY) )


# Text
(class +GText +Graf)
# x y str

(dm T (Home X Y Str)
   (super Home)
   (=: x X)
   (=: y Y)
   (=: str Str) )

(dm pr> ()
   (pr `(char "T") (: x) (: y) (: str))
   (super) )

(dm dist> (X Y)
   (ext:Dist X Y
      (: x) (: y)
      (+ (: x) (* (: home adv) (length (: str))))
      (: y) ) )

(dm mov> (DX DY)
   (inc (:: x) DX)
   (inc (:: y) DY)
   (super DX DY) )


# Compound Graf
(class +GComp +Graf)
# lst

(dm T (Home Lst)
   (super Home)
   (=: home lst (diff (: home lst) Lst))
   (=: home tmp (diff (: home tmp) Lst))
   (=: lst Lst) )

(dm len> ()
   (+
      (sum 'len> (: lst))
      (length (: link)) ) )

(dm pr> ()
   (mapc 'pr> (: lst))
   (super) )

(dm dist> (X Y)
   (and
      (mini '((D) (dist> D X Y)) (: lst))
      (dist> @ X Y) ) )

(dm mov> (DX DY)
   (mapc '((D) (mov> D DX DY)) (: lst))
   (super DX DY) )


### DrawField ###
(extend +DrawField)

# Add new object
(dm line> (X1 Y1 X2 Y2)
   (new> This '(+GLine) X1 Y1 X2 Y2) )

(dm rect> (X Y DX DY)
   (new> This '(+GRect) X Y DX DY) )

(dm oval> (X Y DX DY)
   (new> This '(+GOval) X Y DX DY) )

(dm text> (X Y Str)
   (new> This '(+GText) X Y Str) )

(dm comp> (Lst)
   (new> This '(+GComp) Lst) )

# Link two objects
(dm link> (Obj1 X1 Y1 Obj2 X2 Y2)
   (let (P1 (cons X1 Y1)  P2 (cons X2 Y2))
      (unless (and (memq Obj1 (: lst)) (memq Obj2 (: tmp)))
         (+link> Obj1 Obj2 P1 P2) )
      (unless (and (memq Obj2 (: lst)) (memq Obj1 (: tmp)))
         (+link> Obj2 Obj1 P2 P1) )
      (when (or (memq Obj1 (: lst)) (memq Obj2 (: lst)))
         (set> This (: lst)) )
      (when (or (memq Obj1 (: tmp)) (memq Obj2 (: tmp)))
         (tmp> This (: tmp)) ) ) )

# Delete (non-selected) list of objects
(dm del> (Lst)
   (mapc
      '((Obj)
         (mapc
            '((X) (-link> (car X) Obj))
            (get Obj 'link) ) )
      Lst )
   (set> This (diff (: lst) Lst)) )

# Select (non-selected) list of objects
(dm sel> (Lst)
   (mapc
      '((Tmp)
         (mapc
            '((X)
               (unless (memq (car X) (: tmp))
                  (+link> (car X) Tmp (cddr X) (cadr X)) ) )
            (get Tmp 'link) ) )
      (: tmp) )
   (mapc
      '((Obj)
         (mapc
            '((X)
               (unless (memq (car X) Lst)
                  (-link> (car X) Obj) ) )
            (get Obj 'link) ) )
      Lst )
   (set> This (append (: tmp) (diff (: lst) Lst)))
   (tmp> This Lst) )

# Add object to selection
(dm +sel> (Obj)
   (mapc
      '((X) (-link> (car X) Obj))
      (get Obj 'link) )
   (mapc
      '((Tmp)
         (mapc
            '((X)
               (when (== Obj (car X))
                  (+link> Obj Tmp (cddr X) (cadr X)) ) )
            (get Tmp 'link) ) )
      (: tmp) )
   (set> This (delq Obj (: lst)))
   (tmp> This (cons Obj (: tmp))) )

# Remove object from selection
(dm -sel> (Obj)
   (mapc
      '((X)
         (if (memq (car X) (: tmp))
            (-link> Obj (car X))
            (+link> (car X) Obj (cddr X) (cadr X)) ) )
      (get Obj 'link) )
   (set> This (cons Obj (: lst)))
   (tmp> This (delq Obj (: tmp))) )


### +DrawField Prefix Classes ###
(class +SelectView)
# clk

# Click
(dm clk> (M X Y)
   (=: clk (cons X Y))
   (when (append (: tmp) (: lst))
      (let D (mini '((D) (dist> D X Y)) @)
         (cond
            ((bit? 2 M)  # Control
               (if (memq D (: tmp))
                  (tmp> This)
                  (beep> (: home)) ) )
            ((memq D (: tmp))
               (when (bit? 1 M)
                  (-sel> This D) ) )
            ((bit? 1 M)  # Shift
               (+sel> This D) )
            (T (sel> This (list D))) ) ) ) )

(dm dbl> (M X Y)
   (let D (mini '((D) (dist> D X Y)) (: tmp))
      (when (isa '+GComp D)
         (dialog "Detail" (list (get D 'lst))
            (quote
               (gui '(+SelectView +Mono +DrawField) "" 600 400)
               (closeButton) ) )
         (tmp> This (: tmp)) ) ) )

# Movement
(dm drg> (M X Y)
   (ifn (: clk)
      (clk> This M X Y)
      (let (DX (- X (car (: clk)))  DY (- Y (cdr (: clk))))
         (ifn
            (pick
               '((D)
                  (find
                     '((L)
                        (>= 3
                           (ext:Dist
                              (car (: clk)) (cdr (: clk))
                              (caadr L) (cdadr L) ) ) )
                     (get D 'link) ) )
               (: tmp) )
            (mapc
               '((Obj) (mov> Obj DX DY))
               (: tmp) )
            (inc (cadr @) DX)
            (con (cadr @) (+ DY (cdadr @))) )
         (tmp> This (: tmp))
         (set (: clk) X)
         (con (: clk) Y) ) ) )


# Factory Prefix Classes
(class +ShapeFactory)
# clk

(dm clk> (M X Y)
   (sel> This)
   (=: clk (cons X Y)) )


(class +LineFactory +ShapeFactory)

(dm drg> (M X Y)
   (ifn (: clk)
      (clk> This M X Y)
      (unless (: tmp)
         (=: tmp
            (list
               (new '(+GLine) This (car (: clk)) (cdr (: clk))) ) ) )
      (with (car (: tmp))
         (=: x2 X)
         (=: y2 Y) )
      (tmp> This (: tmp)) ) )


(class +RectFactory +ShapeFactory)

(dm drg> (M X Y)
   (ifn (: clk)
      (clk> This M X Y)
      (let (CX (car (: clk)) CY (cdr (: clk)))
         (unless (: tmp)
            (=: tmp
               (list
                  (new '(+GRect) This CX CY 0 0) ) ) )
         (with (car (: tmp))
            (if (>= X CX)
               (=: dx (- X CX))
               (inc (:: dx) (- (: x) X))
               (=: x X) )
            (if (>= Y CY)
               (=: dy (- Y CY))
               (inc (:: dy) (- (: y) Y))
               (=: y Y) ) )
         (tmp> This (: tmp)) ) ) )


(class +OvalFactory +ShapeFactory)

(dm drg> (M X Y)
   (ifn (: clk)
      (clk> This M X Y)
      (let (CX (car (: clk)) CY (cdr (: clk)))
         (unless (: tmp)
            (=: tmp
               (list
                  (new '(+GOval) This CX CY 0 0) ) ) )
         (with (car (: tmp))
            (if (>= X CX)
               (=: dx (- X CX))
               (inc (:: dx) (- (: x) X))
               (=: x X) )
            (if (>= Y CY)
               (=: dy (- Y CY))
               (inc (:: dy) (- (: y) Y))
               (=: y Y) ) )
         (tmp> This (: tmp)) ) ) )


(class +TextFactory +ShapeFactory)

(dm clk> (M X Y)
   (super)
   (when
      (dialog "Text" NIL
         (quote
            (gui '(+TextField) "Text" 40)
            (----)
            (row (okButton '(val> (: home fields 1))) (quitButton)) ) )
      (text> This X Y @) ) )
