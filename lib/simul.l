# 17may02abu
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
            (setq Lst (append L1 L2)) ) ) ) )

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
   (mapc
      (quote (L)
         (when (setq L (make (eval L)))
            (if (num? (car L))
               (link L)
               (mapc link L) ) ) )
      Lst )
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
      (mapc
         (quote (X)
            (when (< (car C) (car (setq X (parMax N X))))
               (setq C X) ) )
         Lst )
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


### Genetic Algorithm ###
(de gen ("Cnt" "Re" "Mu" "Se" . "Init")
   (use ("P" "X" "Y")
      (setq "P"
         (sort
            (make
               (do "Cnt"
                  (setq "X" ("Mu" (run "Init")))
                  (link (cons ("Se" "X") "X")) ) ) ) )
      (do (* "Cnt" "Cnt")
         (setq "X" (get "P" (rand 1 "Cnt")))                   # Recombination
         (while (== "X" (setq "Y" (get "P" (rand 1 "Cnt")))))
         (setq "X" ("Mu" ("Re" (cdr "X") (cdr "Y"))))          # Mutation
         (when (> (setq "Y" ("Se" "X")) (caar "P"))            # Selection
            (if (seek '((L) (>= (caadr L) "Y")) "P")
               (con @ (cons (cons "Y" "X") (cdr @)))
               (conc "P" (cons (cons "Y" "X"))) )
            (pop '"P") ) )
      (and (car (last "P")) (cdr (last "P"))) ) )
