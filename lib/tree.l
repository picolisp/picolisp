# 01dec04abu
# (c) Software Lab. Alexander Burger

# *VisitedKey *VisitedLess *VisitedMore

(de root (Tree)
   (cond
      ((not Tree) (val *DB))
      ((atom Tree) (val Tree))
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
(de store (Tree Key Val)
   (if (atom Tree)
      (let Base (or Tree *DB)
         (_store (or (val Base) (set Base (cons 0)))) )
      (let Base
         (if (atom (cdr Tree))
            (or
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
      (let Node (new T)
         (setq *VisitedKey Key)
         (off *VisitedLess *VisitedMore)
         (set Node
            (cons Key (cons NIL (cons NIL Val))) )
         (touch Base)
         (inc Root)
         Node )
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

# Calculate tree depth
(de depth (Tree)
   (dpth (cdr (root Tree))) )

(de dpth (Top)
   (ifn Top
      0
      (prog1
         (inc
            (max
               (dpth (cadr (val Top)))
               (dpth (caddr (val Top))) ) )
         (wipe Top) ) ) )

# Key management
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
(de scan ("Tree" "foo" "Beg" "End" "F")
   (default "foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _scan _nacs)
      (cdr (root "Tree")) ) )

(de _scan ("Node")
   (when (setq "Node" (val "Node"))
      (if (< "End" (car "Node"))
         (_scan (cadr "Node"))
         (when (<= "Beg" (car "Node"))
            (_scan (cadr "Node"))
            (unless (and "F" (flg? (fin (car "Node"))))
               ("foo" (car "Node") (cdddr "Node")) ) )
         (_scan (caddr "Node")) ) ) )

(de _nacs ("Node")
   (when (setq "Node" (val "Node"))
      (if (> "End" (car "Node"))
         (_nacs (caddr "Node"))
         (when (>= "Beg" (car "Node"))
            (_nacs (caddr "Node"))
            (unless (and "F" (flg? (fin (car "Node"))))
               ("foo" (car "Node") (cdddr "Node")) ) )
         (_nacs (cadr "Node")) ) ) )

(====)

# Iterate tree values
(de iter ("Tree" "foo" "Beg" "End" "F")
   (default "foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _iter _reti)
      (cdr (root "Tree")) ) )

(de _iter ("Node")
   (when (setq "Node" (val "Node"))
      (if (< "End" (car "Node"))
         (_iter (cadr "Node"))
         (when (<= "Beg" (car "Node"))
            (_iter (cadr "Node"))
            (unless (and "F" (flg? (fin (car "Node"))))
               ("foo" (cdddr "Node")) ) )
         (_iter (caddr "Node")) ) ) )

(de _reti ("Node")
   (when (setq "Node" (val "Node"))
      (if (> "End" (car "Node"))
         (_reti (caddr "Node"))
         (when (>= "Beg" (car "Node"))
            (_reti (caddr "Node"))
            (unless (and "F" (flg? (fin (car "Node"))))
               ("foo" (cdddr "Node")) ) )
         (_reti (cadr "Node")) ) ) )

(====)

# Check tree structure
(de check ("Node" "foo")
   (let ("N" 0  "X")
      (when "Node"
         (recur ("Node")
            (when (> 3 (size (val "Node")))
               (quit "Bad node size" "Node") )
            (when (cadr (val "Node"))
               (unless (ext? (cadr (val "Node")))
                  (quit "Bad node link" "Node") )
               (recurse (cadr (val "Node"))) )
            (when (>= "X" (car (val "Node")))
               (quit "Bad sequence" "Node") )
            (setq "X" (car (val "Node")))
            (inc '"N")
            (and
               "foo"
               (not ("foo" (car (val "Node")) (cdddr (val "Node"))))
               (quit "Check fail" "Node") )
            (when (caddr (val "Node"))
               (unless (ext? (caddr (val "Node")))
                  (quit "Bad node link" "Node") )
               (recurse (caddr (val "Node"))) )
            (wipe "Node") ) )
      "N" ) )
