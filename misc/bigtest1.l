# 19feb03abu
# (c) Software Lab. Alexander Burger

(de rnd ()
   (let L
      (make
         (do (rand 1 30)
            (link (char (+ 48 (rand 0 9)))) ) )
      (while (and (= "0" (car L)) (cdr L))
         (pop 'L) )
      (pack L) ) )

(do 1000000
   (setq
      S1 (and (rand T) "-")
      N1 (rnd)
      S2 (and (rand T) "-") )
   (while (= "0" (setq N2 (rnd))))
   (prinl S1 N1)
   (prinl S2 N2)
   (prinl S1 N1 " + " S2 N2)
   (prinl S1 N1 " + 1")
   (prinl S1 N1 " - " S2 N2)
   (prinl S1 N1 " - 1")
   (prinl S1 N1 " * " S2 N2)
   (prinl S1 N1 " * 2")
   (prinl S1 N1 " % " S2 N2)
   (prinl S1 N1 " / " S2 N2)
   (prinl S1 N1 " / 2")
   (prinl S1 N1 " >= " S2 N2)
   (prinl S1 N1 " > " S2 N2)
   (prinl "sqrt(" N1 ")") )

(bye)
