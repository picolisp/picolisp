# 07jul03abu
# (c) Software Lab. Alexander Burger

# Browsing
(de more ("Lst" "foo")
   (let *Dbg NIL
      (default "foo" print)
      ("foo" (pop '"Lst"))
      (until (or (atom "Lst") (line))
         ("foo" (pop '"Lst")) )
      T ) )

(de stat ()
   (let *Dbg NIL
      (let (F (heap)  H (heap T))
         (prinl
            (format (*/ H 10 `(* 128 1024) T) 1)
            " "
            (- 100 (*/ 100 F H))
            "%" )
         F ) ) )

(de what (S)
   (let *Dbg NIL
      (ifn S
         (make (all link))
         (setq S (chop S))
         (make
            (all
               '(("X")
                  (and (match S (chop "X")) (link "X")) ) ) ) ) ) )


(de who ("X" . "Prg")
   (let (*Dbg NIL  "Who" '("Who" @ @@ @@@))
      (make (all "who")) ) )

(de "who" ("Y")
   (unless (memq "Y" "Who")
      (push '"Who" "Y")
      (if (= `(char "+") (char "Y"))
         (mapc
            '(("Z")
               (if (atom "Z")
                  (and ("match" "Z") (link "Y"))
                  (when ("nest" (cdr "Z"))
                     (link (cons (car "Z") "Y")) ) ) )
            (val "Y") )
         (and
            (pair (val "Y"))
            ("nest" (val "Y"))
            (link "Y") ) )
      (maps
         '(("Z")
            (if (atom "Z")
               (and ("match" "Z") (link "Y"))
               (when ("nest" (car "Z"))
                  (link (cons (cdr "Z") "Y")) ) ) )
         "Y" ) ) )

(de "nest" ("Y")
   ("nst1" "Y")
   ("nst2" "Y") )

(de "nst1" ("Y")
   (let "Z" (setq "Y" (strip "Y"))
      (loop
         (T (atom "Y") (and (sym? "Y") ("who" "Y")))
         (and (sym? (car "Y")) ("who" (car "Y")))
         (and (pair (car "Y")) ("nst1" (car "Y")))
         (T (== "Z" (setq "Y" (cdr "Y")))) ) ) )

(de "nst2" ("Y")
   (let "Z" (setq "Y" (strip "Y"))
      (loop
         (T (atom "Y") ("match" "Y"))
         (T (or ("match" (car "Y")) ("nst2" (car "Y")))
            T )
         (T (== "Z" (setq "Y" (cdr "Y")))) ) ) )

(de "match" ("D")
   (and
      (cond
         ((str? "X") (and (str? "D") (= "X" "D")))
         ((sym? "X") (== "X" "D"))
         (T (match "X" "D")) )
      (or (not "Prg") (run "Prg")) ) )

(de can (X)
   (let *Dbg NIL
      (make
         (all
            '(("Y")
               (and
                  (= `(char "+") (char "Y"))
                  (asoq X (val "Y"))
                  (link (cons X "Y")) ) ) ) ) ) )

# Class dependencies
(de dep ("C")
   (let *Dbg NIL
      (dep1 0 "C")
      (dep2 3 "C")
      "C" ) )

(de dep1 (N "C")
   (mapc
      '(("X") (dep1 (+ 3 N) "X"))
      (type "C") )
   (space N)
   (println "C") )

(de dep2 (N "C")
   (all
      '(("X")
         (when (memq "C" (type "X"))
            (space N)
            (println "X")
            (dep2 (+ 3 N) "X") ) ) ) )

# Single-Stepping
(de _dbg (Lst)
   (or
      (atom (car Lst))
      (num? (caar Lst))
      (=T (caar Lst))
      (== '! (caar Lst))
      (set Lst (cons '! (car Lst))) ) )

(de dbg (Lst)
   (when (pair Lst)
      (case (pop 'Lst)
         (case
            (_dbg Lst)
            (mapc
               '((L) (map _dbg (cdr L)))
               (cdr Lst) ) )
         (cond
            (mapc
               '((L) (map _dbg L))
               Lst ) )
         (quote
            (when (fun? Lst)
               (map _dbg (cdr Lst)) ) )
         ((for use let)
            (map _dbg (cdr Lst)) )
         ((loop do)
            (map
               '((L)
                  (if (and (pair (car L)) (or (=T (caar L)) (not (caar L))))
                     (map _dbg (cdar L))
                     (_dbg L) ) )
               Lst ) )
         (T (map _dbg Lst)) )
      T ) )

(de d () (let *Dbg NIL (dbg ^)))

(de debug ("X" "C")
   (let *Dbg NIL
      (when (pair "X")
         (setq  "C" (cdr "X")  "X" (car "X")) )
      (or
         (dbg (if "C" (method "X" "C") (getd "X")))
         (quit "Can't debug" "X") ) ) )

(de ubg (Lst)
   (when (pair Lst)
      (map
         '((L)
            (when (pair (car L))
               (when (== '! (caar L))
                  (set L (cdar L)) )
               (ubg (car L)) ) )
         Lst )
      T ) )

(de u () (let *Dbg NIL (ubg ^)))

(de unbug ("X" "C")
   (let *Dbg NIL
      (when (pair "X")
         (setq  "C" (cdr "X")  "X" (car "X")) )
      (or
         (ubg (if "C" (method "X" "C") (getd "X")))
         (quit "Can't unbug" "X") ) ) )

# Tracing
(de expr ("F")
   (set "F"
      (list '@ (list 'pass (box (getd "F")))) ) )

(de subr ("F")
   (set "F"
      (getd (cadr (cadr (getd "F")))) ) )

(de traced? ("X" "C")
   (setq "X"
      (if "C"
         (method "X" "C")
         (getd "X") ) )
   (and
      (pair "X")
      (pair (cadr "X"))
      (== '$ (caadr "X")) ) )

# Convert ((X Y) A B) --> ((X Y) ($ foo (X Y) A B))
(de trace ("X" "C")
   (let *Dbg NIL
      (when (pair "X")
         (setq  "C" (cdr "X")  "X" (car "X")) )
      (if "C"
         (unless (traced? "X" "C")
            (or (method "X" "C") (quit "Can't trace" "X"))
            (con @
               (cons
                  (conc
                     (list '$ (cons "X" "C") (car @))
                     (cdr @) ) ) ) )
         (unless (traced? "X")
            (and (sym? (getd "X")) (quit "Can't trace" "X"))
            (and (num? (getd "X")) (expr "X"))
            (set "X"
               (list
                  (car (getd "X"))
                  (conc (list '$ "X") (getd "X")) ) ) ) )
      "X" ) )

# Convert ((X Y) ($ foo (X Y) A B)) --> ((X Y) A B)
(de untrace ("X" "C")
   (let *Dbg NIL
      (when (pair "X")
         (setq  "C" (cdr "X")  "X" (car "X")) )
      (if "C"
         (when (traced? "X" "C")
            (con
               (method "X" "C")
               (cdddr (cadr (method "X" "C"))) ) )
         (when (traced? "X")
            (let X (set "X" (cddr (cadr (getd "X"))))
               (and
                  (== '@ (pop 'X))
                  (= 1 (length X))
                  (= 2 (length (car X)))
                  (== 'pass (caar X))
                  (sym? (cdadr X))
                  (subr "X") ) ) ) )
      "X" ) )

(de *NoTrace
   @ @@ @@@
   pp show more led
   stat what who can dep ed d e debug u unbug trace untrace )

(de traceAll ()
   (let *Dbg NIL
      (all
         '(("X")
            (unless (memq "X" *NoTrace)
               (cond
                  ((= `(char "+") (char "X"))
                     (mapc trace
                        (mapcan
                           '(("Y")
                              (and
                                 (pair "Y")
                                 (fun? (cdr "Y"))
                                 (list (cons (car "Y") "X")) ) )
                           (val "X") ) ) )
                  ((pair (getd "X"))
                     (trace "X") ) ) ) ) ) ) )

# Hex Dump
(de hd (File Cnt)
   (in File
      (let Pos 0
         (while
            (and
               (nand Cnt (lt0 (dec 'Cnt)))
               (make (do 16 (and (rd 1) (link @)))) )
            (let L @
               (prin (pad 8 (hex Pos)) "  ")
               (inc 'Pos 16)
               (mapc
                  '((N) (prin (pad 2 (hex N)) " "))
                  L )
               (space (+ 1 (* 3 (- 16 (length L)))))
               (mapc
                  '((N) (prin (if (<= 32 N 127) (char N) ".")))
                  L )
               (prinl) ) ) ) ) )
