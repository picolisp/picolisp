# 16jan04abu
# (c) Software Lab. Alexander Burger

(de macro "Prg"
   (run (fill "Prg")) )

(de task ("Key" . "Prg")
   (cond
      ((not "Prg")
         (setq *Key (delete (assoc "Key" *Key) *Key)) )
      ((assoc "Key" *Key)
         (quit "Key conflict" "Key") )
      (T
         (push '*Key
            (conc
               (make
                  (link "Key")
                  (when (num? (car "Prg"))
                     (link (+ (pop '"Prg"))) ) )
               (ifn (sym? (car "Prg"))
                  "Prg"
                  (cons
                     (cons
                        'job
                        (cons
                           (make
                              (while (atom (car "Prg"))
                                 (link
                                    (cons (pop '"Prg") (eval (pop '"Prg"))) ) ) )
                           "Prg" ) ) ) ) ) ) ) ) )

(de timeout (N)
   (if (assoc -1 *Key)
      (set (cdr @) (+ N))
      (push '*Key (list -1 (+ N) '(bye))) ) )

(de getd ("X")
   (and
      (sym? "X")
      (fun? (val "X"))
      (val "X") ) )

(de undef ("X" "C")
   (when (pair "X")
      (setq  "C" (cdr "X")  "X" (car "X")) )
   (ifn "C"
      (prog1 (val "X") (set "X"))
      (prog1
         (cdr (asoq "X" (val "C")))
         (set "C"
            (delq (asoq "X" (val "C")) (val "C")) ) ) ) )

(de scl (*Scl . "Prg")
   (run "Prg") )

### I/O ###
(de tab (Lst . @)
   (mapc
      '((N)
         (let V (next)
            (and (gt0 N) (space (- N (length V))))
            (prin V)
            (and (lt0 N) (space (- 0 N (length V)))) ) )
      Lst )
   (prinl) )

(de beep ()
   (prin "^G") )

(de msg (X . @)
   (out NIL
      (print X)
      (while (args)
         (prin (next)) )
      (prinl)
      (flush) ) )

### List ###
(de ?push ("Var" "X")
   (or
      (car (member "X" (val "Var")))
      (push "Var" "X") ) )

(de insert (N Lst X)
   (conc
      (head (- N 1) Lst)
      (cons X)
      (nth Lst N) ) )

(de remove (N Lst)
   (conc
      (head (- N 1) Lst)
      (nth Lst (+ N 1)) ) )

(de sect (Lst1 Lst2)
   (filter '((X) (member X Lst2)) Lst1) )

(de diff (Lst1 Lst2)
   (filter '((X) (not (member X Lst2))) Lst1) )

(de uniq (Lst)
   (let R NIL
      (filter
         '((X) (not (idx 'R X T)))
         Lst ) ) )

(de group (Lst)
   (make
      (while Lst
         (if (assoc (caar Lst) (made))
            (conc @ (cons (cdr (pop 'Lst))))
            (link
               (cons (caar Lst) (cons (cdr (pop 'Lst)))) ) ) ) ) )

(====)

(de sortBy ("foo" "Lst")
   (mapcar cdr
      (sort
         (mapcar '(("X") (cons ("foo" "X") "X")) "Lst") ) ) )

(====)

(de groupBy ("foo" "Lst")
   (mapcar cdr
      (group
         (mapcar '(("X") (cons ("foo" "X") "X")) "Lst") ) ) )

(====)

### Symbol ###
(de loc ("S" "X")
   (if (and (str? "X") (= "S" "X"))
      "X"
      (and
         (pair "X")
         (or
            (loc "S" (car "X"))
            (loc "S" (cdr "X")) ) ) ) )

(====)

(de clone ("X" . Lst)
   (if Lst
      (let "Env" (car Lst)
         (_clone "X" (cdr Lst)) )
      (prog1 (new (ext? "X"))
         (set @ (val "X"))
         (putl @ (getl "X")) ) ) )

(de _clone ("X" Lst)
   (let Obj
      (cdr
         (or
            (asoq "X" (val "Env"))
            (push "Env" (cons "X" (new (ext? "X")))) ) )
      (set Obj (val "X"))
      (mapc
         '(("Y")
            (if (atom "Y")
               (put Obj "Y" (get "X" "Y"))
               (put Obj (car "Y")
                  (_clone
                     (get "X" (car "Y"))
                     (cdr "Y") ) ) ) )
         Lst )
      Obj ) )

### OOP ###
(de class Lst
   (or
      (= (cdr Lst) (type (setq *Class (car Lst))))
      (def *Class (cdr Lst)) ) )

(de extend "X"
   (setq *Class (car "X")) )

# Class variables
(de var X
   (put *Class (car X) (cdr X)) )

(de var: X
   (apply meta X This) )

### Pretty Printing ###
(de *PP
   T NIL if ifn when unless whilst while until until=T do case for with catch
   ! quote setq default let let? use =: in out new )

(de *PP1 let)
(de *PP2 setq default)

(de pretty (X N . @)
   (space (default N 0))
   (while (args)
      (printsp (next)) )
   (if (or (atom X) (<= (size X) 12))
      (print X)
      (while (== 'quote (car X))
         (prin "'")
         (pop 'X) )
      (let Z X
         (prin "(")
         (when (memq (print (pop 'X)) *PP)
            (cond
               ((memq (car Z) *PP1)
                  (if (pair (car X))
                     (when (<= (size (car X)) 12)
                        (space)
                        (print (pop 'X)) )
                     (space)
                     (print (pop 'X))
                     (when (or (atom (car X)) (<= (size (car X)) 12))
                        (space)
                        (print (pop 'X)) ) ) )
               ((memq (car Z) *PP2)
                  (inc 'N 3)
                  (loop
                     (prinl)
                     (pretty (cadr X) N (car X))
                     (NIL (setq X (cddr X))) ) )
               ((or (atom (car X)) (<= (size (car X)) 12))
                  (space)
                  (print (pop 'X)) ) ) )
         (loop
            (NIL X)
            (T (== Z X) (prin " ."))
            (T (atom X) (prin " . ") (print X))
            (prinl)
            (pretty (pop 'X) (+ 3 N)) )
         (space)
         (prin ")") ) ) )

(de pp ("X" "C")
   (let *Dbg NIL
      (when (pair "X")
         (setq "C" (cdr "X")) )
      (prin "(")
      (printsp (if "C" 'dm 'de))
      (prog1
         (printsp "X")
         (setq "X"
            (if "C"
               (method (if (pair "X") (car "X") "X") "C")
               (val "X") ) )
         (cond
            ((atom "X") (print '. "X"))
            ((atom (cdr "X"))
               (if (cdr "X")
                  (print (car "X") '. @)
                  (print (car "X")) ) )
            (T
               (print (pop '"X"))
               (while (pair "X")
                  (prinl)
                  (pretty (pop '"X") 3) )
               (when "X"
                  (prin " . ")
                  (print "X") )
               (space) ) )
         (prinl ")") ) ) )

(de show ("X" . @)
   (let *Dbg NIL
      (setq "X" (apply get (rest) "X"))
      (when (sym? "X")
         (print "X" (val "X"))
         (prinl)
         (maps
            '((X)
               (space 3)
               (if (atom X)
                  (println X)
                  (println (cdr X) (car X)) ) )
            "X" ) )
      "X" ) )
