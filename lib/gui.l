# 20nov02abu
# (c) Software Lab. Alexander Burger

# *DbForms

(de upd Lst
   (wipe Lst)
   (mapc
      '((F) (and (has> F Lst) (upd> F)))
      *DbForms ) )

(de newDlg ("Typ" . @)
   (prog1
      (pass new! 'upd "Typ")
      (dlg> (put *Top 'rv @)) ) )

(de newUrl ("Typ" . @)
   (prog1
      (pass new! 'upd "Typ")
      (url (url> (put *Top 'rv @))) ) )

(de <id> (Ttl . Lst)
   (with *ID
      (prin
         "<TABLE WIDTH=\"100%\"><TR><TD ALIGN=\"LEFT\"><H3>"
         (and (: T) "[")
         Ttl
         " --" )
      (while Lst
         (prin " " (eval (pop 'Lst))) )
      (prin
         (and (: T) "]")
         "</H3></TD><TD ALIGN=\"RIGHT\">" )
      (navi)
      (prinl "</TD></TR></TABLE>") ) )


### Dialog Components ###
(de hotButton (Ttl)
   (gui '(+Able +Button)
      '(or
         (isa '+Hot (: home focus2))
         (isa '+Obj (: home focus2))
         (isa '+ObjView (: home focus2)) )
      "" Ttl
      '(act> (: home focus2)) ) )

(de clrButton (Ttl)
   (gui '(+Button) "" Ttl
      '(prog (=: home rv T) (stop> (: home))) ) )

(de stepButton (@Var @Cls @Hook)
   (gui '(+Rid +Button) "" `(_ "Next data record")
      (list
         'let 'Q
         (fill '(init (tree '@Var '@Cls '@Hook) (get (: home obj) '@Var) T))
         '(step Q)
         '(if (and (step Q) (url> @))
            (url @)
            (beep> (: home)) ) ) ) )

(de choButton (Exe)
   (gui 'hot '(+Rid +Button) "" `(_ "Choose/Create (F4)") Exe) )

(de cloneButton ()
   (gui '(+Button) "" `(_ "New/Copy")
      '(url (url> (clone!> (: home obj) 'upd))) ) )

# Delete object in +ObjForm
(de delButton (Able)
   (gui '(+Able +Button)
      (ifn Able
         '(and (: home obj) (not (: home obj T)))
         (list 'and '(: home obj) '(not (: home obj T)) Able) )
      "" `(_ "Delete")
      '(when (ask `(_ "Deletion") `(_ "Delete this data record?"))
         (lose!> (: home obj) 'upd)
         (and (: home obj) (url> @) (url @)) ) ) )

(de closeButton ()
   (quitButton `(_ "Close")) )

(====)
# Choose object for +ObjForm
# (choDialog Ttl Rel [Hook] [(+Obj +TextField) [pre [post]]])
(de choDialog ("Ttl" "Rel" . @)
   (let
      ("Hook" (and (get (meta (cdr "Rel") (car "Rel")) 'hook) (next))
         "Fld" (or (next) '(+Obj +TextField))
         "Pre" (next)
         "Post" (next)
         "Lst" (make
            (link (cons '+Lock "Fld"))
            (and "Pre" (link "Pre"))
            (link "Rel")
            (and "Hook" (link (lit "Hook")))
            (and "Post" (link "Post"))
            (link "" 40) ) )
      (dialog (pack "Ttl" `(_ "-Choice")) NIL
         (quote
            (row
               (apply gui
                  (make
                     (link "Fld")
                     (and "Pre" (link "Pre"))
                     (link "Rel")
                     (and "Hook" (link (lit "Hook")))
                     (and "Post" (link "Post"))
                     (link "Ttl" 40) ) )
               (gui '(+Able +Button) '(val> (: home fields 1)) "" `(_ "Choose")
                  '(act> (: home fields 1)) )
               (gui '(+Button) "" `(_ "Create")
                  '(with (: home fields 1)
                     (if (get (meta (: objTyp) (: objVar)) 'hook)
                        (newUrl (: objTyp) @ (eval (: objHook)))
                        (newUrl (: objTyp)) ) ) ) )
            (---- T)
            (gui '(+/R +IndexChart)
               (list
                  (car "Rel")
                  'get
                  (if "Hook" (lit "Hook") '*DB)
                  (lit (last "Rel")) )
               8 NIL '((apply gui "Lst")) cons )
            (----)
            (row (hotButton `(_ "Choose")) (quitButton)) ) ) ) )
(====)


# Field Input Prefix
(class +Hint +Sync)
# hint

(dm T (CL . @)
   (=: hint CL)
   (pass super) )

(dm key> (C)
   (use (H Q S)
      (setq
         H (pack
            (head (: sel) (chop (: str)))
            (setq C (extra C)) )
         Q (goal (: hint) '@ H) )
      (do NIL
         (NIL (prove Q) C)
         (T (pre? H (setq S (cdr (last @))))
            (pack (nth (chop S) (+ 1 (: sel)))) ) ) ) )

(dm cho> ()
   (let (H (pack (head (: sel) (chop (: str))))  Q (goal (: hint) '@ H))
      (mapcan
         '((S)
            (when (pre? H S)
               (cons (mkCho S S)) ) )
         (make
            (while
               (and
                  (prove Q)
                  (let S (cdr (last @))
                     (or
                        (member S (made))
                        (prog (link S) (> 40 (length (made)))) ) ) ) ) ) ) ) )


### DB Linkage ###
(class +DbForm +Form)

(dm start> ()
   (push '*DbForms This)
   (super) )

(dm stop> ()
   (super)
   (setq *DbForms (delq This *DbForms)) )


### Object Linkage ###
(class +ObjForm +DbForm)
# typ obj

(dm T (Typ Obj DX DY Prg)
   (=: typ Typ)
   (=: obj Obj)
   (super DX DY Prg) )

(dm set> (Obj)
   (=: obj Obj)
   (upd> This) )

(dm val> ()
   (: obj) )

(dm has> (Lst)
   (memq (: obj) Lst) )


(class +ObjDialog +ObjForm)
# top on

(dm T ("Ttl" "Typ" "Obj" "Lst")
   (initAppId)
   (out *App
      (pr (get (=: top *Top) 'id) "dialog" "Ttl" (: id)) )
   (=: typ "Typ")
   (=: obj "Obj")
   (=: init "Lst")
   (wait NIL (: on)) )

(dm init> ()
   (=: on T)
   (super)
   (start> This) )

(dm stop> ()
   (=: on)
   (super)
   (close> This)
   (setq *Top (: top)) )

(de objDialog ("Ttl" "Typ" "Obj" "Flg" "Lst")
   (with (new '(+View +ObjDialog) "Flg" "Ttl" "Typ" "Obj" "Lst")
      (wait NIL (not (: on)))
      (: rv) ) )


(class +/R)
# erVar erObj

(dm T (Lst . @)
   (=: erVar (car Lst))
   (=: erObj (cdr Lst))
   (pass extra) )

(dm upd> ()
   (set> This (get (eval (: erObj)) (: erVar))) )


(class +E/R +/R)

(dm set> (Val)
   (when (eval (: erObj))
      (put!> @ 'upd (: erVar) Val)
      (extra Val) ) )

(dm chk> ()
   (or
      (extra)
      (and
         (eval (: erObj))
         (mis> @ (: erVar) (val> This)) ) ) )


(class +Blob/R +/R)

(dm set> (Val)
   (when (eval (: erObj))
      (put!> @ 'upd (: erVar) (bool Val))
      (extra
         (and Val
            (allow (blob (eval (: erObj)) (: erVar))) ) ) ) )


(class +ClassField +Map +TextField)
# erObj

(dm T (Exe Ttl Lst)
   (=: erObj Exe)
   (super Lst Ttl (mapcar car Lst)) )

(dm upd> ()
   (set> This (val (eval (: erObj)))) )

(dm set> (Val)
   (when (eval (: erObj))
      (set!> @ 'upd Val) )
   (super Val) )


# Blue Background Prefix
(class +Bg)

(dm T @
   (pass extra)
   (pr "bCol" `(hex "A8A8FF")) )


(class +Obj +Sync)
# objVar objTyp objHook obj

(de objQuery (C)
   (let V (val> This T)
      (cond
         ((sym? V)
            (goal
               (query> This
                  (pack (head (: sel) (chop V)) C) ) ) )
         (C)
         ((num? V)
            (goal (query> This V)) ) ) ) )

(dm T (Rel . @)
   (=: objVar (car Rel))
   (=: objTyp (cdr Rel))
   (when (get (meta (: objTyp) (: objVar)) 'hook)
      (=: objHook (next)) )
   (pass super)
   (hotField) )

(dm set> (Obj)
   (extra
      (get (=: obj Obj) (: objVar)) ) )

(dm val> (Flg)
   (let V (extra)
      (cond
         (Flg V)
         ((= V (get (: obj) (: objVar)))
            (: obj) )
         (T
            (=: obj
               (if (: objHook)
                  (db (: objVar) (last (: objTyp)) (eval @) V)
                  (db (: objVar) (last (: objTyp)) V) ) ) ) ) ) )

(dm key> (C)
   (when (setq C (extra C))
      (ifn (prove (objQuery C))
         C
         (pack
            (nth
               (chop (get (=: obj (cdar @)) (: objVar)))
               (+ 1 (: sel)) ) ) ) ) )

(dm cho> ()
   (let Q (objQuery)
      (mapcar
         '((R) (mkCho (get R (: objVar)) R))
         (make
            (while
               (and
                  (prove Q)
                  (let S (cdar @)
                     (or
                        (member S (made))
                        (prog (link S) (> 40 (length (made)))) ) ) ) ) ) ) ) )

(dm act> ()
   (if (and (val> This) (url> @))
      (url @)
      (beep> (: home)) ) )

(dm chk> ()
   (or
      (extra)
      (and
         (: str)
         (not (val> This))
         (<> "-" (: str))
         `(_ "Data not found") ) ) )

(dm query> (X)
   (if (num? X)
      (list  # ((db var +Cls (<N> . T) @Obj) (isa +Cls @Obj))
         (make
            (link 'db (: objVar) (last (: objTyp)))
            (when (: objHook)
               (link (eval @)) )
            (link (cons X T) '@Obj) )
         (list 'isa (last (: objTyp)) '@Obj) )
      (list  # ((db var +Cls "Str" @Obj) (isa +Cls @Obj) (head "Str" @Obj var))
         (make
            (link 'db (: objVar) (last (: objTyp)))
            (when (: objHook)
               (link (eval @)) )
            (link X '@Obj) )
         (list 'isa (last (: objTyp)) '@Obj)
         (list 'head X '@Obj (: objVar)) ) ) )


(class +ObjView +Lock)
# disp obj

(dm T (Exe . @)
   (=: disp Exe)
   (pass super)
   (hotField) )

(dm set> (Obj)
   (let Exe (: disp)
      (extra
         (with (=: obj Obj) (eval Exe)) ) ) )

(dm val> ()
   (: obj) )

(dm act> ()
   (if (and (: obj) (url> @))
      (url @)
      (beep> (: home)) ) )


# +Obj/+ObjView Prefix
(class +Dlg)

(dm act> ()
   (ifn (: obj)
      (beep> (: home))
      (dlg> @)
      (upd> (: home)) ) )


# +Obj Prefix
(class +Auto)

(dm val> (Flg)
   (or
      (extra Flg)
      (and
         (: str)
         (new! 'upd (: objTyp) (: objVar) (: str)) ) ) )


# +Obj Prefix for +Dialog return value
(class +Rv)

(dm act> ()
   (ifn (val> This)
      (beep> (: home))
      (=: home rv @)
      (stop> (: home) ) ) )


# Query Modifier
(class +Query)
# objQuery

(dm T (Foo . @)
   (=: objQuery Foo)
   (pass extra) )

(dm query> (Str)
   ((: objQuery) Str) )


(class +QueryObjLst +Query +Obj)
# mkObjLst

(dm T (Exe . @)
   (=: mkObjLst Exe)
   (pass super
      '((Str)
         (list
            (list 'lst '@Obj (eval (: mkObjLst)))
            (list 'head Str '@Obj (: objVar)) ) ) ) )

(dm val> (Flg)
   (if Flg
      (super T)
      (let V (super)
         (and V (memq V (eval (: mkObjLst))) V) ) ) )



# Index Tree Chart
(class +IndexChart +chart)
# root

(dm put> ()
   (let Node (init (: root))
      (do (- (: ofs) 1)
         (step Node T) )
      (mapc
         '((F)
            (mapc
               '((F D) (set> F D))
               F
               ((: put) (step Node T)) ) )
         (: fields) ) ) )

(dm get> ())

(dm size> ()
   (or (car (: root)) 0) )

(dm set> (Root)
   (=: root Root)
   (put> This)
   (setScroll) )


# DB Query Chart
(class +QueryChart +Chart)
# iniq quer query

# (.. iniq rows lst prg [put [get]])
(dm T (Exe N Lst Prg Put Get)
   (=: iniq Exe)
   (super N Lst Prg (or Put cons) (or Get car)) )

(dm start> ()
   (unless (: query)
      (=: query (eval (: iniq))) ) )

(dm put> ()
   (while
      (and
         (>
            (: ofs)
            (- (length (: data)) (: rows)) )
         (prove (: quer)) )
      (=: data
         (conc (: data) (cons (cdr (last @)))) ) )
   (super) )

(dm upd> ()
   (=: data)
   (=: quer (copy (: query)))
   (put> This)
   (setScroll) )

(dm end> ()
   (get> This) )

(dm set> (Q)
   (=: quer (copy (=: query Q)))
   (super) )

(dm sort> (Exe)
   (set> This
      (goal
         (list
            (list 'lst '@Obj
               (sortBy
                  '((Obj) (with Obj (eval Exe)))
                  (: data) ) ) ) ) ) )

(dm clr> ()
   (set> This (fail)) )

(dm stat> ()
   (cons
      (cons 'query (: query))
      (super) ) )

(dm DEL> ()
   (super)
   (and (: clip) (lose!> @ 'upd)) )

(dm INS> ()
   (super)
   (and (: clip) (keep!> @ 'upd)) )


### Reporting ###
(de report (Nm Ttl . @)
   (out (list "bin/lat1" (setq "*Rep" (tmp Nm ".txt")))
      (prinl (or Ttl Nm) "^M") )
   (<head> (or Ttl Nm))
   (<href> "Download" (sesId "*Rep"))
   (while (args)
      (prin " | ")
      (<href> (next) (sesId "@" (next)) (next)) )
   (<br>)
   (setq "*Rep" (list "bin/lat1" (pack "+" "*Rep"))) )

(de record @
   (pass <row>)
   (out "*Rep"
      (map
         '((L)
            (prin
               (cond
                  ((== '- (car L)))
                  ((atom (car L)) (car L))
                  ((=T (caar L)) (cadar L)) ) )
            (when
               (seek
                  '((L) (n== '- (car L)))
                  (cdr L) )
               (prin "^I") ) )
         (filter nT (rest)) )
      (prinl "^M") ) )

(de record1 @
   (pass <br>)
   (out "*Rep"
      (when (args)
         (prin
            (cond
               ((atom (next)) (arg))
               ((=T (car (arg))) (cadr (arg))) ) )
         (while (args)
            (prin " "
               (cond
                  ((atom (next)) (arg))
                  ((=T (car (arg))) (cadr (arg))) ) ) ) )
      (prinl "^M") ) )

(de href (Obj Val)
   (cond
      ((= Obj "HTTP")
         (list T Val (if (sub? ":/" Val) Val (pack "http://" Val)) "HTTP") )
      ((= Obj "MAIL")
         (list T Val (pack "mailto:" Val) "MAIL") )
      ((and Obj (url> Obj))
         (list T Val (sesId @)) )
      (T Val) ) )

# Text File Export
(de export (Nm . "Prg")
   (out (list "bin/lat1" (setq Nm (tmp Nm ".txt")))
      (run "Prg") )
   (url Nm) )
