# 24nov16abu
# (c) Software Lab. Alexander Burger

(de checkJson (X Item)
   (unless (= X Item)
      (quit "Bad JSON" Item) ) )

(de parseJson (Str Arr)
   (let L (str Str "_")
      (recur ()
         (case (++ L)
            ("{"
               (make
                  (for (X (recurse) (not (= "}" X)) (recurse))
                     (checkJson ":" (recurse))
                     (link (cons X (recurse)))
                     (T (= "}" (setq X (recurse))))
                     (checkJson "," X) ) ) )
            ("["
               (make
                  (and Arr (link T))  # Array marker
                  (for (X (recurse) (not (= "]" X)) (recurse))
                     (link X)
                     (T (= "]" (setq X (recurse))))
                     (checkJson "," X) ) ) )
            (T
               (let X @
                  (cond
                     ((pair X) (pack X))
                     ((and (= "-" X) (format (car L)))
                        (- (++ L)) )
                     (T X) ) ) ) ) ) ) )

(de readJson (Arr)
   (case (read "_")
      ("{"
         (make
            (for (X (readJson Arr) (not (= "}" X)) (readJson Arr))
               (checkJson ":" (readJson Arr))
               (link (cons X (readJson Arr)))
               (T (= "}" (setq X (readJson Arr))))
               (checkJson "," X) ) ) )
      ("["
         (make
            (and Arr (link T))  # Array marker
            (for (X (readJson Arr) (not (= "]" X)) (readJson Arr))
               (link X)
               (T (= "]" (setq X (readJson Arr))))
               (checkJson "," X) ) ) )
      (T
         (let X @
            (cond
               ((pair X) (pack X))
               ((and (= "-" X) (format (peek)))
                  (- (read)) )
               (T X) ) ) ) ) )

(de printJson (Item)  # For simplicity, without indentation
   (cond
      ((atom Item) (if Item (print @) (prin "{}")))
      ((=T (car Item))
         (prin "[")
         (map
            '((X)
               (printJson (car X))
               (and (cdr X) (prin ", ")) )
            (cdr Item) )
         (prin "]") )
      (T
         (prin "{")
         (map
            '((X)
               (print (caar X))
               (prin ": ")
               (printJson (cdar X))
               (and (cdr X) (prin ", ")) )
            Item )
         (prin "}") ) ) )

# vi:et:ts=3:sw=3
