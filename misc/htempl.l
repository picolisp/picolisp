# 19feb01abu
# (c) Software Lab. Alexander Burger

(app)

(httpHead)
(htempl "misc/htempl.html"
   (App1 (X Y)
      (new '(+Form) X Y
         (quote
            (gui '(+TextField) "Name" 20)
            (gui '(+NumField) "Zahl" 10) ) ) ) )
