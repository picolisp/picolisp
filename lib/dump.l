# 20sep03abu
# (c) Software Lab. Alexander Burger

(de dump CL
   (for ("Q" (goal CL) (asoq '@@ (prove "Q")))
      (let (Obj (cdr @)  Lst)
         (prin "(obj ")
         (_dmp Obj)
         (maps
            '((X)
               (unless (member X Lst)
                  (prinl)
                  (space 3)
                  (if (atom X)
                     (print X T)
                     (printsp (cdr X))
                     (_dmp (car X) T) ) ))
               Obj )
         (prinl " )")
         Obj ) ) )

(de _dmp (Obj Flg)
   (cond
      ((pair Obj)
         (prin "(")
         (_dmp (pop 'Obj) T)
         (while (pair Obj)
            (space)
            (_dmp (pop 'Obj) T) )
         (when Obj
            (prin " . ")
            (_dmp Obj T) )
         (prin ")") )
      ((ext? Obj)
         (when Flg
            (prin "`(obj ") )
         (prin "(")
         (catch NIL
            (maps
               '((X)
                  (with (and (pair X) (meta Obj (cdr X)))
                     (when (isa '+Key This)
                        (or Flg (push 'Lst X))
                        (printsp (type Obj) (: var))
                        (when (: hook)
                           (_dmp (: hook) T)
                           (space) )
                        (_dmp (car X) T)
                        (throw NIL) ) ) )
               Obj )
            (print (type Obj))
            (maps
               '((X)
                  (with (and (pair X) (meta Obj (cdr X)))
                     (when (isa '+Ref This)
                        (space)
                        (or Flg (push 'Lst X))
                        (print (: var))
                        (when (: hook)
                           (space)
                           (_dmp (: hook) T) )
                        (space)
                        (_dmp (car X) T) ) ) )
               Obj ) )
         (when Flg
            (prin ")") )
         (prin ")") )
      (T (print Obj)) ) )
