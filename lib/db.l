# 23jan03abu
# (c) Software Lab. Alexander Burger

### Tree Access ###
(de tree (Var Cls Hook)
   (get (or Hook *DB) Cls Var) )


(de db (Var Cls . @)
   (with (or (get Cls Var) (meta Cls Var))
      (let Tree (tree (: var) (: cls) (and (: hook) (next)))
         (if (isa '+Key This)
            (and
               (fetch Tree (next))
               (pass _db @) )
            (let (Val (next)  Q (init Tree (cons Val) (cons Val T)))
               (loop
                  (NIL (step Q T))
                  (T (pass _db @ Var Val) @) ) ) ) ) ) )

(de _db (Obj . @)
   (loop
      (NIL (next) Obj)
      (NIL (has> Obj (arg) (next))) ) )


# (collect 'var 'cls ['hook] ['val|beg ['end [var ..]]])
(de collect (Var Cls . @)
   (with (or (get Cls Var) (meta Cls Var))
      (let
         (Tree (tree (: var) (: cls) (and (: hook) (next)))
            X1 (next)
            X2 (if (args) (next) (or X1 T)) )
         (make
            (if (isa '+Key This)
               (iter Tree
                  '((X)  (link (if (args) (pass get X) X)))
                  X1 X2 )
               (if (>= X2 X1)
                  (setq X1 (cons X1)  X2 (cons X2 T))
                  (setq X1 (cons X1 T)  X2 (cons X2)) )
               (if (isa '+List This)
                  (iter Tree
                     '((X)
                        (when (args)
                           (setq X (pass get X)) )
                        (or (memq X (made)) (link X)) )
                     X1 X2 )
                  (iter Tree
                     '((X)  (link (if (args) (pass get X) X)))
                     X1 X2 T ) ) ) ) ) ) )


(de genKey (Var Cls Hook Min Max)
   (if (maxKey (tree Var Cls Hook) Min Max)
      (+ 1 @)
      (or Min 1) ) )


### Root Objects ###
(class +ObjRoot)


### Relations ###
(class +Relation)
# cls var

(dm T (Var Lst)
   (=: cls *Class)
   (=: var Var) )

# Default value
(dm dflt> ())

# Type check
(dm mis> (Val Obj))  #> lst

# Value present?
(dm has> (Val X)  #> any | NIL
   (and (= Val X) X) )

# Set value
(dm put> (Obj Old New)
   New )

# Delete value
(dm del> (Obj Old Val)
   (and (<> Old Val) Val) )

# Maintain relations
(dm rel> (Obj Old New))

(dm lose> (Obj Val)
   (rel> This Obj Val) )

(dm keep> (Obj Val)
   (rel> This Obj NIL Val) )

# Finalizer
(dm zap> (Obj Val))


(class +Any +Relation)


# (+Bag) (cls ..) (..) (..)
(class +Bag +Relation)
# bag

(dm T (Var Lst)
   (=: bag
      (mapcar
         '((L)
            (prog1
               (new (car L) Var (cdr L))
               (and
                  (get @ 'hook)
                  (=: hook @) ) ) )
         Lst ) )
   (super Var) )

(de misBag (Val Obj)
   (or
      (ifn (lst? Val) "Not a Bag")
      (pick
         '((X V) (mis> X V Obj))
         (: bag)
         Val ) ) )

(dm mis> (Val Obj)
   (misBag Val Obj) )

(dm has> (Val X)
   (and Val
      (or
         (super Val X)
         (and (member Val X) X) ) ) )

(dm put> (Obj Old New)
   (trim
      (if (and New (misBag New Obj))
         (mapcar
            '((X)
               (if (mis> X New Obj)
                  (dflt> X)
                  (put> X Obj NIL New) ) )
            (: bag) )
         (mapcar
            '((X O N) (put> X Obj O N))
            (: bag)
            Old
            New ) ) ) )

(dm rel> (Obj Old New)
   (if (and Old (misBag Old Obj))
      (mapc
         '((X)
            (ifn (mis> X Old Obj)
               (rel> X Obj Old NIL) ) )
         (: bag) )
      (when Old
         (mapc
            '((X O)
               (rel> X Obj O NIL) )
            (: bag)
            Old ) ) )
   (if (and New (misBag New Obj))
      (mapc
         '((X)
            (ifn (mis> X New Obj)
               (rel> X Obj NIL New) ) )
         (: bag) )
      (when New
         (mapc
            '((X N)
               (rel> X Obj NIL N) )
            (: bag)
            New ) ) ) )


