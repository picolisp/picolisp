# 23jan03abu
# (c) Software Lab. Alexander Burger

(de global? (X)
   (or
      (memq X '(This ^))
      (member (char X) '(`(char '*) `(char '+) `(char '@))) ) )

(de lint1 ("X")
   (if (atom "X")
      (if (memq "X" "*L")
         (setq "*U" (delq "X" "*U"))
         (or
            (not (sym? "X"))
            (memq "X" '(T NIL))
            (getd "X")
            (str? "X")
            (global? "X")
            (memq "X" "*G")
            (push '"*G" "X") ) )
      (unless (num? (car "X"))
         (case (car "X")
            (:)
            (quote
               (let F (fun? (cdr "X"))
                  (and
                     (pair F)
                     (not (cdr (tail 1 F)))
                     (use "*L" (lintFoo (cdr "X"))) ) ) )
            (let
               (use "*L"
                  (if (atom (cadr "X"))
                     (lint2 (cadr "X"))
                     (for (L (cadr "X") L (cddr L))
                        (lint2 (car L))
                        (lint1 (cadr L)) ) )
                  (mapc lint1 (cddr "X")) ) )
            (use
               (use "*L"
                  (if (atom (cadr "X"))
                     (lint2 (cadr "X"))
                     (mapc lint2 (cadr "X")) )
                  (mapc lint1 (cddr "X")) ) )
            (for
               (use "*L"
                  (lint2 (caadr "X"))
                  (mapc lint1 (cdadr "X"))
                  (mapc lint1 (cddr "X")) ) )
            (case
               (lint1 (cadr "X"))
               (mapc
                  '(("X") (mapc lint1 (cdr "X")))
                  (cddr "X") ) )
            (cond
               (mapc
                  '(("X") (mapc lint1 "X"))
                  (cdr "X") ) )
            ((loop do)
               (when (== 'do (car "X"))
                  (lint1 (cadr "X")) )
               (mapc
                  '(("X")
                     (if (and (pair "X") (or (=T (car "X")) (not (car "X"))))
                        (mapc lint1 (cdr "X"))
                        (lint1 "X") ) )
                  (cddr "X") ) )
            (=:
               (lint1 (last (cddr "X"))) )
            ((dec inc pop push queue val)
               (lintSpec '(T)) )
            ((cut port)
               (lintSpec '(NIL T)) )
            (set
               (lintSpec '(T NIL .)) )
            (xchg
               (lintSpec '(T T .)) )
            (T
               (if (sym? (car "X"))
                  (if (memq (car "X") "*L")
                     (setq "*U" (delq (car "X") "*U"))
                     (or
                        (getd (car "X"))
                        (str? (car "X"))
                        (global? (car "X"))
                        (memq (car "X") "*B")
                        (pre? "ext:" (car "X"))
                        (push '"*B" (car "X")) ) )
                  (lint1 (car "X")) )
               (mapc lint1 (cdr "X")) ) ) ) ) )

(de lint2 (X)
   (when (and (sym? X) (nor (str? X) (global? X)))
      (push '"*U" X)
      (push '"*L" X) ) )

(de lintSpec (L)
   (mapc
      '((X Flg)
         (lint1 (if Flg (strip X) X)) )
      (cdr "X")
      L ) )

(de lintFoo ("Lst")
   (let "A" (car "Lst")
      (while (pair "A")
         (lint2 (pop '"A")) )
      (when "A"
         (lint2 "A") )
      (mapc lint1 (cdr "Lst")) ) )

(de lint ("X" "C")
   (let (*Dbg T  "*L" NIL  "*B" NIL  "*G" NIL  "*U")
      (when (pair "X")
         (setq  "C" (cdr "X")  "X" (car "X")) )
      (lintFoo (if "C" (method "X" "C") (getd "X")))
      (when (or "*B" "*G" "*U")
         (if "C"
            (println "X" "C")
            (println "X") )
         (when "*B" (prin "   BadFun ") (println "*B"))
         (when "*G" (prin "   Global ") (println "*G"))
         (when "*U" (prin "   Unused ") (println "*U"))
         T ) ) )

(de lintAll ()
   (let *Dbg NIL
      (all
         '(("X")
            (cond
               ((= `(char "+") (char "X"))
                  (mapc lint
                     (mapcan
                        '(("Y")
                           (and
                              (pair "Y")
                              (fun? (cdr "Y"))
                              (list (cons (car "Y") "X")) ) )
                        (val "X") ) ) )
               ((and (not (global? "X")) (pair (getd "X")))
                  (lint "X") ) ) ) ) ) )
