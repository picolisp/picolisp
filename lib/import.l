# 15jul05abu
# (c) Software Lab. Alexander Burger

### Import Parsing ###
(de getStr (N Lst)
   (pack (clip (get Lst N))) )

(de getSym (N Lst)
   (intern
      (pack (replace (clip (get Lst N)) " " '_)) ) )

(de getStrLst (N Lst)
   (mapcar pack (split (clip (get Lst N)) " ")) )

(de getSymLst (N Lst)
   (mapcar
      '((L) (intern (pack L)))
      (split (clip (get Lst N)) " ") ) )

(de getNum (N Lst)
   (format (getStr N Lst)) )

(de getFlt (P N Lst)
   (format (getStr N Lst) P *Sep0 *Sep3) )

(de getDat (L Lst)
   (date
      (mapcar
         '((N) (getNum N Lst))
         L ) ) )
