# 22dec03abu
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
                     (if (rd)
                        @Exe
                        (close @Var)
                        (task @Var)
                        (off @Var)
                        (tele> '@Obj)
                        (tele @L '@Obj) ) ) ) ) ) ) ) )


(class +TeleForm +Form)
# tele

(dm T (Lst . @)
   (=: tele Lst)
   (pass super) )

(dm start> ()
   (mapc tele (: tele) (circ This))
   (super) )

(dm stop> ()
   (super)
   (mapc
      '((L)
         (let (Var (cadr L)  N (or (val Var) (cdddr L)))
            (task N)
            (close N)
            (set Var) ) )
      (: tele) )
   (tele> This) )

(dm tele> (Flg)
   (upd> This) )
