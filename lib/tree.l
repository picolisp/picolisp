# 23jan03abu
# (c) Software Lab. Alexander Burger

# *VisitedKey *VisitedLess *VisitedMore)

# Fetch
(de fetch (Tree Key)
   (setq Tree (cdr Tree))
   (loop
      (NIL Tree)
      (T (= Key (car (val Tree)))
         (cdddr (val Tree)) )
      (setq Tree
         ((if (< Key (car (val Tree))) cadr caddr)
            (val Tree) ) ) ) )

# Store
(de store (Tree Key Val)
   (cond
      ((= Val (fetch Tree Key)))
      (Val (con Tree (_put (cdr Tree))))
      (T (con Tree (_del (cdr Tree)))) )
   Val )

(de _put (Top)
   (ifn Top
      (let Node (new T)
         (setq
            *VisitedKey Key
            *VisitedLess NIL
            *VisitedMore NIL )
         (set Node
            (cons Key (cons NIL (cons NIL Val))) )
         (inc Tree)
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
            (dec Tree)
            (_delR (cadr (val Top)) (caddr (val Top))) )
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

# Calculate tree depth
(de depth (Tree)
   (dpth (cdr Tree)) )

(de dpth (Top)
   (ifn Top
      0
      (prog1
         (+ 1
            (max
               (dpth (cadr (val Top)))
               (dpth (caddr (val Top))) ) )
         (wipe Top) ) ) )

# Key management
(de maxKey (Tree Min Max)
   (setq Tree (cdr Tree))
   (default Max T)
   (let K NIL
      (while Tree
         (if (>= (car (val Tree)) Max)
            (setq Tree (cadr (val Tree)))
            (when (>= (car (val Tree)) Min)
               (setq K (car (val Tree))) )
            (setq Tree (caddr (val Tree))) ) )
      K ) )

(de minKey (Tree Min Max)
   (setq Tree (cdr Tree))
   (default Max T)
   (let K NIL
      (while Tree
         (if (> Min (car (val Tree)))
            (setq Tree (caddr (val Tree)))
            (when (>= Max (car (val Tree)))
               (setq K (car (val Tree))) )
            (setq Tree (cadr (val Tree))) ) )
      K ) )

# Step
(de init (Tree Beg End)
   (setq Tree (cdr Tree))
   (or Beg End (on End))
   (let Q NIL
      (if (>= End Beg)
         (while Tree
            (if (> Beg (car (val Tree)))
               (setq Tree (caddr (val Tree)))
               (when (>= End (car (val Tree)))
                  (push 'Q Tree) )
               (setq Tree (cadr (val Tree))) ) )
         (while Tree
            (if (< Beg (car (val Tree)))
               (setq Tree (cadr (val Tree)))
               (when (<= End (car (val Tree)))
                  (push 'Q Tree) )
               (setq Tree (caddr (val Tree))) ) ) )
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
            (and F (pair (car Val)) (pair (cdar Val))) ) )
      (cdddr Val) ) )

(====)

# Scan tree nodes
(de scan ("Tree" "foo" "Beg" "End" "F")
   (default "foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _scan _nacs) (cdr "Tree")) )

(de _scan ("Node")
   (when "Node"
      (if (< "End" (car (val "Node")))
         (_scan (cadr (val "Node")))
         (when (<= "Beg" (car (val "Node")))
            (_scan (cadr (val "Node")))
            (unless (and "F" (pair (car (val "Node"))) (pair (cdar (val "Node"))))
               ("foo" (car (val "Node")) (cdddr (val "Node"))) ) )
         (_scan (caddr (val "Node"))) ) ) )

(de _nacs ("Node")
   (when "Node"
      (if (> "End" (car (val "Node")))
         (_nacs (caddr (val "Node")))
         (when (>= "Beg" (car (val "Node")))
            (_nacs (caddr (val "Node")))
            (unless (and "F" (pair (car (val "Node"))) (pair (cdar (val "Node"))))
               ("foo" (car (val "Node")) (cdddr (val "Node"))) ) )
         (_nacs (cadr (val "Node"))) ) ) )

(====)

# Iterate tree values
(de iter ("Tree" "foo" "Beg" "End" "F")
   (default "foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _iter _reti) (cdr "Tree")) )

(de _iter ("Node")
   (when "Node"
      (if (< "End" (car (val "Node")))
         (_iter (cadr (val "Node")))
         (when (<= "Beg" (car (val "Node")))
            (_iter (cadr (val "Node")))
            (unless (and "F" (pair (car (val "Node"))) (pair (cdar (val "Node"))))
               ("foo" (cdddr (val "Node"))) ) )
         (_iter (caddr (val "Node"))) ) ) )

(de _reti ("Node")
   (when "Node"
      (if (> "End" (car (val "Node")))
         (_reti (caddr (val "Node")))
         (when (>= "Beg" (car (val "Node")))
            (_reti (caddr (val "Node")))
            (unless (and "F" (pair (car (val "Node"))) (pair (cdar (val "Node"))))
               ("foo" (cdddr (val "Node"))) ) )
         (_reti (cadr (val "Node"))) ) ) )

(====)

# Check tree structure
(de check ("Node" "foo")
   (let ("N" 0  "X")
      (when "Node"
         (_chk "Node") )
      "N" ) )

(de _chk ("Node")
   (when (> 3 (size (val "Node")))
      (quit "Bad node size" "Node") )
   (when (cadr (val "Node"))
      (unless (ext? (cadr (val "Node")))
         (quit "Bad node link" "Node") )
      (_chk (cadr (val "Node"))) )
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
      (_chk (caddr (val "Node"))) )
   (wipe "Node") )
