# 14jun10abu
# (c) Software Lab. Alexander Burger

# *Dbs *Jnl *Blob upd

### DB Sizes ###
(de dbs Lst
   (default *Dbs (_dbs 1)) )

(de dbs+ (N . Lst)
   (unless (cdr (nth *Dbs N))
      (conc *Dbs (_dbs N)) ) )

(de _dbs (N)
   (mapcar
      '((L)
         (let Dbf (cons N (>> (- (car L)) 64))
            (for Cls (cdr L)
               (if (atom Cls)
                  (put Cls 'Dbf Dbf)
                  (for Var (cdr Cls)
                     (unless (get Cls 1 Var)
                        (quit "Bad relation" (cons Var (car Cls))) )
                     (put (get (car Cls) Var) 'dbf Dbf) ) ) ) )
         (inc 'N)
         (car L) )
      Lst ) )

(de db: Typ
   (or (meta Typ 'Dbf 1) 1) )


### Tree Access ###
(de tree (Var Cls Hook)
   (cons Var
      (if Hook
         (cons Cls Hook)
         Cls ) ) )

(de treeRel (Var Cls)
   (with (or (get Cls Var) (meta Cls Var))
      (or
         (find '((B) (isa '+index B)) (: bag))
         This ) ) )

# (db 'var 'cls ['hook] 'any ['var 'any ..]) -> sym
(de db (Var Cls . @)
   (with (treeRel Var Cls)
      (let (Tree (tree (: var) (: cls) (and (: hook) (next)))  Val (next))
         (if (isa '+Key This)
            (if (args)
               (and (fetch Tree Val) (pass _db @))
               (fetch Tree Val) )
            (let Key (cons (if (isa '+Fold This) (fold Val) Val))
               (let? A (: aux)
                   (for (L (rest) (and L (== (pop 'A) (pop 'L))) (cdr L))
                     (conc Key (cons (car L))) ) )
               (let Q (init Tree Key (append Key T))
                  (loop
                     (NIL (step Q T))
                     (T (pass _db @ Var Val) @) ) ) ) ) ) ) )

(de _db (Obj . @)
   (when (isa Cls Obj)
      (loop
         (NIL (next) Obj)
         (NIL (has> Obj (arg) (next))) ) ) )


# (aux 'var 'cls ['hook] 'any ..) -> sym
(de aux (Var Cls . @)
   (with (treeRel Var Cls)
      (step
         (init (tree (: var) (: cls) (and (: hook) (next)))
            (rest)
            (conc (rest) T) ) ) ) )


# (collect 'var 'cls ['hook] ['any|beg ['end [var ..]]]) -> lst
(de collect (Var Cls . @)
   (with (treeRel Var Cls)
      (let
         (Tree (tree (: var) (: cls) (and (: hook) (next)))
            X1 (next)
            X2 (if (args) (next) (or X1 T)) )
         (make
            (if (isa '+Key This)
               (iter Tree
                  '((X) (and (isa Cls X) (link (pass get X))))
                  X1 X2 )
               (if (>= X2 X1)
                  (if (pair X1)
                     (setq X2 (append X2 T))
                     (setq X1 (cons X1)  X2 (cons X2 T)) )
                  (if (pair X1)
                     (setq X1 (append X1 T))
                     (setq X1 (cons X1 T)  X2 (cons X2)) ) )
               (if (isa '+Idx This)
                  (iter Tree
                     '((X)
                        (and
                           (isa Cls X)
                           (not (memq (setq X (pass get X)) (made)))
                           (link X) ) )
                     X1 X2 T )
                  (iter Tree
                     '((X)
                        (and (isa Cls X) (link (pass get X))) )
                     X1 X2 ) ) ) ) ) ) )


(de genKey (Var Cls Hook Min Max)
   (if (lt0 Max)
      (let K (minKey (tree Var Cls Hook) Min Max)
         (if (lt0 K) (dec K) (or Max -1)) )
      (let K (maxKey (tree Var Cls Hook) Min Max)
         (if (gt0 K) (inc K) (or Min 1)) ) ) )

(de useKey (Var Cls Hook)
   (let (Tree (tree Var Cls Hook)  Max (* 2 (inc (count Tree)))  N)
      (while (fetch Tree (setq N (rand 1 Max))))
      N ) )


### Relations ###
(class +relation)
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

(dm lose> (Obj Val))

(dm keep> (Obj Val))

# Finalizer
(dm zap> (Obj Val))


(class +Any +relation)


# (+Bag) (cls ..) (..) (..)
(class +Bag +relation)
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
         '((This V)
            (mis> This V Obj
               (get
                  (if (sym? (: hook)) Obj Val)
                  (: hook) ) ) )
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
         (pick 'has> (: bag) (circ Val) X) ) ) )

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
         '((This O)
            (rel> This Obj O NIL
               (get
                  (if (sym? (: hook)) Obj Old)
                  (: hook) ) ) )
         (: bag)
         Old ) )
   (when New
      (mapc
         '((This N)
            (rel> This Obj NIL N
               (get
                  (if (sym? (: hook)) Obj New)
                  (: hook) ) ) )
         (: bag)
         New ) ) )

(dm lose> (Obj Val)
   (mapc
      '((This V)
         (lose> This Obj V
            (get
               (if (sym? (: hook)) Obj Val)
               (: hook) ) ) )
      (: bag)
      Val ) )

(dm keep> (Obj Val)
   (mapc
      '((This V)
         (keep> This Obj V
            (get
               (if (sym? (: hook)) Obj Val)
               (: hook) ) ) )
      (: bag)
      Val ) )


(class +Bool +relation)

(dm mis> (Val Obj)
   (and Val (nT Val) ,"Boolean input expected") )


# (+Number) [num]
(class +Number +relation)
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
(class +Symbol +relation)

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
   (and Val (not (str? Val)) ,"String type expected") )


# (+Link) typ
(class +Link +relation)
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
      ,"Type error" ) )

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
      (extract
         '((X)
            (and (atom X) (setq X (cons T X)))
            (and
               (or
                  (== (: var) (meta Obj (cdr X) 'hook))
                  (find
                     '((B) (== (: var) (get B 'hook)))
                     (meta Obj (cdr X) 'bag) ) )
               X ) )
         (getl Obj) )
      (for X L
         (rel> (meta Obj (cdr X)) Obj (car X) NIL (or Old *DB))
         (rel> (meta Obj (cdr X)) Obj NIL (car X) (or New *DB)) ) )
   (extra Obj Old New Hook) )


