# 14jun02abu
# (c) Software Lab. Alexander Burger
# Graphtec Digitizer Interface

(zero "OrgX" "OrgY")

(de digi ()
   (in "/dev/ttyS0"
      (let L (line NIL 4 1 4 1 1)
         (if (atom L)
            (quit "Digitizer error")
            (cons
               (getNum 5 L)                  # Flg
               (cons
                  (getNum 1 L)               # X
                  (getNum 3 L) ) ) ) ) ) )   # Y

(de digitize (Foo Foo1 Foo2)
   (default  Foo1 Foo  Foo2 Foo1)
   (use D
      (while (= 4 (car (setq D (digi))))
         (setq  "OrgX" (cadr D)  "OrgY" (cddr D)) )
      ((case (car D) (2 Foo) (1 Foo1) (8 Foo2))
         (- (cadr D) "OrgX")
         (- (cddr D) "OrgY") ) ) )
