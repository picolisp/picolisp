# 21jul02abu
# (c) Software Lab. Alexander Burger

(de hanoi (N A B C)
   (unless (=0 N)
      (hanoi (- N 1) A C B)
      (println (list N A B))
      (hanoi (- N 1) C B A) ) )