# (+Blob)
(class +Blob +relation)

(de blob (Obj Var)
   (pack *Blob (glue "/" (chop Obj)) "." Var) )

(dm put> (Obj Old New)
   (and
      New
      (dirname (blob Obj))
      (call 'mkdir "-p" @) )
   (if (flg? New)
      New
      (in New (out (blob Obj (: var)) (echo)))
      T ) )

(dm zap> (Obj Val)
   (and Val (call 'rm "-f" (blob Obj (: var)))) )


### Index classes ###
(class +index)
# hook dbf

(dm T (Var Lst)
   (=: hook (car Lst))
   (extra Var (cdr Lst)) )


# (+Key) hook
(class +Key +index)

(dm mis> (Val Obj Hook)
   (or
      (extra Val Obj Hook)
      (and
         Val
         (not (has> Obj (: var) Val))
         (fetch
            (tree (: var) (: cls) (or Hook (get Obj (: hook))))
            Val )
         ,"Not unique" ) ) )

(dm rel> (Obj Old New Hook)
   (let Tree (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      (and Old
         (= Obj (fetch Tree Old))
         (store Tree Old NIL (: dbf)) )
      (and New
         (not (get Obj T))
         (not (fetch Tree New))
         (store Tree New Obj (: dbf)) ) )
   (extra Obj Old New Hook) )

(dm lose> (Obj Val Hook)
   (store
      (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      Val NIL (: dbf) )
   (extra Obj Val Hook) )

(dm keep> (Obj Val Hook)
   (store
      (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      Val Obj (: dbf) )
   (extra Obj Val Hook) )


# (+Ref) hook
(class +Ref +index)
# aux

(dm rel> (Obj Old New Hook)
   (let
      (Tree (tree (: var) (: cls) (or Hook (get Obj (: hook))))
         Aux (conc (mapcar '((S) (get Obj S)) (: aux)) Obj) )
      (when Old
         (store Tree (cons Old Aux) NIL (: dbf)) )
      (and New
         (not (get Obj T))
         (store Tree (cons New Aux) Obj (: dbf)) ) )
   (extra Obj Old New Hook) )

(dm lose> (Obj Val Hook)
   (store
      (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      (cons Val (conc (mapcar '((S) (get Obj S)) (: aux)) Obj))
      NIL (: dbf) )
   (extra Obj Val Hook) )

(dm keep> (Obj Val Hook)
   (store
      (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      (cons Val (conc (mapcar '((S) (get Obj S)) (: aux)) Obj))
      Obj (: dbf) )
   (extra Obj Val Hook) )


# Backing index prefix
(class +Ref2)

(dm T (Var Lst)
   (unless (meta *Class Var)
      (quit "No Ref2" Var) )
   (extra Var Lst) )

(dm rel> (Obj Old New Hook)
   (with (meta (: cls) (: var))
      (let Tree (tree (: var) (: cls))
         (when Old
            (store Tree (cons Old Obj) NIL (: dbf)) )
         (and New
            (not (get Obj T))
            (store Tree (cons New Obj) Obj (: dbf)) ) ) )
   (extra Obj Old New Hook) )

(dm lose> (Obj Val Hook)
   (with (meta (: cls) (: var))
      (store (tree (: var) (: cls)) (cons Val Obj) NIL (: dbf)) )
   (extra Obj Val Hook) )

(dm keep> (Obj Val Hook)
   (with (meta (: cls) (: var))
      (store (tree (: var) (: cls)) (cons Val Obj) Obj (: dbf)) )
   (extra Obj Val Hook) )


# (+Idx) cnt hook
(class +Idx +Ref)
# min

(dm T (Var Lst)
   (=: min (or (car Lst) 3))
   (super Var (cdr Lst)) )

(dm rel> (Obj Old New Hook)
   (let
      (Tree (tree (: var) (: cls) (or Hook (get Obj (: hook))))
         Aux (conc (mapcar '((S) (get Obj S)) (: aux)) Obj) )
      (when Old
         (store Tree (cons Old Aux) NIL (: dbf))
         (for S (split (cdr (chop Old)) " " "^J")
            (while (nth S (: min))
               (store Tree (list (pack S) Obj) NIL (: dbf))
               (pop 'S) ) ) )
      (when (and New (not (get Obj T)))
         (store Tree (cons New Aux) Obj (: dbf))
         (for S (split (cdr (chop New)) " " "^J")
            (while (nth S (: min))
               (store Tree (list (pack S) Obj) Obj (: dbf))
               (pop 'S) ) ) ) )
   (extra Obj Old New Hook) )

(dm lose> (Obj Val Hook)
   (let
      (Tree (tree (: var) (: cls) (or Hook (get Obj (: hook))))
         Aux (conc (mapcar '((S) (get Obj S)) (: aux)) Obj) )
      (store Tree (cons Val Aux) NIL (: dbf))
      (for S (split (cdr (chop Val)) " " "^J")
         (while (nth S (: min))
            (store Tree (list (pack S) Obj) NIL (: dbf))
            (pop 'S) ) ) )
   (extra Obj Val Hook) )

(dm keep> (Obj Val Hook)
   (let
      (Tree (tree (: var) (: cls) (or Hook (get Obj (: hook))))
         Aux (conc (mapcar '((S) (get Obj S)) (: aux)) Obj) )
      (store Tree (cons Val Aux) Obj (: dbf))
      (for S (split (cdr (chop Val)) " " "^J")
         (while (nth S (: min))
            (store Tree (list (pack S) Obj) Obj (: dbf))
            (pop 'S) ) ) )
   (extra Obj Val Hook) )



# (+Sn +index) hook
(class +Sn)

(dm rel> (Obj Old New Hook)
   (let Tree (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      (when Old
         (store Tree (cons (ext:Snx Old) Obj T) NIL (: dbf)) )
      (and New
         (not (get Obj T))
         (store Tree (cons (ext:Snx New) Obj T) Obj (: dbf)) ) )
   (extra Obj Old New Hook) )

(dm lose> (Obj Val Hook)
   (store
      (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      (cons (ext:Snx Val) Obj T)
      NIL (: dbf) )
   (extra Obj Val Hook) )

(dm keep> (Obj Val Hook)
   (store
      (tree (: var) (: cls) (or Hook (get Obj (: hook))))
      (cons (ext:Snx Val) Obj T)
      Obj (: dbf) )
   (extra Obj Val Hook) )


# (+Fold +index) hook
(class +Fold)

(dm has> (Val X)
   (extra Val
      (if (= Val (fold Val)) (fold X) X) ) )

(dm rel> (Obj Old New Hook)
   (extra Obj (fold Old) (fold New) Hook) )

(dm lose> (Obj Val Hook)
   (extra Obj (fold Val) Hook) )

(dm keep> (Obj Val Hook)
   (extra Obj (fold Val) Hook) )


# (+Aux) lst
(class +Aux)

(dm T (Var Lst)
   (=: aux (car Lst))
   (with *Class
      (for A (car Lst)
         (if (asoq A (: Aux))
            (conc @ (cons Var))
            (=: Aux
               (conc (: Aux) (cons (list A Var))) ) ) ) )
   (extra Var (cdr Lst)) )

(de relAux (Obj Var Old Lst)
   (for A Lst
      (let? Val (get Obj A)
         (with (meta Obj A)
            (let Tree (tree (: var) (: cls) (get Obj (: hook)))
               (store Tree
                  (conc
                     (cons Val
                        (mapcar
                           '((S)
                              (if (== S Var) Old (get Obj S)) )
                           (: aux) ) )
                     Obj )
                  NIL
                  (: dbf) )
               (store Tree
                  (conc
                     (cons Val
                        (mapcar
                           '((S)
                              (if (== S Var) (get Obj Var) (get Obj S)) )
                           (: aux) ) )
                     Obj )
                  Obj
                  (: dbf) ) ) ) ) ) )


### Relation prefix classes ###
(class +Dep)
# dep

(dm T (Var Lst)
   (=: dep (car Lst))
   (extra Var (cdr Lst)) )

(dm rel> (Obj Old New Hook)
   (unless New
      (for Var (: dep)
         (del> Obj Var (get Obj Var)) ) )
   (extra Obj Old New Hook) )

(dm lose> (Obj Val Hook)
   (for Var (: dep)
      (del> Obj Var (get Obj Var)) )
   (extra Obj Val Hook) )


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

(dm rel> (Obj Old New Hook)
   (if (or (ele> This Old) (ele> This New))
      (extra Obj Old New Hook)
      (for O (diff Old New)
         (extra Obj O NIL Hook) )
      (for N New
         (extra Obj NIL N Hook) ) ) )

(dm lose> (Obj Val Hook)
   (if (ele> This Val)
      (extra Obj Val Hook)
      (for V Val
         (extra Obj V Hook) ) ) )

(dm keep> (Obj Val Hook)
   (if (ele> This Val)
      (extra Obj Val Hook)
      (for V Val
         (extra Obj V Hook) ) ) )


(class +Need)

(dm mis> (Val Obj)
   (ifn Val
      ,"Input required"
      (extra Val Obj) ) )


(class +Mis)
# mis

(dm T (Var Lst)
   (=: mis (car Lst))
   (extra Var (cdr Lst)) )

(dm mis> (Val Obj)
   (or ((: mis) Val Obj) (extra Val Obj)) )


(class +Alt)

(dm T (Var Lst)
   (extra Var (cdr Lst))
   (=: cls (car Lst)) )


### Entities ###
(class +Entity)

(var Dbf)
(var Aux)

(de dbSync ()
   (let *Run NIL
      (while (lock *DB) (wait 40))
      (sync) ) )

(de new! ("Typ" . @)
   (prog2
      (dbSync)
      (pass new (or (meta "Typ" 'Dbf 1) 1) "Typ")
      (commit 'upd) ) )

(de set! (Obj Val)
   (unless (= Val (val Obj))
      (dbSync)
      (set Obj Val)
      (commit 'upd) )
   Val )

(de put! (Obj Var Val)
   (unless (= Val (get Obj Var))
      (dbSync)
      (put Obj Var Val)
      (commit 'upd) )
   Val )

(de inc! (Obj Var Val)
   (when (num? (get Obj Var))
      (dbSync)
      (prog2
         (touch Obj)
         (inc (prop Obj Var) (or Val 1))
         (commit 'upd) ) ) )

(de blob! (Obj Var File)
   (and *Jnl (blob+ Obj Var))
   (put!> Obj Var File) )

(de blob+ (Obj Var)
   (chdir *Blob
      (call 'ln "-sf"
         (pack (glue "/" (chop Obj)) "." Var)
         (pack (name Obj) "." Var) ) ) )

(dm T @
   (while (args)
      (cond
         ((=T (next)) (put This T T))
         ((atom (arg)) (put> This (arg) (next)))
         (T (put> This (car (arg)) (eval (cdr (arg))))) ) )
   (upd> This (val This)) )

(dm zap> ()
   (for X (getl This)
      (let V (or (atom X) (pop 'X))
         (and (meta This X) (zap> @ This V)) ) ) )

(dm url> (Tab))

(dm upd> (X Old))

(dm has> (Var Val)
   (or
      (nor Val (get This Var))
      (has> (meta This Var) Val (get This Var)) ) )

(dm put> (Var Val)
   (unless (has> This Var Val)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (put This Var (put> (meta This Var) This Old Val)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old) ) )
   Val )

(dm put!> (Var Val)
   (unless (has> This Var Val)
      (dbSync)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (put This Var (put> (meta This Var) This Old Val)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old)
         (commit 'upd) ) )
   Val )

(dm del> (Var Val)
   (when (and Val (has> (meta This Var) Val (get This Var)))
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (put This Var (del> (meta This Var) This Old @)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old) ) ) )

(dm del!> (Var Val)
   (when (and Val (has> (meta This Var) Val (get This Var)))
      (dbSync)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (put This Var (del> (meta This Var) This Old @)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old)
         (commit 'upd) ) ) )

(dm inc> (Var Val)
   (when (num? (get This Var))
      (touch This)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (inc (prop This Var) (or Val 1)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old) ) ) )

(dm inc!> (Var Val)
   (when (num? (get This Var))
      (dbSync)
      (touch This)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (inc (prop This Var) (or Val 1)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old)
         (commit 'upd) ) ) )

(dm dec> (Var Val)
   (when (num? (get This Var))
      (touch This)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (dec (prop This Var) (or Val 1)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old) ) ) )

(dm dec!> (Var Val)
   (when (num? (get This Var))
      (dbSync)
      (touch This)
      (let Old (get This Var)
         (rel> (meta This Var) This Old
            (dec (prop This Var) (or Val 1)) )
         (when (asoq Var (meta This 'Aux))
            (relAux This Var Old (cdr @)) )
         (upd> This Var Old)
         (commit 'upd) ) ) )

(dm mis> (Var Val)
   (mis> (meta This Var) Val This) )

(dm lose1> (Var)
   (when (meta This Var)
      (lose> @ This (get This Var)) ) )

(dm lose> (Lst)
   (unless (: T)
      (for X (getl This)
         (let V (or (atom X) (pop 'X))
            (and
               (not (memq X Lst))
               (meta This X)
               (lose> @ This V) ) ) )
      (=: T T)
      (upd> This) ) )

(dm lose!> ()
   (dbSync)
   (lose> This)
   (commit 'upd) )

(de lose "Prg"
   (let "Flg" (: T)
      (=: T T)
      (run "Prg")
      (=: T "Flg") ) )

(dm keep1> (Var)
   (when (meta This Var)
      (keep> @ This (get This Var)) ) )

(dm keep> (Lst)
   (when (: T)
      (=: T)
      (for X (getl This)
         (let V (or (atom X) (pop 'X))
            (and
               (not (memq X Lst))
               (meta This X)
               (keep> @ This V) ) ) )
      (upd> This T) ) )

(dm keep?> (Lst)
   (extract
      '((X)
         (with (and (pair X) (meta This (cdr X)))
            (and
               (isa '+Key This)
               (fetch (tree (: var) (: cls) (get (up This) (: hook))) (car X))
               (cons (car X) ,"Not unique") ) ) )
      (getl This) ) )

(dm keep!> ()
   (dbSync)
   (keep> This)
   (commit 'upd) )

(de keep "Prg"
   (let "Flg" (: T)
      (=: T)
      (run "Prg")
      (=: T "Flg") ) )

(dm set> (Val)
   (unless (= Val (val This))
      (let
         (L
            (extract
               '((X)
                  (pop 'X)
                  (unless (== (meta Val X) (meta (val This) X))
                     X ) )
               (getl This) )
            V (mapcar
               '((X)
                  (prog1
                     (get This X)
                     (if (meta This X)
                        (put> This X)
                        (put This X) ) ) )
               L ) )
         (xchg This 'Val)
         (mapc
            '((X V)
               (if (meta This X)
                  (put> This X V)
                  (put This X V) ) )
            L V ) )
      (upd> This (val This) Val) )
   (val This) )

(dm set!> (Val)
   (unless (= Val (val This))
      (dbSync)
      (let
         (L
            (extract
               '((X)
                  (pop 'X)
                  (unless (== (meta Val X) (meta (val This) X))
                     X ) )
               (getl This) )
            V (mapcar
               '((X)
                  (prog1
                     (get This X)
                     (if (meta This X)
                        (put> This X)
                        (put This X) ) ) )
               L ) )
         (xchg This 'Val)
         (mapc
            '((X V)
               (if (meta This X)
                  (put> This X V)
                  (put This X V) ) )
            L V ) )
      (upd> This (val This) Val)
      (commit 'upd) )
   (val This) )

(dm clone> ()
   (let Obj (new (or (var: Dbf 1) 1) (val This))
      (for X
         (by
            '((X)
               (nand
                  (pair X)
                  (isa '+Hook (meta This (cdr X))) ) )
            sort
            (getl This ) )
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

(dm clone!> ()
   (prog2
      (dbSync)
      (clone> This)
      (commit 'upd) ) )

# Default syncronization function
(de upd Lst
   (wipe Lst) )


### Utilities ###
# Define object variables as relations
(de rel Lst
   (def *Class
      (car Lst)
      (new (cadr Lst) (car Lst) (cddr Lst)) ) )

# Find or create object
(de request (Typ Var . @)
   (let Dbf (or (meta Typ 'Dbf 1) 1)
      (ifn Var
         (new Dbf Typ)
         (with (meta Typ Var)
            (or
               (pass db Var (: cls))
               (if (: hook)
                  (pass new Dbf Typ (: hook) (next) Var)
                  (pass new Dbf Typ Var) ) ) ) ) ) )

# Create or update object
(de obj Lst
   (let Obj (apply request (pop 'Lst))
      (while Lst
         (put> Obj (pop 'Lst) (pop 'Lst)) )
      Obj ) )

# vi:et:ts=3:sw=3
