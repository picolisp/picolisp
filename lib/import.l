# 19jan05abu
# (c) Software Lab. Alexander Burger

### Import Parsing ###
(de getStr (N Lst)
   (pack (clip (get Lst N))) )

(de getStrl (L Lst)
   (mapcan
      '((N) (and (getStr N Lst) (cons @)))
      L ) )

(de getNum (N Lst)
   (format (getStr N Lst)) )

(de getFlt (P N Lst)
   (format (getStr N Lst) P *Sep0 *Sep3) )

(de getDat (L Lst)
   (date
      (mapcar
         '((N) (getNum N Lst))
         L ) ) )
