# 05feb05abu
# (c) Software Lab. Alexander Burger

# *Line

# Line input editing
(de mkChar (C)
   (prin C)
   (queue '*Line C) )

# Enable line editing
(de *Led
   (use C
      (until (member (setq C (key)) '("^J" "^M"))
         (case C
            (("^H" "^?")
               (when *Line
                  (prin "^H ^H")
                  (setq *Line (cdr (rot *Line))) ) )
            ("^I" (do 3 (mkChar " ")))
            (T (mkChar C)) ) ) )
   (prinl)
   (prog1 (pack *Line) (off *Line)) )
