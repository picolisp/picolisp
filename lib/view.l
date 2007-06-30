# 25jun07abu
# (c) Software Lab. Alexander Burger

(load "lib/draw.l")

### Shapes ###
(class +EntityBox +GComp)
# obj box btn

(dm T (Home X Y Obj Ttl Txt Btn)
   (=: obj Obj)
   (let Str (str Btn)
      (super Home
         (list
            (=: box
               (rect> Home X Y
                  (* (get Home 'adv)
                     (+ 2
                        (max (length Ttl) (length Txt) (length Str)) ) )
                  `(+ 4 (* 3 12)) ) )
            (text> Home (+ X 6) (+ Y 12) Ttl)
            (text> Home (+ X 6) (+ Y 24) Txt)
            (text> Home (+ X 6) (+ Y 36) Str) ) ) )
   (=: btn
      (let X (: home adv)
         (mapcar
            '((S)
               (prog1
                  (cons S X 36)
                  (inc 'X
                     (* (: home adv)
                        (if (atom S)
                           (inc (length S))
                           (+ 3 (length (car S))) ) ) ) ) )
            Btn ) ) )
   (siz> (: home)
      (max (: home sx) (+ 60 X (: box dx)))
      (max (: home sy) (+ 60 Y (: box dy))) ) )

(dm mov> (DX DY)
   (super DX DY)
   (siz> (: home)
      (max (: home sx) (+ 60 (: box x) (: box dx)))
      (max (: home sy) (+ 60 (: box y) (: box dy))) ) )

(dm lst> (Up)
   (cons This
      (mapcan
         '((L)
            (unless (== Up (car L))
               (lst> (car L) This) ) )
         (: link) ) ) )


### ViewField ###
(class +ViewField +SelectView +Mono +DrawField)

(dm clk> (M X Y)
   (ifn
      (pick
         '((This)
            (and
               (find
                  '((B)
                     (>= 8
                        (ext:Dist X Y
                           (+ (: box x) (cadr B))
                           (+ (: box y) (cddr B)) ) ) )
                  (: btn) )
               (cons This @) ) )
         (append (: tmp) (: lst)) )
      (super M X Y)
      (sel> This)
      (let
         (D (car @)
            Var (cadr @)
            X (+ (caddr @) (get D 'box 'x))
            Y1 (+ (cdddr @) (get D 'box 'y))
            Y2 (+ Y1 30)
            Val (get D 'obj (if (atom Var) Var (car Var)))
            L (find
               '((L) (and (= X (caadr L)) (= Y1 (cdadr L))))
               (get D 'link) ) )
         (cond
            ((not L)
               (link> This
                  D X Y1
                  (if (lst? Val)
                     (_viewLst Val X)
                     (view> Val This X Y2) )
                  X Y2 ) )
            ((bit? 1 M)  # Shift
               (sel> This (lst> (car L) D)) )
            (T (del> This (lst> (car L) D))) ) ) ) )

(de _viewLst (Lst X)
   (let
      (D
         (if (lst? (car Lst))
            (_viewBag (car Lst) Y2)
            (view> (car Lst) This X Y2) )
         X2 (+ X (get D 'box 'dx)) )
      (when (cdr Lst)
         (link> This
            D X2 Y2
            (_viewLst (cdr Lst) (inc 'X2 20))
            X2 Y2 ) )
      D ) )

(de _viewBag (Lst Y)
   (if (setq Lst (filter '((X) (isa '+Entity X)) Lst))
      (let (D (view> (car Lst) This X Y)  Y2 (+ Y (get D 'box 'dy)))
         (when (cdr Lst)
            (link> This
               D X Y2
               (_viewBag (cdr Lst) (inc 'Y2 20))
               X Y2 ) )
         D )
      (new> This '(+EntityBox) X Y2) ) )


### Entities ###
(extend +Entity)

(dm view> (Fld X Y)
   (let
      (L (getl This)
         A (car (find '((X) ("_isa" '+Key X)) L))
         B (car (find '((X) ("_isa" '+Idx X)) L))
         Txt (if (and A B)
            (pack A " : " B)
            (or A B
               (car
                  (find '((X) ("_isa" '+Ref X)) L) ) ) ) )
      (new> Fld '(+EntityBox) X Y This
         (str (list This (type This)))
         Txt
         (mapcan
            '((X)
               (when (pair X)
                  (with (meta This (cdr X))
                     (and
                        (or
                           (isa '+Link This)
                           (find
                              '((B) (isa '+Link B))
                              (: bag) ) )
                        (cons
                           (if (isa '+List This)
                              (cons (cdr X))
                              (cdr X) ) ) ) ) ) )
            L ) ) ) )

(de "_isa" (Cls X)
   (and
      (pair X)
      (isa Cls (meta This (cdr X))) ) )

(de view (Obj)
   (dialog "Object Viewer" NIL
      (quote
         (gui '(+Start +ViewField)
            '(prog
               (wait NIL (: adv))
               (view> Obj This 20 20) )
            "" 800 600 )
         (closeButton) ) ) )

# vi:et:ts=3:sw=3
