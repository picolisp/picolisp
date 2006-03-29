# 13feb06abu
# (c) Software Lab. Alexander Burger

# *Prune

(mapc undef
   (quote
      fetch _store _put _del maxKey minKey init step
      scan _scan _nacs iter _iter _reti check ) )
(mapc zap '(_delR _delL))


(de root (Tree)
   (cond
      ((not Tree) (val *DB))
      ((atom Tree) (val Tree))
      ((atom (cdr Tree))
         (get *DB (cdr Tree) (car Tree)) )
      (T (get (cddr Tree) (cadr Tree) (car Tree))) ) )

# Fetch
(de fetch (Tree Key)
   (let? Node (cdr (root Tree))
      (and *Prune (idx '*Prune Node T))
      (use R
         (loop
            (T
               (and
                  (setq R (rank Key (cdr (val Node))))
                  (= Key (car R)) )
               (or (cddr R) (fin (car R))) )
            (NIL
               (setq Node (if R (cadr R) (car (val Node)))) ) ) ) ) )

# Store
(de store (Tree Key Val Dbf)
   (default Dbf (0 . 64))
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
   (and *Prune (cdr Root) (idx '*Prune @ T))
   (ifn Val
      (when (and (cdr Root) (_del @))
         (touch Base)
         (con Root) )
      (and (= Val (fin Key)) (off Val))
      (if (cdr Root)
         (when (_put @)
            (touch Base)
            (con Root (def (new (car Dbf)) (list (cdr Root) @))) )
         (touch Base)
         (con Root
            (def (new (car Dbf))
               (list NIL (cons Key (cons NIL Val))) ) )
         (inc Root) ) ) )

(de _put (Top)
   (let (V (val Top)  R (rank Key (cdr V)))
      (if (and R (= Key (car R)))
         (nil (touch Top) (con (cdr R) Val))
         (cond
            (R
               (let X (memq R V)
                  (if (cadr R)
                     (when (_put @)
                        (touch Top)
                        (con X (cons @ (cdr X)))
                        (_splitBt) )
                     (touch Top)
                     (con X
                        (cons (cons Key (cons NIL Val)) (cdr X)) )
                     (touch Base)
                     (inc Root)
                     (_splitBt) ) ) )
            ((car V)
               (when (_put @)
                  (touch Top)
                  (con V (cons @ (cdr V)))
                  (_splitBt) ) )
            (T
               (touch Top)
               (con V
                  (cons (cons Key (cons NIL Val)) (cdr V)) )
               (touch Base)
               (inc Root)
               (_splitBt) ) ) ) ) )

(de _splitBt ()
   (when (and (cddddr (val Top)) (> (size Top) (cdr Dbf)))
      (let N (>> 1 (length V))
         (set Top (head N V))
         (prog1 (get V (inc N))
            (set (cdr @)
               (def (new (car Dbf))
                  (cons (cadr @) (nth V (+ 2 N))) ) ) ) ) ) )

# Del
(de _del (Top)
   (let (V (val Top)  R (rank Key (cdr V)))
      (cond
         ((not R)
            (when (and (car V) (_del @))
               (touch Top)
               (set V)
               (not (cdr V)) ) )
         ((= Key (car R))
            (if (cadr R)
               (let X (val @)
                  (while (car X) (setq X (val @)))
                  (touch Top)
                  (xchg R (cadr X))
                  (con (cdr R) (cddr (cadr X)))
                  (and (_del (cadr R)) (set (cdr R))) )
               (touch Base)
               (dec Root)
               (nand
                  (or
                     (con V (delq R (cdr V)))
                     (car V) )
                  (touch Top) ) ) )
         ((cadr R)
            (when (_del @)
               (touch Top)
               (set (cdr R)) ) ) ) ) )

# Tree node count
(de count (Tree)
   (or (car (root Tree)) 0) )

# Reverse node
(de revNode (Node)
   (let? Lst (val Node)
      (let (L (car Lst)  R)
         (for X (cdr Lst)
            (push 'R
               (cons (car X) (cons L (cddr X))) )
            (setq L (cadr X)) )
         (cons L R) ) ) )

# Key management
(de minKey (Tree Min Max)
   (default Max T)
   (let (Node (cdr (root Tree))  K)
      (use (V R X)
         (loop
            (NIL (setq V (val Node)) K)
            (T
               (and
                  (setq R (rank Min (cdr V)))
                  (= Min (car R)) )
               Min )
            (if R
               (prog
                  (and
                     (setq X (cdr (memq R V)))
                     (>= Max (caar X))
                     (setq K (caar X)) )
                  (setq Node (cadr R)) )
               (when (>= Max (caadr V))
                  (setq K (caadr V)) )
               (setq Node (car V)) ) ) ) ) )

(de maxKey (Tree Min Max)
   (default Max T)
   (let (Node (cdr (root Tree))  K)
      (use (V R X)
         (loop
            (NIL (setq V (revNode Node)) K)
            (T
               (and
                  (setq R (rank Max (cdr V) T))
                  (= Max (car R)) )
               Max )
            (if R
               (prog
                  (and
                     (setq X (cdr (memq R V)))
                     (>= (caar X) Min)
                     (setq K (caar X)) )
                  (setq Node (cadr R)) )
               (when (>= (caadr V) Min)
                  (setq K (caadr V)) )
               (setq Node (car V)) ) ) ) ) )

# Step
(de init (Tree Beg End)
   (or Beg End (on End))
   (let (Node (cdr (root Tree))  Q)
      (use (V R X)
         (if (>= End Beg)
            (loop
               (NIL (setq V (val Node)))
               (T
                  (and
                     (setq R (rank Beg (cdr V)))
                     (= Beg (car R)) )
                  (push 'Q (memq R V)) )
               (if R
                  (prog
                     (and
                        (setq X (cdr (memq R V)))
                        (>= End (caar X))
                        (push 'Q X) )
                     (setq Node (cadr R)) )
                  (and
                     (cdr V)
                     (>= End (caadr V))
                     (push 'Q (cdr V)) )
                  (setq Node (car V)) ) )
            (loop
               (NIL (setq V (revNode Node)))
               (T
                  (and
                     (setq R (rank Beg (cdr V) T))
                     (= Beg (car R)) )
                  (push 'Q (memq R V)) )
               (if R
                  (prog
                     (and
                        (setq X (cdr (memq R V)))
                        (>= (caar X) End)
                        (push 'Q X) )
                     (setq Node (cadr R)) )
                  (and
                     (cdr V)
                     (>= (caadr V) End)
                     (push 'Q (cdr V)) )
                  (setq Node (car V)) ) ) ) )
      (cons (cons (cons Beg End) Q)) ) )

(de step (Q F)
   (use (L F X)
      (loop
         (while (and (cdr Q) (not (cdar Q)))
            (set Q (cadr Q))
            (con Q (cddr Q)) )
         (NIL (cdr (setq L (car Q))))
         (setq
            F (>= (cdar L) (caar L))
            X (pop (cdr L)) )
         (or (cadr L) (con L (cddr L)))
         (T ((if F > <) (car X) (cdar L)))
         (for (V (cadr X) ((if F val revNode) V) (car @))
            (con L (cons (cdr @) (cdr L)))
            (wipe V) )
         (NIL (and X F (flg? (fin (car X))))
            (or (cddr X) (fin (car X))) ) ) ) )

(====)

# Scan tree nodes
(de scan ("Tree" "Foo" "Beg" "End" "F")
   (default "Foo" println)
   (or "Beg" "End" (on "End"))
   ((if (>= "End" "Beg") _scan _nacs)
      (cdr (root "Tree")) ) )

(de _scan ("Node")
   (let? "V" (val "Node")
      (for "X"
         (if (rank "Beg" (cdr "V"))
            (let "R" @
               (if (= "Beg" (car "R"))
                  (memq "R" (cdr "V"))
                  (_scan (cadr "R"))
                  (cdr (memq "R" (cdr "V"))) ) )
            (_scan (car "V"))
            (cdr "V") )
         (T (> (car "X") "End"))
         (unless (and "F" (flg? (fin (car "X"))))
            ("Foo"
               (car "X")
               (or (cddr "X") (fin (car "X"))) ) )
         (_scan (cadr "X")) )
      (wipe "Node") ) )

(de _nacs ("Node")
   (let? "V" (revNode "Node")
      (for "X"
         (if (rank "Beg" (cdr "V") T)
            (let "R" @
               (if (= "Beg" (car "R"))
                  (memq "R" (cdr "V"))
                  (_nacs (cadr "R"))
                  (cdr (memq "R" (cdr "V"))) ) )
            (_nacs (car "V"))
            (cdr "V") )
         (T (> "End" (car "X")))
         (unless (and "F" (flg? (fin (car "X"))))
            ("Foo"
               (car "X")
               (or (cddr "X") (fin (car "X"))) ) )
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
   (let? "V" (val "Node")
      (for "X"
         (if (rank "Beg" (cdr "V"))
            (let "R" @
               (if (= "Beg" (car "R"))
                  (memq "R" (cdr "V"))
                  (_iter (cadr "R"))
                  (cdr (memq "R" (cdr "V"))) ) )
            (_iter (car "V"))
            (cdr "V") )
         (T (> (car "X") "End"))
         (unless (and "F" (flg? (fin (car "X"))))
            ("Foo" (or (cddr "X") (fin (car "X")))) )
         (_iter (cadr "X")) )
      (wipe "Node") ) )

(de _reti ("Node")
   (let? "V" (revNode "Node")
      (for "X"
         (if (rank "Beg" (cdr "V") T)
            (let "R" @
               (if (= "Beg" (car "R"))
                  (memq "R" (cdr "V"))
                  (_reti (cadr "R"))
                  (cdr (memq "R" (cdr "V"))) ) )
            (_reti (car "V"))
            (cdr "V") )
         (T (> "End" (car "X")))
         (unless (and "F" (flg? (fin (car "X"))))
            ("Foo" (or (cddr "X") (fin (car "X")))) )
         (_reti (cadr "X")) )
      (wipe "Node") ) )

(====)

(de prune (Done)
   (for Node (idx '*Prune)
      (recur (Node)
         (let? V (val (lieu Node))
            (if (nor (car V) (find cadr (cdr V)))
               (wipe Node)
               (recurse (car V))
               (for X (cdr V)
                  (recurse (cadr X))
                  (wipe (lieu (cddr X))) ) ) ) ) )
   (setq *Prune (not Done)) )


# Check tree structure
(de check ("Node" "Foo")
   (let ("N" 0  "X")
      (when "Node"
         (recur ("Node")
            (let "V" (val "Node")
               (let "L" (car "V")
                  (for "Y" (cdr "V")
                     (when "L"
                        (unless (ext? "L")
                           (quit "Bad node link" "Node") )
                        (recurse "L") )
                     (when (>= "X" (car "Y"))
                        (quit "Bad sequence" "Node") )
                     (setq "X" (car "Y"))
                     (inc '"N")
                     (and
                        "Foo"
                        (not ("Foo" (car "Y") (cddr "Y")))
                        (quit "Check fail" "Node") )
                     (setq "L" (cadr "Y")) )
                  (and "L" (recurse "L")) ) )
            (wipe "Node") ) )
      "N" ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
