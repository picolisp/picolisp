# 27jul03abu
# (c) Software Lab. Alexander Burger

### DB Unload/Load ###
(de dbUnload ()
   (for (S *DB S (seq S))
      (println (cons S (cons (val S) (getl S)))) ) )

(de dbLoad1 ()
   (let P *DB
      (for (L (read) L (read))
         (seq P (setq P (car L)))
         (commit) ) ) )

(de dbLoad2 ()
   (for (L (read) L (read))
      (set (car L) (cadr L))
      (putl (car L) (cddr L))
      (commit) ) )


### DB Garbage Collection ###
(de dbgc ()
   (markExt *DB)
   (let N 0
      (for (S *DB  S  (seq S))
         (unless (mark S)
            (inc 'N)
            (and (ntt? S) (zap> S))
            (zap S) ) )
      (mark 0)
      (commit)
      (when *Blob
         (use (@S @R F)
            (let Pat (conc (chop *Blob) '(@S "." @R))
               (in (list "find" *Blob "-type" "f")
                  (whilst (setq F (line))
                     (when (match Pat F)
                        (unless
                           (and
                              (extern (pack (replace @S "/")))
                              (get @ (intern (pack @R))) )
                           (inc 'N)
                           (call "rm" (pack F)) ) ) ) ) ) ) )
      (and (n0 N) N) ) )

(de markExt (S)
   (unless (mark S)
      (mark S T)
      (markData (val S))
      (maps markData S)
      (wipe S) ) )

(de markData (X)
   (while (pair X)
      (markData (pop 'X)) )
   (and (ext? X) (markExt X)) )


### Check tree structures ###
(de dbCheck ()
   (let Hook NIL
      (mapc _dbCheck (getl *DB)) )
   (mark 0) )

(de _dbCheck (X)
   (when (and (pair X) (= `(char "+") (char (cdr X))) (not (mark (car X))))
      (let (Base (car X)  Cls (cdr X))
         (mark Base T)
         (when (= '(+ObjRoot) (val Base))    #! Legacy
            (set Base)                       #
            (commit) )                       #
         (println '== Cls Base)
         (mapc
            '((X)
               (when (and (pair X) (sym? (cdr X)) (pair (car X)) (num? (caar X)))
                  (println (cdr X) (cdar X) (caar X))
                  (unless (= (caar X) (check (cdar X)))
                     (quit "Tree size mismatch") )
                  (iter (tree (cdr X) Cls Hook)
                     '((Obj)
                        (let Hook Obj
                           (mapc _dbCheck (getl Obj)) ) ) )
                  (scan (tree (cdr X) Cls Hook)
                     '((K V)
                        (unless (isa Cls V)
                           (quit "Bad Type" V) )
                        (setq V (get V (cdr X)))
                        (unless
                           (or
                              (member K V)
                              (find '((L) (member K L)) V)
                              (and (pair K)
                                 (or
                                    (member (car K) V)
                                    (find '((L) (member (car K) L)) V) ) ) )
                           (quit "Bad Value" K) ) )
                     NIL T T ) ) )
            (getl Base) )
         (wipe Base) ) ) )


### Check Index References ###
(de dangling (Var Cls Excl)
   (or
      (isa '+Index (get Cls Var))
      (find '((B) (isa '+Ref B)) (get Cls Var 'bag))
      (quit "No Index" (cons Var Cls)) )
   (when
      (mapcan
         '((Obj) (dangle Obj Excl))
         (collect Var Cls) )
      (println 'dangling Var Cls @) ) )

(de dangle (Obj Excl)
   (and
      (mapcan
         '((X)
            (let V (or (atom X) (pop 'X))
               (unless (memq X Excl)
                  (with (meta Obj X)
                     (cond
                        ((isa '+Joint This)
                           (if (isa '+List This)
                              (unless
                                 (find
                                    '((Y)
                                       (if (atom (setq Y (get Y (: slot))))
                                          (== Obj Y)
                                          (memq Obj Y) ) )
                                    V )
                                 (list X) )
                              (let Y (get V (: slot))
                                 (if (atom Y)
                                    (unless (== Obj Y) (list X))
                                    (unless (memq Obj Y) (list X)) ) ) ) )
                        ((isa '+Key This)
                           (and
                              (<> Obj
                                 (fetch
                                    (tree X (: cls) (get Obj (: hook)))
                                    V ) )
                              (list X) ) )
                        ((isa '+Ref This)
                           (if (isa '+List This)
                              (and
                                 (find
                                    '((Y)
                                       (fetch
                                          (tree Y (: cls) (get Obj (: hook)))
                                          (cons V Obj) ) )
                                    V )
                                 (list X) )
                              (and
                                 (<> Obj
                                    (fetch
                                       (tree X (: cls) (get Obj (: hook)))
                                       (cons V Obj) ) )
                                 (list X) ) ) )
                        ((find '((B) (isa '+Ref B)) (: bag))
                           (let (R @  N (index R (: bag)))
                              (when
                                 (find
                                    '((L)
                                       (and
                                          (get L N)
                                          (<> Obj
                                             (fetch
                                                (tree (get R 'var) (get R 'cls) (get R 'hook))
                                                (cons (get L N) Obj) ) ) ) )
                                    V )
                                 (list X) ) ) ) ) ) ) ) )
         (getl Obj) )
      (list (cons Obj @)) ) )


### Rebuild tree ###
(de rebuild (Lst Var Cls Hook)
   (when (get (or Hook *DB) Cls)
      (put @ Var NIL)
      (commit) )
   (mapc
      '((Obj)
         (and
            (not (get Obj T))
            (get Obj Var)
            (let Val @
               (put> Obj Var NIL)
               (put> Obj Var Val)
               (commit) ) ) )
      Lst ) )
