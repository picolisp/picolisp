# 26dec04abu
# (c) Software Lab. Alexander Burger

(de rnd ()
   (let N
      (if (rand T)
         (hex
            (pack
               (make
                  (do (rand 1 5)
                     (link (if (rand T) "FFFFFFFF" "00000000")) ) ) ) )
         (let L
            (make
               (do (rand 1 60)
                  (link (char (+ 48 (rand 0 9)))) ) )
            (while (and (= "0" (car L)) (cdr L))
               (pop 'L) )
            (format (pack L)) ) )
      (if (rand T) N (- N)) ) )

(do 8000000
   (setq N1 (rnd))
   (while (=0 (setq N2 (rnd))))
   (prinl N1)
   (prinl N2)
   (prinl N1 " + " N2)
   (prinl N1 " + 1")
   (prinl N1 " - " N2)
   (prinl N1 " - 1")
   (prinl N1 " * " N2)
   (prinl N1 " * 2")
   (prinl N1 " % " N2)
   (prinl N1 " / " N2)
   (prinl N1 " / 2")
   (prinl N1 " >= " N2)
   (prinl N1 " > " N2)
   (prinl "sqrt(" (abs N1) ")") )

(bye)
