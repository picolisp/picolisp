# 27feb10abu
# (c) Software Lab. Alexander Burger

# Structure Editor
(setq *Clip)

(de ed ("X" "C")
   (when (pair "X")
      (setq  "C" (cdr "X")  "X" (car "X")) )
   (catch NIL
      (let (*Dbg NIL  "Done")
         (ifn "C"
            (set "X" (_ed (val "X")))
            (and
               (asoq "X" (val "C"))
               (con @ (_ed (cdr @))) ) )
         (pp "X" "C") ) ) )

(de _ed (X)
   (use C
      (loop
         (T "Done" X)
         (pretty (car X))
         (prinl)
         (T (member (setq C (key)) '("^H" "^?")) X)
         (T (= C "^I") (on "Done") X)
         (setq X
            (if (>= "9" C "1")
               (cons
                  (head (setq C (format  C)) X)
                  (nth X (inc C)) )
               (case (uppc C)
                  (("^M" "^J") (cons (_ed (car X)) (cdr X)))
                  ("^[" (throw))
                  (" " (cons (car X) (_ed (cdr X))))
                  ("D" (cdr X))
                  ("I" (prin "Insert:") (cons (read) X))
                  ("R" (prin "Replace:") (cons (read) (cdr X)))
                  ("X" (setq *Clip (car X)) (cdr X))
                  ("C" (setq *Clip (car X)) X)
                  ("V" (cons *Clip X))
                  ("0" (append (car X) (cdr X)))
                  ("B"
                     (if (== '! (caar X))
                        (cons (cdar X) (cdr X))
                        (cons (cons '! (car X)) (cdr X)) ) )
                  (T X) ) ) ) ) ) )
