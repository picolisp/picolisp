# 14sep04abu
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
         (let (N (rand 1 (length Lst))  L1 (head (- N 1) Lst)  L2 (nth Lst N))
            (link (pop 'L2))
            (setq Lst (conc L1 L2)) ) ) ) )

(de samples (Cnt Lst)
   (make
      (until (=0 Cnt)
         (when (>= Cnt (rand 1 (length Lst)))
            (link (car Lst))
            (dec 'Cnt) )
         (pop 'Lst) ) ) )


### Parallel Execution Trees ###
# *Pet

(de pet (Prg Pet)
   (let Lst
      (make
         (when Pet
            (made Pet (cdr (parMax 0 Pet))) )
         (run Prg) )
      (if (num? (car Lst))
         (list Lst)
         Lst ) ) )

(de par Lst
   (for L Lst
      (when (setq L (make (eval L)))
         (if (num? (car L))
            (link L)
            (mapc link L) ) ) )
   (when (made)
      (made (made) (cdr (parMax 0 (made)))) ) )

(de parMax (N Lst)  #> (num . lst)
   (let C NIL
      (while (num? (car Lst))
         (inc 'N (pop 'Lst))
         (setq
            C Lst
            Lst (cdr Lst) ) )
      (push 'C N)
      (for X Lst
         (when (< (car C) (car (setq X (parMax N X))))
            (setq C X) ) )
      C ) )

# PET execution
(de pex (Lst)
   (mapcan
      '((*Pet)
         (run (cadr *Pet))
         (if (=0 (dec *Pet))
            (when (setq *Pet (cddr *Pet))
               ((if (num? (car *Pet)) list copy) *Pet) )
            (list *Pet) ) )
      Lst ) )


# Alpha-Beta tree search
(de game ("Flg" "Cnt" "Pos" "moves" "move" "cost")
   (_game "Flg" "Cnt" "Pos" '(T)) )

(de _game ("Flg" "Cnt" "Pos" "Alpha" "Beta")
   (let? "Lst"
      (sort
         (mapcar
            '(("Mov")
               (and
                  ("move" "Flg" "Pos" "Mov")
                  (cons ("cost" "Flg" @) (cons "Mov" @)) ) )
            ("moves" "Flg" "Pos") ) )
      (dec '"Cnt")
      (use "Val"
         (loop
            (setq "Val"
               (or
                  (and
                     (n0 "Cnt")
                     (_game
                        (not "Flg")
                        "Cnt"
                        (cddar "Lst")
                        (cons (- "Beta"))
                        (- (car "Alpha")) )
                     (cons
                        (- (car @))
                        (cons (cdar "Lst") (cdr @)) ) )
                  (cons (caar "Lst") (cons (cdar "Lst"))) ) )
            (T (>= "Beta" (car "Val"))
               (cons "Beta" (cons (cdar "Lst") (cdr "Alpha"))) )
            (when (> (car "Alpha") (car "Val"))
               (setq "Alpha" "Val") )
            (NIL (setq "Lst" (cdr "Lst")) "Alpha") ) ) ) )


### Genetic Algorithm ###
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
