# 26feb04abu
# (c) Software Lab. Alexander Burger

### Tree Access ###
(de tree (Var Cls Hook)
   (cons Var
      (if Hook
         (cons Cls Hook)
         Cls ) ) )

# (db 'var 'cls ['hook] 'val ['var 'val ..])
(de db (Var Cls . @)
   (with (or (get Cls Var) (meta Cls Var))
      (when (find '((B) (isa '+Index B)) (: bag))
         (setq This @) )
      (let Tree (tree (: var) (: cls) (and (: hook) (next)))
         (if (isa '+Key This)
            (and
               (fetch Tree (next))
               (pass _db @) )
            (let
               (Val (next)
                  Key (if (isa '+Fold This) (fold Val) Val)
                  Q (init Tree (cons Key) (cons Key T)) )
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
      (when (find '((B) (isa '+Index B)) (: bag))
         (setq This @) )
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
   (if (lt0 Max)
      (let K (minKey (tree Var Cls Hook) Min Max)
         (if (lt0 K) (- K 1) (or Max -1)) )
      (let K (maxKey (tree Var Cls Hook) Min Max)
         (if (gt0 K) (+ K 1) (or Min 1)) ) ) )


### Relations ###
(class +Relation)
# cls var

(dm T (Var Lst)
   (=: cls *Class)
   (=: var Var) )

# Type check
(dm mis> (Val Obj))  #> lst
(dm ele> (Val))

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
               (and (get @ 'hook) (=: hook T)) ) )
         Lst ) )
   (super Var) )

(dm mis> (Val Obj)
   (or
      (ifn (lst? Val) "Not a Bag")
      (pick
         '((X V)
            (mis> X V Obj
               (with X
                  (get
                     (if (sym? (: hook)) Obj Val)
                     (: hook) ) ) ) )
         (: bag)
         Val ) ) )

(dm ele> (Val)
   (and Val
      (or
         (atom Val)
         (find 'ele> (: bag) Val) ) ) )

(dm has> (Val X)
   (and Val
      (or
         (super Val X)
         (car (member Val X)) ) ) )

(dm put> (Obj Old New)
   (trim
      (mapcar
         '((X O N) (put> X Obj O N))
         (: bag)
         Old
         New ) ) )

(dm rel> (Obj Old New)
   (when Old
      (mapc
         '((X O)
            (rel> X Obj O NIL
               (with X
                  (get
                     (if (sym? (: hook)) Obj Old)
                     (: hook) ) ) ) )
         (: bag)
         Old ) )
   (when New
      (mapc
         '((X N)
            (rel> X Obj NIL N
               (with X
                  (get
                     (if (sym? (: hook)) Obj New)
                     (: hook) ) ) ) )
         (: bag)
         New ) ) )

(dm lose> (Obj Val)
   (mapc
      '((X O)
         (rel> X Obj O NIL
            (with X
               (get
                  (if (sym? (: hook)) Obj Val)
                  (: hook) ) ) ) )
      (: bag)
      Val ) )

(dm keep> (Obj Val)
   (mapc
      '((X N)
         (rel> X Obj NIL N
            (with X
               (get
                  (if (sym? (: hook)) Obj Val)
                  (: hook) ) ) ) )
      (: bag)
      Val ) )


(class +Bool +Relation)

(dm mis> (Val Obj)
   (and Val (nT Val) ,"Boolean input expected") )


# (+Number) [num]
(class +Number +Relation)
# scl

(dm T (Var Lst)
   (=: scl (car Lst))
   (super Var (cdr Lst)) )

(dm mis> (Val Obj)
   (and Val (not (num? Val)) ,"Numeric input expected") )


# (+Date)
(class +Date +Number)

(dm T (Var Lst)
   (super Var (cons NIL Lst)) )


# (+Time)
(class +Time +Number)

(dm T (Var Lst)
   (super Var (cons NIL Lst)) )


# (+Symbol)
(class +Symbol +Relation)

(dm mis> (Val Obj)
   (unless (sym? Val)
      ,"Symbolic type expected" ) )


# (+String) [num]
(class +String +Symbol)
# len

(dm T (Var Lst)
   (=: len (car Lst))
   (super Var (cdr Lst)) )

(dm mis> (Val Obj)
   (unless (str? Val)
      ,"String type expected" ) )


# (+Link) typ
(class +Link +Relation)
# type

(dm T (Var Lst)
   (unless (=: type (car Lst))
      (quit "No Link" Var) )
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
      ,"Type error" ) )


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
      ,"Bad type" ) )

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


# +Link or +Joint prefix
(class +Hook)

