# 06oct04abu
# (c) Software Lab. Alexander Burger

(de subDirs (Dir)
   (cache '*DirCache (or (pack (reverse (chop Dir))) ".")
      (mapcan
         '((F)
            (when (=T (car (info (setq F (pack Dir F)))))
               (cons (pack F '/)) ) )
         (dir Dir) ) ) )

(de dir.html (Path)
   (and (app) (setq *DirTree (subDirs)))
   (html "Test"
      (<tree> "@dir.html" Path *DirTree subDirs nil subDirs prinl) ) )

(server 8080 "@dir.html")
