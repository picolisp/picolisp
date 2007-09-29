# 08sep07abu
# (c) Software Lab. Alexander Burger

# *Top *Gui *Get *Form *Event *Lock
# "*Cnt" "*Lst" "*App" "*Err" "*Post2" "*Stat" "*Ix" "*Chart" "*Cho"

(allow (path "@img/") T)
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
         (<post> "Attr" (urlMT *Url *Menu *Tab *ID)
            (<hidden> '*Get *Get)
            (<hidden> '*Form *Form)
            (<hidden> '*Event (inc (:: event)))
            (zero "*Ix")
            (if *Post
               (let gui
                  '(()
                     (with (get "*App" 'gui (inc '"*Ix"))
                        (for E "*Err"
                           (when (== This (car E))
                              (<p> 'err
                                 (if (atom (cdr E))
                                    (ht:Prin (eval (cdr E) 1))
                                    (eval (cdr E) 1) ) ) ) )
                        (if (: id)
                           (let *Gui (val "*App")
                              (show> This (cons '*Gui @)) )
                           (setq "*Chart" This) )
                        This ) )
                  (and (== *Post "*App") (setq *Top "*App"))
                  (htPrin "Prg") )
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
                           ((not (arg)) (pass new))
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
                                             ((: put)
                                                (get (nth (: data) (: ofs)) (: rows))
                                                (+ (: ofs) (: rows) -1) )
                                             I )
                                          T )
                                       (put Fld 'chart (list This (: rows) I))
                                       Fld ) ) ) )
                           ((get "*App" (arg)) (quit "gui conflict" (arg)))
                           (T (put "*App" (arg) (pass new))) )
                        (=: home gui (conc (: home gui) (cons This)))
                        (unless (: chart) (init> This))
                        (when (: id)
                           (let *Gui (val "*App")
                              (show> This (cons '*Gui (: id))) ) )
                        This ) )
                  (htPrin "Prg") ) ) )
         (eval (: show))
         (=: show) ) ) )

# Disable form
(de disable (Flg)
   (and Flg (=: able)) )

# Click button
(de <click> ()
   (unless *Post
      (prinl
         "<script type=\"text/javascript\">document.getElementById(\""
         *Form "--" "*Ix"
         "\").click();</script>" ) ) )

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
               (httpHead "text/plain; charset=utf-8")
               (if
                  (and
                     (= (car "*Stat") "*Err")
                     (= (cdr "*Stat") (get "*Lst" (- "*Cnt" *Get))) )
                  (ht:Out T
                     (when (: auto)
                        (prin *Form '- (: auto 1 id) ': (: auto -1))
                        (=: auto) )
                     (for This (: gui)
                        (if (: id)
                           (prin '& *Form '- @ '& (js> This))
                           (setq "*Chart" This) ) ) )
                  (setq "*Post2" *Post)
                  (prin "1^M^JT^M^J0^M^J^M^J") ) ) ) )  # 'T'
      (cond
         ((= '@ (car Url))
            ((intern (pack (cdr Url)))) )
         ((tail '("." "l") Url)
            (load *Url) ) ) ) )

