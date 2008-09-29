# 10jul08abu
# (c) Software Lab. Alexander Burger

(load "lib/http.l" "lib/xhtml.l")

(de subDirs (Dir)
   (cache '*DirCache (or (pack (flip (chop Dir))) ".")
      (extract
         '((F)
            (when (=T (car (info (setq F (pack Dir F)))))
               (pack F '/) ) )
         (dir Dir) ) ) )

(de dir.html (Path)
   (and (app) (setq *DirTree (subDirs)))
   (html NIL "Test" NIL NIL
      (<tree> "@dir.html" Path *DirTree subDirs nil subDirs) ) )

(server 8080 "@dir.html")
