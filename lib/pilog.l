# 10mar04abu
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
      (let (N 0  S (next)  L (get S T)  L1 L)
         (loop
            (NIL L)
            (prin (inc 'N) " (be ")
            (print S)
            (mapc
               '((X) (space) (print X))
               (pop 'L) )
            (prinl ")")
            (T (== L L1) (println '(repeat))) )
         S ) ) )

### Pilog Interpreter ###
(de goal ("CL" . @)
   (let Env '(T)
      (while (args)
         (push 'Env
            (cons (cons 0 (next)) (cons 1 (next))) ) )
      (while (and "CL" (pat? (car "CL")))
         (push 'Env
            (cons
               (cons 0 (pop '"CL"))
               (cons 1 (eval (pop '"CL"))) ) ) )
      (cons
         (cons
            (conc (list 1 (0) NIL "CL" NIL) Env) ) ) ) )

(de fail ()
   (goal '((NIL))) )

(de pilog ("CL" . "Prg")
   (for ("Q" (goal "CL") (prove "Q"))
      (bind @ "Prg") ) )

(de solve ("CL" . "Prg")
   (make
      (if "Prg"
         (for ("Q" (goal "CL") (prove "Q"))
            (link (bind @ "Prg")) )
         (for ("Q" (goal "CL") (prove "Q"))
            (link @) ) ) ) )

(de query ("Q" "Dbg")
   (use "R"
      (loop
         (NIL (prove "Q" "Dbg"))
         (T (=T (setq "R" @)) T)
         (mapc
            '((X)
               (space)
               (print (car X))
               (print '=)
               (print (cdr X)) )
            "R" )
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

(be call (@P . @L)
   (2 cons (cons (-> @P) (-> @L))) )

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

(be clause ("@H" "@B")
   ("@A" get (-> "@H") T)
   (member "@B" "@A") )

(be show (@X) (@ show (-> @X)))

### idx ###
(be idx (@Idx @Str @Sym)
   (@Q box
      (let (Node (val (-> @Idx))  Str (-> @Str)  Q)
         (while Node
            (if (> Str (car Node))
               (setq Node (cddr Node))
               (when (pre? Str (car Node))
                  (push 'Q Node) )
               (setq Node (cadr Node)) ) )
         (cons Str Q) ) )
   (_idx @Sym @Q) )

(be _idx (@Sym @Q)
   (@ not
      (setq "R"
         (let (Q (val (-> @Q))  Val (cadr Q)  Node (cddr Val))
            (con Q (cddr Q))
            (when Node
               (loop
                  (T (> (car Q) (car Node)))
                  (when (pre? (car Q) (car Node))
                     (con Q (cons Node (cdr Q))) )
                  (NIL (setq Node (cadr Node))) ) )
            (car Val) ) ) )
   T
   (fail) )

(be _idx (@Sym @Q) (@Sym . "R"))

(repeat)

### DB ###
(de initQuery (Var Cls Hook Val)
   (let (Tree (tree Var Cls Hook)  Rel (get Cls Var))
      (when (find '((B) (isa '+Index B)) (get Rel 'bag))
         (setq Rel @) )
      (cond
         ((pair Val)
            (cond
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
         (T
            (cond
               ((isa '+Key Rel)
                  (init Tree Val (pack Val `(char T))) )
               ((isa '+Idx Rel)
                  (let Q (init Tree (cons Val) (cons (pack Val `(char T)) T))
                     (if (cdr Q)
                        Q
                        (setq Val (pack (car (split (chop Val) " "))))
                        (init Tree (cons Val) (cons (pack Val `(char T)) T)) ) ) )
               (T (init Tree (cons Val) (cons (pack Val `(char T)) T))) ) ) ) ) )

# (db var cls obj)
(be db (@Var @Cls @Obj)
   (@Q box
      (with (or (get (-> @Cls) (-> @Var)) (meta (-> @Cls) (-> @Var)))
         (initQuery (: var) (: cls) NIL '(NIL . T)) ) )
   (_db @Obj @Q) )

# (db var cls hook|val obj)
(be db (@Var @Cls @X @Obj)
   (@Q box
      (with (or (get (-> @Cls) (-> @Var)) (meta (-> @Cls) (-> @Var)))
         (if (: hook)
            (initQuery (: var) (: cls) (-> @X) '(NIL . T))
            (initQuery (: var) (: cls) NIL (-> @X)) ) ) )
   (_db @Obj @Q) )

# (db var cls hook val obj)
(be db (@Var @Cls @Hook @Val @Obj)
   (@Q box
      (with (or (get (-> @Cls) (-> @Var)) (meta (-> @Cls) (-> @Var)))
         (initQuery (: var) (: cls) (-> @Hook) (-> @Val)) ) )
   (_db @Obj @Q) )

(be _db (@Obj @Q)
   (@ let Q (val (-> @Q))
      (not
         (setq "R"
            (step Q (= '(NIL) (caar Q))) ) ) )
   T
   (fail) )

(be _db (@Obj @Q) (@Obj . "R"))

(repeat)


(be val (@V . @L)
   (@V let L (-> @L)
      (apply get (cdr L) (car L)) )
   T )

(be lst (@V . @L)
   (@Lst box
      (let L (-> @L)
         (apply get (cdr L) (car L)) ) )
   (_lst @V @Lst) )

(be _lst (@Val @Lst) (@ not (val (-> @Lst))) T (fail))
(be _lst (@Val @Lst) (@Val pop (-> @Lst)))
(repeat)

(be map (@V . @L)
   (@Lst box
      (let L (-> @L)
         (apply get (cdr L) (car L)) ) )
   (_map @V @Lst) )

(be _map (@Val @Lst) (@ not (val (-> @Lst))) T (fail))
(be _map (@Val @Lst) (@Val prog1 (val (-> @Lst)) (pop (-> @Lst))))
(repeat)


(be isa (@Typ . @L)
   (@ or
      (not (-> @Typ))
      (isa (-> @Typ)
         (let L (-> @L)
            (apply get (cdr L) (car L)) ) ) ) )

(be same (@V . @L)
   (@ let V (-> @V)
      (or
         (not V)
         (let L (-> @L)
            ("same"
               (get (car L) (cadr L))
               (cddr L) ) ) ) ) )

(de "same" (X L)
   (if L
      (cond
         ((atom X)
            ("same" (get X (car L)) (cdr L)) )
         ((pair (car L))
            ("same"
               (apply get (cdar L) (assoc (caar L) X))
               (cdr L) ) )
         (T
            (pick
               '((Y) ("same" (get Y (car L)) (cdr L)) )
               X ) ) )
      (if (atom X)
         (= V X)
         (find '((Y) (= V Y)) X) ) ) )

(be bool (@F . @L)
   (@ or
      (not (-> @F))
      (let L (-> @L)
         (apply get (cdr L) (car L)) ) ) )

(be range (@N . @L)
   (@ let N (-> @N)
      (or
         (not N)
         (let L (-> @L)
            ("range"
               (get (car L) (cadr L))
               (cddr L) ) ) ) ) )

(de "range" (X L)
   (if L
      (cond
         ((atom X)
            ("range" (get X (car L)) (cdr L)) )
         ((pair (car L))
            ("range"
               (apply get (cdar L) (assoc (caar L) X))
               (cdr L) ) )
         (T
            (pick
               '((Y) ("range" (get Y (car L)) (cdr L)) )
               X ) ) )
      (if (atom X)
         (or
            (<= (car N) X (cdr N))
            (>= (car N) X (cdr N)) )
         (find
            '((Y)
               (or
                  (<= (car N) Y (cdr N))
                  (>= (car N) Y (cdr N)) ) )
            X ) ) ) )

(be head (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("head"
               (get (car L) (cadr L))
               (cddr L) ) ) ) ) )

(de "head" (X L)
   (if L
      (cond
         ((atom X)
            ("head" (get X (car L)) (cdr L)) )
         ((pair (car L))
            ("head"
               (apply get (cdar L) (assoc (caar L) X))
               (cdr L) ) )
         (T
            (pick
               '((Y) ("head" (get Y (car L)) (cdr L)) )
               X ) ) )
      (if (atom X)
         (pre? S X)
         (find '((Y) (pre? S Y)) X) ) ) )

(be fold (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("fold"
               (get (car L) (cadr L))
               (cddr L) ) ) ) ) )

(de "fold" (X L)
   (if L
      (cond
         ((atom X)
            ("fold" (get X (car L)) (cdr L)) )
         ((pair (car L))
            ("fold"
               (apply get (cdar L) (assoc (caar L) X))
               (cdr L) ) )
         (T
            (pick
               '((Y) ("fold" (get Y (car L)) (cdr L)) )
               X ) ) )
      (if (atom X)
         (pre? (fold S) (fold X))
         (let P (fold S)
            (find
               '((Y) (pre? P (fold Y)))
               X ) ) ) ) )

(be part (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("part"
               (get (car L) (cadr L))
               (cddr L) ) ) ) ) )

(de "part" (X L)
   (if L
      (cond
         ((atom X)
            ("part" (get X (car L)) (cdr L)) )
         ((pair (car L))
            ("part"
               (apply get (cdar L) (assoc (caar L) X))
               (cdr L) ) )
         (T
            (pick
               '((Y) ("part" (get Y (car L)) (cdr L)) )
               X ) ) )
      (if (atom X)
         (sub? S X)
         (find '((Y) (sub? S Y)) X) ) ) )

(be tolr (@S . @L)
   (@ let S (-> @S)
      (or
         (not S)
         (let L (-> @L)
            ("tolr"
               (get (car L) (cadr L))
               (cddr L) ) ) ) ) )

(de "tolr" (X L)
   (if L
      (cond
         ((atom X)
            ("tolr" (get X (car L)) (cdr L)) )
         ((pair (car L))
            ("tolr"
               (apply get (cdar L) (assoc (caar L) X))
               (cdr L) ) )
         (T
            (pick
               '((Y) ("tolr" (get Y (car L)) (cdr L)) )
               X ) ) )
      (if (atom X)
         (or (sub? S X) (pre? (ext:Snx S) (ext:Snx X)))
         (let P (ext:Snx S)
            (find
               '((Y)
                  (or (sub? S Y) (pre? P (ext:Snx Y))) )
               X ) ) ) ) )


(de "select" (Lst Flg)
   (use (X Var Cls Hook Val)
      (when (atom (setq X (pop 'Lst)))
         (setq Cls (pop 'Lst)  Hook (and (get Cls X 'hook) (pop 'Lst))) )
      (when (or (setq Val (pop 'Lst)) Flg)
         (cons
            (cons
               (for (L NIL Lst)
                  (push 'L (pop 'Lst) NIL)
                   L )
               (if (atom X)
                  ("initSel" X Cls Hook)
                  (make
                     (while X
                        (chain
                           ("initSel"
                              (setq Var (pop 'X))
                              (setq Cls (pop 'X))
                              (and (get Cls Var 'hook) (pop 'Lst)) ) ) ) ) ) ) ) ) ) )

(de "initSel" (Var Cls Hook)
   (with (or (get Cls Var) (meta Cls Var))
      (when (find '((B) (isa '+Index B)) (: bag))
         (setq This @) )
      (cond
         ((isa '+Fold This)
            (initQuery Var (: cls) Hook (fold Val)) )
         ((isa '+Sn This)
            (conc
               (initQuery Var (: cls) Hook Val)
               (initQuery Var (: cls) Hook (ext:Snx Val)) ) )
         (T (initQuery Var (: cls) Hook Val)) ) ) )

(de _gen (Lst Q)
   (ifn Lst
      (step Q (= '(NIL) (caar Q)))
      (use (X)
         (loop
            (T
               (cond
                  ((atom (car Lst))
                     (prog1 (car Lst) (set Lst)) )
                  ((atom (caar Lst)) (pop Lst))
                  (T
                     (prog1
                        (step (car Lst) (= '(NIL) (caaar Lst)))
                        (or (cdar Lst) (set Lst)) ) ) )
               @ )
            (NIL (setq X (_gen (cddr Lst) Q)))
            (set Lst
               (cond
                  ((atom (cadr Lst)) (get X (cadr Lst)))
                  ((=T (caddr (cadr Lst)))
                     (initQuery
                        (caadr Lst)
                        (cadr (cadr Lst))
                        X
                        (cadddr (cadr Lst)) ) )
                  (T
                     (initQuery
                        (caadr Lst)
                        (cadr (cadr Lst))
                        (caddr (cadr Lst))
                        X ) ) ) ) ) ) ) )

(be select (("@Obj" . "@X") . "@Lst")
   (@ unify (-> "@X"))
   ("@P" box (cdr (-> "@Lst")))
   ("@C" box  # ((obj ..) curr . lst)
      (let L (car (-> "@Lst"))
         (setq L
            (or
               (mapcan "select" L)
               ("select" (car L) T) ) )
         (cons NIL (cons L L)) ) )
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
