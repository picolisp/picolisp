# 13nov02abu
# (c) Software Lab. Alexander Burger

(de test1 (S N1)
   (let (N (read)  X (eval (list S N1)))
      (unless (= N X)
         (prinl "^J" N ": (" S " " N1 ") -> " X)
         (bye) ) ) )

(de test2 (S N1 N2)
   (let (N (read)  X (eval (list S N1 N2)))
      (unless (= N X)
         (prinl "^J" N ": (" S " " N1 " " N2 ") -> " X)
         (bye) ) ) )

(in NIL
   (do 1000
      (prin ".")
      (flush)
      (do 1000
         (setq
            N1 (read)
            N2 (read) )
         (test2 '+ N1 N2)
         (test2 '+ N1 1)
         (test2 '- N1 N2)
         (test2 '- N1 1)
         (test2 '* N1 N2)
         (test2 '* N1 2)
         (test2 '% N1 N2)
         (test2 '/ N1 N2)
         (test2 '/ N1 2)
         (test1 'sqrt (abs N1)) ) ) )

(prinl)
(bye)
