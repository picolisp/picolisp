# 14sep04abu
# (c) Software Lab. Alexander Burger

### Java Remote Control ###
(allow "java/tele.jar")

# ((port sym exe) ..)
(de tele (@L @Obj)
   (let (@S (port (car @L))  @Var (cadr @L)  @Exe (caddr @L))
      (con (cddr @L) @S)
      (macro
         (task @S
            (when (setq @Var (accept @S))
               (task @S)
               (close @S)
               (tele> '@Obj T)
               (task @Var
                  (in @Var
                     (if (rd 1)
                        @Exe
                        (close @Var)
                        (task @Var)
                        (off @Var)
                        (tele> '@Obj)
                        (tele @L '@Obj) ) ) ) ) ) ) ) )


# Form Prefix
(class +Tele)
# tele

(dm T (Lst . @)
   (=: tele Lst)
   (pass extra) )

(dm start> ()
   (mapc tele (: tele) (circ This))
   (extra) )

(dm stop> ()
   (extra)
   (for L (: tele)
      (let (Var (cadr L)  N (or (val Var) (cdddr L)))
         (task N)
         (close N)
         (set Var) ) )
   (tele> This) )

(dm tele> (Flg)
   (upd> This) )
