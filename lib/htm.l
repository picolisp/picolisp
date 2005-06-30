# 28may05abu
# (c) Software Lab. Alexander Burger

### Plain HTML GUI (Preliminary, experimental) ###
# *ID *Fld *Apps *Top *Fox *PnlFld *PnlCnt *LayPnl *LayRow *Bar

(mapc allow '(*Fld "@act"))

(de act (App Ix)
   (act> (get (cdr (assoc App *Apps)) 'fields Ix)) )

(de url (Str Tar . @)
   (when Str
      (let (L (split (chop Str) "?")  U (car L))  ## -> lib/http.l
         (setq
            L (mapcan
               '((L)
                  (ifn (cdr (setq L (split L "=")))
                     (cons (htArg (car L)))
                     (_htSet (car L) (htArg (cadr L)))
                     NIL ) )
               (split (cadr L) "&") )
            *Url (ht:Pack U) )
         (cond
            ((member '@ U)
               (apply (val (intern (ht:Pack (cdr @)))) (conc L (rest))) )
            ((tail '("." "l") U)
               (load *Url) )
            ((tail '("." "h" "t" "m" "l") U)
               (httpEcho *Url NIL 86400) ) ) ) ) )

(de bar (Ttl X Y Prg)
   (prinl Ttl '<hr>)
   (setq *Bar (form '(+Form) X Y Prg))
   (navi) )


(class +Form)
# app dx dy fields arrays focus hot able lock rv

(de form @
   (when (atom (next))
      (default *ID (arg))
      (next) )
   (setq *Fox -1)
   (let
      (App (pack *Url "?*ID=" (ht:Fmt *ID))
         F (if (assoc App *Apps)
            (cdr @)
            (prog1
               (pass new (arg))
               (put @ 'app App)
               (push '*Apps (cons App @)) ) ) )
      (init> F)
      (off *ID *Fld)
      (show> F)
      F ) )

(de gui @
   (cond
      ((pair (next)) (pass new @))
      ((and (not (: fields)) (get *Top (arg)))
         (quit "gui conflict" (arg)) )
      (T (put *Top (arg) (pass new (next)))) )
   (off *LayPnl)
   (on *LayRow) )

(de txt @
   (while (next)
      (new '(+txt) @)
      (off *LayPnl)
      (off *LayRow) )
   (on *LayRow) )

(de row "Prg"
   (_row) )

(de flow "Prg"
   (on *LayPnl)
   (_row)
   (endPnl> *Fld 1) )

(de _row ()
   (eval (pop '"Prg"))
   (while "Prg"
      (off *LayRow *LayPnl)
      (eval (pop '"Prg")) ) )

(de ---- ()
   (and *Fld (endPnl> *Fld *PnlCnt))
   (on *PnlFld)
   (on *LayPnl *LayRow) )

(de -|- ()
   (when *PnlFld
      (inc '*PnlCnt)
      (inc (prop *PnlFld '*))
      (off *PnlFld) )
   (endPnl> *Fld (dec *PnlCnt))
   (on *LayPnl)
   (off *LayRow) )


(dm T ("DX" "DY" "Prg" . @)
   (setq *Top This)
   (=: dx "DX")
   (=: dy "DY")
   (set This (conc (rest) (val This)))
   (let (*PnlFld T  *PnlCnt 0  *LayPnl T  *LayRow)
      (for (I . F) (=: fields (make (run "Prg")))
         (put F 'ix I) )
      (endPnl> (last (: fields)) *PnlCnt) ) )

(dm init> ()
   (=: focus)
   (mapc 'init> (: fields))
   (mapc 'init> (: arrays))
   (upd> This) )

(dm upd> ()
   (mapc 'upd> (: fields))
   (mapc 'upd> (: arrays)) )

(dm lock> (Flg)
   (=: lock Flg)
   (upd> This) )

(dm show> ()
   (let N 0
      (map
         '((F)
            (with (car F)
               (unless (=0 N)
                  (prin (if (: +) "</TD></TR><TR><TD>" "</TD><TD>")) )
               (do (: *)
                  (inc 'N)
                  (prin "<TABLE><TR><TD>") )
               (show> This)
               (do (: **)
                  (dec 'N)
                  (prin "</TD></TR></TABLE>") ) ) )
         (: fields) ) )
      (when (: focus)
         (prinl "<script type=\"text/javascript\">")
         (prinl "document.forms[" (: focus fox) "].elements[0].focus();")
         (prinl "document.forms[" (: focus fox) "].elements[0].select();")
         (prinl "</script>") ) )

(dm help> ())


### Form Prefix Classes ###
(class +View)
# "view"

(dm T (Exe . @)
   (=: "view" Exe)
   (pass extra) )

(dm upd> ()
   (lock> This (eval (: "view")))
   (extra) )


### Dialogs ###
(class +Dialog +Form)
# top args

(dm T ("Ttl" "Lst" "Args")
   (=: top *Top)
   (super 0 0 "Lst")
   (=: args "Args") )

(dm init> ()
   (super)
   (mapc
      '((V F) (and V (set> F V)))
      (if (lst? (: args))
         (: args)
         (car (val (: args))) )
      (: fields) )
   (unless (lst? (: args))
      (mapc
         '((L B)
            (while L
               (put B (caar L) (cdr (pop 'L))) ) )
         (cdr (val (: args)))
         (: arrays) ) ) )

(dm show> ()
   (<hr>)
   (super)
   (<hr>) )

(dm stop> ()
   (unless (lst? (: args))
      (set (: args)
         (cons
            (mapcar 'val> (: fields))
            (mapcar 'stat> (: arrays)) ) ) )
   (show> (: top)) )


(de alert (Ttl @X)
   (html "Ttl"
      (<hr>)
      (<head> Ttl 3)
      (if (pair @X)
         (apply <br> @X)
         (<br> @X) )
      (<hr>) ) )

(de dialog ("Ttl" "Args" "Lst")
   (html "Ttl"
      (form "Ttl" '(+Dialog) "Ttl" "Lst" "Args") ) )

# Dialog Buttons
(de okButton (@Exe S Able)
   (gui '(+Able +Button) (or Able T) "" (or S "Ok")
      (cons 'prog
         (ifn @Exe
            '((=: home rv T) (stop> (: home)))
            (list
               (fill '(=: home rv @Exe))
               '(stop> (: home)) ) ) ) ) )

(de quitButton (S)
   (gui '(+Rid +Button) "" (or S ,"Cancel")
      '(stop> (: home)) ) )


### Busy/Progress indicator ###
(de busy ("Cnt" "Msg" . "Prg")
   (run "Prg") )

(de work ())


### Field Prefix Classes ###
(class +Sync)

(dm T @
   (pass extra) )


(class +Map +Sync)
# map

(dm T (Lst . @)
   (=: map Lst)
   (pass extra) )

(dm set> (Val)
   (extra
      (if
         (seek
            '((X) (= Val (cdar X)))
            (: map) )
         (caar @)
         Val ) ) )

(dm val> ()
   (let V (extra)
      (if (assoc V (: map))
         (cdr @)
         V ) ) )

(dm cho> ()
   (let H (pack (head (: sel) (chop (: str))))
      (mapcan
         '((X)
            (when (pre? H (car X))
               (cons (mkCho (car X) (cdr X))) ) )
         (: map) ) ) )


(class +Mac)
# mac

(dm T (Lst . @)
   (pass extra) )


(class +Macro +Sync +Mac)


# F2-Choice
(class +Cho)
# cho

(dm T (Foo . @)
   (=: cho Foo)
   (pass extra) )

(dm cho> ()
   (mapcar
      '((L)  # ("key" T  setFocus (quote . Obj))
         (cons
            ((: cho) (car L) (eval (cadddr L)))
            (cdr L) ) )
      (extra) ) )


(class +Uppc)

(dm set> (Str)
   (extra (uppc Str)) )


(class +Lowc)

(dm set> (Str)
   (extra (lowc Str)) )


# Field enable/disable
(class +Able)

(dm T (Exe . @)
   (=: able Exe)
   (put *Top 'able
      (cons This (get *Top 'able)) )
   (pass extra) )

(dm cho> ()
   (when (eval (: able))
      (extra) ) )


(class +Lock +Able)

(dm T @
   (pass super NIL) )


# Able prefix
(class +Skip)


# Escape from Form lock
(class +Rid)

(dm upd> ()
   (extra)
   (and
      (: home lock)
      (memq This (: home able)) ) )


# Field display
(class +Font)
# fnt siz

#? "Helvetica" "SansSerif" "serif" "Monospaced"
(dm T (Name Size . @)
   (=: fnt Name)
   (=: siz Size)
   (pass extra) )

(class +Mono +Font)

(dm T @
   (pass super "Monospaced" 12) )


(class +Align +Mono)

(dm set> (Val)
   (extra (and Val (align (: dx) Val))) )


(class +Limit +Sync)
# lim

(dm T (N . @)
   (=: lim N)
   (pass super) )

(dm chk> ()
   (or
      (and (> (length (: str)) (: lim)) ,"Text too long")
      (extra) ) )


(class +Color)
# bCol fCol

(dm T (B F . @)
   (=: bCol B)
   (=: fCol F)
   (pass extra) )


(class +Radio)
# radio

(dm T (Lst . @)
   (=: radio Lst)
   (pass extra) )

(dm set> (Val)
   (extra Val)
   (when Val
      (for "X" (: radio)
         (clr> (field "X")) ) ) )

(de radio (N Rows Cols)
   (make
      (let I (- Rows N)
         (do Rows
            (or (=0 I) (link (* I Cols)))
            (dec 'I) ) ) ) )


(class +Trigger)
# trigger

(dm T (Exe . @)
   (=: trigger Exe)
   (pass extra) )

(dm set> (Val)
   (extra Val)
   (and Val (eval (: trigger))) )


(class +Relay)
# relay

(de relay (Val)
   (for "X" (: relay)
      (cond
         ((atom "X")
            (and (field "X") (set> @ Val)) )
         ((not (cdr "X"))
            (and (field (car "X")) (upd> @)) )
         ((field (car "X"))
            (set> @
               (if (or (atom (cdr "X")) (lst? (cadr "X")))
                  ((cdr "X") Val)
                  (with Val (eval (cdr "X"))) ) ) ) ) ) )

(dm T (Lst . @)
   (=: relay Lst)
   (pass extra) )

(dm upd> ()
   (extra)
   (relay (val> This)) )

(dm set> (Val)
   (let Old (val> This)
      (extra Val)
      (let Val (val> This)
         (unless (= Old Val)
            (relay Val) ) ) ) )

(dm end> ()
   (extra)
   (relay (val> This)) )


(class +Hot)
# hot

(dm T (Exe . @)
   (=: hot Exe)
   (pass extra)
   (hotField) )

(dm act> ()
   (eval (: hot)) )


(class +Init)
# "init"

(dm T (Exe . @)
   (=: "init" Exe)
   (pass extra) )

(dm init> ()
   (eval (: "init"))
   (extra) )


(class +Start)
# "start"

(dm T (Exe . @)
   (=: "start" Exe)
   (pass extra) )

(dm start> ()
   (eval (: "start"))
   (extra) )


(class +Set)
# set

(dm T (Foo . @)
   (=: set Foo)
   (pass extra) )

(dm set> @
   (pass (: set)) )


(class +Dflt)
# dflt

(dm T (Exe . @)
   (=: dflt Exe)
   (pass extra) )

(dm set> (Val)
   (extra (or Val (eval (: dflt)))) )

(dm val> (Flg)
   (let? Val (extra Flg)
      (and (<> Val (eval (: dflt))) Val) ) )

(dm chk> ()
   (when (val> This)
      (extra) ) )


(class +Clr)
# clr

(dm T (Exe . @)
   (=: clr Exe)
   (pass extra) )

(dm clr> ()
   (eval (: clr)) )


(class +Fmt)
# set val

(dm T (Foo1 Foo2 . @)
   (=: set Foo1)
   (=: val Foo2)
   (pass extra) )

(dm set> (Val)
   (extra ((: set) Val)) )

(dm val> ()
   ((: val) (extra)) )


(class +Upd)
# upd

(dm T (Exe . @)
   (=: upd Exe)
   (pass extra) )

(dm upd> ()
   (eval (: upd)) )


(class +Var)
# var

(dm T (Var . @)
   (=: var Var)
   (pass extra) )

(dm set> (Val)
   (extra (set (: var) Val)) )

(dm upd> ()
   (extra)
   (set> This (val (: var))) )


(class +Beg)
# beg

(dm T (Exe . @)
   (=: beg Exe)
   (pass extra) )

(dm beg> ()
   (eval (: beg))
   (extra) )


(class +Chg)
# chg

(dm T (Exe . @)
   (=: chg Exe)
   (pass extra) )

(dm chg> ()
   (let S (: str)
      (extra)
      (unless (= S (: str))
         (eval (: chg)) ) ) )


(class +Chk)
# chk

(dm T (Exe . @)
   (=: chk Exe)
   (pass extra) )

(dm chk> ()
   (eval (: chk)) )


(class +End)
# end

(dm T (Exe . @)
   (=: end Exe)
   (pass extra) )

(dm end> ()
   (eval (: end)) )


### Form Field Classes ###
(class +field)
# home lay ix fox + * ** lbl str ign arr able

(dm T ()
   (setq *Fld This)
   (when (=T *PnlFld)
      (setq *PnlFld This) )
   (=: home *Top)
   (and *LayRow (=: + T))
   (and *LayPnl (=: * 1) (inc '*PnlCnt))
   (link This) )

(dm arr> ()
   T )

(dm endPnl> (N)
   (dec '*PnlCnt N)
   (if (:: **)
      (inc @ N)
      (=: ** N) ) )

(dm init> ()
   (when (assoc (: ix) *Fld)
      (=: str (cdr @))
      (=: home focus This)
      (unless (: ign)
         (if (or (chk> This) (and (: arr) (chk> (: arr))))
            (let Err @
               (prinl
                  (if (: lbl)
                     (cons
                        (pack "*** " @ " ***")
                        (if (pair Err) Err (cons Err)) )
                     Err ) ) )
            (end> This)
            (and (: arr) (end> @))
            (and
               (find
                  '((F)
                     (and (get F 'fox) (able?> F)) )
                  (cdr (memq This (: home fields))) )
               (=: home focus @) ) ) ) ) )

(dm upd> ())
(dm chk> ())
(dm end> ())
(dm cho> ())

(dm str> (Str)
   (=: str Str) )

(dm set> (Val)
   (str> This Val) )

(dm clr> ()
   (set> This) )

(dm val> ())

(dm able?> ()
   (or
      (not (memq This (: home able)))
      (eval (: able)) ) )

(dm scr> (N)
   (scr> (: arr) N) )


# Mark hot link field (blue foreground)
(de hotField ()
   )  #?

# Get field
(de field (X)
   (if (sym? X)
      (get (: home) X)
      (get (: home fields) (+ X (: ix))) ) )

# Get current chart data row
(de curr @
   (pass get
      (pick
         '((F D) (and (memq This F) D))
         (: arr fields)
         (nth (: arr data) (: arr ofs)) ) ) )


(class +txt +field)

(dm T (Str)
   (=: str Str)
   (pass super) )

(dm arr> ())

(dm show> ()
   (ht:Prin (: str)) )


(class +Button +field)
# exe

(dm T (Lbl Str Exe . @)
   (=: lbl Lbl)
   (=: str Str)
   (=: exe Exe)
   (=: ign T)
   (pass super) )

(dm show> ()
   (and (: lbl) (prin @ "</TD><TD>"))
   (prin
      "[<A HREF=\""
      *SesId "@act?" (ht:Fmt (: home app) (: ix)) "\""
      (and *Frame " TARGET=\"MAIN\"")
      ">" )
   (ht:Prin (: str))
   (prinl "</A>]") )

(dm act> ()
   (eval (: exe)) )

(dm set> (Val)
   (=: str Val)
   (super Val) )

(dm val> ()
   (: str) )


(class +SetButton +Button)

(dm act> ()
   (when (super)
      (let (Val @  Fld (get (: home fields) (inc (: ix))))
         (if (=T Val)
            (clr> Fld)
            (set> Fld Val) ) ) ) )


(class +ChgButton +Button)
# chg

(dm T (Lbl Str Foo . @)
   (=: chg Foo)
   (pass super Lbl Str
      '(let
         (Fld (get (: home fields) (inc (: ix)))
            Val ((: chg) (val> Fld)) )
         (when Val
            (if (=T Val)
               (clr> Fld)
               (set> Fld Val) ) ) ) ) )


(class +ClrButton +Button)
# clr

(dm T (Lbl Str Lst . @)
   (=: clr Lst)
   (pass super Lbl Str
      '(prog
         (for X (: clr)
            (if (atom X)
               (clr> (get (: home) X))
               (set> (get (: home) (car X)) (eval (cdr X))) ) ) ) ) )


(class +Checkbox +field)

(dm T (Lbl . @)
   (=: lbl Lbl)
   (pass super) )

(dm show> ()
   (and (: lbl) (prin @ "</TD><TD>"))
   (prinl
      "[<A HREF=\"" *SesId (: home app) "&*Fld(" (ht:Fmt (: ix)) ")="
      (if (: str) " " "X")
      "\">"
      (if (: str) "X" " ")
      "</A>]" ) )

(dm set> (Val)
   (super (=: str (bool Val))) )

(dm val> ()
   (bool (: str)) )


(class +Label +field)

(dm T (Lbl Str . @)
   (=: lbl Lbl)
   (=: str Str)
   (=: ign T)
   (pass super) )

(dm show> ()
   (and (: lbl) (prin @ "</TD><TD>"))
   (prin (: str)) )


(class +DrawField +field)


(class +PictField +field)

(dm show> ())


(class +TextField +field)
# dx dy

# (lbl dx [dy])
# (lbl lst)
(dm T (Lbl . @)
   (=: lbl Lbl)
   (=: dx (next))
   (=: fox (inc '*Fox))
   (pass super) )

(dm show> ()
   (and (: lbl) (prin @ "</TD><TD>"))
   (<post> (: home app)
      (prin
         "<INPUT TYPE=TEXT NAME=\"*Fld("
         (ht:Fmt (: ix))
         ")\" VALUE=\"" )
      (ht:Prin (: str))
      (prinl "\" SIZE=" (: dx) ">") ) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Val)
   (str> This Val) )

(dm val> ()
   (: str) )


(class +ListTextField +TextField)
# split

(dm T (C . @)
   (=: split C)
   (pass super) )

(dm set> (Val)
   (super (glue (: split) Val)) )

(dm val> ()
   (mapcar pack (split (chop (super)) (: split))) )


# Matchcode Field
(class +McField +Uppc +TextField)


# Secure Transmission Field Prefix
(class +Rsa)


# Password Field
(class +PwField +Rsa +TextField)

(dm show> ()
   (and (: lbl) (prin @ "</TD><TD>"))
   (<post> (: home app)
      (prinl
         "<INPUT TYPE=PASSWORD NAME=\"*Fld("
         (ht:Fmt (: ix))
         ")\" SIZE=" (: dx) ">" ) ) )


# Symbol Fields
(class +SymField +TextField)

(dm val> ()
   (let S (super)
      (and (<> "-" S) (intern S)) ) )


# Class Fields
(class +ClsField +Map +TextField)
# cls

(dm T (Exe Lbl Lst)
   (=: cls Exe)
   (super Lst Lbl (mapcar car Lst)) )

(dm upd> ()
   (set> This (val (eval (: cls)))) )

(dm set> (Val)
   (when (eval (: cls))
      (set @ Val) )
   (super Val) )


(class +DigField +Align +TextField)


(class +NumField +DigField)

(dm set> (Val)
   (super (format Val)) )

(dm val> ()
   (format (super)) )


(class +IntField +NumField)


(class +FixField  +Align +TextField)
# scl

(dm T (N . @)
   (=: scl N)
   (pass super) )

(dm set> (Val)
   (super (format Val (: scl) *Sep0 *Sep3)) )

(dm val> ()
   (let (S (super)  L (chop S))
      (unless (member *Sep0 L)
         (setq S (pack S *Sep0)) )
      (format S (: scl) *Sep0 *Sep3) ) )


# Number- or String-Field
(class +AtomField +Mono +TextField)

(dm set> (Val)
   (super
      (if (num? Val)
         (align (: dx) (format Val))
         Val ) ) )

(dm val> ()
   (let S (super)
      (or (format S) S) ) )


(class +DateField +TextField)

(dm cho> ()
   (let (D (or (val> This) (date))  I (- D 8))
      (make
         (do 15
            (link
               (mkCho
                  (pack
                     (datStr (inc 'I))
                     " ("
                     (day I)
                     ")"
                     (and (= D I) " <--") )
                  I ) ) ) ) ) )

(dm set> (Val)
   (super (datStr Val)) )

(dm val> ()
   (expDat (super)) )

(dm chk> ()
   (and
      (: str)
      (not (val> This))
      ,"Bad date format" ) )


(class +TimeField +TextField)

(dm cho> ()
   (let Tim (time)
      (list (mkCho (tim$ Tim (> (: dx) 6)) Tim)) ) )

(dm set> (Val)
   (super (tim$ Val (> (: dx) 6))) )

(dm val> ()
   ($tim (super)) )

(dm chk> ()
   (and
      (: str)
      (not (val> This))
      ,"Bad time format" ) )


(class +FileField +TextField)
# file org

(dm T (Exe . @)
   (=: file Exe)
   (pass super) )

(dm upd> ()
   (set> This
      (=: org
         (let F (eval (: file))
            (and F (info F) (in F (till NIL T))) ) ) ) )

(dm set> (Val)
   (and
      (<> Val (: org))
      (eval (: file))
      (out @ (prin Val)) )
   (super Val) )


(class +HttpField +TextField)

(dm T @
   (pass super)
   (hotField) )

#(dm act> ()
#   (when (val> This)
#      (let Val @
#         (out *App
#            (pr
#               (: home id) "url"
#               (if (sub? ":/" Val) Val (pack "http://" Val))
#               "HTTP" ) ) ) ) )


(class +MailField +TextField)

(dm T @
   (pass super)
   (hotField) )

#(dm act> ()
#   (when (val> This)
#      (out *App
#         (pr (: home id) "url" (pack "mailto:" @) "MAIL") ) ) )


### Field Arrays ###
(class +array)
# home fields

(dm T ()
   (=: home *Top)
   (put *Top 'arrays
      (conc (get *Top 'arrays) (cons This)) ) )

(dm init> ())

(dm upd> ())

(dm chk> ())
(dm end> ())

(dm set> ())
(dm val> ())
(dm stat> ())

(dm clr> ()
   (set> This) )


(class +Array +array)
# put get

# (.. ttl cols foo lst [put [get]])
(dm T ("Ttl" "N" "Foo" "Lst" "Put" "Get")
   (super)
   (txt "Ttl")
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (=: fields
      (mapcan
         '((F)
            (link F)
            (put F 'arr This)
            (and (arr> F) (cons F)) )
         (make
            (while "Lst"
               (let *LayRow T
                  (do "N"
                     ("Foo" (pop '"Lst"))
                     (NIL "Lst")
                     (off *LayRow) ) ) ) ) ) ) )


(class +chart +array)
# rows cols put get ofs lock

# (.. rows lst prg [put [get]])
(dm T ("N" "Lst" "Prg" "Put" "Get")
   (super)
   (=: rows 0)
   (apply txt "Lst")
   (=: cols (length "Prg"))
   (=: ofs 1)
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (=: fields
      (mapcar
         '((L)
            (mapcan
               '((F)
                  (link F)
                  (put F 'arr This)
                  (and (arr> F) (cons F)) )
               L ) )
         (make
            (do "N"
               (inc (:: rows))
               (let *LayRow T
                  (link
                     (make
                        (for L "Prg"
                           (eval L)
                           (off *LayRow) ) ) ) ) ) ) ) )
   (=: lock
      (not
         (find
            '((F) (nor (isa '+Button F) (isa '+Lock F)))
            (: fields 1) ) ) ) )


(class +Chart +chart)
# data clip

(dm put> ()
   (mapc
      '((F D)
         (mapc 'set> F ((: put) D)) )
      (: fields)
      (nth (: data) (: ofs)) )  )

(dm get> ()
   (unless (: lock)
      (map
         '((F D)
            (set D
               (trim
                  ((: get)
                     (mapcar '((F) (val> F)) (car F))
                     (car D) ) ) ) )
         (: fields)
         (nth
            (=: data
               (need
                  (- 1 (: ofs) (: rows))
                  (: data) ) )
            (: ofs) ) )
      (=: data (trim (: data))) ) )

(dm size> ()
   (length (: data)) )

(dm upd> ()
   (get> This)
   (put> This) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Lst)
   (unless (= Lst (: data))
      (let N (- (length Lst) (: rows) -1)
         (when (> (: ofs) N)
            (=: ofs (max 1 N)) ) )
      (=: data (copy Lst)) )
   (put> This) )

(dm val> ()
   (get> This)
   (: data) )

(dm stat> ()
   (list
      (cons 'ofs (: ofs))
      (cons 'data (: data)) ) )


(class +ListChart +Chart)

(dm set> (Lst)
   (super (mapcar list Lst)) )

(dm val> ()
   (mapcar car (super)) )


### DB GUI ###
(de newUrl ("Typ" . @)
   (prog1
      (pass new! "Typ")
      (url (url> @)) ) )

(de <id> (Ttl . Lst)
   (with *ID
      (prin
         "<TABLE WIDTH=\"100%\"><TR><TD ALIGN=\"LEFT\"><H3>"
         (and (: T) "[") )
      (ht:Prin Ttl)
      (prin " --")
      (while Lst
         (prin " " (eval (pop 'Lst))) )
      (prin
         (and (: T) "]")
         "</H3></TD><TD ALIGN=\"RIGHT\">" )
      (navi)
      (prinl "</TD></TR></TABLE>") ) )


### Dialog Components ###
(de hotButton (Str)
   (gui '(+Able +Button)
      '(or
         (isa '+Hot (: home focus2))
         (isa '+Obj (: home focus2))
         (isa '+ObjView (: home focus2)) )
      "" Str
      '(act> (: home focus2)) ) )

(de clrButton (Str)
   (gui '(+Button) "" Str
      '(prog (=: home rv T) (stop> (: home))) ) )

(de stepButton (Var Cls Hook)
   (let
      (Key
         (if (isa '+Key (get Cls Var))
            (get *Top 'obj Var)
            (cons (get *Top 'obj Var) (get *Top 'obj)) )
         Q (init (tree Var Cls Hook) Key T)
         U (and (step Q) (step Q) (url> @)) )
      (when U
         (gui '(+Rid +Button) "" ,"Next data record"
            (list 'url U) ) ) ) )

(de choButton (Exe)
   (gui 'hot '(+Rid +Button) "" ,"Choose/Create" Exe) )

(de cloneButton ()
   (gui '(+Button) "" ,"New/Copy"
      '(url (url> (clone!> (: home obj)))) ) )

# Delete object in +ObjForm
(de delButton (Able)
   (gui '(+Able +Button)
      (ifn Able
         '(and (: home obj) (not (: home obj T)))
         (list 'and '(: home obj) '(not (: home obj T)) Able) )
      "" ,"Delete"
      '(when (ask ,"Delete" ,"Delete this data record?")
         (lose!> (: home obj))
         (and (: home obj) (url> @) (url @)) ) ) )

(de closeButton ()
   (quitButton ,"Close") )

(====)
# Choose object for +ObjForm
# (choDialog Ttl Rel [Hook] [(+Obj +TextField) [pre [post]]])
(de choDialog ("Ttl" "Rel" . @)
   (let
      ("Hook" (and (meta (cdr "Rel") (car "Rel") 'hook) (next))
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
      (dialog (pack "Ttl" ,"-Choice") NIL
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
               (gui '(+Button) "" ,"Create"
                  '(with (: home fields 1)
                     (if (meta (: objTyp) (: objVar) 'hook)
                        (newUrl (: objTyp) @ (eval (: objHook)))
                        (newUrl (: objTyp)) ) ) ) )
            (---- T)
            (gui '(+IndexChart)
               (cons
                  (car "Rel")
                  (cons
                     (meta (cdr "Rel") (car "Rel") 'cls)
                     (lit "Hook") ) )
               8 NIL '((apply gui "Lst")) ) ) ) ) )
(====)


### Object Linkage ###
(class +ObjForm +Form)
# typ obj

(dm T ("Typ" "Obj" . @)
   (=: typ "Typ")
   (=: obj (extern "Obj"))
   (pass super) )

(dm set> (Obj)
   (=: obj Obj) )

(dm val> ()
   (: obj) )


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
      (put!> @ (: erVar) Val)
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
      (put!> @ (: erVar) (bool Val))
      (extra
         (and Val
            (allow (blob (eval (: erObj)) (: erVar))) ) ) ) )


(class +ClassField +Map +TextField)
# erObj

(dm T (Exe Lbl Lst)
   (=: erObj Exe)
   (super Lst Lbl (mapcar car Lst)) )

(dm upd> ()
   (set> This (val (eval (: erObj)))) )

(dm set> (Val)
   (when (eval (: erObj))
      (set!> @ Val) )
   (super Val) )


# Blue Background Prefix
(class +Bg)


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
   (when (meta (: objTyp) (: objVar) 'hook)
      (=: objHook (next)) )
   (pass super)
   (hotField) )

(dm show> ()
   (cond
      ((able?> This) (extra))
      ((and (val> This) (url> @))
         (<href> (: str) @) )
      (T (do (: dx) (prin '.))) ) )

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
            (let Cls (meta (: objTyp) (: objVar) 'cls)
               (=: obj
                  (if (: objHook)
                     (db (: objVar) Cls (eval @) V)
                     (db (: objVar) Cls V) ) ) ) ) ) ) )

(dm cho> ()
   (let Q (objQuery)
      (mapcar
         '((R) (mkCho (get R (: objVar)) R))
         (make
            (while
               (and
                  (asoq '@@ (prove Q))
                  (let S (cdr @)
                     (or
                        (member S (made))
                        (prog (link S) (> 40 (length (made)))) ) ) ) ) ) ) ) )

(dm act> ()
   (ifn (and (: obj) (url> @))
      (beep> (: home))
      (url @) ) )

(dm chk> ()
   (or
      (extra)
      (and
         (: str)
         (not (val> This))
         (<> "-" (: str))
         ,"Data not found" ) ) )

(dm query> (X)
   (let Cls (meta (: objTyp) (: objVar) 'cls)
      (if (num? X)
         (list  # ((db var +Cls (<N> . T) @@) (isa +Cls @@))
            (make
               (link 'db (: objVar) Cls)
               (when (: objHook)
                  (link (eval @)) )
               (link (cons X T) '@@) )
            (list 'isa Cls '@@) )
         (list  # ((db var +Cls "Str" @@) (isa +Cls @@) (head "Str" @@ var))
            (make
               (link 'db (: objVar) Cls)
               (when (: objHook)
                  (link (eval @)) )
               (link X '@@) )
            (list 'isa Cls '@@)
            (list 'head X '@@ (: objVar)) ) ) ) )


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


# Index Tree Chart
(class +IndexChart +chart)
# tree beg end

# (.. tree rows lst prg [put])
(dm T ("Tree" "N" "Lst" "Prg" "Put")
   (=: tree "Tree")
   (super "N" "Lst" "Prg" (or "Put" cons)) )

(dm put> ()
   (let Node
      (init
         (tree
            (car (: tree))
            (cadr (: tree))
            (eval (cddr (: tree))) )
         (: beg) (: end) )
      (do (dec (: ofs))
         (step Node T) )
      (for F (: fields)
         (mapc 'set> F ((: put) (step Node T))) ) ) )

(dm upd> ()
   (put> This) )

(dm get> ())

(dm size> ()
   (count
      (tree
         (car (: tree))
         (cadr (: tree))
         (eval (cddr (: tree))) ) ) )

(dm set> (Beg End)
   (=: beg Beg)
   (=: end End)
   (put> This) )
