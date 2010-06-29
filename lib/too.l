# 14jun10abu
# (c) Software Lab. Alexander Burger

### DB Garbage Collection ###
(de dbgc ()
   (markExt *DB)
   (let Cnt 0
      (finally (mark 0)
         (for (F . @) (or *Dbs (2))
            (for (S (seq F)  S  (seq S))
               (unless (mark S)
                  (inc 'Cnt)
                  (and (isa '+Entity S) (zap> S))
                  (zap S) ) ) ) )
      (commit)
      (when *Blob
         (use (@S @R F S)
            (let Pat (conc (chop *Blob) '(@S "." @R))
               (in (list 'find *Blob "-type" "f")
                  (while (setq F (line))
                     (when (match Pat F)
                        (unless
                           (and
                              (setq S (extern (pack (replace @S '/))))
                              (get S (intern (pack @R))) )
                           (inc 'Cnt)
                           (call 'rm (pack F)) )
                        (wipe S) ) ) ) ) ) )
      (gt0 Cnt) ) )

(de markExt (S)
   (unless (mark S T)
      (markData (val S))
      (maps markData S)
      (wipe S) ) )

(de markData (X)
   (while (pair X)
      (markData (pop 'X)) )
   (and (ext? X) (markExt X)) )


### DB Mapping ###
(de dbMap ("ObjFun" "TreeFun")
   (default "ObjFun" quote "TreeFun" quote)
   (finally (mark 0)
      (_dbMap *DB)
      (dbMapT *DB) ) )

(de _dbMap ("Hook")
   (unless (mark "Hook" T)
      ("ObjFun" "Hook")
      (for "X" (getl "Hook")
         (when (pair "X")
            (if
               (and
                  (ext? (car "X"))
                  (not (isa '+Entity (car "X")))
                  (sym? (cdr "X"))
                  (find
                     '(("X") (isa '+relation (car "X")))
                     (getl (cdr "X")) ) )
               (let ("Base" (car "X")  "Cls" (cdr "X"))
                  (dbMapT "Base")
                  (for "X" (getl "Base")
                     (when
                        (and
                           (pair "X")
                           (sym? (cdr "X"))
                           (pair (car "X"))
                           (num? (caar "X"))
                           (ext? (cdar "X")) )
                        ("TreeFun" "Base" (car "X") (cdr "X") "Cls" "Hook")
                        (iter (tree (cdr "X") "Cls" "Hook") _dbMap) ) )
                  (wipe "Base") )
               (dbMapV (car "X")) ) ) )
      (wipe "Hook") ) )

(de dbMapT ("Base")
   (let "X" (val "Base")
      (when
         (and
            (pair "X")
            (num? (car "X"))
            (ext? (cdr "X")) )
         ("TreeFun" "Base" "X")
         (iter "Base" dbMapV) ) ) )

(de dbMapV ("X")
   (while (pair "X")
      (dbMapV (pop '"X")) )
   (and (ext? "X") (_dbMap "X")) )


### DB Check ###
(de dbCheck ()
   (and (lock) (quit 'lock @))  # Lock whole database
   (for (F . N) (or *Dbs (2))  # Low-level integrity check
      (unless (pair (println F N (dbck F T)))
         (quit 'dbck @) ) )
   (dbMap  # Check tree structures
      NIL
      '((Base Root Var Cls Hook)
         (println Base Root Var Cls Hook)
         (unless (= (car Root) (chkTree (cdr Root)))
            (quit "Tree size mismatch") )
         (when Var
            (scan (tree Var Cls Hook)
               '((K V)
                  (or
                     (isa Cls V)
                     (isa '+Alt (meta V Var))
                     (quit "Bad Type" V) )
                  (unless (has> V Var (if (pair K) (car K) K))
                     (quit "Bad Value" K) ) )
               NIL T T ) ) ) )
   (and *Dbs (dbfCheck))  # Check DB file assignments
   (and (dangling) (println 'dangling @))  # Show dangling index references
   T )

(de dangling ()
   (make
      (dbMap
         '((This)
            (and
               (not (: T))
               (dangle This)
               (link @) ) ) ) ) )

# Check Index References
(de dangle (Obj)
   (and
      (make
         (for X (getl Obj)
            (let V (or (atom X) (pop 'X))
               (with (meta Obj X)
                  (cond
                     ((isa '+Joint This)
                        (if (isa '+List This)
                           (when
                              (find
                                 '((Y)
                                    (if (atom (setq Y (get Y (: slot))))
                                       (n== Obj Y)
                                       (not (memq Obj Y)) ) )
                                 V )
                              (link X) )
                           (let Y (get V (: slot))
                              (if (atom Y)
                                 (unless (== Obj Y) (link X))
                                 (unless (memq Obj Y) (link X)) ) ) ) )
                     ((isa '+Key This)
                        (and
                           (<> Obj
                              (fetch
                                 (tree X (: cls) (get Obj (: hook)))
                                 V ) )
                           (link X) ) )
                     ((isa '+Ref This)
                        (let
                           (Tree (tree X (: cls) (get Obj (: hook)))
                              Aux (conc (mapcar '((S) (get Obj S)) (: aux)) Obj) )
                           (if (isa '+List This)
                              (when
                                 (find
                                    '((Y)
                                       (and
                                          (or
                                             (not (isa '+Fold This))
                                             (setq V (fold V)) )
                                          (<> Obj (fetch Tree (cons Y Aux))) ) )
                                    V )
                                 (link X) )
                              (and
                                 (or
                                    (not (isa '+Fold This))
                                    (setq V (fold V)) )
                                 (<> Obj (fetch Tree (cons V Aux)))
                                 (link X) ) ) ) )
                     (T
                        (for (N . B) (: bag)
                           (cond
                              ((isa '+Key B)
                                 (with B
                                    (when
                                       (find
                                          '((L)
                                             (let? Val (get L N)
                                                (<> Obj
                                                   (fetch
                                                      (tree (: var) (: cls)
                                                         (get
                                                            (if (sym? (: hook)) Obj L)
                                                            (: hook) ) )
                                                      Val ) ) ) )
                                             V )
                                          (link X) ) ) )
                              ((isa '+Ref B)
                                 (with B
                                    (when
                                       (find
                                          '((L)
                                             (let? Val (get L N)
                                                (when (isa '+Fold This)
                                                   (setq Val (fold Val)) )
                                                (<> Obj
                                                   (fetch
                                                      (tree (: var) (: cls)
                                                         (get
                                                            (if (sym? (: hook)) Obj L)
                                                            (: hook) ) )
                                                      (cons Val Obj) ) ) ) )
                                             V )
                                          (link X) ) ) ) ) ) ) ) ) ) ) )
      (cons Obj @) ) )


### Rebuild tree ###
(de rebuild (X Var Cls Hook)
   (let Lst NIL
      (let? Base (get (or Hook *DB) Cls)
         (unless X
            (setq Lst
               (if (; (treeRel Var Cls) hook)
                  (collect Var Cls Hook)
                  (collect Var Cls) ) ) )
         (zapTree (get Base Var -1))
         (put Base Var NIL)
         (commit) )
      (nond
         (X
            (let Len (length Lst)
               (recur (Lst Len)
                  (unless (=0 Len)
                     (let (N (>> 1 (inc Len))  L (nth Lst N))
                        (re-index (car L) Var)
                        (recurse Lst (dec N))
                        (recurse (cdr L) (- Len N)) ) ) ) ) )
         ((atom X)
            (for Obj X
               (re-index Obj Var) ) )
         (NIL
            (for (Obj X Obj (seq Obj))
               (and (isa Cls Obj) (re-index Obj Var)) ) ) )
      (commit) ) )

(de re-index (Obj Var)
   (unless (get Obj T)
      (when (get Obj Var)
         (rel> (meta Obj Var) Obj NIL
            (put> (meta Obj Var) Obj NIL @) )
         (at (0 . 10000) (commit)) ) ) )


### Database file management ###
(de dbfCheck ()
   (for "Cls" (all)
      (when (and (= `(char "+") (char "Cls")) (isa '+Entity "Cls"))
         (or
            (get "Cls" 'Dbf)
            (meta "Cls" 'Dbf)
            (println 'dbfCheck "Cls") )
         (for Rel (getl "Cls")
            (and
               (pair Rel)
               (or
                  (isa '+index (car Rel))
                  (find '((B) (isa '+index B)) (; Rel 1 bag)) )
               (unless (; Rel 1 dbf)
                  (println 'dbfCheck (cdr Rel) "Cls") ) ) ) ) ) )

(de dbfMigrate (Pool Dbs)
   (let
      (scan
         '(("Tree" "Fun")
            (let "Node" (cdr (root "Tree"))
               (if (ext? (fin (val "Node")))
                  (recur ("Node")
                     (let? "X" (val "Node")
                        (recurse (cadr "X"))
                        ("Fun" (car "X") (cdddr "X"))
                        (recurse (caddr "X"))
                        (wipe "Node") ) )
                  (recur ("Node")
                     (let? "X" (val "Node")
                        (recurse (car "X"))
                        (for "Y" (cdr "X")
                           ("Fun" (car "Y") (or (cddr "Y") (fin (car "Y"))))
                           (recurse (cadr "Y")) )
                        (wipe "Node") ) ) ) ) )
         iter
         '(("Tree" "Bar")
            (scan "Tree" '(("K" "V") ("Bar" "V"))) )
         zapTree
         '((Node)
            (let? X (val Node)
               (zapTree (cadr X))
               (zapTree (caddr X))
               (zap Node) ) ) )
      (dbfUpdate) )
   (let Lst
      (make
         (for (S *DB S (seq S))
            (link (cons S (val S) (getl S))) ) )
      (pool)
      (call 'rm (pack Pool 1))
      (pool Pool Dbs)
      (set *DB (cadar Lst))
      (putl *DB (cddr (pop 'Lst)))
      (for L Lst
         (let New (new T)
            (set New (cadr L))
            (putl New (cddr L))
            (con L New) ) )
      (set *DB (dbfReloc0 (val *DB) Lst))
      (for X Lst
         (set (cdr X) (dbfReloc0 (val (cdr X)) Lst))
         (putl (cdr X) (dbfReloc0 (getl (cdr X)) Lst)) )
      (commit)
      (dbMap  # Relocate base symbols
         '((Obj)
            (putl Obj (dbfReloc0 (getl Obj) Lst))
            (commit) )
         '((Base Root Var Cls Hook)
            (when (asoq (cdr Root) Lst)
               (con Root (cdr @))
               (touch Base)
               (commit) ) ) ) ) )

(de dbfUpdate ()
   (dbMap  # Move
      '((Obj)
         (let N (or (meta Obj 'Dbf 1) 1)
            (unless (= N (car (id Obj T)))
               (let New (new N)
                  (set New (val Obj))
                  (putl New (getl Obj))
                  (set Obj (cons T New)) )
               (commit) ) ) ) )
   (when *Blob
      (for X
         (make
            (use (@S @R F S)
               (let Pat (conc (chop *Blob) '(@S "." @R))
                  (in (list 'find *Blob "-type" "f")
                     (while (setq F (line))
                        (and
                           (match Pat F)
                           (setq S (extern (pack (replace @S '/))))
                           (=T (car (pair (val S))))
                           (link
                              (cons (pack F) (blob (cdr (val S)) @R)) ) ) ) ) ) ) )
         (and (dirname (cdr X)) (call 'mkdir "-p" @))
         (call 'mv (car X) (cdr X)) ) )
   (dbMap  # Relocate
      '((Obj)
         (when (=T (car (pair (val Obj))))
            (setq Obj (cdr (val Obj))) )
         (when (isa '+Entity Obj)
            (putl Obj (dbfReloc (getl Obj)))
            (commit) ) )
      '((Base Root Var Cls Hook)
         (if Var
            (dbfRelocTree Base Root (tree Var Cls Hook) (get Cls Var 'dbf))
            (dbfRelocTree Base Root Base) ) ) )
   (dbgc) )

(de dbfReloc (X)
   (cond
      ((pair X)
         (cons (dbfReloc (car X)) (dbfReloc (cdr X))) )
      ((and (ext? X) (=T (car (pair (val X)))))
         (cdr (val X)) )
      (T X) ) )

(de dbfReloc0 (X Lst)
   (cond
      ((pair X)
         (cons (dbfReloc0 (car X) Lst) (dbfReloc0 (cdr X) Lst)) )
      ((asoq X Lst) (cdr @))
      (T X) ) )

(de dbfRelocTree (Base Root Tree Dbf)
   (let? Lst (make (scan Tree '((K V) (link (cons K V)))))
      (zapTree (cdr Root))
      (touch Base)
      (set Root 0)
      (con Root)
      (commit)
      (for X
         (make
            (for
               (Lst (cons Lst) Lst
                  (mapcan
                     '((L)
                        (let (N (/ (inc (length L)) 2)  X (nth L N))
                           (link (car X))
                           (make
                              (and (>= N 2) (link (head (dec N) L)))
                              (and (cdr X) (link @)) ) ) )
                     Lst ) ) ) )
         (store Tree
            (dbfReloc (car X))
            (dbfReloc (cdr X))
            Dbf ) )
      (commit) ) )


### Dump Objects ###
(de dump CL
   (let B 0
      (for ("Q" (goal CL) (asoq '@@ (prove "Q")))
         (let (Obj (cdr @)  Lst)
            (prin "(obj ")
            (_dmp Obj)
            (maps
               '((X)
                  (unless (member X Lst)
                     (prinl)
                     (space 3)
                     (cond
                        ((pair X)
                           (printsp (cdr X))
                           (_dmp (car X) T) )
                        ((isa '+Blob (meta Obj X))
                           (prin X " `(tmp " (inc 'B) ")")
                           (out (tmp B)
                              (in (blob Obj X) (echo)) ) )
                        (T (print X T)) ) ) )
                  Obj )
            (prinl " )")
            Obj ) ) ) )

(de _dmp (Obj Flg)
   (cond
      ((pair Obj)
         (prin "(")
         (_dmp (pop 'Obj) T)
         (while (pair Obj)
            (space)
            (_dmp (pop 'Obj) T) )
         (when Obj
            (prin " . ")
            (_dmp Obj T) )
         (prin ")") )
      ((ext? Obj)
         (when Flg
            (prin "`(obj ") )
         (prin "(")
         (catch NIL
            (maps
               '((X)
                  (with (and (pair X) (meta Obj (cdr X)))
                     (when (isa '+Key This)
                        (or Flg (push 'Lst X))
                        (printsp (type Obj) (: var))
                        (when (: hook)
                           (_dmp (: hook) T)
                           (space) )
                        (_dmp (car X) T)
                        (throw) ) ) )
               Obj )
            (print (type Obj))
            (maps
               '((X)
                  (with (and (pair X) (meta Obj (cdr X)))
                     (when (isa '+Ref This)
                        (space)
                        (or Flg (push 'Lst X))
                        (print (: var))
                        (when (: hook)
                           (space)
                           (_dmp (: hook) T) )
                        (space)
                        (_dmp (car X) T) ) ) )
               Obj ) )
         (when Flg
            (prin ")") )
         (prin ")") )
      (T (print Obj)) ) )

`*Dbg
(noLint 'dbfMigrate 'iter)

# vi:et:ts=3:sw=3
