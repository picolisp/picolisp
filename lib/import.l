# 14sep03abu
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

# Upper/lower case conversions
(de *Ulowc
   (`(chop "GMBH") . "GmbH")
   (`(chop "UND") . "und")
   (`(chop "AG") . "AG")
   (`(chop "KG") . "KG")
   (`(chop "OHG") . "OHG") )

(de getUlowc (N Lst)
   (setq Lst (clip (get Lst N)))
   (pack
      (make
         (while Lst
            (let L
               (make
                  (while (or (low? (car Lst)) (upp? (car Lst)))
                     (link (pop 'Lst)) ) )
               (cond
                  ((assoc (mapcar uppc L) *Ulowc)
                     (link (cdr @)) )
                  ((>= 3 (length L))
                     (link L) )
                  (T
                     (link
                        (uppc (car L))
                        (mapcar lowc (cdr L)) ) ) ) )
            (and Lst (link (pop 'Lst))) ) ) ) )
