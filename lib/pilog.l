# 19dec02abu
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
         (do NIL
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
   (let "R" (prove "Q" "Dbg")
      (do NIL
         (NIL "R")
         (T (=T "R") T)
         (mapc
            '((X)
               (space)
               (print (car X))
               (print '=)
               (print (cdr X)) )
            "R" )
         (T (line))
         (setq "R" (prove "Q" "Dbg")) ) ) )

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

(be asserta (@C) (@ asserta (-> @C)))
(be assertz (@C) (@ assertz (-> @C)))

(be clause ("@H" "@B")
   ("@A" get (-> "@H") T)
   (member "@B" "@A") )


### DB ###
(be isa (@Typ @Obj) (@ isa (-> @Typ) (-> @Obj)))
(be isa (@Typ @Obj) (@Typ val (-> @Obj)))

(de initQuery (Var Cls Tree Val)
   (cond
      ((pair Val)
         (cond
            ((isa '+Key (get Cls Var))
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
         (if (isa '+Key (get Cls Var))
            (init Tree Val Val)
            (init Tree (cons Val) (cons Val T)) ) )
      (T
         (cond
            ((isa '+Key (get Cls Var))
               (init Tree Val (pack Val `(char T))) )
            ((isa '+Idx (get Cls Var))
               (let Q (init Tree (cons Val) (cons (pack Val `(char T)) T))
                  (if (cdr Q)
                     Q
                     (setq Val (pack (car (split (chop Val) " "))))
                     (init Tree (cons Val) (cons (pack Val `(char T)) T)) ) ) )
            (T (init Tree (cons Val) (cons (pack Val `(char T)) T))) ) ) ) )

(be db (@Var @Cls @Obj) (db @Var @Cls (NIL . T) @Obj))

(be db (@Var @Cls @Val @Obj) (db @Var @Cls NIL @Val @Obj))

(be db (@Var @Cls @Hook @Val @Obj)
   (@Q box
      (with
         (or
            (get (-> @Cls) (-> @Var))
            (meta (-> @Cls) (-> @Var)) )
         (initQuery (: var) (: cls)
            (tree (: var) (: cls) (-> @Hook))
            (-> @Val) ) ) )
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


(be show (@Obj) (@ show (-> @Obj)))


(be val (@V . @L)
   (@V let (L (-> @L)  X (pop 'L))
      (while L
         (setq X (get X (pop 'L))) )
      X )
   T )

(be lst (@V . @L)
   (@Lst box
      (let (L (-> @L)  X (pop 'L))
         (while L
            (setq X (get X (pop 'L))) )
         X ) )
   (_lst @V @Lst) )

(be _lst (@Val @Lst) (@ not (val (-> @Lst))) T (fail))
(be _lst (@Val @Lst) (@Val pop (-> @Lst)))
(repeat)


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
      (if (atom X)
         ("same" (get X (car L)) (cdr L))
         (pick
            '((Y)
               ("same" (get Y (car L)) (cdr L)) )
            X ) )
      (if (atom X)
         (= V X)
         (find '((Y) (= V Y)) X) ) ) )

(be bool (@F . @L)
   (@ let F (-> @F)
      (or
         (=0 F)
         (let (L (-> @L)  X (pop 'L))
            (while L
               (setq X (get X (pop 'L))) )
            (= F X) ) ) ) )

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
      (if (atom X)
         ("range" (get X (car L)) (cdr L))
         (pick
            '((Y)
               ("range" (get Y (car L)) (cdr L)) )
            X ) )
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
      (if (atom X)
         ("head" (get X (car L)) (cdr L))
         (pick
            '((Y)
               ("head" (get Y (car L)) (cdr L)) )
            X ) )
      (if (atom X)
         (pre? S X)
         (find '((Y) (pre? S Y)) X) ) ) )

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
      (if (atom X)
         ("part" (get X (car L)) (cdr L))
         (pick
            '((Y)
               ("part" (get Y (car L)) (cdr L)) )
            X ) )
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
      (if (atom X)
         ("tolr" (get X (car L)) (cdr L))
         (pick
            '((Y)
               ("tolr" (get Y (car L)) (cdr L)) )
            X ) )
      (if (atom X)
         (tolr S X)
         (find '((Y) (tolr S Y)) X) ) ) )


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
   (if (isa '+Sn (get Cls Var))
      (conc
         (initQuery Var Cls (tree Var Cls Hook) Val)
         (initQuery Var Cls (tree Var Cls Hook) (ext:Snx Val)) )
      (initQuery Var Cls (tree Var Cls Hook) Val) ) )

(de _gen (Lst Q)
   (ifn Lst
      (step Q (= '(NIL) (caar Q)))
      (use (X)
         (do NIL
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
               (if (atom (cadr Lst))
                  (get X (cadr Lst))
                  (init
                     (apply tree (cadr Lst))
                     (cons X)
                     (cons X T) ) ) ) ) ) ) )

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
   (@ not (memq "*R" (car (val (-> "@C")))))
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
      (push C (-> "@Obj" 2))
      (rot (cddr C) (offset (cadr C) (cddr C)))
      (set (cdr C) (cddr C)) )
   T )

(be _sel ()
   (@ let C (cdr (val (-> "@C" 2)))
      (set C (or (cdar C) (cdr C))) )
   (fail) )