# (+Number) [num]
(class +Number +Relation)
# scl

(dm T (Var Lst)
   (=: scl (car Lst))
   (super Var (cdr Lst)) )

(dm dflt> ()
   0 )

(dm mis> (Val Obj)
   (and
      Val
      (not (num? Val))
      `(_ "Numeric input expected") ) )


# (+Date)
(class +Date +Number)

(dm T (Var Lst)
   (super Var (cons NIL Lst)) )

(dm dflt> ()
   (date) )


# (+Time)
(class +Time +Number)

(dm T (Var Lst)
   (super Var (cons NIL Lst)) )

(dm dflt> ()
   (time) )


# (+Symbol)
(class +Symbol +Relation)

(dm mis> (Val Obj)
   (unless (sym? Val)
      `(_ "Symbolic type expected") ) )


# (+String) [num]
(class +String +Symbol)
# len

(dm T (Var Lst)
   (=: len (car Lst))
   (super Var (cdr Lst)) )

(dm mis> (Val Obj)
   (unless (str? Val)
      `(_ "String type expected") ) )


# (+Link) typ
(class +Link +Relation)
# type

(dm T (Var Lst)
   (unless (=: type (car Lst))
      (quit "Missing Link" Var) )
   (super Var (cdr Lst)) )

(de canQuery (Val)
   (and
      (pair Val)
      (pair (car Val))
      (not
         (find
            '((L)
               (not
                  (find
                     '((Cls)
                        (get
                           Cls
                           ((if (lst? (car L)) cadr car) L) ) )
                     (: type) ) ) )
            Val ) ) ) )

(dm mis> (Val Obj)
   (and
      Val
      (nor
         (isa (: type) Val)
         (canQuery Val) )
      `(_ "Typ-Fehler") ) )


# (+Hook) typ
(class +Hook +Link)

