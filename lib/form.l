# 24dec06abu
# (c) Software Lab. Alexander Burger

# *Top *Gui *Get *Form *Event *Button
# "*Cnt" "*Lst" "*App" "*Err" "*Post2" "*Stat" "*Ix" "*Chart" "*Row" "*Cho"

(push1 '*JS (allow (path "@lib/form.js")))
(mapc allow '(*Gui *Get *Form *Event "@jsForm"))

(one "*Cnt")
(off "*Lst" "*Post2" "*Cho")

# Define GUI form
(de form ("Attr" . "Prg")
   (inc '*Form)
   (let "App"
      (if *Post
         (get "*Lst" (- "*Cnt" *Get) *Form)
         (with (setq *Top (box))
            (=: able T)
            (=: event 0) )
         (conc (get "*Lst" (- "*Cnt" *Get)) (cons *Top))
         *Top )
      (for ("F" . "L") (get "*Lst" (- "*Cnt" *Get) 1)
         (let *Form (- "F")
            (cond
               ((and (== *Post (car "L")) (memq "App" (get *Post 'top)))
                  (apply "form" "L")
                  (<br>) )
               ((or (== *Post "App") (memq "App" (get *Post 'top)))
                  (unless (get "L" 1 'top)
                     (put (car "L") 'top (cons *Post (get *Post 'top))) )
                  (let *Post NIL (apply "form" "L"))
                  (<br>) ) ) ) )
      ("form" "App" "Attr" "Prg") ) )

(de "form" ("*App" "Attr" "Prg")
   (with "*App"
      (job (: env)
         (<post> "Attr" *Url
            (<hidden> '*Menu *Menu)
            (<hidden> '*Tab *Tab)
            (<hidden> '*Get *Get)
            (<hidden> '*Form *Form)
            (<hidden> '*Event (inc (:: event)))
            (zero "*Ix")
            (if *Post
               (let gui
                  '(()
                     (with (get "*App" 'gui (inc '"*Ix"))
                        (when (asoq This "*Err")
                           (<p> 'err
                              (let X (cdr @)
                                 (if (atom X)
                                    (ht:Prin (eval X 1))
                                    (eval X 1) ) ) ) )
                        (if (: id)
                           (let *Gui (val "*App")
                              (show> This (cons '*Gui @)) )
                           (zero "*Row")
                           (setq "*Chart" This) )
                        This ) )
                  (and (== *Post "*App") (setq *Top "*App"))
                  (htPrin 1 "Prg") )
               (set "*App")
               (putl "*App"
                  (list
                     (cons (: top) 'top)
                     (cons (: able) 'able)
                     (cons (: event) 'event)
                     (cons (: env) 'env) ) )
               (let gui
                  '(@
                     (inc '"*Ix")
                     (with
                        (cond
                           ((pair (next)) (pass new @))
                           ((num? (arg))
                              (with "*Chart"
                                 (let (I (arg)  L (last (: gui)))
                                    (when (get L I)
                                       (inc (:: rows))
                                       (conc (: gui)
                                          (list (setq L (need (: cols)))) ) )
                                    (let Fld (pass new)
                                       (set (nth L I) Fld)
                                       (and (get Fld 'chg) (get Fld 'able) (=: lock))
                                       (set> Fld
                                          (get
                                             ((: put) (get (nth (: data) (: ofs)) (: rows)))
                                             I )
                                          T )
                                       (put Fld 'chart (list This (: rows) I))
                                       Fld ) ) ) )
                           ((get "*App" (arg)) (quit "gui conflict" (arg)))
                           (T (put "*App" (arg) (pass new))) )
                        (or (: id) (zero "*Row"))
                        (=: home gui (conc (: home gui) (cons This)))
                        (unless (: chart) (init> This))
                        (when (: id)
                           (let *Gui (val "*App")
                              (show> This (cons '*Gui (: id))) ) )
                        This ) )
                  (htPrin 1 "Prg") ) ) ) ) ) )

# Disable form
(de disable (Flg)
   (and Flg (=: able)) )

# Handle form actions
(de action Prg
   (unless "*Post2" (off "*Err"))
   (catch "stop"
      (if *Post
         (with (postForm) (postGui))
         (push '"*Lst" (cons))
         (and (nth "*Lst" 99) (con @))
         (setq *Get "*Cnt")
         (inc '"*Cnt") )
      (one *Form)
      (run Prg 1)
      (setq "*Stat" (cons "*Err" (copy (get "*Lst" (- "*Cnt" *Get)))))
      (off "*Post2") ) )

(de jsForm (Url)
   (setq *Url Url  Url (chop Url))
   (let action
      '(Prg
         (off "*Err")
         (catch "stop"
            (with (postForm)
               (postGui)
               (httpHead  "text/plain; charset=utf-8")
               (ht:Out T
                  (if
                     (and
                        (= (car "*Stat") "*Err")
                        (= (cdr "*Stat") (get "*Lst" (- "*Cnt" *Get))) )
                     (for This (: gui)
                        (if (: id)
                           (prin '& (pack *Form '- @) '& (js> This))
                           (zero "*Row")
                           (setq "*Chart" This) ) )
                     (setq "*Post2" *Post)
                     (prin T) ) ) ) ) )
      (cond
         ((= '@ (car Url))
            ((intern (pack (cdr Url)))) )
         ((tail '("." "l") Url)
            (load *Url) ) ) ) )

(de postForm ()
   (let Lst (get "*Lst" (- "*Cnt" (setq *Get (format *Get))))
      (setq
         *Menu (format *Menu)
         *Tab (format *Tab)
         *Form (format *Form)
         *Event (format *Event)
         *Post (or
            "*Post2"
            (if (gt0 *Form)
               (get Lst *Form)
               (get Lst 1 (- *Form) 1) ) ) )
      (set Lst
         (filter
            '((L) (not (memq *Post (get L 1 'top))))
            (car Lst) ) )
      *Post ) )

(de postGui ()
   (if (or "*Post2" (<> *Event (: event)))
      (off *Gui)
      (while *Gui
         (con
            (assoc (caar *Gui) (val *Post))
            (cdr (pop '*Gui)) ) )
      (and (: obj) (setq *ID @))
      (job (: env)
         (for This (: gui)
            (cond
               ((not (: id)) (setq "*Chart" This))
               ((chk> This) (err @))
               ((set> This (val> This) T)) ) )
         (for This (: gui)
            (unless (: id)
               (if (chk> (setq "*Chart" This))
                  (err @)
                  (set> This (val> This)) ) ) )
         (unless "*Err"
            (for This (: gui)
               (nond
                  ((: id) (setq "*Chart" This))
                  ((ge0 (: id))
                     (let? A (assoc (: id) (val *Post))
                        (let? *Button (cdr A)
                           (con A)
                           (and (eval (: able)) (act> This)) ) ) ) ) )
            (for This (: gui)
               (or (: id) (setq "*Chart" This))
               (upd> This) ) ) ) ) )

(de err (Exe)
   (queue '"*Err" (cons This Exe)) )

(de url (Url . @)
   (when Url
      (setq *Url Url  Url (chop Url))
      (off *Post)
      (cond
         ((= '@ (car Url))
            (apply (intern (pack (cdr Url)))
               (make
                  (while (args)
                     (if (and (sym? (next)) (= `(char '*) (char (arg))))
                        (set (arg) (next))
                        (link (arg)) ) ) ) ) )
         ((tail '("." "l") Url)
            (while (args)
               (set (next) (next)) )
            (load *Url) )
         ((assoc (stem Url ".") *Mimes)
            (apply httpEcho (cdr @) *Url) )
         (T (httpEcho *Url "application/octet-stream" 1 T)) )
      (throw "stop") ) )

(de mkUrl (Lst)
   (pack (pop 'Lst) '?
      (make
         (while Lst
            (and
               (sym? (car Lst))
               (= `(char '*) (char (car Lst)))
               (link (pop 'Lst) '=) )
            (link (ht:Fmt (pop 'Lst)))
            (and Lst (link '&)) ) ) ) )

# Return chart property
(de chart @
   (pass get "*Chart") )

# Return current data row from chart
(de row ()
   (with "*Chart"
      (get (: data) (+ (: ofs) (inc '"*Row") -1)) ) )

# Scroll chart
(de scroll (N)
   (with "*Chart"
      (get> This)
      (unless (gt0 (inc (:: ofs) N))
         (=: ofs 1) )
      (put> This) ) )


### Dialogs ###
(de _dlg (Attr Env)
   (with (box)
      (push
         (get "*Lst" (- "*Cnt" *Get))
         (list This Attr Prg) )
      (=: able T)
      (=: event 0)
      (=: env Env) ) )

(de dialog (Env . Prg)
   (_dlg 'dialog Env) )

(de alert (Env . Prg)
   (_dlg 'alert Env) )

(de diaform (Lst . Prg)
   (if (and *Post (not (: diaform)))
      (_dlg 'dialog (env Lst))
      (=: env (env Lst))
      (=: diaform T)
      (run Prg 1) ) )

(de dispose (App)
   (let L (get "*Lst" (- "*Cnt" *Get))
      (del (asoq App (car L)) L) ) )

(de closeButton (Lbl Exe)
   (when (: top)
      (gui '(+Close +Button) Lbl Exe) ) )

(de okButton (Exe)
   (when (: top)
      (gui '(+Close +Button) "Ok" Exe) ) )

(de cancelButton ()
   (when (: top)
      (gui '(+Close +Button) ',"Cancel") ) )

(de yesButton (Exe)
   (gui '(+Close +Button) ',"Yes" Exe) )

(de noButton (Exe)
   (gui '(+Close +Button) ',"No" Exe) )

(de choButton (Exe)
   (gui '(+Rid +Button) ',"Select" Exe) )


(class +Close)

(dm act> ()
   (when (eval (: able))
      (dispose (: home))
      (extra)
      (for This (: home top)
         (for This (: gui)
            (or (: id) (setq "*Chart" This))
            (upd> This) ) ) ) )


### Field Prefix Classes ###
(class +Txt)
# txt

(dm T (Foo . @)
   (=: txt Foo)
   (pass extra) )

(dm txt> (Val)
   ((: txt) Val) )


(class +Set)
# set

(dm T (Foo . @)
   (=: set Foo)
   (pass extra) )

(dm set> (Val Dn)
   (extra ((: set) Val) Dn) )


(class +Val)
# val

(dm T (Foo . @)
   (=: val Foo)
   (pass extra) )

(dm val> ()
   ((: val) (extra)) )


(class +Fmt)
# set val

(dm T (Foo1 Foo2 . @)
   (=: set Foo1)
   (=: val Foo2)
   (pass extra) )

(dm set> (Val Dn)
   (extra ((: set) Val) Dn) )

(dm val> ()
   ((: val) (extra)) )


(class +Upd)
# upd

(dm T (Exe . @)
   (=: upd Exe)
   (pass extra) )

(dm upd> ()
   (eval (: upd)) )


(class +Init)
# init

(dm T (Val . @)
   (=: init Val)
   (pass extra) )

(dm init> ()
   (set> This (: init)) )


(class +Cue)
# cue

(dm T (Exe . @)
   (=: cue Exe)
   (pass extra) )

(dm set> (Val Dn)
   (extra (or Val (eval (: cue))) Dn) )

(dm val> ()
   (let V (extra)
      (unless (= V (eval (: cue))) V) ) )


(class +Map)
# map

(dm T (Lst . @)
   (=: map Lst)
   (pass extra) )

(dm set> (Val Dn)
   (extra
      (if
         (find
            '((X) (= Val (cdr X)))
            (: map) )
         (val (car @))
         Val )
      Dn ) )

(dm val> ()
   (let V (extra)
      (if
         (find
            '((X) (= V (val (car X))))
            (: map) )
         (cdr @)
         V ) ) )


# Field enable/disable
(de able ()
   (when (or (: rid) (: home able))
      (eval (: able)) ) )

(class +Able)

(dm T (Exe . @)
   (pass extra)
   (=: able Exe) )


(class +Lock +Able)

(dm T @
   (pass super NIL) )


# Escape from Form lock
(class +Rid)
# rid

(dm T @
   (=: rid T)
   (pass extra) )


(class +Align)

(dm T @
   (=: align T)
   (pass extra) )


(class +Limit)
# lim

(dm T (Exe . @)
   (=: lim Exe)
   (pass extra) )


(class +Var)
# var

(dm T (Var . @)
   (=: var Var)
   (pass extra) )

(dm set> (Val Dn)
   (extra (set (: var) Val) Dn) )

(dm upd> ()
   (set> This (val (: var))) )


(class +Chk)
# chk

(dm T (Exe . @)
   (=: chk Exe)
   (pass extra) )

(dm chk> ()
   (eval (: chk)) )


### Form Field Classes ###
(de showFld "Prg"
   (when (: lbl)
      (prin "<label>")
      (ht:Prin (eval @))
      (<nbsp>) )
   (style (cons 'id (pack *Form '- (: id)))
      (run "Prg") )
   (and (: lbl) (prinl "</label>")) )


(class +gui)
# home id chg able chart

(dm T ()
   (push (=: home "*App") (cons (=: id "*Ix")))
   (=: able T) )

(dm txt> (Val))

(dm set> (Val Dn))

(dm clr> ()
   (set> This) )

(dm val> ())

(dm init> ()
   (upd> This) )

(dm upd> ())

(dm chk> ())


(class +field +gui)

(dm T ()
   (super)
   (=: chg T) )

(dm txt> (Val)
   Val )

(dm js> ()
   (let S (ht:Fmt (cdr (assoc (: id) (val *Post))))
      (if (able) S (pack S "&=")) ) )

(dm set> (Str Dn)
   (con (assoc (: id) (val (: home))) Str)
   (and (not Dn) (: chart) (set> (car @) (val> (car @)))) )

(dm str> ()
   (cdr (assoc (: id) (val (: home)))) )

(dm val> ()
   (str> This) )


# Get field
(de field (X . @)
   (if (sym? X)
      (pass get (: home) X)
      (pass get (: home gui) (+ X (abs (: id)))) ) )

# Get current chart data row
(de curr @
   (pass get (: chart 1 data) (+ (: chart 1 ofs) (: chart 2) -1)) )

(de prev @
   (pass get (: chart 1 data) (+ (: chart 1 ofs) (: chart 2) -2)) )


(class +Button +gui)
# lbl alt act js

# (lbl [alt] act)
(dm T (Lbl . @)
   (=: lbl Lbl)
   (let X (next)
      (ifn (args)
         (=: act X)
         (=: alt X)
         (=: act (next)) ) )
   (super)
   (set
      (car (val "*App"))
      (=: id (- (: id))) ) )

(dm js> ()
   (if (able)
      (let Str (ht:Fmt (eval (: lbl)))
         (if (pre? "img/" Str) (sesId Str) Str) )
      (let Str (ht:Fmt (or (eval (: alt)) (eval (: lbl))))
         (pack (if (pre? "img/" Str) (sesId Str) Str) "&=") ) ) )

(dm show> ("Var")
   (style (cons 'id (pack *Form '- (: id)))
      (if (able)
         (let Str (eval (: lbl))
            ((if (pre? "img/" Str) <image> <submit>) Str "Var" NIL (: js)) )
         (let Str (or (eval (: alt)) (eval (: lbl)))
            ((if (pre? "img/" Str) <image> <submit>) Str "Var" T (: js)) ) ) ) )

(dm act> ()
   (and (able) (eval (: act))) )


(class +JS)

(dm T @
   (=: js T)
   (pass extra) )


(class +DnButton +Rid +Able +Button)

(dm T (Exe Lbl Alt)
   (super
      (list '>= '(length (chart 'data)) (list '+ Exe '(chart 'ofs)))
      (or Lbl "v")
      (or Alt "=")
      (list 'scroll Exe) ) )


(class +UpButton +Rid +Able +Button)

(dm T (Exe Lbl Alt)
   (super
      '(> (chart 'ofs) 1)
      (or Lbl "\^")
      (or Alt "=")
      (list 'scroll (list '- Exe)) ) )


(class +ClrButton +Button)
# clr

(dm T (Lbl Lst . @)
   (=: clr Lst)
   (pass super Lbl
      '(for X (: clr)
         (if (atom X)
            (clr> (field X))
            (set> (field (car X)) (eval (cdr X))) ) ) ) )


(class +Checkbox +field)
# lbl

# ([lbl])
(dm T (Lbl)
   (=: lbl Lbl)
   (super) )

(dm txt> (Val)
   (if Val ,"Yes" ,"No") )

(dm show> ("Var")
   (showFld (<check> "Var" (not (able)))) )

(dm set> (Val Dn)
   (super (bool Val) Dn) )

(dm val> ()
   (bool (super)) )


(class +TextField +field)
# dx|lst lbl lim align

# (dx [dy] [lbl])
# (lst [lbl])
(dm T (X . @)
   (nond
      ((num? X)
         (=: lst X)
         (=: lbl (next)) )
      ((num? (next))
         (=: dx X)
         (=: lbl (arg)) )
      (NIL
         (=: dx X)
         (=: dy (arg))
         (=: lbl (next)) ) )
   (super)
   (or (: dx) (: lst) (=: chg)) )

(dm show> ("Var")
   (showFld
      (cond
         ((: dy)
            (<area>
               (: dx)
               (: dy)
               "Var"
               (not (able)) ) )
         ((: dx)
            (<field>
               (if (: align) (- (: dx)) (: dx))
               "Var"
               (eval (: lim))
               (not (able)) ) )
         ((: lst)
            (let (L (mapcar val @)  S (str> This))
               (<select>
                  (if (member S L) L (cons S L))
                  "Var"
                  (not (able)) ) ) )
         (T
            (prin "<span id=\"" (pack *Form '- (: id)) "\">")
            (if (str> This) (ht:Prin @) (<nbsp>))
            (prin "</span>") ) ) ) )


(class +ListTextField +TextField)
# split

(dm T (Lst . @)
   (=: split Lst)
   (pass super) )

(dm set> (Val Dn)
   (super (glue (car (: split)) Val) Dn) )

(dm val> ()
   (mapcan
      '((S) (and (pack S) (cons @)))
      (apply split (: split) (chop (super))) ) )


# Password Field
(class +PwField +TextField)

(dm show> ("Var")
   (showFld
      (<passwd> (: dx) "Var" (not (able))) ) )


# Upload Field
(class +UpField +TextField)

(dm show> ("Var")
   (showFld
      (<upload> (: dx) "Var" (not (able))) ) )


# Symbol Fields
(class +SymField +TextField)

(dm val> ()
   (let S (super)
      (and (<> "-" S) (intern S)) ) )

(dm set> (Val Dn)
   (super (name Val) Dn) )


(class +numField +Align +TextField)
# scl

(dm chk> ()
   (and
      (str> This)
      (not (format @ (: scl) *Sep0 *Sep3))
      ,"Numeric input expected" ) )


(class +NumField +numField)

(dm txt> (Val)
   (format Val) )

(dm set> (Val Dn)
   (super (format Val) Dn) )

(dm val> ()
   (format (super) NIL *Sep0 *Sep3) )


(class +FixField +numField)

(dm T (N . @)
   (=: scl N)
   (pass super) )

(dm txt> (Val)
   (format Val (: scl) *Sep0 *Sep3) )

(dm set> (Val Dn)
   (super (format Val (: scl) *Sep0 *Sep3) Dn) )

(dm val> ()
   (let (S (super)  L (chop S))
      (unless (member *Sep0 L)
         (setq S (pack S *Sep0)) )
      (format S (: scl) *Sep0 *Sep3) ) )


(class +DateField +TextField)

(dm txt> (Val)
   (datStr Val) )

(dm set> (Val Dn)
   (super (datStr Val) Dn) )

(dm val> ()
   (expDat (super)) )

(dm chk> ()
   (and
      (str> This)
      (not (val> This))
      ,"Bad date format" ) )


(class +TimeField +TextField)

(dm txt> (Val)
   (tim$ Val (> (: dx) 6)) )

(dm set> (Val Dn)
   (super (tim$ Val (> (: dx) 6)) Dn) )

(dm val> ()
   ($tim (super)) )

(dm chk> ()
   (and
      (str> This)
      (not (val> This))
      ,"Bad time format" ) )


(class +TelField +TextField)

(dm txt> (Val)
   (telStr Val) )

(dm set> (Val Dn)
   (super (telStr Val) Dn) )

(dm val> ()
   (expTel (super)) )

(dm chk> ()
   (and
      (str> This)
      (not (val> This))
      ,"Bad phone number format" ) )


(class +JsField +gui)
# js str

(dm T (Nm)
   (super)
   (=: js Nm) )

(dm show> ("Var"))

(dm js> ()
   (pack (ht:Fmt (: str)) "&" (: js)) )

(dm set> (Val Dn)
   (=: str Val) )


### GUI Charts ###
(class +Chart)
# home gui rows cols ofs lock put get data clip

# (.. cols [put [get]])
(dm T (N Put Get)
   (setq "*Chart" This)
   (put (=: home "*App") 'chart
      (conc (get "*App" 'chart) (cons This)) )
   (=: rows 1)
   (when N
      (=: gui (list (need (=: cols N)))) )
   (=: ofs 1)
   (=: lock T)
   (=: put (or Put prog1))
   (=: get (or Get prog1)) )

(dm put> ()
   (mapc
      '((G D)
         (unless (memq NIL G)
            (mapc 'set> G ((: put) D) '(T .)) ) )
      (: gui)
      (nth (: data) (: ofs)) )  )

(dm get> ()
   (unless (: lock)
      (map
         '((G D)
            (set D
               (trim
                  ((: get)
                     (mapcar 'val> (car G))
                     (car D)
                     (car G) ) ) ) )
         (: gui)
         (nth
            (=: data
               (need
                  (- 1 (: ofs) (: rows))
                  (: data) ) )
            (: ofs) ) )
      (=: data (trim (: data))) ) )

(dm txt> ()
   (for L (: data)
      (map
         '((G D)
            (prin (txt> (car G) (car D)))
            (if (cdr G) (prin "^I") (prinl)) )
         (: gui 1)
         ((: put) L) ) ) )

(dm set> (Lst)
   (unless (= Lst (: data))
      (let N (- (length Lst) (: rows) -1)
         (when (> (: ofs) N)
            (=: ofs (max 1 N)) ) ) )
   (=: data (copy Lst))
   (put> This)
   (: data) )

(dm clr> ()
   (set> This) )

(dm val> ()
   (get> This)
   (: data) )

(dm init> ()
   (upd> This) )

(dm upd> ())

(dm chk> ())

(dm size> ()
   (length (: data)) )

(dm cut> ()
   (get> This)
   (=: clip (get (: data) (: ofs)))
   (=: data (remove (: ofs) (: data)))
   (put> This) )

(dm paste> (Flg)
   (get> This)
   (=: data (insert (: ofs) (: data) (unless Flg (: clip))))
   (put> This) )


(class +Chart1 +Chart)

(dm set> (Lst)
   (super (cons Lst)) )

(dm val> ()
   (car (super)) )


### DB GUI ###
(de newUrl @
   (prog1
      (pass new!)
      (apply url (url> @)) ) )


# (choDlg Dst Ttl Rel [Hook] [(+TextField) [pre [post]]])
(de choDlg (Dst Ttl Rel . @)
   (let
      (Hook (and (meta (cdr Rel) (car Rel) 'hook) (next))
         Fld (or (next) '(+TextField))
         Gui
         (make
            (link (append '(+Lock +Obj) Fld))
            (and (next) (link @))
            (link Rel)
            (and Hook (link (lit Hook)))
            (and (next) (link @))
            (link 40) ) )
      (diaform '(Dst Ttl Rel Hook Fld Gui)
         (gui 'pat (cons '+Init Fld) (cdr (lup "*Cho" Rel)) 40)
         (gui '(+JS +Button) ',"Search"
            '(init> (: home query)) )
         (gui 'query '(+QueryChart) 6
            '(let Val (val> (: home pat))
               (and (lup "*Cho" Rel) (idx '"*Cho" @ NIL))
               (idx '"*Cho" (cons Rel Val) T)
               (goal
                  (list
                     (list 'db (car Rel) (last Rel) Hook Val '@@) ) ) )
            (if (flg? Dst) 1 2) )
         (<table> NIL Ttl NIL
            (do 6
               (<row> NIL
                  (apply gui Gui 1)
                  (unless (flg? Dst)
                     (gui 2 '(+DstButton) -1) ) ) ) )
         (gui '(+JS +DnButton) 6)
         (gui '(+JS +UpButton) 6)
         (when (=T Dst)
            (gui '(+Button) ',"New"
               '(if (meta (cdr Rel) (car Rel) 'hook)
                  (newUrl (cdr Rel) @ Hook)
                  (newUrl (cdr Rel)) ) ) )
         (cancelButton) ) ) )


# Able Object
(class +AO +Able)

(dm T @
   (pass super
      '(and (: home obj) (not (: home obj T))) ) )


# Select (choose or create) object
(class +ChoButton +Button)

(dm T (Ttl Rel)
   (super ">" (list 'choDlg '(field 1) Ttl (lit Rel))) )


(class +DstButton +Able +Close +Button)

(dm T (@F)
   (super
      (fill '(val> (field @F)))
      ">"
      (fill '(set> Dst (val> (field @F)))) ) )


# Step to next object in form
(de stepBtn (Var Cls Hook)
   (let Q
      (init
         (tree Var Cls Hook)
         (cond
            ((isa '+Key (meta *ID Var))
               (get *ID Var) )
            ((isa '+Fold (meta *ID Var))
               (cons (fold (get *ID Var)) *ID) )
            (T (cons (get *ID Var) *ID)) )
         T )
      (step Q T)
      (if (and (step Q T) (url> @))
         (<href> ,"Next record" (mkUrl @))
         (<nbsp>) ) ) )

# Delete object in form
(de delButton (Able Txt)
   (gui '(+Able +Button)
      (list 'and
         '(: home obj)
         '(not (: home obj T))
         (or Able T) )
      ',"Delete"
      (list 'alert NIL
         (list 'ht:Prin (or Txt ',"Delete this record?"))
         "<br><br>"
         '(yesButton '(lose!> (: home top 1 obj)))
         '(noButton) ) ) )


(class +/R)
# erVar erObj

(dm T (Lst . @)
   (=: erVar (car Lst))
   (=: erObj (cdr Lst))
   (pass extra)
   (=: able '(and (eval (: erObj)) (not (get @ T)))) )

(dm upd> ()
   (set> This (get (eval (: erObj)) (: erVar))) )


(class +E/R +/R)

(dm set> (Val Dn)
   (when (eval (: erObj))
      (put!> @ (: erVar) Val) )
   (extra Val Dn) )

(dm chk> ()
   (or
      (extra)
      (and
         (eval (: erObj))
         (mis> @ (: erVar) (val> This)) ) ) )


(class +Blob/R +/R)

(dm set> (Val Dn)
   (extra
      (and
         (eval (: erObj))
         (put!> @ (: erVar) (bool Val))
         (allow (blob (eval (: erObj)) (: erVar))) )
      Dn ) )


(class +BlobField +/R +TextField)
# org

(dm set> (Val Dn)
   (and
      (eval (: erObj))
      (put!> @ (: erVar) (bool Val))
      (<> Val (: org))
      (out (allow (blob (eval (: erObj)) (: erVar)))
         (prinl (=: org Val)) ) )
   (super Val Dn) )

(dm upd> ()
   (set> This
      (and
         (eval (: erObj))
         (get @ (: erVar))
         (in (allow (blob (eval (: erObj)) (: erVar)))
            (=: org (till NIL T)) ) ) ) )


(class +ClassField +Map +TextField)
# erObj

(dm T (Exe Lst)
   (=: erObj Exe)
   (super Lst (mapcar car Lst)) )

(dm upd> ()
   (set> This (val (eval (: erObj)))) )

(dm set> (Val Dn)
   (when (eval (: erObj))
      (set!> @ Val) )
   (super Val Dn) )


(class +obj)
# msg obj

# ([msg] ..)
(dm T ()
   (ifn (atom (next))
      (=: msg 'url>)
      (=: msg (arg))
      (next) ) )

(dm js> ()
   (cond
      ((or (: dx) (: lst))
         (if (try (: msg) (: obj))
            (pack (extra) "&*" (sesId "img/obj.png") '& (sesId (ht:Fmt (mkUrl @))))
            (pack (extra) "&*" (sesId "img/no.png") '&) ) )
      ((try (: msg) (: obj))
         (pack (str> This) "&+" (sesId (ht:Fmt (mkUrl @)))) )
      (T (extra)) ) )

(dm show> ("Var")
   (showFld
      (cond
         ((or (: dx) (: lst))
            (prin "<table cellspacing=\"0\" cellpadding=\"0\"><td>")
            (extra "Var")
            (prin "</td><td>")
            (if (try (: msg) (: obj))
               (<img> "img/obj.png" "obj" (mkUrl @))
               (<img> "img/no.png") )
            (prinl "</td></table>") )
         ((try (: msg) (: obj))
            (<href> (str> This) (mkUrl @)) )
         (T (extra "Var")) ) ) )


(class +Obj +obj)
# objVar objTyp objHook

# ([msg] (var . typ) [hook] [T] ..)
(dm T @
   (super)
   (=: objVar (car (arg)))
   (=: objTyp (cdr (arg)))
   (when (meta (: objTyp) (: objVar) 'hook)
      (=: objHook (next)) )
   (pass extra
      (if (nT (next))
         (arg)
         (cons NIL
            (if (: objHook)
               (collect (: objVar) (last (: objTyp)) (eval @) NIL T (: objVar))
               (collect (: objVar) (last (: objTyp)) NIL T (: objVar)) ) ) ) ) )

(dm txt> (Obj)
   (if (ext? Obj)
      (get Obj (: objVar))
      Obj ) )

(dm set> (Obj Dn)
   (extra
      (if (ext? (=: obj Obj))
         (get Obj (: objVar))
         Obj )
      Dn ) )

(dm val> ()
   (let V (extra)
      (cond
         ((and (: obj) (not (ext? @))) V)
         ((= V (get (: obj) (: objVar)))
            (: obj) )
         ((: objTyp)
            (=: obj
               (if (: objHook)
                  (db (: objVar) (last (: objTyp)) (eval @) V)
                  (db (: objVar) (last (: objTyp)) V) ) ) )
         (T V) ) ) )

(dm chk> ()
   (or
      (extra)
      (let? S (str> This)
         (and
            (: objTyp)
            (not (val> This))
            (<> "-" S)
            ,"Data not found" ) ) ) )


(class +ObjView +obj)
# disp obj

# ([msg] exe ..)
(dm T @
   (super)
   (=: disp (arg))
   (pass extra)
   (=: able) )

(dm txt> (Obj)
   (let Exe (: disp)
      (if (ext? Obj)
         (with Obj (eval Exe))
         Obj ) ) )

(dm set> (Obj Dn)
   (let Exe (: disp)
      (extra
         (if (ext? (=: obj Obj))
            (with Obj (eval Exe))
            Obj )
         Dn ) ) )

(dm val> ()
   (: obj) )


# DB Query Chart
(class +QueryChart +Chart)
# iniR iniq query

# (.. iniR iniQ cols [put [get]])
(dm T (R Q N Put Get)
   (=: iniR R)
   (=: iniQ Q)
   (super N (or Put cons) (or Get car)) )

(dm init> ()
   (query> This (eval (: iniQ))) )

(dm put> ()
   (while
      (and
         (>
            (+ "*Row" (: ofs))
            (- (length (: data)) (max (: rows) (: iniR))) )
         (asoq '@@ (prove (: query))) )
      (=: data (conc (: data) (cons (cdr @)))) )
   (super) )

(dm txt> ()
   (for (Q (eval (: iniQ)) (prove Q))
      (map
         '((G D)
            (prin (txt> (car G) (car D)))
            (if (cdr G) (prin "^I") (prinl)) )
         (: gui 1)
         ((: put) (cdr (asoq '@@ @))) ) ) )

(dm query> (Q)
   (=: query Q)
   (set> This) )

(dm sort> (Exe)
   (set> This
      (goal
         (list
            (list 'lst '@@
               (by '((This) (eval Exe)) sort (: data)) ) ) ) ) )

(dm clr> ()
   (query> This (fail)) )


(====)

# Utilities
(de <id> "Lst"
   (with (if *Post (: obj) (=: obj *ID))
      (and (: T) (prin "["))
      (for "X" "Lst"
         (ht:Prin (eval "X")) )
      (and (: T) (prin "]")) )
   (disable (: obj T)) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
