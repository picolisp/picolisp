# 16feb03abu
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
      (unless (=0 N)
         (commit)
         N ) ) )

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

### Check tree structures ###
(de dbCheck ()
   (maps _dbCheck *DB)
   (mark 0) )

(de _dbCheck (X)
   (when (and (pair X) (= `(char "+") (char (cdr X))) (not (mark (car X))))
      (mark (car X) T)
      (when (= '(+ObjRoot) (val (car X)))  #! Legacy
         (set (car X))
         (commit) )
      (println '== (cdr X) (car X))
      (maps
         '((X)
            (when (and (pair X) (sym? (cdr X)) (pair (car X)) (num? (caar X)))
               (println (cdr X) (cdar X) (caar X))
               (unless (= (caar X) (check (cdar X)))
                  (quit "Tree size mismatch") )
               (iter (car X)
                  '((Obj) (maps _dbCheck Obj)) )
               (scan (car X)
                  '((K V)
                     (setq V (get V (cdr X)))
                     (unless
                        (or
                           (member K V)
                           (find '((L) (member K L)) V)
                           (and (pair K)
                              (or
                                 (member (car K) V)
                                 (find '((L) (member (car K) L)) V) ) ) )
                        (quit "Bad Index" K) ) )
                  NIL T T ) ) )
         (car X) )
      (wipe (car X)) ) )

### Index References ###
(de dangling (Var Cls Hook)
   (or
      (isa '+Index (get Cls Var))
      (find '((B) (isa '+Ref B)) (get Cls Var 'bag))
      (quit "No Index" (cons Var Cls)) )
   (mapcan
      '((Obj)
         (and
            (mapcan
               '((X)
                  (and
                     (pair X)
                     (get Obj (cdr X))
                     (let V (pop 'X)
                        (cond
                           ((isa '+Joint V)
                              (if (isa '+List V)
                                 (unless
                                    (find
                                       '((Y)
                                          (if (atom (setq Y (get Y (get V 'slot))))
                                             (== Obj Y)
                                             (memq Obj Y) ) )
                                       (get Obj X) )
                                    (list X) )
                                 (when (get Obj X)
                                    (let Y (get @ (get V 'slot))
                                       (if (atom Y)
                                          (unless (== Obj Y) (list X))
                                          (unless (memq Obj Y) (list X)) ) ) ) ) )
                           ((isa '+Key V)
                              (and
                                 (<> Obj
                                    (fetch
                                       (tree X Cls (get Obj (get V 'hook)))
                                       (get Obj X) ) )
                                 (list X) ) )
                           ((isa '+Ref V)
                              (if (isa '+List V)
                                 (and
                                    (find
                                       '((X)
                                          (fetch
                                             (tree X Cls (get Obj (get V 'hook)))
                                             (cons (get Obj X) Obj) ) )
                                       (get Obj X) )
                                    (list X) )
                                 (and
                                    (<> Obj
                                       (fetch
                                          (tree X Cls (get Obj (get V 'hook)))
                                          (cons (get Obj X) Obj) ) )
                                    (list X) ) ) )
                           ((find '((B) (isa '+Ref B)) (get V 'bag))
                              (with @
                                 (let N (index This (get V 'bag))
                                    (when
                                       (find
                                          '((L)
                                             (and
                                                (get L N)
                                                (<> Obj
                                                   (fetch
                                                      (tree (: var) (: cls) (: hook))
                                                      (cons (get L N) Obj) ) ) ) )
                                          (get Obj X) )
                                       (list X) ) ) ) ) ) ) ) )
               (getl Cls) )
            (list (cons Obj @)) ) )
      (collect Var Cls Hook) ) )
