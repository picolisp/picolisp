# 16mar06abu
# (c) Software Lab. Alexander Burger

# *DelBtn
# "*Var" "*Dlg" "*Err" "*Ix" "*Array" "*Row"

(off "*Dlg")

# Define GUI form
(de form ("*Var" "Attr" . "Prg")
   (when "*Dlg"
      (put (car "*Dlg") T "*Var")
      (let *Post NIL (apply "form" "*Dlg"))
      (off "*Dlg") )
   ("form" "*Var" "Attr" "Prg") )

(de "form" ("*Var" "Attr" "Prg")
   (with (allow "*Var")
      (<post> "Attr" *Url
         (<hidden> '*Post "*Var")
         (zero "*Ix")
         (if *Post
            (let gui
               '(()
                  (with (get "*Var" 'gui (inc '"*Ix"))
                     (if (: id)
                        (show> This (cons "*Var" @))
                        (zero "*Row")
                        (setq "*Array" This) )
                     This ) )
               (when (= *Post "*Var")
                  (for X "*Err"
                     (<p> 'err (ht:Prin X)) ) )
               (htPrin 1 "Prg") )
            (set "*Var")
            (putl "*Var" (list (cons (: T) T)))
            (let gui
               '(@
                  (inc '"*Ix")
                  (with
                     (cond
                        ((pair (next)) (pass new @))
                        ((num? (arg))
                           (with "*Array"
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
                                          I ) )
                                    (put Fld 'arr (list This (: rows) I))
                                    Fld ) ) ) )
                        ((get "*Var" (arg)) (quit "gui conflict" (arg)))
                        (T (put "*Var" (arg) (pass new))) )
                     (or (: id) (zero "*Row"))
                     (init> (link This))
                     (and (: id) (show> This (cons "*Var" (: id))))
                     This ) )
               (put "*Var" 'gui (make (htPrin 1 "Prg"))) ) ) ) ) )

# Handle form actions
(de action Prg
   (off "*Err")
   (catch "url"
      (with (setq "*Var" (intern *Post))
         (for This (: gui)
            (unless (lt0 (: id))
               (or (: id) (setq "*Array" This))
               (cond
                  ((chk> This) (err @))
                  ((not (: arr)) (chg> This)) ) ) )
         (for This (: gui)
            (ifn (: id)
               (setq "*Array" This)
               (when (lt0 (: id))
                  (let? A (assoc (: id) (val "*Var"))
                     (let? V (cdr A)
                        (con A)
                        (and
                           (eval (: able))
                           (not "*Err")
                           (act> This V) ) ) ) ) ) )
         (for This (: gui)
            (or (: id) (setq "*Array" This))
            (upd> This) ) )
      (run Prg 1) ) )

(de err (Str)
   (queue '"*Err" Str) )

(de url (Url . @)
   (when Url
      (setq *Url Url  Url (chop Url))
      (off *Post)
      (cond
         ((= '@ (car Url))
            (pass (intern (pack (cdr Url)))) )
         ((tail '("." "l") Url)
            (while (args)
               (set (next) (next)) )
            (load *Url) )
         ((assoc (stem Url ".") *Mimes)
            (apply httpEcho (cdr @) *Url) )
         (T (httpEcho *Url "application/octet-stream" 1 T)) )
      (throw "url") ) )

(de mkUrl (Lst)
   (pack (car Lst) '?
      (if (= `(char '@) (char (pop 'Lst)))
         (apply 'ht:Fmt Lst)
         (make
            (while Lst
               (link (pop 'Lst) '= (ht:Fmt (pop 'Lst)))
               (and Lst (link '&)) ) ) ) ) )

# Return array property
(de arr Lst
   (apply get Lst "*Array") )

# Return current data row from array/chart
(de row ()
   (with "*Array"
      (get (: data) (+ (: ofs) (inc '"*Row") -1)) ) )

# Scroll chart
(de scroll (N)
   (with "*Array"
      (get> This)
      (unless (gt0 (inc (:: ofs) N))
         (=: ofs 1) )
      (put> This) ) )


### Dialogs ###
(de dialog (Var . Prg)
   (setq "*Dlg" (list Var 'dialog Prg)) )

(de alert (Var . Prg)
   (setq "*Dlg" (list Var 'alert Prg)) )

(de okButton (Exe)
   (gui '(+Button) "Ok" Exe) )

(de yesButton (Exe)
   (gui '(+Button) ,"Yes" Exe) )

(de noButton (Exe)
   (gui '(+Button) ,"No" Exe) )


### Field Prefix Classes ###
(class +Set)
# set

(dm T (Foo . @)
   (=: set Foo)
   (pass extra) )

(dm set> @
   (pass (: set)) )


(class +Init)
# init

(dm T (Val . @)
   (=: init Val)
   (pass extra) )

(dm init> ()
   (set> This (: init)) )


(class +Map)
# map

(dm T (Lst . @)
   (=: map Lst)
   (pass extra) )

(dm set> (Val)
   (extra
      (val
         (car
            (find
               '((X) (= Val (cdr X)))
               (: map) ) ) ) ) )

(dm val> ()
   (let V (extra)
      (cdr
         (find
            '((X) (= V (val (car X))))
            (: map) ) ) ) )


# Field enable/disable
(class +Able)

(dm T (Exe . @)
   (pass extra)
   (=: able Exe) )


(class +Lock +Able)

(dm T @
   (pass super NIL) )


(class +Align)

(dm T @
   (=: align T)
   (pass extra) )


(class +Limit)
# lim

(dm T (N . @)
   (=: lim N)
   (pass extra) )


(class +Var)
# var

(dm T (Var . @)
   (=: var Var)
   (pass extra) )

(dm set> (Val)
   (extra (set (: var) Val)) )

(dm init> ()
   (set> This (val (: var))) )

(dm upd> ()
   (set> This (val (: var))) )


### Form Field Classes ###
(de showFld "Prg"
   (when (: lbl)
      (prin "<label>")
      (ht:Prin (eval @)) )
   (if (eval (: able))
      (eval (car "Prg"))
      (run (cdr "Prg")) )
   (and (: lbl) (prinl "</label>")) )


(class +gui)
# home id chg able arr

(dm T ()
   (=: home "*Var")
   (push "*Var" (cons (=: id "*Ix")))
   (=: able T) )

(dm set> (Str))

(dm clr> ()
   (set> This) )

(dm val> ())

(dm init> ())

(dm chg> ())

(dm upd> ())

(dm chk> ())


(class +field +gui)

(dm T ()
   (super)
   (=: chg T) )

(dm set> (Str)
   (con (assoc (: id) (val (: home))) Str) )

(dm str> ()
   (cdr (assoc (: id) (val (: home)))) )

(dm val> ()
   (cdr (assoc (: id) (val (: home)))) )

(dm chg> ()
   (set> This (val> This)) )


# Get field
(de field (X)
   (if (sym? X)
      (get (: home) X)
      (get (: home gui) (+ X (abs (: id)))) ) )

# Get current chart data row
(de curr @
   (pass get (: arr 1 data) (+ (: arr 1 ofs) (: arr 2) -1)) )


(class +Button +gui)
# lbl alt act

(dm T (Lbl . @)
   (=: lbl Lbl)
   (let X (next)
      (ifn (args)
         (=: act X)
         (=: alt X)
         (=: act (next)) ) )
   (super)
   (set
      (car (val "*Var"))
      (=: id (- (: id))) ) )

(dm show> ("Var")
   (let (Lbl (eval (: lbl))  Foo (if (pre? "img/" Lbl) <image> <submit>))
      (cond
         ((eval (: able)) (Foo Lbl "Var"))
         ((eval (: alt)) (Foo @ "Var"))
         (T (ht:Prin "[" Lbl "]")) ) ) )

(dm act> (Val)
   (and (eval (: able)) (eval (: act))) )


(class +UpButton +Able +Button)

(dm T (N Lbl Alt)
   (super
      '(> (arr ofs) 1)
      (or Lbl "\^")
      (or Alt "=")
      (list 'scroll (- N)) ) )


(class +DnButton +Able +Button)

(dm T (N Lbl Alt)
   (super
      (list '>= '(length (arr data)) (list '+ N '(arr ofs)))
      (or Lbl "v")
      (or Alt "=")
      (list 'scroll N) ) )


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

(dm show> ("Var")
   (showFld
      (<check> "Var")
      (prin "[" (if (val> This) "X" " ") "]") ) )

(dm set> (Val)
   (super (bool Val)) )

(dm val> ()
   (bool (super)) )


(class +TextField +field)
# dx|lst lbl lim align

# (dx [lbl])
# (lst [lbl])
(dm T (X Lbl)
   (if (num? X)
      (=: dx X)
      (=: lst X) )
   (=: lbl Lbl)
   (super) )

(dm show> ("Var")
   (showFld
      (if (: dx)
         (<field>
            (if (: align) (- (: dx)) (: dx))
            "Var"
            (: lim) )
         (<select> (mapcar val (: lst)) "Var") )
      (ht:Prin (str> This)) ) )


# Password Field
(class +PwField +TextField)

(dm show> ("Var")
   (showFld
      (<passwd> (: dx) "Var")
      (prin '====) ) )


# Symbol Fields
(class +SymField +TextField)

(dm val> ()
   (let S (super)
      (and (<> "-" S) (intern S)) ) )


(class +NumField +Align +TextField)

(dm set> (Val)
   (super (format Val)) )

(dm val> ()
   (format (super)) )

(dm chk> ()
   (and
      (str> This)
      (not (format @))
      ,"Numeric input expected" ) )


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


(class +DateField +TextField)

(dm set> (Val)
   (super (datStr Val)) )

(dm val> ()
   (expDat (super)) )

(dm chk> ()
   (and
      (str> This)
      (not (val> This))
      ,"Bad date format" ) )


(class +TimeField +TextField)

(dm set> (Val)
   (super (tim$ Val (> (: dx) 6))) )

(dm val> ()
   ($tim (super)) )

(dm chk> ()
   (and
      (str> This)
      (not (val> This))
      ,"Bad time format" ) )




### GUI Arrays ###
(class +array)
# home gui

(dm T ()
   (setq "*Array" This)
   (=: home "*Var")
   (put "*Var" 'arrays
      (conc (get "*Var" 'arrays) (cons This)) ) )

(dm set> (Lst))

(dm clr> ()
   (set> This) )

(dm val> ())

(dm init> ())

(dm chg> ()
   (set> This (val> This)) )

(dm upd> ())

(dm chk> ())


(class +Array +array)
# put get


(class +chart +array)
# rows cols ofs lock put get

# (.. cols [put [get]])
(dm T (N Put Get)
   (super)
   (=: rows 1)
   (when N
      (=: gui (list (need (=: cols N)))) )
   (=: ofs 1)
   (=: lock T)
   (=: put (or Put prog1))
   (=: get (or Get prog1)) )


(class +Chart +chart)
# data

(dm put> ()
   (mapc
      '((G D)
         (unless (memq NIL G)
            (mapc 'set> G ((: put) D)) ) )
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

(dm size> ()
   (length (: data)) )

(dm set> (Lst)
   (unless (= Lst (: data))
      (let N (- (length Lst) (: rows) -1)
         (when (> (: ofs) N)
            (=: ofs (max 1 N)) ) )
      (=: data (copy Lst)) )
   (put> This)
   (: data) )

(dm val> ()
   (get> This)
   (: data) )


### DB GUI ###
(de newUrl @
   (prog1
      (pass new!)
      (apply url (url> @)) ) )

# Delete object in form
(de delButton (Able)
   (gui '(+Able +Button)
      (if Able
         (list 'and '(: home obj) '(not (: home obj T)) @)
         '(and (: home obj) (not (: home obj T))) )
      ,"Delete"
      '(alert '*DelBtn
         (<h3> NIL ,"Delete")
         ,"Delete this data record?"
         (yesButton '(lose!> (: home T obj)))
         (noButton) ) ) )


(class +/R)
# erVar erObj

(dm T (Lst . @)
   (=: erVar (car Lst))
   (=: erObj (cdr Lst))
   (pass extra) )

(dm init> ()
   (set> This (get (eval (: erObj)) (: erVar))) )

(dm upd> ()
   (set> This (get (eval (: erObj)) (: erVar))) )


(class +E/R +/R)

(dm set> (Val)
   (when (eval (: erObj))
      (put!> @ (: erVar) Val) )
   (extra Val) )

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

(dm T (Exe Lst)
   (=: erObj Exe)
   (super Lst (mapcar car Lst)) )

(dm init> ()
   (set> This (val (eval (: erObj)))) )

(dm upd> ()
   (set> This (val (eval (: erObj)))) )

(dm set> (Val)
   (when (eval (: erObj))
      (set!> @ Val) )
   (super Val) )


(class +Obj)
# msg obj

(dm T @
   (ifn (atom (next))
      (=: msg 'url>)
      (=: msg (arg))
      (next) )
   (=: objVar (car (arg)))
   (=: objTyp (cdr (arg)))
   (when (meta (: objTyp) (: objVar) 'hook)
      (=: objHook (next)) )
   (pass extra) )

(dm show> ("Var")
   (showFld
      (prog
         (prin "<table><td>")
         (if (and (: obj) (send (: msg) @))
            (<href> '> (mkUrl @))
            (prin '=) )
         (prin "</td><td>")
         (extra "Var")
         (prinl "</td></table>") )
      (if (and (: obj) (send (: msg) @))
         (<href> (str> This) (mkUrl @))
         (ht:Prin (str> This)) ) ) )

(dm set> (Obj)
   (extra (get (=: obj Obj) (: objVar))) )

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

(dm chk> ()
   (or
      (extra)
      (and
         (str> This)
         (not (val> This))
         (<> "-" (: str))
         ,"Data not found" ) ) )


# DB Query Chart
(class +QueryChart +Chart)
# iniR iniq quer query

# (.. iniR iniQ cols [put [get]])
(dm T (R Q N Put Get)
   (=: iniR R)
   (=: iniQ Q)
   (super N (or Put cons) (or Get car)) )

(dm init> ()
   (query> This (: iniQ)) )

(dm put> ()
   (while
      (and
         (>
            (+ "*Row" (: ofs))
            (- (length (: data)) (max (: rows) (: iniR))) )
         (asoq '@@ (prove (: quer))) )
      (=: data (conc (: data) (cons (cdr @)))) )
   (super) )

(dm query> (Q)
   (=: quer (copy (=: query Q)))
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
(de <id> ("Ttl" . "Lst")
   (with (if *Post (: obj) (=: obj *ID))
      (and (: T) (prin "["))
      (ht:Prin "Ttl")
      (prin " --")
      (for "X" "Lst"
         (ht:Prin " " (eval "X")) )
      (and (: T) (prin "]")) ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
