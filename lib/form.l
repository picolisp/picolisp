# 25mar09abu
# (c) Software Lab. Alexander Burger

# *Top *Gui *Get *Form *Event *Lock
# "*Cnt" "*Lst" "*App" "*Err" "*Foc" "*Post2" "*Stat" "*Ix" "*Chart" "*Cho"

(allow (path "@img/") T)
(push1 '*JS (allow (path "@lib/form.js")))
(mapc allow '(*Gui *Get *Form *Event "@jsForm" "@jsHint"))

(once
   (one "*Cnt")
   (off "*Lst" "*Post2" "*Cho") )

(de *Throbber
   ("+---" "-+--" "--+-" "---+" "--+-" "-+--" .) )

# Define GUI form
(de form ("Attr" . "Prg")
   (inc '*Form)
   (let "App"
      (if *Post
         (get "*Lst" (- "*Cnt" *Get) *Form)
         (prog1 (setq *Top (new NIL NIL  'able T  'event 0))
            (conc
               (get "*Lst" (- "*Cnt" *Get))
               (cons *Top) ) ) )
      (let "Lst" (get "*Lst" (- "*Cnt" *Get) 1)
         (for ("F" . "L") "Lst"
            (let *Form (- "F" (length "Lst"))
               (cond
                  ((and (== *Post (car "L")) (memq "App" (get *Post 'top)))
                     (apply "form" "L") )
                  ((or (== *Post "App") (memq "App" (get *Post 'top)))
                     (if (get "L" 1 'top)
                        (apply "form" "L")
                        (put (car "L") 'top (cons *Post (get *Post 'top)))
                        (let *Post NIL (apply "form" "L")) ) ) ) ) ) )
      ("form" "App" "Attr" "Prg") ) )

(de "form" ("*App" "Attr" "Prg")
   (with "*App"
      (job (: env)
         (<post> "Attr" (urlMT *Url *Menu *Tab *ID)
            (<hidden> '*Get *Get)
            (<hidden> '*Form *Form)
            (<hidden> '*Event (inc (:: event)))
            (zero "*Ix")
            (off "*Chart")
            (if *Post
               (let gui
                  '(()
                     (with (get "*App" 'gui (inc '"*Ix"))
                        (for E "*Err"
                           (when (== This (car E))
                              (<div> 'err
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
               (let gui
                  '(@
                     (inc '"*Ix")
                     (with
                        (cond
                           ((pair (next)) (pass new @))
                           ((not (arg)) (pass new))
                           ((num? (arg))
                              (ifn "*Chart"
                                 (quit "no chart" (rest))
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
                                          Fld ) ) ) ) )
                           ((get "*App" (arg)) (quit "gui conflict" (arg)))
                           (T (put "*App" (arg) (pass new))) )
                        (=: home gui (conc (: home gui) (cons This)))
                        (unless (: chart) (init> This))
                        (when (: id)
                           (let *Gui (val "*App")
                              (show> This (cons '*Gui (: id))) ) )
                        This ) )
                  (htPrin "Prg") ) ) )
         (--)
         (eval (: show))
         (=: show) ) ) )

# Disable form
(de disable (Flg)
   (and Flg (=: able)) )

# Handle form actions
(de action Prg
   (off "*Foc")
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
      (setq "*Stat"
         (cons
            (pair "*Err")
            (copy (get "*Lst" (- "*Cnt" *Get))) ) ) )
   (off "*Post2") )

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
                  (ht:Out *Chunked
                     (when (: auto)
                        (prin *Form '- (: auto 1 id) ': (: auto -1))
                        (=: auto) )
                     (for This (: gui)
                        (if (: id)
                           (prin '& *Form '- @ '& (js> This))
                           (setq "*Chart" This) ) ) )
                  (setq "*Post2" *Post)
                  (ht:Out *Chunked (prin T)) ) ) ) )
      (cond
         ((= '@ (car Url))
            ((intern (pack (cdr Url)))) )
         ((tail '("." "l") Url)
            (load *Url) ) ) ) )

(de postForm ()
   (let? Lst (get "*Lst" (- "*Cnt" (setq *Get (format *Get))))
      (setq
         *Form (format *Form)
         *Event (format *Event)
         *Post
         (or "*Post2"
            (if (gt0 *Form)
               (get Lst *Form)
               (get Lst 1 (+ (length (car Lst)) *Form) 1) ) ) ) ) )

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
         (if (pair "*Err")
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
                              (act> This) ) ) ) ) ) )
            (for This (: gui)
               (or (: id) (setq "*Chart" This))
               (upd> This) ) ) ) ) )

(de err (Exe)
   (cond
      ((=T Exe) (on "*Err"))
      ((nT "*Err") (queue '"*Err" (cons This Exe))) ) )

(de url (Url . @)
   (when Url
      (setq *Url Url  Url (chop Url))
      (off *Post)
      (let L
         (make
            (while (args)
               (if (and (sym? (next)) (= `(char '*) (char (arg))))
                  (set (arg) (next))
                  (link (arg)) ) ) )
         (cond
            ((= '@ (car Url))
               (apply (intern (pack (cdr Url))) L) )
            ((tail '("." "l") Url)
               (apply script L *Url) )
            ((assoc (stem Url ".") *Mimes)
               (apply httpEcho (cdr @) *Url) )
            (T (httpEcho *Url "application/octet-stream" 1 T)) ) )
      (throw "stop") ) )

# Return chart property
(de chart @
   (pass get "*Chart") )

# Table highlighting
(daemon '<table>
   (on "rowF") )

(de alternating ()
   (onOff "rowF") )

# Scroll chart
(de "scrl" (N)
   (with "*Chart"
      (get> This)
      (unless (gt0 (inc (:: ofs) N))
         (=: ofs 1) )
      (put> This) ) )

(de "goto" (N)
   (with "*Chart"
      (get> This)
      (=: ofs (max 1 N))
      (put> This) ) )


# REPL form
(de repl (Attr)
   (form Attr
      (gui 'view '(+FileField) '(tmp "repl") 80 25)
      (--)
      (gui 'line '(+Focus +TextField) 64 ":")
      (gui '(+JS +Button) "eval"
         '(let Str (val> (: home line))
            (out (pack "+" (tmp "repl"))
               (prinl ": " Str)
               (catch '(NIL)
                  (let Res (in "/dev/null" (eval (any Str)))
                     (prin "-> ")
                     (println Res) ) )
               (when *Msg (prinl @) (off *Msg)) )
            (clr> (: home line)) ) )
      (gui '(+JS +Button) "clear"
         '(clr> (: home view)) ) ) )


# Dialogs
(de _dlg (Attr Env)
   (push (get "*Lst" (- "*Cnt" *Get))
      (list
         (new NIL NIL  'btn This  'able T  'event 0  'env Env)
         Attr
         Prg ) ) )

(de dialog (Env . Prg)
   (_dlg 'dialog Env) )

(de alert (Env . Prg)
   (_dlg 'alert Env) )

(de note (Str Lst)
   (alert (env '(Str Lst))
      (<span> 'note Str)
      (--)
      (for S Lst (<br> S))
      (okButton) ) )

(de ask (Str . Prg)
   (alert (env '(Str Prg))
      (<span> 'ask Str)
      (--)
      (yesButton (cons 'prog Prg))
      (noButton) ) )

(de diaform (Lst . Prg)
   (if (and *Post (not (: diaform)))
      (_dlg 'dialog (env Lst))
      (=: env (env Lst))
      (=: diaform T)
      (run Prg 1) ) )

(de closeButton (Lbl Exe)
   (when (get "*App" 'top)
      (gui '(+Close +Button) Lbl Exe) ) )

(de okButton (Exe)
   (when (get "*App" 'top)
      (gui '(+Close +Button) "OK" Exe) ) )

(de cancelButton ()
   (when (get "*App" 'top)
      (gui '(+Force +Close +Button) T ',"Cancel") ) )

(de yesButton (Exe)
   (gui '(+Close +Button) ',"Yes" Exe) )

(de noButton (Exe)
   (gui '(+Close +Button) ',"No" Exe) )

(de choButton (Exe)
   (gui '(+Rid +Tip +Button)
      ,"Find or create an object of the same type"
      ',"Select" Exe ) )


(class +Force)
# force

(dm T (Exe . @)
   (=: force Exe)
   (pass extra) )

(dm chk> ()
   (when
      (and
         (cdr (assoc (: id) (val *Post)))
         (eval (: force)) )
      (for A (val *Post)
         (and
            (lt0 (car A))
            (<> (: id) (car A))
            (con A) ) )
      T ) )


(class +Close)

(dm act> ()
   (when (able)
      (and
         (get "*Lst" (- "*Cnt" *Get))
         (set @
            (filter
               '((L) (memq (car L) (: home top)))
               (car @) ) ) )
      (extra)
      (for This (: home top)
         (for This (: gui)
            (or (: id) (setq "*Chart" This))
            (upd> This) ) ) ) )


# Choose a value
(class +ChoButton +Tiny +Tip +Button)

(dm T (Exe)
   (super  ,"Choose a suitable value" "+" Exe)
   (=: chg T) )


(class +PickButton +Tiny +Tip +Button)

(dm T (Exe)
   (super ,"Adopt this value" "@" Exe) )


(class +DstButton +Set +Able +Close +PickButton)
# msg obj

(dm T (Dst Msg)
   (=: msg (or Msg 'url>))
   (super
      '((Obj) (=: obj Obj))
      '(: obj)
      (when Dst
         (or
            (pair Dst)
            (list 'set> (lit Dst) '(: obj)) ) ) ) )

(dm js> ()
   (cond
      ((: act) (super))
      ((try (: msg) (: obj) 1)
         (pack "@&+" (ht:Fmt (sesId (mkUrl @)))) )
      (T "@") ) )

(dm show> ("Var")
   (if (: act)
      (super "Var")
      (<style> (cons 'id (pack *Form '- (: id)))
         (if (try (: msg) (: obj) 1)
            (<tip> "-->" (<href> "@" (mkUrl @)))
            (<span> *Style "@") ) ) ) )


(class +Hint +ChoButton)
# ttl hint

(dm T (Ttl Exe)
   (=: ttl Ttl)
   (=: hint Exe)
   (super
      '(dialog (env 'Ttl (eval (: ttl))  'Lst (eval (: hint))  'Dst (field 1))
         (<table> 'chart Ttl '((btn) NIL)
            (for X Lst
               (<row> NIL
                  (gui '(+Close +PickButton)
                     (list 'set> 'Dst
                        (if (get Dst 'dy)
                           (list 'pack '(str> Dst) (fin X))
                           (lit (fin X)) ) ) )
                  (ht:Prin (if (atom X) X (car X))) ) ) )
         (cancelButton) ) ) )


(class +Hint0)

(dm show> ("Var")
   (<style>
      '(("onfocus" . "doHint(this)") ("onkeypress" . "return hintKey(this,event);"))
      (extra "Var") ) )

(de jsHint (Ix)
   (httpHead "text/plain; charset=utf-8")
   (ht:Out *Chunked
      (let? Lst (get "*Lst" (- "*Cnt" (format *Get)))
         (let? L
            (try 'hint>
               (get
                  (if (gt0 (format *Form))
                     (get Lst @)
                     (get Lst 1 (+ (length (car Lst)) (format *Form)) 1) )
                  'gui
                  (format Ix) ) )
            (prin
               (ht:Fmt
                  (if (atom (car L))
                     (car L)
                     (caar L) ) ) )
            (for X (cdr L)
               (prin '&
                  (ht:Fmt (if (atom X) X (car X))) ) ) ) ) ) )


(class +Hint1 +Hint0)
# hint

(dm T (Exe . @)
   (=: hint Exe)
   (pass extra) )

(dm hint> ()
   (eval (: hint)) )


(class +Hint2 +Hint0)

(dm hint> ()
   (eval (field -1 'hint)) )


(class +Txt)
# txt

(dm T (Fun . @)
   (=: txt Fun)
   (pass extra) )

(dm txt> (Val)
   ((: txt) Val) )


(class +Set)
# set

(dm T (Fun . @)
   (=: set Fun)
   (pass extra) )

(dm set> (Val Dn)
   (extra ((: set) Val) Dn) )


(class +Val)
# val

(dm T (Fun . @)
   (=: val Fun)
   (pass extra) )

(dm val> ()
   ((: val) (extra)) )


(class +Fmt)
# set val

(dm T (Fun1 Fun2 . @)
   (=: set Fun1)
   (=: val Fun2)
   (pass extra) )

(dm set> (Val Dn)
   (extra ((: set) Val) Dn) )

(dm val> ()
   ((: val) (extra)) )


(class +Chg)
# old new

(dm T (Fun . @)
   (=: new Fun)
   (pass extra) )

(dm set> (Val Dn)
   (extra (=: old Val) Dn) )

(dm val> ()
   (let Val (extra)
      (if (= (: old) Val)
         Val
         ((: new) Val) ) ) )


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
         (cons "onfocus" (pack "if (this.value=='" (: cue) "') this.value=''"))
         (cons "onblur" (pack "if (this.value=='') this.value='" (: cue) "'")) )
      (extra "Var") ) )

(dm set> (Val Dn)
   (extra (or Val (: cue)) Dn) )

(dm val> ()
   (let Val (extra)
      (unless (= Val (: cue)) Val) ) )


(class +Trim)

(dm val> ()
   (pack (trim (chop (extra)))) )


(class +Enum)
# enum

(dm T (Lst . @)
   (=: enum Lst)
   (pass extra) )

(dm set> (N Dn)
   (extra (get (: enum) N) Dn) )

(dm val> ()
   (index (extra) (: enum)) )


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
   (let Val (extra)
      (if
         (find
            '((X) (= Val (val (car X))))
            (: map) )
         (cdr @)
         Val ) ) )


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
   (when (: able)
      (=: able
         (cond
            ((=T (: able)) Exe)
            ((and (pair (: able)) (== 'and (car @)))
               (cons 'and Exe (cdr (: able))) )
            (T (list 'and Exe (: able))) ) ) ) )


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


(class +Click)
# clk

(dm T (N . @)
   (=: clk N)
   (pass extra) )

(dm show> ("Var")
   (extra "Var")
   (unless (or (pair "*Err") (get "*Lst" (- "*Cnt" *Get) 1))
      (javascript NIL
         "window.setTimeout(\"document.getElementById(\\\""
         *Form '- (: id)
         "\\\").click()\","
         (: clk)
         ")" ) ) )


(class +Focus)

(dm show> ("Var")
   (extra "Var")
   (when (and (able) (not "*Foc"))
      (on "*Foc")
      (javascript NIL
         "window.setTimeout(\"document.getElementById(\\\""
         *Form '- (: id)
         "\\\").focus()\",420)" ) ) )


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


# Monospace font
(class +Mono)

(dm show> ("Var")
   (<style> "mono" (extra "Var")) )

(dm js> ()
   (pack (extra) "&#mono") )


# Signum field
(class +Sgn)

(dm show> ("Var")
   (<style> (and (lt0 (val> This)) "red") (extra "Var")) )

(dm js> ()
   (pack (extra) "&#" (and (lt0 (val> This)) "red")) )


### Form field classes ###
(de showFld "Prg"
   (when (: lbl)
      (ht:Prin (eval @))
      (<nbsp>) )
   (style (cons 'id (pack *Form '- (: id))) "Prg") )


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
   (when (able)
      (=: home auto
         (cons
            (eval (car (: auto)))
            (eval (cdr (: auto))) ) )
      (extra) ) )


(class +DnButton +Tiny +Rid +JS +Able +Button)

(dm T (Exe Lbl)
   (super
      '(> (length (chart 'data)) (chart 'ofs))
      (or Lbl ">")
      (list '"scrl" Exe) ) )


(class +UpButton +Tiny +Rid +JS +Able +Button)

(dm T (Exe Lbl)
   (super
      '(> (chart 'ofs) 1)
      (or Lbl "<")
      (list '"scrl" (list '- Exe)) ) )

(class +GoButton +Tiny +Rid +JS +Able +Button)

(dm T (Exe Lbl)
   (super
      (list 'and
         (list '>= '(length (chart 'data)) Exe)
         (list '<> '(chart 'ofs) Exe) )
      Lbl
      (list '"goto" Exe) ) )

(de scroll (N Flg)
   (when Flg
      (gui '(+Tip +GoButton) ,"Go to first line" 1 "|<") )
   (gui '(+Tip +UpButton) ,"Scroll up one page" N "<<")
   (gui '(+Tip +UpButton) ,"Scroll up one line" 1)
   (gui '(+Tip +DnButton) ,"Scroll down one line" 1)
   (gui '(+Tip +DnButton) ,"Scroll down one page" N ">>")
   (when Flg
      (gui '(+Tip +GoButton) ,"Go to last line"
         (list '- '(length (chart 'data)) (dec N))
         ">|" )
      (<nbsp>)
      (gui '(+View +TextField)
         '(let? Len (gt0 (length (chart 'data)))
            (pack
               (chart 'ofs)
               "-"
               (min Len (dec (+ (chart 'ofs) (chart 'rows))))
               " / "
               Len ) ) ) ) )


# Delete row
(class +DelRowButton +Tiny +JS +Able +Tip +Button)
# del exe

(dm T (Txt Exe)
   (=: del Txt)
   (=: exe Exe)
   (super '(nth (: chart 1 data) (row)) ,"Delete row" "x"
      '(if (or (: home del) (not (curr)))
         (_delRow (: exe))
         (ask (if (: del) (eval @) ,"Delete row?")
            (with (: home btn)
               (=: home del T)
               (_delRow (: exe)) ) ) ) ) )

(de _delRow (Exe)
   (eval Exe)
   (set> (: chart 1) (remove (row) (: chart 1 data))) )

# Move row up
(class +BubbleButton +Tiny +JS +Able +Tip +Button)

(dm T ()
   (super
      '(> (: chart 2) 1)
      ,"Shift row up"
      "\^"
      '(let L (: chart 1 data)
         (set> (: chart 1)
            (conc
               (cut (row -2) 'L)
               (cons (cadr L))
               (cons (car L))
               (cddr L) ) ) ) ) )


(class +ClrButton +JS +Tip +Button)
# clr

(dm T (Lbl Lst . @)
   (=: clr Lst)
   (pass super ,"Clear all input fields" Lbl
      '(for X (: clr)
         (if (atom X)
            (clr> (field X))
            (set> (field (car X)) (eval (cdr X))) ) ) ) )


(class +ShowButton +Button)

(dm T (Flg Exe)
   (super ,"Show"
      (list '=: 'home 'show (lit Exe)) )
   (and Flg (=: home show Exe)) )


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


(class +Radio +field)  # Inited by Tomas Hlavaty <kvietaag@seznam.cz>
# grp val lbl

# (grp val [lbl])
(dm T (Grp Val Lbl)
   (super)
   (=: grp (if Grp (field @) This))
   (=: val Val)
   (=: lbl Lbl) )

(dm show> ("Var")
   (showFld
      (<radio>
         (cons '*Gui (: grp id))
         (: val)
         (not (able)) ) ) )

(dm js> ()
   (pack
      (ht:Fmt (: val))
      "&" (= (: val) (val> (: grp)))
      (unless (able) "&=") ) )

(dm set> (Val Dn)
   (when (== This (: grp))
      (super Val Dn) ) )


(class +TextField +field)
# dx dy lst lbl lim align

# ([dx [dy] [lbl]])
# ([lst [lbl]])
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
            (<area> (: dx) (: dy) "Var" (not (able))) )
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
            (<style> (cons 'id (pack *Form '- (: id)))
               (<span> *Style
                  (if (str> This) (ht:Prin @) (<nbsp>)) ) ) ) ) ) )


(class +ListTextField +TextField)
# split

(dm T (Lst . @)
   (=: split Lst)
   (pass super) )

(dm set> (Val Dn)
   (super (glue (car (: split)) Val) Dn) )

(dm val> ()
   (extract pack
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
   (let S (super)
      (format
         (if (sub? *Sep0 S) S (pack S *Sep0))
         (: scl)
         *Sep0
         *Sep3 ) ) )


(class +AtomField +Mono +TextField)

(dm set> (Val Dn)
   (super
      (if (num? Val)
         (align (: dx) (format Val))
         Val )
      Dn ) )

(dm val> ()
   (let S (super)
      (or (format S) S) ) )


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


(class +Icon)
# icon url

(dm T (Exe Url . @)
   (=: icon Exe)
   (=: url Url)
   (pass extra) )

(dm js> ()
   (pack (extra) "&*"
      (ht:Fmt (sesId (eval (: icon)))) '&
      (and (eval (: url)) (ht:Fmt (sesId @))) ) )

(dm show> ("Var")
   (prin "<table cellspacing=\"0\" cellpadding=\"0\"><td>")
   (extra "Var")
   (prin "</td><td>")
   (<img> (eval (: icon)) 'icon (eval (: url)))
   (prinl "</td></table>") )


(class +FileField +TextField)
# file org

(dm T (Exe . @)
   (=: file Exe)
   (pass super) )

(dm set> (Val Dn)
   (and
      (: home able)
      (<> Val (: org))
      (eval (: file))
      (out @ (prin (=: org Val))) )
   (super Val Dn) )

(dm upd> ()
   (set> This
      (=: org
         (let? F (eval (: file))
            (and (info F) (in F (till NIL T))) ) ) ) )


(class +Url)
# url

(dm T (Fun . @)
   (=: url Fun)
   (pass extra) )

(dm js> ()
   (if2 (or (: dx) (: lst)) (txt> This (val> This))
      (pack (extra) "&*" (ht:Fmt (sesId `(path "@img/go.png"))) '& (ht:Fmt (sesId ((: url) @))))
      (pack (extra) "&*" (ht:Fmt (sesId `(path "@img/no.png"))) '&)
      (pack @ "&+" (ht:Fmt (sesId ((: url) @))))
      (extra) ) )

(dm show> ("Var")
   (cond
      ((or (: dx) (: lst))
         (prin "<table cellspacing=\"0\" cellpadding=\"0\"><td>")
         (extra "Var")
         (prin "</td><td title=\"-->\">")
         (if (val> This)
            (<img> `(path "@img/go.png") 'url ((: url) (txt> This @)))
            (<img> `(path "@img/no.png")) )
         (prinl "</td></table>") )
      ((val> This)
         (showFld (<href> @ ((: url) (txt> This @)))) )
      (T (extra "Var")) ) )


(class +HttpField +Url +TextField)

(dm T @
   (pass super
      '((S) (if (sub? "://" S) S (pack "http://" S))) ) )


(class +MailField +Url +TextField)

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

# (cols [put [get]])
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

(dm txt> (Flg)
   (for (I . L) (: data)
      (map
         '((G D)
            (prin (txt> (car G) (car D)))
            (if
               (cdr G)
               (prin "^I")
               (prinl (and Flg "^M")) ) )
         (: gui 1)
         ((: put) L I) ) ) )

(dm set> (Lst)
   (=: ofs
      (max 1
         (min (: ofs) (length (=: data (copy Lst)))) ) )
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

(dm cut> (N)
   (get> This)
   (=: clip (get (: data) (: ofs)))
   (set> This (remove (or N (: ofs)) (: data))) )

(dm paste> (Flg N)
   (get> This)
   (set> This (insert (or N (: ofs)) (: data) (unless Flg (: clip)))) )


(class +Chart1 +Chart)

# (cols)
(dm T (N)
   (super N list car) )


### DB GUI ###
(de newUrl @
   (prog1
      (pass new!)
      (lock (setq *Lock @))
      (apply url (url> @ 1)) ) )


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
               (cons '+Focus '+Var (car Fld))
               (cdr (or (assoc Rel "*Cho") (push '"*Cho" (list Rel NIL))))
               (cdr Fld) ) )
         (searchButton '(init> (: home query)))
         (gui 'query '(+QueryChart) (cho)
            '(goal
               (list
                  (list 'db (car Rel) (last Rel) Hook (val> (: home gui 1)) '@@) ) )
            2 '((Obj) (list Obj Obj)) )
         (<table> 'chart (if (atom Ttl) Ttl (apply choTtl Ttl)) '((btn) NIL)
            (do (cho)
               (<row> (alternating)
                  (gui 1 '(+DstButton) Dst)
                  (apply gui Gui 2) ) ) )
         (<spread>
            (scroll (cho))
            (if (meta (cdr Rel) (car Rel) 'hook)
               (newButton T Dst (cdr Rel) @ Hook
                  (car Rel)
                  (val> (: home gui 1)) )
               (newButton T Dst (cdr Rel)
                  (car Rel)
                  (val> (: home gui 1)) ) )
            (cancelButton) ) ) ) )

(de choTtl (Ttl Var Cls Hook)
   (with (or (get Cls Var) (meta Cls Var))
      (pack (count (tree (: var) (: cls) Hook)) " " Ttl) ) )

(de cho ()
   (if (: diaform) 16 8) )


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
(class +Edit +Rid +Force +Tip)
# save

(dm T (Exe)
   (=: save Exe)
   (super
      '(nor (: home able) (lock (: home obj)))
      '(if (: home able)
         ,"Release exclusive write access for this object"
         ,"Gain exclusive write access for this object" )
      '(if (: home able) ,"Done" ,"Edit")
      '(if (: home able)
         (when (able)
            (eval (: save))
            (unless (pair "*Err")
               (rollback)
               (off *Lock) ) )
         (tryLock (: home obj)) ) ) )

(de tryLock (Obj)
   (if (lock Obj)
      (err (text ,"Currently edited by '@2' (@1)" @  (cdr (lup *Users @))))
      (sync)
      (setq *Lock Obj) ) )


(de editButton (Able Exe)
   (<style> (and (: able) 'edit)
      (gui '(+AO +Focus +Edit +Button) Able Exe) ) )

(de searchButton (Exe)
   (gui '(+JS +Tip +Button) ,"Start search" ,"Search" Exe) )

(de resetButton (Lst)
   (gui '(+ClrButton) ,"Reset" Lst) )

(de newButton (Able Dst . Args)
   (gui '(+Able +Close +Tip +Button) Able ,"Create new object" ',"New"
      (nond
         (Dst (cons 'newUrl Args))
         ((pair Dst)
            (list 'set> (lit Dst) (cons 'new! Args)) )
         (NIL
            (list 'prog (list '=: 'obj (cons 'new! Args)) Dst) ) ) ) )

# Clone object in form
(de cloneButton (Able)
   (gui '(+Rid +Able +Tip +Button) (or Able T)
      ,"Create a new copy of this object"
      ,"New/Copy"
      '(apply url
         (url>
            (prog1
               (clone!> (: home obj))
               (lock (setq *Lock @)) )
            1 ) ) ) )

# Delete object in form
(de delButton (Able @Txt)
   (gui '(+Force +Rid +Able +Tip +Button) T Able
      '(if (: home obj T)
         ,"Mark this object as \"not deleted\""
         ,"Mark this object as \"deleted\"" )
      '(if (: home obj T) ,"Restore" ,"Delete")
      (fill
         '(if (: home obj T)
            (ask (text ,"Restore @1?" @Txt)
               (keep!> (: home top 1 obj)) )
            (ask (text ,"Delete @1?" @Txt)
               (lose!> (: home top 1 obj)) ) ) ) ) )


# Relations
(class +/R +Able)
# erVar erObj

(dm T (Lst . @)
   (=: erVar (car Lst))
   (=: erObj (cdr Lst))
   (pass extra)
   (pass super
      '(and (eval (: erObj)) (not (get @ T))) ) )

(dm upd> ()
   (set> This (get (eval (: erObj)) (: erVar))) )


# Symbol/Relation
(class +S/R +/R)

(dm set> (Val Dn)
   (and
      (: home able)
      (eval (: erObj))
      (put! @ (: erVar) Val) )
   (extra Val Dn) )


# Entity/Relation
(class +E/R +/R)

(dm set> (Val Dn)
   (and
      (: home able)
      (eval (: erObj))
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
         (: home able)
         (eval (: erObj))
         (put!> @ (: erVar) (bool Val))
         (allow (blob (eval (: erObj)) (: erVar))) )
      Dn ) )


(class +BlobField +/R +TextField)
# org

(dm set> (Val Dn)
   (and
      (: home able)
      (<> Val (: org))
      (eval (: erObj))
      (put!> @ (: erVar) (bool Val))
      (out (allow (blob (eval (: erObj)) (: erVar)))
         (prin (=: org Val)) ) )
   (super Val Dn) )

(dm upd> ()
   (set> This
      (=: org
         (and
            (eval (: erObj))
            (get @ (: erVar))
            (in (allow (blob (eval (: erObj)) (: erVar)))
               (till NIL T) ) ) ) ) )


(class +ClassField +Map +TextField)
# erObj

(dm T (Exe Lst)
   (=: erObj Exe)
   (super Lst (mapcar car Lst)) )

(dm upd> ()
   (set> This (val (eval (: erObj)))) )

(dm set> (Val Dn)
   (and
      (: home able)
      (eval (: erObj))
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
      (if2 (or (: dx) (: lst)) (try (: msg) (: obj) 1)
         (pack (extra) "&*" (ht:Fmt (sesId `(path "@img/go.png"))) '& (ht:Fmt (sesId (mkUrl @))))
         (pack (extra) "&*" (ht:Fmt (sesId `(path "@img/no.png"))) '&)
         (pack (ht:Fmt (nonblank (str> This))) "&+" (ht:Fmt (sesId (mkUrl @))))
         (extra) ) ) )

(dm show> ("Var")
   (cond
      ((=T (: msg)) (extra "Var"))
      ((or (: dx) (: lst))
         (prin "<table cellspacing=\"0\" cellpadding=\"0\"><td>")
         (extra "Var")
         (prin "</td><td title=\"-->\">")
         (if (try (: msg) (: obj) 1)
            (<img> `(path "@img/go.png") 'obj (mkUrl @))
            (<img> `(path "@img/no.png")) )
         (prinl "</td></table>") )
      ((try (: msg) (: obj) 1)
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
         (cons NIL (hint> This)) ) ) )

(dm hint> ()
   (if (: objHook)
      (collect (: objVar) (last (: objTyp)) (eval @) NIL T (: objVar))
      (collect (: objVar) (last (: objTyp)) NIL T (: objVar)) ) )

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
   (let Val (extra)
      (cond
         ((and (: obj) (not (ext? @))) Val)
         ((= Val (get (: obj) (: objVar)))
            (: obj) )
         ((: objTyp)
            (=: obj
               (if (: objHook)
                  (db (: objVar) (last (: objTyp)) (eval @) Val)
                  (db (: objVar) (last (: objTyp)) Val) ) ) )
         (T Val) ) ) )

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

# (iniR iniQ cols [put [get]])
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
         (get (prove (: query)) '@@) )
      (=: data (conc (: data) (cons @))) )
   (super) )

(dm txt> (Flg)
   (for ((I . Q) (eval (: iniQ)) (prove Q))
      (map
         '((G D)
            (prin (txt> (car G) (car D)))
            (if (cdr G)
               (prin "^I")
               (prinl (and Flg "^M")) ) )
         (: gui 1)
         ((: put) (; @ @@) I) ) ) )

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
         ((== *Lock (: obj)) T)
         (*Lock (rollback) (off *Lock)) ) ) )

(de panel (Able Txt Del Dlg Var Cls Hook Msg Exe)
   (<spread>
      (prog
         (editButton Able Exe)
         (updLink) )
      (delButton
         (cond
            ((=T Able) Del)
            ((=T Del) Able)
            ((and Able Del) (list 'and Able Del)) )
         (list 'text Txt (list ': 'home 'obj Var)) )
      (choButton Dlg)
      (stepBtn Var Cls Hook Msg) )
   (--) )

`*Dbg
(noLint 'gui)
(noLint 'choDlg 'gui)
(noLint 'jsForm 'action)

# vi:et:ts=3:sw=3
