# 23nov10abu
# (c) Software Lab. Alexander Burger

(de task (Key . Prg)
   (nond
      (Prg (del (assoc Key *Run) '*Run))
      ((num? Key) (quit "Bad Key" Key))
      ((assoc Key *Run)
         (push '*Run
            (conc
               (make
                  (when (lt0 (link Key))
                     (link (+ (eval (pop 'Prg) 1))) ) )
               (ifn (sym? (car Prg))
                  Prg
                  (cons
                     (cons 'job
                        (cons
                           (lit
                              (make
                                 (while (atom (car Prg))
                                    (link
                                       (cons (pop 'Prg) (eval (pop 'Prg) 1)) ) ) ) )
                           Prg ) ) ) ) ) ) )
      (NIL (quit "Key conflict" Key)) ) )

(de forked ()
   (let N (caar *Run)
      (when (gt0 N)
         (push '*Fork (list 'close N)) )
      (push '*Fork (list 'task N)) ) )

(de timeout (N)
   (if2 N (assoc -1 *Run)
      (set (cdr @) (+ N))
      (push '*Run (list -1 (+ N) '(bye)))
      (del @ '*Run) ) )

(de abort ("N" . "Prg")
   (catch 'abort
      (alarm "N" (throw 'abort))
      (finally (alarm 0) (run "Prg")) ) )

(de macro "Prg"
   (run (fill "Prg")) )

(de later ("@Var" . "@Prg")
   (macro
      (task (pipe (pr (prog . "@Prg")))
         (setq "@Var" (in @ (rd)))
         (task (close @)) ) )
   "@Var" )

(de recur recurse
   (run (cdr recurse)) )

(de curry "Z"
   (let ("X" (pop '"Z")  "Y" (pop '"Z")  "P" (filter pat? "X"))
      (if2 "P" (diff "X" "P")
         (list "Y" (cons 'job (lit (env @)) (fill "Z" "P")))
         (cons "Y" (fill "Z" "P"))
         (list "Y" (cons 'job (lit (env @)) "Z"))
         (cons "Y" "Z") ) ) )

(====)

(de expr ("F")
   (set "F"
      (list '@ (list 'pass (box (getd "F")))) ) )

(de subr ("F")
   (set "F"
      (getd (cadr (cadr (getd "F")))) ) )

(de undef ("X" "C")
   (when (pair "X")
      (setq  "C" (cdr "X")  "X" (car "X")) )
   (ifn "C"
      (prog1 (val "X") (set "X"))
      (prog1
         (cdr (asoq "X" (val "C")))
         (set "C"
            (delq (asoq "X" (val "C")) (val "C")) ) ) ) )

(de redef "Lst"
   (let ("Old" (car "Lst")  "New" (name "Old"))
      (set
         "New" (getd "Old")
         "Old" "New"
         "Old" (fill (cdr "Lst") "Old") )
      "New" ) )

(de daemon ("X" . Prg)
   (prog1
      (nond
         ((pair "X")
            (or (pair (getd "X")) (expr "X")) )
         ((pair (cdr "X"))
            (method (car "X") (cdr "X")) )
         (NIL
            (method (car "X") (get (or (cddr "X") *Class) (cadr "X"))) ) )
      (con @ (append Prg (cdr @))) ) )

(de patch ("Lst" "Pat" . "Prg")
   (bind (fish pat? "Pat")
      (recur ("Lst")
         (loop
            (cond
               ((match "Pat" (car "Lst"))
                  (set "Lst" (run "Prg")) )
               ((pair (car "Lst"))
                  (recurse @) ) )
            (NIL (cdr "Lst"))
            (T (atom (cdr "Lst"))
               (when (match "Pat" (cdr "Lst"))
                  (con "Lst" (run "Prg")) ) )
            (setq "Lst" (cdr "Lst")) ) ) ) )

(====)

(de cache ("Var" "Str" . Prg)
   (nond
      ((setq "Var" (car (idx "Var" "Str" T)))
         (set "Str" "Str"  "Str" (run Prg 1)) )
      ((n== "Var" (val "Var"))
         (set "Var" (run Prg 1)) )
      (NIL (val "Var")) ) )

(====)

(de scl (N)
   (setq *Scl N) )

### I/O ###
(de tab (Lst . @)
   (for N Lst
      (let V (next)
         (and (gt0 N) (space (- N (length V))))
         (prin V)
         (and (lt0 N) (args) (space (- 0 N (length V)))) ) )
   (prinl) )

(de beep ()
   (prin "^G") )

(de msg (X . @)
   (out 2
      (print X)
      (pass prinl)
      (flush) )
   X )

(de script (File . @)
   (load File) )

(de once Prg
   (unless (idx '*Once (file) T)
      (run Prg 1) ) )

(de rc (File Key . @)
   (ctl File
      (let Lst (in File (read))
         (ifn (args)
            (cdr (assoc Key Lst))
            (let Val (next)
               (if (assoc Key Lst)
                  (con @ Val)
                  (push 'Lst (cons Key Val)) )
               (protect
                  (out File (println Lst)) )
               Val ) ) ) ) )

(de acquire (File)
   (ctl File
      (let P (in File (rd))
         (or
            (= P *Pid)
            (unless (and P (kill P 0))
               (out File (pr *Pid)) ) ) ) ) )

(de release (File)
   (ctl File (out File)) )

### List ###
(de insert (N Lst X)
   (conc
      (cut (dec N) 'Lst)
      (cons X)
      Lst ) )

(de remove (N Lst)
   (conc
      (cut (dec N) 'Lst)
      (cdr Lst) ) )

(de place (N Lst X)
   (conc
      (cut (dec N) 'Lst)
      (cons X)
      (cdr Lst) ) )

(de uniq (Lst)
   (let R NIL
      (filter
         '((X) (not (idx 'R X T)))
         Lst ) ) )

(de group (Lst)
   (make
      (for X Lst
         (if (assoc (car X) (made))
            (conc @ (cons (cdr X)))
            (link (list (car X) (cdr X))) ) ) ) )

### Symbol ###
(de qsym "Sym"
   (cons (val "Sym") (getl "Sym")) )

(de loc (S X)
   (if (and (str? X) (= S X))
      X
      (and
         (pair X)
         (or
            (loc S (car X))
            (loc S (cdr X)) ) ) ) )

### OOP ###
(de class Lst
   (let L (val (setq *Class (car Lst)))
      (def *Class
         (recur (L)
            (if (atom (car L))
               (cdr Lst)
               (cons (car L) (recurse (cdr L))) ) ) ) ) )

(de object ("Sym" "Val" . @)
   (def "Sym" "Val")
   (putl "Sym")
   (while (args)
      (put "Sym" (next) (next)) )
   "Sym" )

(de extend X
   (setq *Class (car X)) )

# Class variables
(de var X
   (put *Class (car X) (cdr X)) )

(de var: X
   (apply meta X This) )

### Pretty Printing ###
(de *PP
   T NIL if ifn when unless while until do case state for
   with catch finally co ! setq default push job use let let?
   prog1 later recur redef =: in out ctl tab new )
(de *PP1 let let? for redef)
(de *PP2 setq default)

(de pretty (X N . @)
   (setq N (abs (space (or N 0))))
   (while (args)
      (printsp (next)) )
   (if (or (atom X) (>= 12 (size X)))
      (print X)
      (while (== 'quote (car X))
         (prin "'")
         (pop 'X) )
      (let Z X
         (prin "(")
         (when (memq (print (pop 'X)) *PP)
            (cond
               ((memq (car Z) *PP1)
                  (if (and (pair (car X)) (pair (cdar X)))
                     (when (>= 12 (size (car X)))
                        (space)
                        (print (pop 'X)) )
                     (space)
                     (print (pop 'X))
                     (when (or (atom (car X)) (>= 12 (size (car X))))
                        (space)
                        (print (pop 'X)) ) ) )
               ((memq (car Z) *PP2)
                  (inc 'N 3)
                  (loop
                     (prinl)
                     (pretty (cadr X) N (car X))
                     (NIL (setq X (cddr X)) (space)) ) )
               ((or (atom (car X)) (>= 12 (size (car X))))
                  (space)
                  (print (pop 'X)) ) ) )
         (when X
            (loop
               (T (== Z X) (prin " ."))
               (T (atom X) (prin " . ") (print X))
               (prinl)
               (pretty (pop 'X) (+ 3 N))
               (NIL X) )
            (space) )
         (prin ")") ) ) )

(de pp ("X" C)
   (let *Dbg NIL
      (and (pair "X") (setq C (cdr "X")))
      (prin "(")
      (printsp (if C 'dm 'de))
      (prog1 (printsp "X")
         (setq "X"
            (if C
               (method (if (pair "X") (car "X") "X") C)
               (val "X") ) )
         (cond
            ((atom "X") (prin ". ") (print "X"))
            ((atom (cdr "X"))
               (ifn (cdr "X")
                  (print (car "X"))
                  (print (car "X"))
                  (prin " . ")
                  (print @) ) )
            (T
               (let Z "X"
                  (print (pop '"X"))
                  (loop
                     (T (== Z "X") (prin " ."))
                     (NIL "X")
                     (T (atom "X")
                        (prin " . ")
                        (print "X") )
                     (prinl)
                     (pretty (pop '"X") 3) )
                  (space) ) ) )
         (prinl ")") ) ) )

(de show ("X" . @)
   (let *Dbg NIL
      (setq "X" (pass get "X"))
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

(de view (X Y)
   (let *Dbg NIL
      (if (=T Y)
         (let N 0
            (recur (N X)
               (when X
                  (recurse (+ 3 N) (cddr X))
                  (space N)
                  (println (car X))
                  (recurse (+ 3 N) (cadr X)) ) ) )
         (let Z X
            (loop
               (T (atom X) (println X))
               (if (atom (car X))
                  (println '+-- (pop 'X))
                  (print '+---)
                  (view
                     (pop 'X)
                     (append Y (cons (if X "|   " "    "))) ) )
               (NIL X)
               (mapc prin Y)
               (T (== Z X) (println '*))
               (println '|)
               (mapc prin Y) ) ) ) ) )

# vi:et:ts=3:sw=3
