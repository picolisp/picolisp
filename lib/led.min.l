# 26apr02abu
# (c) Software Lab. Alexander Burger

# *Line

# Line input editing
(de mkChar (C)
   (prin C)
   (setq *Line (conc *Line (list C))) )

# Enable line editing
(de *Led
   (use C
      (until (member (setq C (key)) '("^J" "^M"))
         (case C
            ("^C" (prinl) (bye))
            (("^H" "^?")
               (when *Line
                  (prin "^H ^H")
                  (setq *Line (reverse (cdr (reverse *Line)))) ) )
            ("^I" (do 3 (mkChar " ")))
            (T (mkChar C)) ) ) )
   (prinl)
   (prog1 (pack *Line) (off *Line)) )
