# 28jan10abu
# (c) Software Lab. Alexander Burger

# *Rule

(de be CL
   (with (car CL)
      (if (== *Rule This)
         (=: T (conc (: T) (cons (cdr CL))))
         (=: T (cons (cdr CL)))
         (setq *Rule This) )
      This ) )

(de repeat ()
   (conc (get *Rule T) (get *Rule T)) )

(de asserta (CL)
   (with (car CL)
      (=: T (cons (cdr CL) (: T))) ) )

(de assertz (CL)
   (with (car CL)
      (=: T (conc (: T) (cons (cdr CL)))) ) )

(de retract (X)
   (if (sym? X)
      (put X T)
      (put (car X) T
         (delete (cdr X) (get (car X) T)) ) ) )

(de rules @
   (while (args)
      (let S (next)
         (for ((N . L) (get S T) L)
            (prin N " (be ")
            (print S)
            (for X (pop 'L)
               (space)
               (print X) )
            (prinl ")")
            (T (== L (get S T))
               (println '(repeat)) ) )
         S ) ) )

### Pilog Interpreter ###
(de goal ("CL" . @)
   (let "Env" '(T)
      (while (args)
         (push '"Env"
            (cons (cons 0 (next)) 1 (next)) ) )
      (while (and "CL" (pat? (car "CL")))
         (push '"Env"
            (cons
               (cons 0 (pop '"CL"))
               (cons 1 (eval (pop '"CL"))) ) ) )
      (cons
         (cons
            (conc (list 1 (0) NIL "CL" NIL) "Env") ) ) ) )

(de fail ()
   (goal '((NIL))) )

(de pilog ("CL" . "Prg")
   (for ("Q" (goal "CL") (prove "Q"))
      (bind @ (run "Prg")) ) )

(de solve ("CL" . "Prg")
   (make
      (if "Prg"
         (for ("Q" (goal "CL") (prove "Q"))
            (link (bind @ (run "Prg"))) )
         (for ("Q" (goal "CL") (prove "Q"))
            (link @) ) ) ) )

(de query ("Q" "Dbg")
   (use "R"
      (loop
         (NIL (prove "Q" "Dbg"))
         (T (=T (setq "R" @)) T)
         (for X "R"
            (space)
            (print (car X))
            (print '=)
            (print (cdr X))
            (flush) )
         (T (line)) ) ) )

(de ? "CL"
   (let "L"
      (make
         (while (nor (pat? (car "CL")) (lst? (car "CL")))
            (link (pop '"CL")) ) )
      (query (goal "CL") "L") ) )

### Basic Rules ###
(be repeat)
(repeat)

(be true)

(be not @P (1 -> @P) T (fail))
(be not @P)

(be call @P
   (2 cons (-> @P)) )

(be or @L (@C box (-> @L)) (_or @C))

(be _or (@C) (3 pop (-> @C)))
(be _or (@C) (@ not (val (-> @C))) T (fail))
(repeat)

(be nil (@X) (@ not (-> @X)))

(be equal (@X @X))

(be different (@X @X) T (fail))
(be different (@ @))

(be append (NIL @X @X))
(be append ((@A . @X) @Y (@A . @Z)) (append @X @Y @Z))

(be member (@X (@X . @)))
(be member (@X (@ . @Y)) (member @X @Y))

(be delete (@A (@A . @Z) @Z))
(be delete (@A (@X . @Y) (@X . @Z))
   (delete @A @Y @Z) )

(be permute ((@X) (@X)))
(be permute (@L (@X . @Y))
   (delete @X @L @D)
   (permute @D @Y) )

(be uniq (@B @X)
   (@ not (idx (-> @B) (-> @X) T)) )

(be asserta (@C) (@ asserta (-> @C)))

(be assertz (@C) (@ assertz (-> @C)))

(be retract (@C)
   (2 cons (-> @C))
   (@ retract (list (car (-> @C)) (cdr (-> @C)))) )

(be clause ("@H" "@B")
   ("@A" get (-> "@H") T)
   (member "@B" "@A") )

(be show (@X) (@ show (-> @X)))

### DB ###
(de initQuery (Var Cls Hook Val)
   (let (Tree (tree Var Cls Hook)  Rel (get Cls Var))
      (when (find '((B) (isa '+index B)) (get Rel 'bag))
         (setq Rel @) )
      (cond
         ((pair Val)
            (cond
               ((pair (cdr Val))
                  (cond
                     ((not (; Rel aux)) (quit "No Aux"))
                     ((atom (car Val))
                        (init Tree Val (append Val T)) )
                     ((>= (cdr Val) (car Val))
                        (init Tree (car Val) (append (cdr Val) T)) )
                     (T (init Tree (append (car Val) T) (cdr Val))) ) )
               ((isa '+Key Rel)
                  (init Tree (car Val) (cdr Val)) )
               ((>= (cdr Val) (car Val))
                  (init Tree
                     (cons (car Val))
                     (cons (cdr Val) T) ) )
               (T
                  (init Tree
                     (cons (car Val) T)
                     (cons (cdr Val)) ) ) ) )
         ((or (num? Val) (ext? Val))
            (if (isa '+Key Rel)
               (init Tree Val Val)
               (init Tree (cons Val) (cons Val T)) ) )
         ((=T Val) (init Tree))
         ((isa '+Key Rel)
            (init Tree Val (pack Val `(char T))) )
         ((isa '+Idx Rel)
            (let Q (init Tree (cons Val) (cons (pack Val `(char T)) T))
               (if (cdr Q)
                  Q
                  (setq Val (pack (car (split (chop Val) " "))))
                  (init Tree (cons Val) (cons (pack Val `(char T)) T)) ) ) )
         (T (init Tree (cons Val) (cons (pack Val `(char T)) T))) ) ) )

# (db var cls obj)
(be db (@Var @Cls @Obj)
   (@Q box
      (with (or (get (-> @Cls) (-> @Var)) (meta (-> @Cls) (-> @Var)))
         (initQuery (: var) (: cls) NIL '(NIL . T)) ) )
   (_db @Obj) )

# (db var cls hook|val obj)
(be db (@Var @Cls @X @Obj)
   (@Q box
      (with (or (get (-> @Cls) (-> @Var)) (meta (-> @Cls) (-> @Var)))
         (cond
            ((: hook)
               (initQuery (: var) (: cls) (-> @X) '(NIL . T)) )
            ((isa '+Fold This)
               (initQuery (: var) (: cls) NIL (fold (-> @X))) )
            (T
               (initQuery (: var) (: cls) NIL (-> @X)) ) ) ) )
   (_db @Obj) )

# (db var cls hook val obj)
(be db (@Var @Cls @Hook @Val @Obj)
   (@Q box
      (with (or (get (-> @Cls) (-> @Var)) (meta (-> @Cls) (-> @Var)))
         (initQuery (: var) (: cls) (-> @Hook)
            (if (isa '+Fold This)
               (fold (-> @Val))
               (-> @Val) ) ) ) )
   (_db @Obj) )

(be _db (@Obj)
   (@ let (Q (val (-> @Q 2))  Cls (-> @Cls 2))
      (loop
         (NIL (step Q (= '(NIL) (caaar Q))) T)
         (T (isa Cls (setq "R" @))) ) )
   T
   (fail) )

(be _db (@Obj) (@Obj . "R"))

(repeat)


(be val (@V . @L)
   (@V apply get (-> @L))
   T )

(be lst (@V . @L)
   (@Lst box (apply get (-> @L)))
   (_lst @V @Lst) )

(be _lst (@Val @Lst) (@ not (val (-> @Lst))) T (fail))
(be _lst (@Val @Lst) (@Val pop (-> @Lst)))
(repeat)

(be map (@V . @L)
   (@Lst box (apply get (-> @L)))
   (_map @V @Lst) )

(be _map (@Val @Lst) (@ not (val (-> @Lst))) T (fail))
(be _map (@Val @Lst) (@Val prog1 (val (-> @Lst)) (pop (-> @Lst))))
(repeat)


(be isa (@Typ . @L)
   (@ or
      (not (-> @Typ))
      (isa (-> @Typ) (apply get (-> @L))) ) )

(be same (@V . @L)
   (@ let V (-> @V)
      (or
         (not V)
         (let L (-> @L)
            ("same" (car L) (cdr L)) ) ) ) )

(de "same" (X L)
   (cond
      ((not L)
         (if (atom X)
            (= V X)
            (member V X) ) )
      ((atom X)
         ("same" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("same" (get Y (car L)) (cdr L)))
            X ) )
      (T ("same" (apply get (car L) X) (cdr L))) ) )

(be bool (@F . @L)
   (@ or
      (not (-> @F))
      (apply get (-> @L)) ) )

(be range (@N . @L)
   (@ let N (-> @N)
      (or
         (not N)
         (let L (-> @L)
            ("range" (car L) (cdr L)) ) ) ) )

(de "range" (X L)
   (cond
      ((not L)
         (if (atom X)
            (or
               (<= (car N) X (cdr N))
               (>= (car N) X (cdr N)) )
            (find
               '((Y)
                  (or
                     (<= (car N) Y (cdr N))
                     (>= (car N) Y (cdr N)) ) )
               X ) ) )
      ((atom X)
         ("range" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("range" (get Y (car L)) (cdr L)))
            X ) )
      (T ("range" (apply get (car L) X) (cdr L))) ) )

(be head (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("head" (car L) (cdr L)) ) ) ) )

(de "head" (X L)
   (cond
      ((not L)
         (if (atom X)
            (pre? S X)
            (find '((Y) (pre? S Y)) X) ) )
      ((atom X)
         ("head" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("head" (get Y (car L)) (cdr L)))
            X ) )
      (T ("head" (apply get (car L) X) (cdr L))) ) )

(be fold (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("fold" (car L) (cdr L)) ) ) ) )

(de "fold" (X L)
   (cond
      ((not L)
         (let P (fold S)
            (if (atom X)
               (pre? P (fold X))
               (find '((Y) (pre? P (fold Y))) X) ) ) )
      ((atom X)
         ("fold" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("fold" (get Y (car L)) (cdr L)))
            X ) )
      (T ("fold" (apply get (car L) X) (cdr L))) ) )

(be part (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("part" (car L) (cdr L)) ) ) ) )

(de "part" (X L)
   (cond
      ((not L)
         (let P (fold S)
            (if (atom X)
               (sub? P (fold X))
               (find '((Y) (sub? P (fold Y))) X) ) ) )
      ((atom X)
         ("part" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("part" (get Y (car L)) (cdr L)))
            X ) )
      (T ("part" (apply get (car L) X) (cdr L))) ) )

(be tolr (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("tolr" (car L) (cdr L)) ) ) ) )

(de "tolr" (X L)
   (cond
      ((not L)
         (if (atom X)
            (or (sub? S X) (pre? (ext:Snx S) (ext:Snx X)))
            (let P (ext:Snx S)
               (find
                  '((Y)
                     (or (sub? S Y) (pre? P (ext:Snx Y))) )
                  X ) ) ) )
      ((atom X)
         ("tolr" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("tolr" (get Y (car L)) (cdr L)))
            X ) )
      (T ("tolr" (apply get (car L) X) (cdr L))) ) )


(de "select" (Lst Flg)
   (let? X
      (nond
         ((atom (car Lst))
            (make
               (for (L (pop 'Lst) L)
                  (let
                     (Var (pop 'L)
                        Cls (pop 'L)
                        Hook (and (get Cls Var 'hook) (pop 'L))
                        Val (pop 'L) )
                     (and (or Val Flg) (chain ("initSel"))) ) ) ) )
         ((pat? (car Lst))
            (let
               (Var (pop 'Lst)
                  Cls (pop 'Lst)
                  Hook (and (get Cls Var 'hook) (pop 'Lst))
                  Val (pop 'Lst) )
               (and (or Val Flg) ("initSel")) ) )
         (NIL
            (let (Var (pop 'Lst) Val (pop 'Lst))
               (and
                  (or Flg (apply or Val))
                  (cons Var (goal (pop 'Lst))) ) ) ) )
      (cons
         (cons
            (for (L NIL Lst)
               (push 'L (pop 'Lst) NIL)
                L )
            X ) ) ) )

(de "initSel" ()
   (with (treeRel Var Cls)
      (cond
         ((isa '+Fold This)
            (initQuery Var (: cls) Hook (fold Val)) )
         ((isa '+Sn This)
            (conc
               (initQuery Var (: cls) Hook Val)
               (initQuery Var (: cls) Hook (ext:Snx Val)) ) )
         (T (initQuery Var (: cls) Hook Val)) ) ) )

(de _gen (Lst Q)
   (cond
      (Lst
         (use X
            (loop
               (T
                  (cond
                     ((atom (car Lst))
                        (prog1 (car Lst) (set Lst)) )
                     ((atom (caar Lst)) (pop Lst))
                     (T
                        (prog1
                           (step (car Lst) (= '(NIL) (caar (caar Lst))))
                           (or (cdaar Lst) (set Lst)) ) ) )
                  @ )
               (NIL (setq X (_gen (cddr Lst) Q)))
               (set Lst
                  (let Y (cadr Lst)
                     (cond
                        ((atom Y) (get X Y))
                        ((=T (caddr Y))
                           (initQuery (car Y) (cadr Y) X (cadddr Y)) )  # X = Hook
                        (T
                           (initQuery
                              (car Y)
                              (cadr Y)
                              (caddr Y)
                              (if (cadddr Y)
                                 (cons
                                    (cons X (car @))
                                    (cons X (cdr @)) )
                                 X ) ) ) ) ) ) ) ) )
      ((pat? (car Q)) (get (prove (cdr Q)) @))
      (T (step Q (= '(NIL) (caaar Q)))) ) )

(be select (("@Obj" . "@X") . "@Lst")
   (@ unify (-> "@X"))
   ("@P" box (cdr (-> "@Lst")))
   ("@C" box  # ((obj ..) curr . lst)
      (let L (car (-> "@Lst"))
         (setq L
            (or
               (mapcan "select" L)
               ("select" (car L) T) ) )
         (cons NIL L L) ) )
   (_gen "@Obj")
   (_sel) )

(be _gen (@Obj)
   (@ let C (caadr (val (-> "@C" 2)))
      (not (setq "*R" (_gen (car C) (cdr C)))) )
   T
   (fail) )

(be _gen (@Obj) (@Obj . "*R"))

(repeat)

(be _sel ()
   (2 val (-> "@P" 2))
   (@ let C (val (-> "@C" 2))
      (unless (idx C "*R" T)
         (rot (cddr C) (offset (cadr C) (cddr C)))
         (set (cdr C) (cddr C)) ) )
   T )

(be _sel ()
   (@ let C (cdr (val (-> "@C" 2)))
      (set C (or (cdar C) (cdr C))) )
   (fail) )

### Remote queries ###
(de rqry Args
   (for (Q (goal (cdr Args)) (prove Q))
      (pr (get @ (car Args)))
      (NIL (flush)) )
   (bye) )

(be remote ("@Lst" . "@CL")
   (@Sockets box
      (prog1 (cdr (-> "@Lst"))
         (for X @  # (out . in)
            ((car X)
               (cons 'rqry (car (-> "@Lst")) (-> "@CL")) ) ) ) )
   (@ unify (car (-> "@Lst")))
   (_remote "@Lst") )

(be _remote ((@Obj . @))
   (@ not (val (-> @Sockets 2)))
   T
   (fail) )

(be _remote ((@Obj . @))
   (@Obj let (Box (-> @Sockets 2)  Lst (val Box))
      (rot Lst)
      (loop
         (T ((cdar Lst)) @)
         (NIL (set Box (setq Lst (cdr Lst)))) ) ) )

(repeat)

# vi:et:ts=3:sw=3