(de postForm ()
   (let Lst (get "*Lst" (- "*Cnt" (setq *Get (format *Get))))
      (setq
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
         (if "*Err"
            (and *Lock (with (caar "*Err") (tryLock *Lock)))
            (finally
               (when *Lock
                  (if (lock @)
                     (=: able (off *Lock))
                     (sync) ) )
               (for This (: gui)
                  (nond
                     ((: id) (setq "*Chart" This))
                     ((ge0 (: id))
                        (let? A (assoc (: id) (val *Post))
                           (when (cdr A)
                              (con A)
                              (and (eval (: able)) (act> This)) ) ) ) ) ) )
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

# Return chart property
(de chart @
   (pass get "*Chart") )

(de alternating ()
   (onOff "rowF") )

# Scroll chart
(de "scrl" (N)
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
   (when (get "*App" 'top)
      (gui '(+Close +Button) Lbl Exe) ) )

(de okButton (Exe)
   (when (get "*App" 'top)
      (gui '(+Close +Button) "Ok" Exe) ) )

(de cancelButton ()
   (when (get "*App" 'top)
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


# Choose a value
(class +ChoButton +Tiny +Button)

(dm T (Exe)
   (super "+" Exe)
   (=: chg T) )


(class +PickButton +Tiny +Button)

(dm T (Exe)
   (super "@" Exe) )


(class +DstButton +Able +Close +PickButton)

(dm T (@Dst @F)
   (super
      (fill '(val> (field @F)))
      (fill '(set> '@Dst (val> (field @F)))) ) )


(class +Hint +ChoButton)
# ttl exe

(dm T (Ttl Exe)
   (=: ttl Ttl)
   (=: exe Exe)
   (super
      '(dialog (env 'Ttl (eval (: ttl))  'Lst (eval (: exe))  'Dst (field 1))
         (<table> 'chart Ttl '(NIL (btn))
            (for X Lst
               (<row> NIL
                  (ht:Prin (if (atom X) X (car X)))
                  (gui '(+Close +PickButton) (list 'set> 'Dst (lit (fin X)))) ) ) )
         (cancelButton) ) ) )


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
   (set> This (eval (: upd))) )


(class +Init)
# init

(dm T (Val . @)
   (=: init Val)
   (pass extra) )

(dm init> ()
   (set> This (: init)) )


(class +Cue)
# cue

(dm T (Str . @)
   (=: cue (pack "<" Str ">"))
   (pass extra) )

(dm show> ("Var")
   (<style>
      (list
         (cons 'onfocus (pack "if (this.value=='" (: cue) "') this.value=''"))
         (cons 'onblur (pack "if (this.value=='') this.value='" (: cue) "'")) )
      (extra "Var") ) )

(dm set> (Val Dn)
   (extra (or Val (: cue)) Dn) )

(dm val> ()
   (let Val (extra)
      (unless (= Val (: cue)) Val) ) )


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


# Case conversions
(class +Uppc)

(dm set> (Val Dn)
   (extra (uppc Val) Dn) )

(dm val> ()
   (uppc (extra)) )


(class +Lowc)

(dm set> (Val Dn)
   (extra (lowc Val) Dn) )

(dm val> ()
   (lowc (extra)) )


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


(class +View +Lock +Upd)


# Escape from form lock
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


(class +Tip)
# tip

(dm T (Exe . @)
   (=: tip Exe)
   (pass extra) )

(dm show> ("Var")
   (<tip> (eval (: tip)) (extra "Var")) )

(dm js> ()
   (pack (extra) "&?" (ht:Fmt (eval (: tip)))) )


(class +Tiny)

(dm show> ("Var")
   (<style> 'tiny (extra "Var")) )


### Styles ###
(class +Style)
# style

(dm T (Exe . @)
   (=: style Exe)
   (pass extra) )

(dm show> ("Var")
   (<style> (eval (: style)) (extra "Var")) )

(dm js> ()
   (pack (extra) "&#" (eval (: style))) )


# Signum field
(class +Sgn +Style)

(dm T @
   (pass super '(if (lt0 (val> This)) 'red 'black)) )


### Form field classes ###
(de showFld "Prg"
   (when (: lbl)
      (prin "<label>")
      (ht:Prin (eval @))
      (<nbsp>) )
   (style (cons 'id (pack *Form '- (: id))) "Prg")
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
(de row (D)
   (+ (: chart 1 ofs) (: chart 2) -1 (or D 0)) )

(de curr @
   (pass get (: chart 1 data) (row)) )

(de prev @
   (pass get (: chart 1 data) (row -1)) )


(class +Button +gui)
# img lbl alt act js

# ([T] lbl [alt] act)
(dm T @
   (and (=: img (=T (next))) (next))
   (=: lbl (arg))
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
         (if (: img) (sesId Str) Str) )
      (let Str (ht:Fmt (or (eval (: alt)) (eval (: lbl))))
         (pack (if (: img) (sesId Str) Str) "&=") ) ) )

(dm show> ("Var")
   (<style> (cons 'id (pack *Form '- (: id)))
      (if (able)
         (let Str (eval (: lbl))
            ((if (: img) <image> <submit>) Str "Var" NIL (: js)) )
         (let Str (or (eval (: alt)) (eval (: lbl)))
            ((if (: img) <image> <submit>) Str "Var" T (: js)) ) ) ) )

(dm act> ()
   (and (able) (eval (: act))) )


(class +JS)

(dm T @
   (=: js T)
   (pass extra) )


(class +Auto +JS)
# auto

(dm T (Fld Exe . @)
   (=: auto (cons Fld Exe))
   (pass super) )

(dm act> ()
   (=: home auto
      (cons
         (eval (car (: auto)))
         (eval (cdr (: auto))) ) )
   (extra) )


(class +DnButton +Tiny +Rid +JS +Able +Button)

(dm T (Exe Lbl)
   (super
      (list '>= '(length (chart 'data)) (list '+ Exe '(chart 'ofs)))
      (or Lbl ">")
      (list '"scrl" Exe) ) )


(class +UpButton +Tiny +Rid +JS +Able +Button)

(dm T (Exe Lbl)
   (super
      '(> (chart 'ofs) 1)
      (or Lbl "<")
      (list '"scrl" (list '- Exe)) ) )

(de scroll (N)
   (gui '(+UpButton) N "<<")
   (gui '(+UpButton) 1 "<")
   (gui '(+DnButton) 1 ">")
   (gui '(+DnButton) N ">>") )


# Delete row
(class +DelRowButton +Tiny +JS +Able +Button)
# exe

(dm T (Exe)
   (=: exe Exe)
   (super '(nth (: chart 1 data) (row)) "x"
      '(if (curr)
         (alert (env 'Fld This 'Exe (: exe))
            ,"Delete row?"
            (----)
            (yesButton '(with Fld (_delRow)))
            (noButton) )
         (_delRow) ) ) )

(de _delRow ()
   (eval Exe)
   (set> (: chart 1) (remove (row) (: chart 1 data))) )

# Move row up
(class +BubbleButton +Tiny +JS +Able +Button)

(dm T ()
   (super
      '(and
         (> (: chart 2) 1)
         (nth (: chart 1 data) (row)) )
      "\^"
      '(let L (: chart 1 data)
         (set> (: chart 1)
            (conc
               (cut (row -2) 'L)
               (cons (cadr L))
               (cons (car L))
               (cddr L) ) ) ) ) )


(class +ClrButton +JS +Button)
# clr

(dm T (Lbl Lst . @)
   (=: clr Lst)
   (pass super Lbl
      '(for X (: clr)
         (if (atom X)
            (clr> (field X))
            (set> (field (car X)) (eval (cdr X))) ) ) ) )


(class +ShowButton +Button)

(dm T (Exe)
   (super ,"Show"
      (list '=: 'home 'show (lit Exe)) ) )


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
            (prin "<span id=\"" *Form '- (: id) "\">")
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


# Password field
(class +PwField +TextField)

(dm show> ("Var")
   (showFld
      (<passwd> (: dx) "Var" (eval (: lim)) (not (able))) ) )


# Upload field
(class +UpField +TextField)

(dm show> ("Var")
   (showFld
      (<upload> (: dx) "Var" (not (able))) ) )


# Symbol fields
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


(class +UrlField +TextField)
# url

(dm T (Foo . @)
   (=: url Foo)
   (pass super) )

(dm js> ()
   (if2 (or (: dx) (: lst)) (ht:Fmt (val> This))
      (pack (super) "&*" (sesId (ht:Fmt `(path "@img/go.png"))) '& (ht:Fmt ((: url) @)))
      (pack (super) "&*" (sesId (ht:Fmt `(path "@img/no.png"))) '&)
      (pack @ "&+" (ht:Fmt ((: url) @)))
      (super) ) )

(dm show> ("Var")
   (cond
      ((or (: dx) (: lst))
         (prin "<table cellspacing=\"0\" cellpadding=\"0\"><td>")
         (super "Var")
         (prin "</td><td>")
         (if (val> This)
            (<img> `(path "@img/go.png") 'url ((: url) @))
            (<img> `(path "@img/no.png")) )
         (prinl "</td></table>") )
      ((val> This)
         (showFld (<href> @ ((: url) @))) )
      (T (super "Var")) ) )


(class +HttpField +UrlField)

(dm T @
   (pass super '((S) (pack "http://" S))) )


(class +MailField +UrlField)

(dm T @
   (pass super '((S) (pack "mailto:" S))) )


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


(class +SexField +Map +TextField)

(dm T (Lbl)
   (super
      '((,"male" . T) (,"female" . 0))
      '(NIL ,"male" ,"female")
      Lbl ) )


(class +JsField +gui)
# js str

(dm T (Nm)
   (super)
   (=: js Nm) )

(dm show> ("Var"))

(dm js> ()
   (pack (ht:Fmt (: str) (: js))) )

(dm set> (Val Dn)
   (=: str Val) )


### GUI charts ###
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
   (let I (: ofs)
      (mapc
         '((G D)
            (unless (memq NIL G)
               (mapc 'set> G ((: put) D I) '(T .)) )
            (inc 'I) )
         (: gui)
         (nth (: data) I) ) ) )

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
   (for (I . L) (: data)
      (map
         '((G D)
            (prin (txt> (car G) (car D)))
            (if (cdr G) (prin "^I") (prinl)) )
         (: gui 1)
         ((: put) L I) ) ) )

(dm set> (Lst)
   (=: ofs (max 1 (min (: ofs) (length (=: data Lst)))))
   (put> This)
   Lst )

(dm log> (Lst)
   (=: ofs (max (: ofs) (- (length (: data)) (: rows) -2)))
   (set> This (conc (: data) (cons Lst))) )

(dm clr> ()
   (set> This) )

(dm val> ()
   (get> This)
   (: data) )

(dm init> ()
   (upd> This) )

(dm upd> ())

(dm chk> ())

(dm cut> ()
   (get> This)
   (=: clip (get (: data) (: ofs)))
   (set> This (remove (: ofs) (: data))) )

(dm paste> (Flg)
   (get> This)
   (set> This (insert (: ofs) (: data) (unless Flg (: clip)))) )


(class +Chart1 +Chart)

(dm set> (Lst)
   (super (cons Lst)) )

(dm val> ()
   (car (super)) )


### DB GUI ###
(de newUrl @
   (prog1
      (pass new!)
      (lock (setq *Lock @))
      (apply url (url> @)) ) )


# (choDlg Dst Ttl Rel [Hook] [((+XyzField) ..) Exe [Rel2 [Hook2]]])
(de choDlg (Dst Ttl Rel . @)
   (let
      (Hook (and (meta (cdr Rel) (car Rel) 'hook) (next))
         Fld (or (next) '((+TextField) 40))
         Gui
         (if (next)
            (list '(+ObjView +TextField) @)
            (list (list '+ObjView (last (car Fld))) (list ': (car Rel))) ) )
      (nond
         ((next)
            (setq Ttl (list Ttl (car Rel) (cadr Rel) Hook)) )
         ((=T (arg))
            (setq Ttl (list Ttl (car (arg)) (cadr (arg)) (next))) ) )
      (diaform '(Dst Ttl Rel Hook Fld Gui)
         (apply gui
            (cons
               (cons '+Var (car Fld))
               (cdr (or (assoc Rel "*Cho") (push '"*Cho" (list Rel NIL))))
               (cdr Fld) ) )
         (searchButton '(init> (: home query)))
         (gui 'query '(+QueryChart) 6
            '(goal
               (list
                  (list 'db (car Rel) (last Rel) Hook (val> (: home gui 1)) '@@) ) )
            (if (flg? Dst) 1 2)
            cons car )
         (<table> 'chart (if (atom Ttl) Ttl (apply choTtl Ttl)) '(NIL (btn))
            (do 6
               (<row> (alternating)
                  (apply gui Gui 1)
                  (unless (flg? Dst)
                     (gui 2 '(+DstButton) Dst -1) ) ) ) )
         (<spread>
            (scroll 6)
            (when (=T Dst)
               (gui '(+Button) ',"New"
                  '(if (meta (cdr Rel) (car Rel) 'hook)
                     (newUrl (cdr Rel) @ Hook)
                     (newUrl (cdr Rel)) ) ) )
            (cancelButton) ) ) ) )

(de choTtl (Ttl Var Cls Hook)
   (with (or (get Cls Var) (meta Cls Var))
      (pack (count (tree (: var) (: cls) Hook)) " " Ttl) ) )


# Able object
(class +AO +Able)
# ao

(dm T (Exe . @)
   (=: ao Exe)
   (pass super
      '(and
         (: home obj)
         (not (: home obj T))
         (eval (: ao)) ) ) )


# Lock/Edit button prefix
(class +Edit +Rid)
# save

(dm T (Exe)
   (=: save Exe)
   (super
      '(if (: home able) ,"Save" ,"Edit")
      '(if (: home able)
         (when (able)
            (eval (: save))
            (unless "*Err"
               (rollback)
               (off *Lock) ) )
         (tryLock (: home obj)) ) ) )

(de tryLock (Obj)
   (if (lock Obj)
      (err (editing @ (cdr (lup *Users @))))
      (sync)
      (setq *Lock Obj) ) )

(de editing (Pid Nm)
   (text ,"Currently edited by '@2' (@1)" Pid Nm) )

(de editButton (Able Exe)
   (<style> (and (: able) 'edit)
      (gui '(+AO +Edit +Button) Able Exe) ) )

(de searchButton (Exe)
   (gui '(+JS +Button) ,"Search" Exe) )

(de resetButton (Lst)
   (gui '(+ClrButton) ,"Reset" Lst) )

# Clone object in form
(de cloneButton (Able)
   (gui '(+Rid +Able +Button) (or Able T) ,"New/Copy"
      '(apply url (url> (clone!> (: home obj)))) ) )

# Delete object in form
(de delButton (Able @Txt)
   (gui '(+Rid +Able +Button) Able '(if (: home obj T) ,"Restore" ,"Delete")
      (fill
         '(if (: home obj T)
            (alert NIL
               (ht:Prin (text ,"Restore @1?" @Txt))
               (----)
               (yesButton '(keep!> (: home top 1 obj)))
               (noButton) )
            (alert NIL
               (ht:Prin (text ,"Delete @1?" @Txt))
               (----)
               (yesButton '(lose!> (: home top 1 obj)))
               (noButton) ) ) ) ) )


(class +/R)
# erVar erObj

(dm T (Lst . @)
   (=: erVar (car Lst))
   (=: erObj (cdr Lst))
   (pass extra)
   (when (: able)
      (=: able '(and (eval (: erObj)) (not (get @ T)))) ) )

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

# ([T|msg] ..)
(dm T ()
   (ifn (atom (next))
      (=: msg 'url>)
      (=: msg (arg))
      (next) ) )

(dm js> ()
   (if (=T (: msg))
      (extra)
      (if2 (or (: dx) (: lst)) (try (: msg) (: obj))
         (pack (extra) "&*" (sesId (ht:Fmt `(path "@img/go.png"))) '& (sesId (ht:Fmt (mkUrl @))))
         (pack (extra) "&*" (sesId (ht:Fmt `(path "@img/no.png"))) '&)
         (pack (ht:Fmt (nonblank (str> This))) "&+" (sesId (ht:Fmt (mkUrl @))))
         (extra) ) ) )

(dm show> ("Var")
   (cond
      ((=T (: msg)) (extra "Var"))
      ((or (: dx) (: lst))
         (prin "<table cellspacing=\"0\" cellpadding=\"0\"><td>")
         (extra "Var")
         (prin "</td><td>")
         (if (try (: msg) (: obj))
            (<img> `(path "@img/go.png") "obj" (mkUrl @))
            (<img> `(path "@img/no.png")) )
         (prinl "</td></table>") )
      ((try (: msg) (: obj))
         (showFld (<href> (nonblank (str> This)) (mkUrl @))) )
      (T (extra "Var")) ) )


(class +Obj +obj)
# objVar objTyp objHook

# ([T|msg] (var . typ) [hook] [T] ..)
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

# ([T|msg] exe ..)
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


# DB query chart
(class +QueryChart +Chart)
# iniR iniq query

# (.. iniR iniQ cols [put [get]])
(dm T (R Q . @)
   (=: iniR R)
   (=: iniQ Q)
   (pass super) )

(dm init> ()
   (query> This (eval (: iniQ))) )

(dm put> ()
   (while
      (and
         (> (: ofs) (- (length (: data)) (max (: rows) (: iniR))))
         (asoq '@@ (prove (: query))) )
      (=: data (conc (: data) (cons (cdr @)))) )
   (super) )

(dm txt> ()
   (for ((I . Q) (eval (: iniQ)) (prove Q))
      (map
         '((G D)
            (prin (txt> (car G) (car D)))
            (if (cdr G) (prin "^I") (prinl)) )
         (: gui 1)
         ((: put) (cdr (asoq '@@ @)) I) ) ) )

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

# Form object
(de <id> "Lst"
   (with (if *Post (: obj) (=: obj *ID))
      (and (: T) (prin "["))
      (for "X" (if (=T (car "Lst")) (cdr "Lst") "Lst")
         (ht:Prin (eval "X")) )
      (and (: T) (prin "]")) )
   (=: able
      (cond
         ((: obj T))
         ((=T (car "Lst")) T)
         (*Solo)
         ((== *Lock (: obj)) T)
         (*Lock (rollback) (off *Lock)) ) ) )

(de panel (Able Txt Del Dlg Var Cls Hook Msg Exe)
   (<spread>
      (editButton Able Exe)
      (delButton
         (cond
            ((=T Able) Del)
            ((=T Del) Able)
            ((and Able Del) (list 'and Able Del)) )
         (list 'text Txt (list ': 'top 1 'obj Var)) )
      (choButton Dlg)
      (stepBtn Var Cls Hook Msg) )
   (----) )

# vi:et:ts=3:sw=3
