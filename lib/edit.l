# 17dec04abu
# (c) Software Lab. Alexander Burger

# "*F" "*Lst" "*X" "*K"

(de edit @
   (let *Dbg NIL
      (setq "*F" (tmp '"edit"))
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
                        (if (atom "X")
                           (println "X" T)
                           (printsp (cdr "X"))
                           (pretty (setq "X" (car "X")))
                           (cond
                              ((type "X")
                                 (prin "  # ")
                                 (print @) )
                              ((<= 666666 "X" 999999)
                                 (prin "  # " (datStr "X")) ) )
                           (prinl) ) )
                     (prinl)
                     (println '(********))
                     (prinl) ) ) ) )
         (call 'vim
            "+set iskeyword=@,33-34,36-38,42-90,92,94-95,97-125"
            "+map ^] yw:call setline(line(\"$\"), \"(\" . line(\".\") . \" \" . @@ . \")\")^MZZ"
            "+map ^T GC(0)^[ZZ"
            (pack "+" "N")
            "*F" )
         (apply ==== "*Lst")
         (in "*F"
            (while (and (setq "*X" (read)) (atom "*X"))
               (def "*X" (read))
               (until (= '(********) (setq "*K" (read)))
                  (def "*X" "*K" (read)) ) ) )
         (====)
         (NIL "*X" (throw))
         (T (=0 (car "*X")))
         (setq "N" (car "*X"))
         ("edit" (conc (cdr "*X") "Lst")) ) ) )

(de "loc" ("X")
   (cond
      ((and "X" (str? "X") (not (memq "X" (made))))
         (link "X") )
      ((pair "X")
         ("loc" (car "X"))
         ("loc" (cdr "X")) ) ) )
