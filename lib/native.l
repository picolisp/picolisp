# 22jul10abu
# (c) Software Lab. Alexander Burger

(de gcc (Nm L . Lst)
   (out (tmp Nm ".c") (here "/**/"))
   ~(case *OS
      (("Linux" "FreeBSD")
         (quote
            (apply call L 'gcc "-o" (tmp Nm)
               "-fPIC" "-shared" "-export-dynamic"
               "-O" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" (tmp Nm ".c") ) ) ) )
   (for L Lst
      (def (car L)
         (list
            (cadr L)
            (cons 'native (tmp Nm) (name (caddr L)) (cdddr L)) ) )
      (when (== '@ (fin (cadr L)))
         (push (cdaar L) 'pass) ) ) )

(de unsigned (N)
   (& `(dec (** 2 32)) (+ N `(** 2 32))) )

# vi:et:ts=3:sw=3