(dm rel> (Obj Old New)
   (let L
      (filter
         '((X)
            (and
               (pair X)
               (or
                  (== (: var) (get (meta Obj (cdr X)) 'hook))
                  (find
                     '((B) (== (: var) (get B 'hook)))
                     (get (meta Obj (cdr X)) 'bag) ) ) ) )
         (getl Obj) )
      (put Obj (: var) Old)
      (mapc
         '((X)
            (rel> (meta Obj (cdr X)) Obj (car X)) )
         L )
      (put Obj (: var) New)
      (mapc
         '((X)
            (rel> (meta Obj (cdr X)) Obj NIL (car X)) )
         L ) )
   (super Obj Old New) )


# (+Joint) var typ
(class +Joint +Link)
# slot

(dm T (Var Lst)
   (=: slot (car Lst))
   (super Var (cdr Lst)) )

(dm mis> (Val Obj)
   (and
      Val
      (nor
         (canQuery Val)
         (and
            (isa (: type) Val)
            (with (meta Val (: slot))
               (or
                  (isa '+Joint This)
                  (find
                     '((B) (isa '+Joint B))
                     (: bag) ) ) ) ) )
      `(_ "Bad type") ) )

(dm rel> (Obj Old New)
   (and Old (del> Old (: slot) Obj))
   (and New
      (not (get Obj T))
      (put> New (: slot) Obj) ) )

(dm lose> (Obj Val)
   (when Val
      (put Val (: slot)
         (del> (meta Val (: slot)) Obj (get Val (: slot)) Obj) ) ) )

(dm keep> (Obj Val)
   (when Val
      (put Val (: slot)
         (put> (meta Val (: slot)) Obj (get Val (: slot)) Obj) ) ) )


# (+Blob)
(class +Blob +Relation)

(dm put> (Obj Old New)
   (cond
      (Old
         (call "rm" "-f" (blob Obj (: var))) )
      (New
         (call "mkdir" "-p" (dirname (blob Obj (: var)))) ) )
   (super Obj Old New) )

(dm zap> (Obj Val)
   (put> This Obj T NIL) )

(de blob (Obj Var)
   (pack *Blob (glue "/" (chop Obj)) "." Var) )


### Index classes ###
(class +Index)
# hook

(dm T (Var Lst)
   (=: hook (car Lst))
   (extra Var (cdr Lst)) )

(de idxHook (Obj)
   (or (get Obj (: hook)) *DB) )

(de idxRoot (Obj)
   (let Root
      (or
         (get (idxHook Obj) (: cls))
         (put (idxHook Obj) (: cls) (new T '(+ObjRoot))) )
      (touch Root)
      (or
         (get Root (: var))
         (put Root (: var) (cons 0) ) ) ) )


# (+Key) hook
(class +Key +Index)

(dm mis> (Val Obj)
   (or
      (and
         Val
         (<> Val (get Obj (: var)))
         (fetch
            (tree (: var) (: cls) (idxHook Obj))
            Val )
         `(_ "Not unique") )
      (extra Val Obj) ) )

(dm rel> (Obj Old New)
   (let R (idxRoot Obj)
      (and Old
         (= Obj (fetch R Old))
         (store R Old NIL) )
      (and New
         (not (get Obj T))
         (not (fetch R New))
         (store R New Obj) ) )
   (extra Obj Old New) )


# (+Ref) hook
(class +Ref +Index)

(dm rel> (Obj Old New)
   (let R (idxRoot Obj)
      (when Old
         (store R (cons Old Obj) NIL) )
      (and New
         (not (get Obj T))
         (store R (cons New Obj) Obj) ) )
   (extra Obj Old New) )


# (+Idx) hook
(class +Idx +Ref)
# min

(dm T (Var Lst)
   (=: min (or (car Lst) 3))
   (super Var (cdr Lst)) )

