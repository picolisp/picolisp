# 13jan16abu
# (c) Software Lab. Alexander Burger

# "*F" "*Lst" "*X" "*K"

(de edit @
   (let *Dbg NIL
      (setq "*F" (tmp '"edit.l"))
      (catch NIL
         ("edit" (rest)) ) ) )

(de "edit" ("Lst")
   (let "N" 1
      (loop
         (out "*F"
            (setq "*Lst"
               (make
                  (for "S" "Lst"
                     ("loc" (printsp "S"))
                     ("loc" (val "S"))
                     (pretty (val "S"))
                     (prinl)
                     (for "X" (sort (getl "S"))
                        ("loc" "X")
                        (space 3)
                        (if (atom "X")
                           (println "X" T)
                           (printsp (cdr "X"))
                           (pretty (setq "X" (car "X")) -3)
                           (cond
                              ((type "X")
                                 (prin "  # ")
                                 (print @) )
                              ((>= 799999 "X" 700000)
                                 (prin "  # " (datStr "X")) ) )
                           (prinl) ) )
                     (prinl)
                     (println '(=======))
                     (prinl) ) ) ) )
         (call "vim"
            "+set isk=33-34,36-38,42-90,92,94-95,97-125"
            "+map K yiw:call setline(line(\"$\"), \"(\" . line(\".\") . \" \" . @@ . \")\")^MZZ"
            "+map Q GC(0)^[ZZ"
            (pack "+" "N")
            "*F" )
         (apply ==== "*Lst")
         (in "*F"
            (while (and (setq "*X" (read)) (atom "*X"))
               (def "*X" (read))
               (until (= '(=======) (setq "*K" (read)))
                  (def "*X" "*K" (read)) ) ) )
         (====)
         (NIL "*X" (throw))
         (T (=0 (car "*X")))
         (setq "N" (car "*X"))
         ("edit" (conc (cdr "*X") "Lst")) ) ) )

(de "loc" ("X" "Lst")
   (cond
      ((memq "X" "Lst"))
      ((and (str? "X") (not (memq "X" (made))))
         (link "X") )
      ((pair "X")
         (push '"Lst" "X")
         ("loc" (car "X") "Lst")
         ("loc" (cdr "X") "Lst") ) ) )

# vi:et:ts=3:sw=3
