# 06jun05abu
# (c) Software Lab. Alexander Burger

(de permute (Lst)
   (ifn (cdr Lst)
      (cons Lst)
      (mapcan
         '((X)
            (mapcar
               '((Y) (cons X Y))
               (permute (delete X Lst)) ) )
         Lst ) ) )

(de shuffle (Lst)
   (make
      (while Lst
         (let (N (rand 1 (length Lst))  L1 (head (dec N) Lst)  L2 (nth Lst N))
            (link (pop 'L2))
            (setq Lst (conc L1 L2)) ) ) ) )

(de samples (Cnt Lst)
   (make
      (until (=0 Cnt)
         (when (>= Cnt (rand 1 (length Lst)))
            (link (car Lst))
            (dec 'Cnt) )
         (pop 'Lst) ) ) )


# Genetic Algorithm
(de gen ("Cnt" "re" "mu" "se" . "Init")
   (use ("P" "X" "Y")
      (setq "P"
         (sort
            (make
               (do "Cnt"
                  (setq "X" ("mu" (run "Init")))
                  (link (cons ("se" "X") "X")) ) ) ) )
      (do (* "Cnt" "Cnt")
         (setq "X" (get "P" (rand 1 "Cnt")))                   # Recombination
         (while (== "X" (setq "Y" (get "P" (rand 1 "Cnt")))))
         (setq "X" ("mu" ("re" (cdr "X") (cdr "Y"))))          # Mutation
         (when (> (setq "Y" ("se" "X")) (caar "P"))            # Selection
            (if (seek '((L) (>= (caadr L) "Y")) "P")
               (con @ (cons (cons "Y" "X") (cdr @)))
               (conc "P" (cons (cons "Y" "X"))) )
            (pop '"P") ) )
      (and (car (last "P")) (cdr (last "P"))) ) )


# Alpha-Beta tree search
(de game ("Flg" "Cnt" "moves" "move" "cost")
   (let ("Alpha" '(1000000)  "Beta" -1000000)
      (recur ("Flg" "Cnt" "Alpha" "Beta")
         (let? "Lst"
            (sort
               (mapcar
                  '(("Mov")
                     (prog2
                        ("move" (car "Mov"))
                        (cons ("cost" "Flg") "Mov")
                        ("move" (cdr "Mov")) ) )
                  ("moves" "Flg") ) )
            (dec '"Cnt")
            (loop
               ("move" (cadar "Lst"))
               (setq "*Val"
                  (or
                     (and
                        (n0 "Cnt")
                        (recurse
                           (not "Flg")
                           "Cnt"
                           (cons (- "Beta"))
                           (- (car "Alpha")) )
                        (cons
                           (- (car @))
                           (cons (cdar "Lst") (cdr @)) ) )
                     (list (caar "Lst") (cdar "Lst")) ) )
               ("move" (cddar "Lst"))
               (T (>= "Beta" (car "*Val"))
                  (cons "Beta" (cons (cdar "Lst") (cdr "Alpha"))) )
               (when (> (car "Alpha") (car "*Val"))
                  (setq "Alpha" "*Val") )
               (NIL (setq "Lst" (cdr "Lst")) "Alpha") ) ) ) ) )


### Grids ###
(de grid (DX DY)
   (let Grid
      (make
         (for (X 1 (>= DX X) (inc X))
            (link
               (make
                  (for (Y 1 (>= DY Y) (inc Y))
                     (link
                        (def
                           (if (> DX 26)
                              (box)
                              (intern (pack (char (+ X 96)) Y)) )
                           (cons (cons) (cons)) ) ) ) ) ) ) )
      (for (X 2 (>= DX X) (inc X))
         (for (Y 1 (>= DY Y) (inc Y))
            (set (car (val (get Grid X Y))) (get Grid (dec X) Y)) ) )  # west
      (for (X 1 (> DX X) (inc X))
         (for (Y 1 (>= DY Y) (inc Y))
            (con (car (val (get Grid X Y))) (get Grid (inc X) Y)) ) )  # east
      (for (X 1 (>= DX X) (inc X))
         (for (Y 2 (>= DY Y) (inc Y))
            (set (cdr (val (get Grid X Y))) (get Grid X (dec Y))) ) )  # south
      (for (X 1 (>= DX X) (inc X))
         (for (Y 1 (> DY Y) (inc Y))
            (con (cdr (val (get Grid X Y))) (get Grid X (inc Y))) ) )  # north
      Grid ) )

(de west (Fld)
   (caar (val Fld)) )

(de east (Fld)
   (cdar (val Fld)) )

(de south (Fld)
   (cadr (val Fld)) )

(de north (Fld)
   (cddr (val Fld)) )