(dm rel> (Obj Old New)
   (let R (idxRoot Obj)
      (when Old
         (store R (cons Old Obj) NIL)
         (mapc
            '((S)
               (while (nth S (: min))
                  (store R (list (pack S) Obj) NIL)
                  (pop 'S) ) )
            (split (cdr (chop Old)) " " "^J") ) )
      (when (and New (not (get Obj T)))
         (store R (cons New Obj) Obj)
         (mapc
            '((S)
               (while (nth S (: min))
                  (store R (list (pack S) Obj) Obj)
                  (pop 'S) ) )
            (split (cdr (chop New)) " " "^J") ) ) )
   (extra Obj Old New) )


# (+Sn +Index) hook
(class +Sn)

(dm rel> (Obj Old New)
   (let R (idxRoot Obj)
      (when Old
         (store R (cons (ext:Snx Old) (cons Obj T)) NIL) )
      (and New
         (not (get Obj T))
         (store R (cons (ext:Snx New) (cons Obj T)) Obj) ) )
   (extra Obj Old New) )


### Relation prefix classes ###
(class +Dep)
# dep

(dm T (Var Lst)
   (=: dep (car Lst))
   (extra Var (cdr Lst)) )

(dm rel> (Obj Old New)
   (unless New
      (mapc
         '((Var) (del> Obj Var (get Obj Var)))
         (: dep) ) )
   (extra Obj Old New) )


(class +List)

(dm mis> (Val Obj)
   (or
      (ifn (lst? Val) "Not a List")
      (pick '((V) (extra V Obj)) Val) ) )

(dm has> (Val X)
   (and Val
      (or
         (extra Val X)
         (find '((X) (extra Val X)) X) ) ) )

(dm put> (Obj Old New)
   (if (and New (mis> This New Obj))
      (cons (extra Obj Old New) Old)
      (mapcar
         '((N O) (extra Obj O N))
         New
         Old ) ) )

(dm del> (Obj Old Val)
   (delete Val Old) )

(dm rel> (Obj Old New)
   (if
      (or
         (and Old (mis> This Old Obj))
         (and New (mis> This New Obj)) )
      (extra Obj Old New)
      (mapc
         '((O) (extra Obj O NIL))
         (diff Old New) )
      (mapc
         '((N) (extra Obj NIL N))
         New ) ) )

(dm lose> (Obj Val)
   (if (and Val (mis> This Val Obj))
      (extra Obj Val)
      (mapc
         '((V) (extra Obj V))
         Val ) ) )

(dm keep> (Obj Val)
   (if (and Val (mis> This Val Obj))
      (extra Obj Val)
      (mapc
         '((V) (extra Obj V))
         Val ) ) )


(class +Need)

(dm mis> (Val Obj)
   (ifn Val
      `(_ "Input required")
      (extra Val Obj) ) )


### Entities ###
(class +Entity)

(de ntt? (X)
   (isa '+Entity X) )

(de dbSync ()
   (let *Key NIL
      (while (lock *DB)
         (wait 40) )
      (sync) ) )

(dm T @
   (upd> This (val This))
   (while (args)
      (if (atom (next))
         (put> This (arg) (next))
         (put> This (car (arg)) (eval (cdr (arg)))) ) ) )

(de new! ("Sym" "Typ" . @)
   (prog2
      (dbSync)
      (pass new T "Typ")
      (commit "Sym") ) )

(dm zap> ()
   (mapc
      '((X)
         (if (atom X)
            (and
               (meta This X)
               (zap> @ This T) )
            (and
               (meta This (cdr X))
               (zap> @ This (car X)) ) ) )
      (getl This) ) )

(dm dlg> ())
(dm url> ())

(dm upd> (X))

(dm has> (Var Val)
   (or
      (nor Val (get This Var))
      (has> (meta This Var) Val (get This Var)) ) )

(dm put> (Var Val)
   (unless (has> This Var Val)
      (rel> (meta This Var) This (get This Var)
         (put This Var
            (put> (meta This Var) This (get This Var) Val) ) )
      (upd> This Var) )
   Val )

(dm put!> (Sym Var Val)
   (unless (has> This Var Val)
      (dbSync)
      (rel> (meta This Var) This (get This Var)
         (put This Var
            (put> (meta This Var) This (get This Var) Val) ) )
      (upd> This Var)
      (commit Sym) )
   Val )

(dm del> (Var Val)
   (when (and Val (has> (meta This Var) Val (get This Var)))
      (rel> (meta This Var) This (get This Var)
         (put This Var
            (del> (meta This Var) This (get This Var) @) ) )
      (upd> This Var) ) )

(dm del!> (Sym Var Val)
   (when (and Val (has> (meta This Var) Val (get This Var)))
      (dbSync)
      (rel> (meta This Var) This (get This Var)
         (put This Var
            (del> (meta This Var) This (get This Var) @) ) )
      (upd> This Var)
      (commit Sym) ) )

(dm inc> (Var)
   (when (num? (get This Var))
      (touch This)
      (rel> (meta This Var) This (get This Var)
         (inc (prop This Var)) )
      (upd> This Var) ) )

(dm inc!> (Sym Var)
   (when (num? (get This Var))
      (dbSync)
      (touch This)
      (rel> (meta This Var) This (get This Var)
         (inc (prop This Var)) )
      (upd> This Var)
      (commit Sym) ) )

(dm mis> (Var Val)
   (mis> (meta This Var) Val This) )

(dm lose> (Lst)
   (mapc
      '((X)
         (let V (or (atom X) (pop 'X))
            (and
               (not (memq X Lst))
               (meta This X)
               (lose> @ This V) ) ) )
      (getl This) )
   (=: T T)
   (upd> This) )

(dm lose!> (Sym)
   (dbSync)
   (lose> This)
   (commit Sym) )

(dm keep> (Lst)
   (=: T)
   (mapc
      '((X)
         (let V (or (atom X) (pop 'X))
            (and
               (not (memq X Lst))
               (meta This X)
               (keep> @ This V) ) ) )
      (getl This) )
   (upd> This T) )

(dm keep!> (Sym)
   (dbSync)
   (keep> This)
   (commit Sym) )

(dm set> (Val)
   (unless (= Val (val This))
      (let
         (L
            (mapcan
               '((X)
                  (pop 'X)
                  (unless (== (meta Val X) (meta (val This) X))
                     (cons X) ) )
               (getl This) )
            V (mapcar
               '((X)
                  (prog1
                     (get This X)
                     (if (meta This X)
                        (put> This X)
                        (put This X) ) ) )
               L ) )
         (set This Val)
         (mapc
            '((X V)
               (if (meta This X)
                  (put> This X V)
                  (put This X V) ) )
            L V ) )
      (upd> This (val This)) )
   Val )

(dm set!> (Sym Val)
   (unless (= Val (val This))
      (dbSync)
      (let
         (L
            (mapcan
               '((X)
                  (pop 'X)
                  (unless (== (meta Val X) (meta (val This) X))
                     (cons X) ) )
               (getl This) )
            V (mapcar
               '((X)
                  (prog1
                     (get This X)
                     (if (meta This X)
                        (put> This X)
                        (put This X) ) ) )
               L ) )
         (set This Val)
         (mapc
            '((X V)
               (if (meta This X)
                  (put> This X V)
                  (put This X V) ) )
            L V ) )
      (upd> This (val This))
      (commit Sym) )
   Val )

(dm clone> ()
   (let Obj (new T (val This))
      (mapc
         '((X)
            (if (atom X)
               (ifn (meta This X)
                  (put Obj X T)
                  (let M @
                     (put> Obj X T)
                     (when (isa '+Blob M)
                        (in (blob This X)
                           (out (blob Obj X) (echo)) ) ) ) )
               (ifn (meta This (cdr X))
                  (put Obj (cdr X) (car X))
                  (let M @
                     (cond
                        ((isa '+Key M)
                           (let H (get This (get M 'hook))
                              (cond
                                 ((isa '+Number M)
                                    (put> Obj (cdr X)
                                       (genKey (cdr X) (get M 'cls) H) ) )
                                 ((isa '+String M)
                                    (let S (pack "# " (car X))
                                       (while (fetch (tree (cdr X) (get M 'cls) H) S)
                                          (setq S (pack "# " S)) )
                                       (put> Obj (cdr X) S) ) ) ) ) )
                        ((or (not (isa '+Joint M)) (isa '+List (meta Obj (cdr X))))
                           (put> Obj (cdr X) (car X)) ) ) ) ) ) )
         (getl This) )
      Obj ) )

(dm clone!> (Sym)
   (prog2
      (dbSync)
      (clone> This)
      (commit Sym) ) )


### Utilities ###
# Define object variables as relations
(de rel Lst
   (put *Class
      (car Lst)
      (new (cadr Lst) (car Lst) (cddr Lst)) ) )

# Find or create object
(de request (Typ Var . @)
   (with (meta 'Typ Var)
      (or
         (pass db Var (: cls))
         (if (: hook)
            (pass new T Typ  @ (next)  Var)
            (pass new T Typ Var) ) ) ) )

# Create or update object
(de obj Lst
   (let Obj (apply request (pop 'Lst))
      (while Lst
         (put> Obj (pop 'Lst) (pop 'Lst)) )
      Obj ) )
