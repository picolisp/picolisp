# 14sep04abu
# (c) Software Lab. Alexander Burger

### DB Unload/Load ###
(de dbUnload (File)
   (out File
      (for (S *DB S (seq S))
         (println (cons S (cons (val S) (getl S)))) ) ) )

(de dbLoad (File)
   (in File
      (let (P *DB  F)
         (for (L (read) L (read))
            (setq F (seq P (setq P (car L)) F))
            (commit) ) ) )
   (in File
      (for (L (read) L (read))
         (set (car L) (cadr L))
         (putl (car L) (cddr L))
         (commit) ) ) )


### DB Garbage Collection ###
(de dbgc ()
   (markExt *DB)
   (let N 0
      (for (S *DB  S  (seq S))
         (unless (mark S)
            (inc 'N)
            (and (isa '+Entity S) (zap> S))
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
         (println '== Cls Base)
         (for X (getl Base)
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
                     (or
                        (isa Cls V)
                        (isa '+Alt (meta V (cdr X)))
                        (quit "Bad Type" V) )
                     (unless (has> V (cdr X) (if (pair K) (car K) K))
                        (quit "Bad Value" K) ) )
                  NIL T T ) ) )
         (wipe Base) ) ) )


### Check Index References ###
(de dangling (Var Cls Excl)
   (or
      (isa '+Index (get Cls Var))
      (find '((B) (isa '+Index B)) (get Cls Var 'bag))
      (quit "No Index" (cons Var Cls)) )
   (when
      (mapcan
         '((Obj) (dangle Obj Excl))
         (collect Var Cls) )
      (println 'dangling Var Cls @) ) )

(de dangle (Obj Excl)
   (and
      (make
         (for X (getl Obj)
            (let V (or (atom X) (pop 'X))
               (unless (memq X Excl)
                  (with (meta Obj X)
                     (and
                        (isa '+Fold This)
                        (setq V
                           (if (pair V)
                              (mapcar fold V)
                              (fold V) ) ) )
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
                           (if (isa '+List This)
                              (and
                                 (find
                                    '((Y)
                                       (fetch
                                          (tree Y (: cls) (get Obj (: hook)))
                                          (cons V Obj) ) )
                                    V )
                                 (link X) )
                              (and
                                 (<> Obj
                                    (fetch
                                       (tree X (: cls) (get Obj (: hook)))
                                       (cons V Obj) ) )
                                 (link X) ) ) )
                        (T
                           (for B (: bag)
                              (cond
                                 ((isa '+Key B)
                                    (let N (index B (: bag))
                                       (with B
                                          (when
                                             (find
                                                '((L)
                                                   (and
                                                      (get L N)
                                                      (<> Obj
                                                         (fetch
                                                            (tree (: var) (: cls)
                                                               (get
                                                                  (if (sym? (: hook)) Obj L)
                                                                  (: hook) ) )
                                                            (get L N) ) ) ) )
                                                   V )
                                                (link X) ) ) ) )
                                 ((isa '+Ref B)
                                    (let N (index B (: bag))
                                       (with B
                                          (when
                                             (find
                                                '((L)
                                                   (and
                                                      (get L N)
                                                      (<> Obj
                                                         (fetch
                                                            (tree (: var) (: cls)
                                                               (get
                                                                  (if (sym? (: hook)) Obj L)
                                                                  (: hook) ) )
                                                            (cons (get L N) Obj) ) ) ) )
                                                   V )
                                                (link X) ) ) ) ) ) ) ) ) ) ) ) ) )
      (list (cons Obj @)) ) )


### Rebuild tree ###
(de rebuild (Lst Var Cls Hook)
   (when (get (or Hook *DB) Cls)
      (put @ Var NIL)
      (commit)
      (dbgc) )
   (for Obj Lst
      (and
         (not (get Obj T))
         (get Obj Var)
         (let Val @
            (put> Obj Var NIL)
            (put> Obj Var Val)
            (commit) ) ) ) )
