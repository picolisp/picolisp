# 21jan07abu
# (c) Software Lab. Alexander Burger

# This file is deprecated
# Use "lib/btree.l" for all new projects

# *VisitedKey *VisitedLess *VisitedMore


### Pilog compatibility ###
(be _db (@Obj)
   (@ let (Q (val (-> @Q 2))  Cls (-> @Cls 2))
      (loop
         (NIL (step Q (= '(NIL) (caar Q))) T)
         (T (isa Cls (setq "R" @))) ) )
   T
   (fail) )

(be _db (@Obj) (@Obj . "R"))

(repeat)


(undef '_gen)
(de _gen (Lst Q)
   (ifn Lst
      (step Q (= '(NIL) (caar Q)))
      (use X
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
                              X ) ) ) ) ) ) ) ) ) )

### End Pilog compatibility ###

(mapc undef
   (quote
      fetch store _store _put _del maxKey minKey init step
      scan _scan _nacs iter _iter _reti check ) )


(de root (Tree)
   (cond
      ((not Tree) (val *DB))
      ((atom Tree) (val Tree))
      ((ext? (cdr Tree)) (get @ (car Tree)))
      ((atom (cdr Tree))
         (get *DB (cdr Tree) (car Tree)) )
      (T (get (cddr Tree) (cadr Tree) (car Tree))) ) )

# Fetch
(de fetch (Tree Key)
   (let Node (cdr (root Tree))
      (loop
         (NIL Node)
         (T (= Key (car (val Node)))
            (cdddr (val Node)) )
         (setq Node
            ((if (< Key (car (val Node))) cadr caddr)
               (val Node) ) ) ) ) )

# Store
(de store (Tree Key Val Dbf)
   (default Dbf (1 . 64))
   (if (atom Tree)
      (let Base (or Tree *DB)
         (_store (or (val Base) (set Base (cons 0)))) )
      (let Base
         (if (atom (cdr Tree))
            (or
               (ext? (cdr Tree))
               (get *DB (cdr Tree))
               (put *DB (cdr Tree) (new T)) )
            (or
               (get (cddr Tree) (cadr Tree))
               (put (cddr Tree) (cadr Tree) (new T)) ) )
         (_store
            (or
               (get Base (car Tree))
               (put Base (car Tree) (cons 0)) ) ) ) )
   Val )


(de _store (Root)
   (con Root ((if Val _put _del) (cdr Root))) )

