# 15may07abu
# (c) Software Lab. Alexander Burger

# *Profile

(de _prf? (Lst)
   (and (pair Lst) (== 'tick (caadr Lst))) )

(de _prf (Lst)
   (when (pair Lst)
      (if (_prf? Lst)
         (prog1
            (cadr (cadr Lst))
            (set (cdadr Lst) (cons (+ 0) (+ 0))) )
         (con
            Lst
            (list (cons 'tick (cons (+ 0) (+ 0)) (cdr Lst))) )
         T ) ) )

(de "uprf" (Lst)
   (when (_prf? Lst)
      (con Lst (cddr (cadr Lst)))
      T ) )

(de prof ("X" "C")
   (when (pair "X")
      (setq  "C" (cdr "X")  "X" (car "X")) )
   (and (not "C") (num? (getd "X")) (expr "X"))
   (unless
      (and
         (_prf (if "C" (method "X" "C") (getd "X")))
         (push1 '*Profile (cons "X" "C")) )
      (quit "Can't profile" "X") ) )

(de unprof ("X" "C")
   (del (cons "X" "C") '*Profile)
   ("uprf" (if "C" (method "X" "C") (getd "X"))) )

(de profile ()
   (mapc println
      (flip
         (by '((X) (+ (car X) (cadr X))) sort
            (mapcar
               '(("X")
                  (let P
                     (_prf
                        (if (cdr "X")
                           (method (car "X") (cdr "X"))
                           (getd (car "X")) ) )
                     (cons (car P) (cdr P) "X") ) )
               *Profile ) ) ) ) )
