# 30dec11abu
# (c) Software Lab. Alexander Burger

(if (opt)
   (let "Lst" (chop @)
      (if (= "-" (car "Lst"))
         (let "Pre" (pop '"Lst")
            (when (member (car "Lst") '("\"" "'"))
               (setq "Pre" (pop '"Lst")) )
            (let "Str" (pack "Lst")
               (for "Sym" (all)
                  (and
                     (pre? "Str" "Sym")
                     (getd "Sym")
                     (prinl "Pre" "Sym") ) ) ) )
         (let ("Path" (rot (split "Lst" "/"))  "Str" (pack (car "Path")))
            (setq "Path" (and (cdr "Path") (pack (glue "/" @) "/")))
            (for "Sym" (dir "Path" T)
               (and
                  (pre? "Str" "Sym")
                  (prinl "Path" "Sym") ) ) ) ) )
   (prinl '+) )

# vi:et:ts=3:sw=3
