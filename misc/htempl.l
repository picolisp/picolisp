# 06nov04abu
# (c) Software Lab. Alexander Burger

(app)

(httpHead)
(htempl "misc/htempl.html"
   (App1 (X Y)
      (new '(+Form) X Y
         (quote
            (gui '(+TextField) "Text" 20)
            (gui '(+NumField) "Number" 10) ) ) ) )
