# 14jun02abu
# (c) Software Lab. Alexander Burger

# *Profile

(de _prf? (Lst)
   (and (pair Lst) (== 'tick (caadr Lst))) )

(de _prf (Lst)
   (when (pair Lst)
      (if (_prf? Lst)
         (prog1
            (cadr (cadr Lst))
            (set (cdadr Lst) (+ 0)) )
         (con
            Lst
            (list (cons 'tick (cons (+ 0) (cdr Lst)))) )
         T ) ) )

(de "uprf" (Lst)
   (when (_prf? Lst)
      (con Lst (cddr (cadr Lst)))
      T ) )

(de prof ("X" "N")
   (let "C"
      (cond
         ((pair "X") (setq  "X" (car "X")) (cdr "X"))
         ((num? "N") (expr "N" "X") NIL)
         (T "N") )
      (unless
         (and
            (_prf (if "C" (method "X" "C") (getd "X")))
            (?push '*Profile (cons "X" "C")) )
         (quit "Can't profile" "X") ) ) )

(de unprof ("X" "C")
   (setq *Profile (delete (cons "X" "C")) *Profile)
   ("uprf" (if "C" (method "X" "C") (getd "X"))) )

(de profile ()
   (mapc println
      (reverse
         (sort
            (mapcar
               '(("X")
                  (cons
                     (_prf
                        (if (cdr "X")
                           (method (car "X") (cdr "X"))
                           (getd (car "X")) ) )
                     "X" ) )
               *Profile ) ) ) ) )