(dm rel> (Obj Old New Hook)
   (let L
      (filter
         '((X)
            (and
               (pair X)
               (or
                  (== (: var) (meta Obj (cdr X) 'hook))
                  (find
                     '((B) (== (: var) (get B 'hook)))
                     (meta Obj (cdr X) 'bag) ) ) ) )
         (getl Obj) )
      (mapc
         '((X)
            (rel> (meta Obj (cdr X)) Obj (car X) NIL Old) )
         L )
      (mapc
         '((X)
            (rel> (meta Obj (cdr X)) Obj NIL (car X) New) )
         L ) )
   (extra Obj Old New Hook) )


# (+Blob)
(class +Blob +Relation)

(de blob (Obj Var)
   (pack *Blob (glue "/" (chop Obj)) "." Var) )

(dm rel> (Obj Old New)
   (and New (call "mkdir" "-p" (dirname (blob Obj)))) )

(dm zap> (Obj Val)
   (and Val (call "rm" "-f" (blob Obj (: var)))) )


### Index classes ###
(class +Index)
# hook

(dm T (Var Lst)
   (=: hook (car Lst))
   (extra Var (cdr Lst)) )


# (+Key) hook
(class +Key +Index)

(dm mis> (Val Obj Hook)
   (or
      (extra Val Obj Hook)
      (and
         Val
         (not (has> Obj (: var) Val))
         (fetch
            (tree (: var) (: cls) (or Hook (get Obj (: hook)) *DB))
            Val )
         ,"Not unique" ) ) )

(dm rel> (Obj Old New Hook)
   (let Tree (tree (: var) (: cls) (or Hook (get Obj (: hook)) *DB))
      (and Old
         (= Obj (fetch Tree Old))
         (store Tree Old NIL) )
      (and New
         (not (get Obj T))
         (not (fetch Tree New))
         (store Tree New Obj) ) )
   (extra Obj Old New Hook) )


# (+Ref) hook
(class +Ref +Index)

(dm rel> (Obj Old New Hook)
   (let Tree (tree (: var) (: cls) (or Hook (get Obj (: hook)) *DB))
      (when Old
         (store Tree (cons Old Obj) NIL) )
      (and New
         (not (get Obj T))
         (store Tree (cons New Obj) Obj) ) )
   (extra Obj Old New Hook) )


# Backing index prefix
(class +Ref2)

(dm T (Var Lst)
   (unless (meta *Class Var)
      (quit "No Ref2" Var) )
   (extra Var Lst) )

(dm rel> (Obj Old New Hook)
   (let Tree
      (tree
         (: var)
         (meta (: cls) (: var) 'cls)
         (or Hook (get Obj (: hook)) *DB) )
      (when Old
         (store Tree (cons Old Obj) NIL) )
      (and New
         (not (get Obj T))
         (store Tree (cons New Obj) Obj) ) )
   (extra Obj Old New Hook) )


# (+Idx) cnt hook
(class +Idx +Ref)
# min

(dm T (Var Lst)
   (=: min (or (car Lst) 3))
   (super Var (cdr Lst)) )

(dm rel> (Obj Old New Hook)
   (let Tree (tree (: var) (: cls) (or Hook (get Obj (: hook)) *DB))
      (when Old
         (store Tree (cons Old Obj) NIL)
         (mapc
            '((S)
               (while (nth S (: min))
                  (store Tree (list (pack S) Obj) NIL)
                  (pop 'S) ) )
            (split (cdr (chop Old)) " " "^J") ) )
      (when (and New (not (get Obj T)))
         (store Tree (cons New Obj) Obj)
         (mapc
            '((S)
               (while (nth S (: min))
                  (store Tree (list (pack S) Obj) Obj)
                  (pop 'S) ) )
            (split (cdr (chop New)) " " "^J") ) ) )
   (extra Obj Old New Hook) )


# (+Sn +Index) hook
(class +Sn)

(dm rel> (Obj Old New Hook)
   (let Tree (tree (: var) (: cls) (or Hook (get Obj (: hook)) *DB))
      (when Old
         (store Tree (cons (ext:Snx Old) (cons Obj T)) NIL) )
      (and New
         (not (get Obj T))
         (store Tree (cons (ext:Snx New) (cons Obj T)) Obj) ) )
   (extra Obj Old New Hook) )


# (+Fold +Index) hook
(class +Fold)

(dm has> (Val X)
   (extra Val
      (if (= Val (fold Val)) (fold X) X) ) )

(dm rel> (Obj Old New Hook)
   (extra Obj (fold Old) (fold New) Hook) )


### Relation prefix classes ###
(class +Dep)
# dep

(dm T (Var Lst)
   (=: dep (car Lst))
   (extra Var (cdr Lst)) )

(dm rel> (Obj Old New Hook)
   (unless New
      (mapc
         '((Var) (del> Obj Var (get Obj Var)))
         (: dep) ) )
   (extra Obj Old New Hook) )


(class +List)

(dm mis> (Val Obj)
   (or
      (ifn (lst? Val) "Not a List")
      (pick '((V) (extra V Obj)) Val) ) )

(dm ele> (Val)
   (and Val (or (atom Val) (find extra Val))) )

(dm has> (Val X)
   (and Val
      (or
         (extra Val X)
         (find '((X) (extra Val X)) X) ) ) )

(dm put> (Obj Old New)
   (if (ele> This New)
      (cons (extra Obj Old New) Old)
      (mapcar
         '((N O) (extra Obj O N))
         New
         Old ) ) )

(dm del> (Obj Old Val)
   (and
      (<> Old Val)
      (delete Val Old) ) )

(dm rel> (Obj Old New)
   (if (or (ele> This Old) (ele> This New))
      (extra Obj Old New)
      (mapc
         '((O) (extra Obj O NIL))
         (diff Old New) )
      (mapc
         '((N) (extra Obj NIL N))
         New ) ) )

(dm lose> (Obj Val)
   (if (ele> This Val)
      (extra Obj Val)
      (mapc
         '((V) (extra Obj V))
         Val ) ) )

(dm keep> (Obj Val)
   (if (ele> This Val)
      (extra Obj Val)
      (mapc
         '((V) (extra Obj V))
         Val ) ) )


(class +Need)

(dm mis> (Val Obj)
   (ifn Val
      ,"Input required"
      (extra Val Obj) ) )


(class +Alt)

(dm T (Var Lst)
   (extra Var (cdr Lst))
   (=: cls (car Lst)) )


### Entities ###
(class +Entity)

(de dbSync ()
   (let *Key NIL
      (while (lock *DB)
         (wait 40) )
      (sync) ) )

(de new! ("Sym" "Typ" . @)
   (prog2
      (dbSync)
      (pass new T "Typ")
      (commit "Sym") ) )

(de set! (Obj Sym Val)
   (unless (= Val (val Obj))
      (dbSync)
      (set Obj Val)
      (commit Sym) )
   Val )

(de put! (Obj Sym Var Val)
   (unless (= Val (get Obj Var))
      (dbSync)
      (put Obj Var Val)
      (commit Sym) )
   Val )

(de inc! (Obj Sym Var)
   (when (num? (get Obj Var))
      (dbSync)
      (touch Obj)
      (inc (prop Obj Var))
      (commit Sym) ) )

(de blob! (Obj Sym Rel File)
   (put!> Obj Sym Rel T)
   (call "mv" File (blob Obj Rel)) )

(dm T @
   (while (args)
      (if (atom (next))
         (put> This (arg) (next))
         (put> This (car (arg)) (eval (cdr (arg)))) ) )
   (upd> This (val This)) )

(dm zap> ()
   (mapc
      '((X)
         (let V (or (atom X) (pop 'X))
            (and (meta This X) (zap> @ This V)) ) )
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

(dm lose1> (Var)
   (when (meta This Var)
      (lose> @ This (get This Var)) ) )

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

(dm keep1> (Var)
   (when (meta This Var)
      (keep> @ This (get This Var)) ) )

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
                  (let Rel @
                     (put> Obj X T)
                     (when (isa '+Blob Rel)
                        (in (blob This X)
                           (out (blob Obj X) (echo)) ) ) ) )
               (ifn (meta This (cdr X))
                  (put Obj (cdr X) (car X))
                  (let Rel @
                     (cond
                        ((find '((B) (isa '+Key B)) (get Rel 'bag))
                           (let (K @  H (get K 'hook))
                              (put> Obj (cdr X)
                                 (mapcar
                                    '((Lst)
                                       (mapcar
                                          '((B Val)
                                             (if (== B K)
                                                (cloneKey B (cdr X) Val
                                                   (get (if (sym? H) This Lst) H) )
                                                Val ) )
                                          (get Rel 'bag)
                                          Lst ) )
                                    (car X) ) ) ) )
                        ((isa '+Key Rel)
                           (put> Obj (cdr X)
                              (cloneKey Rel (cdr X) (car X)
                                 (get This (get Rel 'hook)) ) ) )
                        ((or (not (isa '+Joint Rel)) (isa '+List (meta Obj (cdr X))))
                           (put> Obj (cdr X) (car X)) ) ) ) ) ) )
         (getl This) )
      Obj ) )

(de cloneKey (Rel Var Val Hook)
   (cond
      ((isa '+Number Rel)
         (genKey Var (get Rel 'cls) Hook) )
      ((isa '+String Rel)
         (let S (pack "# " Val)
            (while (fetch (tree Var (get Rel 'cls) Hook) S)
               (setq S (pack "# " S)) )
            S ) ) ) )

(dm clone!> (Sym)
   (prog2
      (dbSync)
      (clone> This)
      (commit Sym) ) )

# Default syncronization function
(de upd Lst
   (wipe Lst) )


### Utilities ###
# Define object variables as relations
(de rel Lst
   (put *Class
      (car Lst)
      (new (cadr Lst) (car Lst) (cddr Lst)) ) )

# Find or create object
(de request (Typ Var . @)
   (with (meta Typ Var)
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