(de _put (Top)
   (ifn Top
      (prog1 (new (car Dbf))
         (set @ (cons Key (cons NIL (cons NIL Val))))
         (setq *VisitedKey Key)
         (off *VisitedLess *VisitedMore)
         (touch Base)
         (inc Root) )
      (use (Less More Node)
         (setq
            Less (cadr (val Top))
            More (caddr (val Top)) )
         (cond
            ((= Key (car (val Top)))
               (con (cddr (val (touch Top))) Val) )
            ((< Key (car (val Top)))
               (unless (== Less (setq Node (_put Less)))
                  (if (> (seed (car (val Top))) (seed *VisitedKey))
                     (set  # Rotate right
                        (cdr (val (touch Top))) *VisitedMore   # Top->less
                        (cddr (val (touch Node))) Top          # Node->more
                        '*VisitedMore Top
                        'Top Node )
                     (set
                        (cdr (val (touch Top))) Node  # Top->less
                        '*VisitedKey (car (val Top))
                        '*VisitedLess Node
                        '*VisitedMore More ) ) ) )
            (T
               (unless (== More (setq Node (_put More)))
                  (if (> (seed (car (val Top))) (seed *VisitedKey))
                     (set  # Rotate left
                        (cddr (val (touch Top))) *VisitedLess  # Top->more
                        (cdr (val (touch Node))) Top           # Node->less
                        '*VisitedLess Top
                        'Top Node )
                     (set
                        (cddr (val (touch Top))) Node  # Top->more
                        '*VisitedKey (car (val Top))
                        '*VisitedLess Less
                        '*VisitedMore Node ) ) ) ) )
         Top ) ) )

# Del
(de _del (Top)
   (when Top
      (cond
         ((= Key (car (val Top)))
            (touch Base)
            (dec Root)
            (prog1
               (_delR (cadr (val Top)) (caddr (val Top)))
               (and *Solo (zap Top)) ) )
         ((< Key (car (val Top)))
            (use Node
               (ifn
                  (=
                     (cadr (val Top))
                     (setq Node (_del (cadr (val Top)))) )
                  (set (cdr (val (touch Top))) Node) ) )
            Top )
         (T
            (use Node
               (ifn
                  (=
                     (caddr (val Top))
                     (setq Node (_del (caddr (val Top)))) )
                  (set (cddr (val (touch Top))) Node) ) )
            Top ) ) ) )

(de _delR (Less More)
   (ifn Less
      More
      (if More
         (set
            (cddr (val (touch Less)))
            (_delL (caddr (val Less)) More) ) )
      Less ) )

(de _delL (Less More)
   (ifn More
      Less
      (if Less
         (set
            (cdr (val (touch More)))
            (_delR Less (cadr (val More))) ) )
      More ) )

# Tree node count
(de count (Tree)
   (or (car (root Tree)) 0) )

# Key management
(de minKey (Tree Min Max)
   (default Max T)
   (let (Node (cdr (root Tree))  K)
      (while Node
         (if (> Min (car (val Node)))
            (setq Node (caddr (val Node)))
            (when (>= Max (car (val Node)))
               (setq K (car (val Node))) )
            (setq Node (cadr (val Node))) ) )
      K ) )

(de maxKey (Tree Min Max)
   (default Max T)
   (let (Node (cdr (root Tree))  K)
      (while Node
         (if (>= (car (val Node)) Max)
            (setq Node (cadr (val Node)))
            (when (>= (car (val Node)) Min)
               (setq K (car (val Node))) )
            (setq Node (caddr (val Node))) ) )
      K ) )

# Step
(de init (Tree Beg End)
   (or Beg End (on End))
   (let (Node (cdr (root Tree))  Q)
      (if (>= End Beg)
         (while Node
            (if (> Beg (car (val Node)))
               (setq Node (caddr (val Node)))
               (when (>= End (car (val Node)))
                  (push 'Q Node) )
               (setq Node (cadr (val Node))) ) )
         (while Node
            (if (< Beg (car (val Node)))
               (setq Node (cadr (val Node)))
               (when (<= End (car (val Node)))
                  (push 'Q Node) )
               (setq Node (caddr (val Node))) ) ) )
      (cons (cons Beg End) Q) ) )

(de step (Q F)
   (use (Node Val)
      (while
         (prog
            (until (prog (setq Node (cadr Q)) (con Q (cddr Q)) (atom Node))
               (set Q Node) )
            (setq Val (val Node))
            (wipe Node)
            (if (>= (cdar Q) (caar Q))
               (when (setq Node (caddr Val))
                  (loop
                     (NIL (<= (caar Q) (car (val Node))))
                     (when (>= (cdar Q) (car (val Node)))
                        (con Q (cons Node (cdr Q))) )
                     (NIL (setq Node (cadr (val Node)))) ) )
               (when (setq Node (cadr Val))
                  (loop
                     (NIL (>= (caar Q) (car (val Node))))
                     (when (<= (cdar Q) (car (val Node)))
                        (con Q (cons Node (cdr Q))) )
                     (NIL (setq Node (caddr (val Node)))) ) ) )
            (and Val F (flg? (fin (car Val)))) ) )
      (cdddr Val) ) )

(====)

# Scan tree nodes
(de scan ("Tree" "Foo" "Beg" "End" "F")
   (default "Foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _scan _nacs)
      (cdr (root "Tree")) ) )

(de _scan ("Node")
   (let? "X" (val "Node")
      (if (> (car "X") "End")
         (_scan (cadr "X"))
         (when (>= (car "X") "Beg")
            (_scan (cadr "X"))
            (unless (and "F" (flg? (fin (car "X"))))
               ("Foo" (car "X") (cdddr "X")) ) )
         (_scan (caddr "X")) )
      (wipe "Node") ) )

(de _nacs ("Node")
   (let? "X" (val "Node")
      (if (> "End" (car "X"))
         (_nacs (caddr "X"))
         (when (>= "Beg" (car "X"))
            (_nacs (caddr "X"))
            (unless (and "F" (flg? (fin (car "X"))))
               ("Foo" (car "X") (cdddr "X")) ) )
         (_nacs (cadr "X")) )
      (wipe "Node") ) )

(====)

# Iterate tree values
(de iter ("Tree" "Foo" "Beg" "End" "F")
   (default "Foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _iter _reti)
      (cdr (root "Tree")) ) )

(de _iter ("Node")
   (let? "X" (val "Node")
      (if (> (car "X") "End")
         (_iter (cadr "X"))
         (when (>= (car "X") "Beg")
            (_iter (cadr "X"))
            (unless (and "F" (flg? (fin (car "X"))))
               ("Foo" (cdddr "X")) ) )
         (_iter (caddr "X")) )
      (wipe "Node") ) )

(de _reti ("Node")
   (let? "X" (val "Node")
      (if (> "End" (car "X"))
         (_reti (caddr "X"))
         (when (>= "Beg" (car "X"))
            (_reti (caddr "X"))
            (unless (and "F" (flg? (fin (car "X"))))
               ("Foo" (cdddr "X")) ) )
         (_reti (cadr "X")) )
      (wipe "Node") ) )

(====)

# Check tree structure
(de check ("Node" "Foo")
   (let ("N" 0  "X")
      (when "Node"
         (recur ("Node")
            (let "V" (val "Node")
               (when (> 3 (size "V"))
                  (quit "Bad node size" "Node") )
               (when (cadr "V")
                  (unless (ext? (cadr "V"))
                     (quit "Bad node link" "Node") )
                  (recurse (cadr "V")) )
               (when (>= "X" (car "V"))
                  (quit "Bad sequence" "Node") )
               (setq "X" (car "V"))
               (inc '"N")
               (and
                  "Foo"
                  (not ("Foo" (car "V") (cdddr "V")))
                  (quit "Check fail" "Node") )
               (when (caddr "V")
                  (unless (ext? (caddr "V"))
                     (quit "Bad node link" "Node") )
                  (recurse (caddr "V")) ) )
            (wipe "Node") ) )
      "N" ) )
