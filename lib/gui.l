# 22apr03abu
# (c) Software Lab. Alexander Burger

### Java Applet GUI ###
# *AppGate *AppPort *App *Apps *AppId *Top *Bar *Menu

(default *APorts 0)

(de *Events
   (act> . 1) (cmd> . 1) (key> . 1) (nxt> . 1) (rsa> . 1)
   (scr> . 2) (adv> . 2)
   (chg> . 3) (log> . 3)
   (clk> . 4) (drg> . 4) )

(de dispatch ()
   (timeout `(* 15 60000))
   (in *App
      (let S (rd)
         (cond
            ((not S) (bye))
            ((num? S))
            ((pair S))
            ((=T S) (push '*AppId (rd)))
            ((<> meth (val S))
               (out NIL (prinl ">> " S " <<")) )
            ((get *Apps (rd))
               (send S (setq *Top @)) )
            ((assoc S *Events)
               (do (cdr @) (rd)) ) ) ) ) )

(de url (Str Tar . @)
   (when Str
      (out *App
         (pr
            (get *Top 'id)
            "url"
            (pack
               (baseHRef)
               *SesId
               Str
               (and (args) (pack "?" (pass htFmt))) )
            (or Tar (if *Frame "MAIN" "_self")) ) ) ) )

(de bar (Ttl X Y Prg)
   (prinl Ttl "<hr>")
   (setq *Bar (new '(+Form) X Y Prg))
   (navi) )

(de initAppId ()
   (if *AppId
      (set (nth *Apps (=: id (pop '*AppId))) This)
      (=: id (+ 1 (length *Apps)))
      (queue '*Apps This) ) )


(class +Applet)
# id run

(dm T (A J DX DY . @)
   (unless *AppPort
      (task (setq "Sok1" (port *APorts '*AppPort))
         (task "Sok1")  # Only once
         (task -40000 40000
            (out *App (pr 0)) )
         (task (setq *App (or (listen "Sok1" 60000) (quit "Bad Applet")))
            (dispatch) ) ) )
   (initAppId)
   (prinl "<APPLET CODE=\"" A ".class\" ARCHIVE=\"" *SesId J
      "\" WIDTH=" DX " HEIGHT=" DY ">" )
   (prinl "<PARAM NAME=\"ID\" VALUE=\"" (: id) "\">")
   (prinl "<PARAM NAME=\"port\" VALUE=\"" *AppPort "\">")
   (when *AppGate
      (prinl "<PARAM NAME=\"gate\" VALUE=\"" *AppGate "\">") )
   (while (args)
      (prinl "<PARAM NAME=\"" (next) "\" VALUE=\"" (next) "\">") )
   (prinl "</APPLET>") )

(dm close> ()
   (set (nth *Apps (: id)))
   (out *App
      (pr (- (: id))) ) )

(dm init> ())

(dm start> ()
   (=: run T) )

(dm upd> ())

(dm paint> ())

(dm stop> ()
   (=: run) )

(dm esc> ()
   (beep> This) )

(dm rsa> ()
   (setq *OutN (rd)) )

(dm cmd> ()
   (eval (nth *Menu (rd) 3)) )

(dm beep> ()
   (out *App
      (pr (: id) "beep") ) )

(dm play> (X)
   (out *App
      (pr (: id) "play" X) ) )

(dm menu> (Ttl Lst)
   (out *App
      (pr (: id) "menu" Ttl (length Lst))
      (mapc
         '((L) (pr (car L) (eval (cadr L))))
         (setq *Menu Lst) ) ) )


### Applet Form ###
# *Lay

(class +Form +Applet)
# init fields arrays focus focus2 hot able lock rv

(de form @
   (if (pair (next))
      (pass new (arg))
      (pass new) ) )

(de gui @
   (pr *Lay)
   (cond
      ((pair (next)) (pass new (arg)))
      ((and (not (: fields)) (get *Top (arg)))
         (quit "Conflict" (arg)) )
      (T (put *Top (arg) (pass new (next)))) )
   (setq *Lay '+) )

(de txt @
   (pr *Lay)
   (pr (next) -1)  # Label WEST
   (while (args)
      (pr '- (next) 0) )  # SOUTH
   (setq *Lay '+) )

(de row "Prg"
   (_row) )

(de flow "Prg"
   (pr "[")
   (_row)
   (pr "]") )

(de _row ()
   (eval (pop '"Prg"))
   (while "Prg"
      (setq *Lay '-)
      (eval (pop '"Prg")) ) )

(de ---- (Flg)
   (setq *Lay (if Flg '/ '*)) )

(de -|- (Flg)
   (setq *Lay (if Flg ': '=)) )


(dm T (DX DY Prg)
   (super "Front" "pico.jar" DX DY)
   (=: init Prg) )

(dm init> ()
   (super)
   (out *App
      (pr (: id) "make")
      (let *Lay '*
         (=: fields (make (run (: init)))) )
      (pr NIL) )
   (let I 0
      (mapc
         '((F)
            (put F 'ix (inc 'I))
            (init> F) )
         (: fields) ) )
   (mapc 'init> (: arrays)) )

(dm start> ()
   (super)
   (mapc 'start> (: fields))
   (mapc 'start> (: arrays))
   (upd> This)
   (focus1> This) )

(dm focus1> ()
   (find
      '((F)
         (and
            (isa '+TextField F)
            (able?> F)
            (t (focus> F)) ) )
      (: fields) ) )

(dm upd> ()
   (super)
   (mapc
      '((F) (or (get F 'touch) (upd> F)))
      (: fields) )
   (mapc
      '((A) (or (get A 'touch) (upd> A)))
      (: arrays) )
   (able> This) )

(dm stop> ()
   (fieldEnd)
   (mapc 'stop> (: fields))
   (mapc 'stop> (: arrays))
   (super) )

(dm able> ()
   (unless (: lock)
      (mapc 'able> (: able)) ) )

(dm lock> (Flg)
   (out *App
      (pr (: id) "lock" (bool (=: lock Flg))) )
   (upd> This) )

(dm focus> (F)
   (=: focus F)
   (out *App
      (pr (: id) "focus" (get F 'ix)) ) )

(dm next> ()
   (out *App
      (pr (: id) "next") ) )

(dm menu> (F Ttl Lst)
   (out *App
      (pr (: id) "menu" (get F 'ix) Ttl (length Lst))
      (mapc
         '((L) (pr (car L) (eval (cadr L))))
         (setq *Menu Lst) ) ) )

(dm help> ())

# Events
# ix
(dm clk> ()
   (clk> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm drg> ()
   (drg> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm adv> ()
   (put (: fields) (rd) 'adv (rd)) )

(dm act> ()
   (let F (get (: fields) (rd))
      (and (fieldEnd) (= F (: focus)) (act> F))
      (when (get *Apps (: id))
         (out *App (pr (: id) "ack")) ) ) )

# sym
(dm key> ()
   (let X (rd)
      (when (: focus)
         (ifn (key> (: focus) X)
            (beep> This)
            (type> (: focus) @)
            (=: focus touch T)
            (and (: focus arr) (=: focus arr touch T)) ) ) ) )

(dm ret> ()
   (use (B L)
      (ifn
         (and
            (setq B (: focus arr))
            (isa '+Chart B)
            (setq L
               (seek
                  '((L) (memq (: focus) (car L)))
                  (get B 'fields) ) )
            (not
               (find 'able?> (cdr (memq (: focus) (car L)))) )
            (not
               (find '((L) (find 'able?> L)) (cdr L)) ) )
         (next> This)
         (focus> (car (last (get B 'fields))))
         (send 'DN> B) ) ) )

(de _boxSend X
   (ifn
      (mini
         '((F)
            (or
               (not (get F 'arr))
               (abs (- (: focus ix) (get F 'ix))) ) )
         (: fields) )
      (beep> This)
      (let A (get @ 'arr)
         (when (fieldEnd)
            (send (car X) A) ) ) ) )

(dm PGUP> ()
   (_boxSend PGUP>) )

(dm PGDN> ()
   (_boxSend PGDN>) )

(dm END> ()
   (_boxSend END>) )

(dm BEG> ()
   (_boxSend BEG>) )

(dm UP> ()
   (_boxSend UP>) )

(dm DN> ()
   (_boxSend DN>) )

(dm DEL> ()
   (_boxSend DEL>) )

(dm INS> ()
   (_boxSend INS>) )


# Help
(dm F1> ()
   (url (or (help> This) *Help)) )

# Choice
(dm F2> ()
   (if (and (not (: lock)) (: focus) (cho> (: focus)))
      (menu> This (: focus) `(_ "F2-Choice") @)
      (beep> This) ) )

# Field Hot-Action
(dm F3> ()
   (ifn (: focus)
      (beep> This)
      (when (fieldEnd)
         (act> (: focus)) ) ) )

# Form Hot-Action
(dm F4> ()
   (ifn (: hot)
      (beep> This)
      (when (fieldEnd)
         (act> (: hot)) ) ) )

# Undo
(dm F5> ()
   (if (: focus undo)
      (undo> (: focus))
      (beep> This) ) )

# Redo
(dm F6> ()
   (if (: focus redo)
      (redo> (: focus))
      (beep> This) ) )

(dm F7> ()
   (beep> This) )

(dm F8> ()
   (beep> This) )

(dm F9> ()
   (beep> This) )

(dm F10> ()
   (beep> This) )

(dm F11> ()
   (beep> This) )

(dm F12> ()
   (beep> This) )

# ix sym|flg sel
(dm chg> ()  # Change string
   (=: "last")
   (chg> (get (: fields) (rd))) )

# ix sym|flg sel
(dm log> ()  # Change string and log state
   (=: "last")
   (log> (get (: fields) (rd))) )

# ix
(dm nxt> ()
   (let F (get (: fields) (rd))
      (when (fieldEnd)
         (when (isa '+TextField F)
            (=: focus2 F) )
         (beg> (=: focus F)) ) ) )

# ix val
(dm scr> ()
   (let (N (rd)  P (rd))
      (when (fieldEnd)
         (scr> (get (: fields) N) P) ) ) )


# Clear undo/redo
(de zapUndo ()
   (mapc
      '((L) (mapc 'zapUndo> L))
      (: fields) ) )

# Enter value into current focus field
(de setFocus (Val)
   (set> (: focus) Val)
   (able> This)
   (next> This) )

# Field end processing
(de fieldEnd ()
   (cond
      ((not (: run)))
      ((not (: focus)) T)
      ((: focus ign) T)
      ((or (chk> (: focus)) (and (: focus arr) (chk> (: focus arr))))
         (let Err @
            (or
               (== (: "last") (: focus))
               (and (: top) (not (: on)))
               (nil
                  (=: "last" (: focus))
                  (beep> This)
                  (focus> (: "last"))
                  (alert "Check"
                     (if (: "last" lbl)
                        (cons
                           (pack "*** " @ " ***")
                           (if (pair Err) Err (cons Err)) )
                        Err ) )
                  (when (: "last" undo)
                     (undo> (: "last")) ) ) ) ) )
      (T
         (end> (: focus))
         (and (: focus arr) (end> @))
         (=: focus touch NIL)
         (and (: focus arr) (=: focus arr touch NIL))
         T ) ) )


### Form Prefix Classes ###
(class +View)
# "view"

(dm T (Flg . @)
   (=: "view" Flg)
   (pass extra) )

(dm init> ()
   (extra)
   (lock> This (: "view")) )


### Dialogs ###
(class +Dialog +Form)
# top on args

(dm T ("Ttl" "Lst" "Args")
   (initAppId)
   (out *App
      (pr (get (=: top *Top) 'id) "dialog" "Ttl" (: id)) )
   (=: init "Lst")
   (=: args "Args")
   (wait NIL (: on)) )

(dm init> ()
   (=: on T)
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
         (: arrays) ) )
   (start> This) )

(dm stop> ()
   (unless (lst? (: args))
      (set (: args)
         (cons
            (mapcar 'val> (: fields))
            (mapcar 'stat> (: arrays)) ) ) )
   (=: on)
   (super)
   (close> This)
   (setq *Top (: top)) )


(de alert (Ttl @X)
   (with
      (new '(+Dialog) Ttl
         (cons
            (fill
               (if (pair @X)
                  '(mapc txt '@X)
                  '(txt @X) ) )
            '((okButton)) ) )
      (wait NIL (not (: on))) ) )

(de ask (Ttl @X)
   (with
      (new '(+Dialog) Ttl
         (cons
            (fill
               (if (pair @X)
                  '(mapc txt '@X)
                  '(txt @X) ) )
            '((----)
               (row (okButton NIL `(_ "Yes")) (quitButton `(_ "No"))) ) ) )
      (wait NIL (not (: on)))
      (: rv) ) )

(de confirm ("Ttl" "@X" "Exe")
   (with
      (new '(+Dialog) "Ttl"
         (cons
            (fill
               (if (pair "@X")
                  '(mapc txt '"@X")
                  '(txt "@X") ) )
            (quote
               (----)
               (row
                  (okButton NIL `(_ "Yes"))
                  (gui '(+Button) "" `(_ "No")
                     '(prog (=: home rv 0) (stop> (: home))) )
                  (quitButton) ) ) ) )
      (wait NIL (not (: on)))
      (when (=T (: rv))
         (eval "Exe") )
      (: rv) ) )

(de dialog ("Ttl" "Args" "Lst")
   (with (new '(+Dialog) "Ttl" "Lst" "Args")
      (wait NIL (not (: on)))
      (: rv) ) )

# Dialog Buttons
(de okButton (@Exe S)
   (gui '(+Button) "" (or S "Ok")
      (cons 'prog
         (ifn @Exe
            '((=: home rv T) (stop> (: home)))
            (list
               (fill '(=: home rv @Exe))
               '(stop> (: home)) ) ) ) ) )

(de quitButton (S)
   (gui '(+Rid +Button) "" (or S `(_ "Cancel"))
      '(stop> (: home)) ) )


### Busy/Progress indicator ###
(====)
(off "Busy")

(class +BusyDialog +Dialog)
# prg work ind

(dm T (Ttl Cnt Prg Lst)
   (=: work Cnt)
   (=: prg Prg)
   (setq "Busy" This)
   (super Ttl Lst) )

(dm paint> ()
   (super)
   (run (: prg))
   (stop> This) )

(dm stop> ()
   (super)
   (off "Busy") )


# Busy/Progress utilities
(de busy ("Cnt" "Msg" . "Prg")
   (ifn *Top
      (run "Prg")
      (catch "busy"
         (new '(+BusyDialog) `(_ "Please wait") "Cnt" "Prg"
            (quote
               (mapc txt "Msg")
               (----)
               (row
                  (quitButton)
                  (gui 'ind '(+Mono +Label) "->" (pack "Cnt" "        ")) ) ) )
         (wait NIL (not "Busy")) ) ) )

(de work ()
   (when *Top
      (if "Busy"
         (with @
            (set> (: ind)
               (format (abs (dec (:: work)))) ) )
         (throw "busy") ) ) )
(====)


### Field Prefix Classes ###
(class +Sync)

(dm T @
   (pass extra)
   (pr "sync") )


(class +Map +Sync)
# map

(dm T (Lst . @)
   (=: map Lst)
   (pass super) )

(dm key> (C)
   (let H
      (pack
         (head (: sel) (chop (: str)))
         (setq C (extra C)) )
      (if
         (find
            '((X) (pre? H (car X)))
            (: map) )
         (pack (nth (chop (car @)) (+ 1 (: sel))))
         C ) ) )

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
   (mac> This Lst)
   (pass extra) )

(dm mac> (Lst)
   (let N 0
      (=: mac
         (mapcar
            '((X)
               (cond
                  ((num? X) (setq X (chop (format X))))
                  ((sym? X) (setq X (chop X))) )
               (when (> (length X) N)
                  (setq N (length X)) )
               X )
            Lst ) )
      (=: mac (cons N (: mac))) ) )

(dm cho> ()
   (if (=0 (: sel))
      (mapcar
         '((X) (mkCho (pack X)))
         (cdr (: mac)) )
      (let H
         (tail
            (car (: mac))
            (head (: sel) (chop (: str))) )
         (mapcan
            '((M)
               (when
                  (seek
                     '((S) (not (find <> S M)))
                     H )
                  (cons
                     (list
                        (pack M)
                        T
                        'type>
                        '(: focus)
                        (lit (nth M (+ 1 (length @)))) ) ) ) )
            (cdr (: mac)) ) ) ) )


(class +Macro +Sync +Mac)

(dm key> (C)
   (when (setq C (extra C))
      (let H
         (append
            (tail
               (car (: mac))
               (head (: sel) (chop (: str))) )
            (cons C) )
         (use M
            (if
               (seek
                  '((S)
                     (setq M
                        (find
                           '((M) (not (find <> S M)))
                           (cdr (: mac)) ) ) )
                  H )
               (pack (nth M (length @)))
               C ) ) ) ) )


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

(dm key> (C)
   (uppc (extra C)) )


# Field enable/disable
(class +Able)

(dm T (Exe . @)
   (=: able Exe)
   (put *Top 'able
      (cons This (get *Top 'able)) )
   (pass extra)
   (pr "able") )

(dm cho> ()
   (when (eval (: able))
      (extra) ) )


(class +Lock +Able)

(dm T @
   (pass super NIL) )


# Able prefix
(class +Skip)

(dm beg> ()
   (if (eval (: able))
      (extra)
      (next> (: home)) ) )


# Escape from Form lock
(class +Rid)

(dm T @
   (pass extra)
   (pr "rid") )

(dm upd> ()
   (extra)
   (and
      (: home lock)
      (memq This (: home able))
      (able> This) ) )


# Field display
(class +Font)

# "Helvetica" "SansSerif" "serif" "Monospaced"
(dm T (Name Size . @)
   (pass extra)
   (pr Name Size) )

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

(dm key> (C)
   (when (> (: lim) (length (: str)))
      (extra C) ) )

(dm chk> ()
   (or
      (and (> (length (: str)) (: lim)) `(_ "Text too long"))
      (extra) ) )


(class +Color)

(dm T (B F . @)
   (pass extra)
   (and B (pr "bCol" B))
   (and F (pr "fCol" F)) )


(class +Radio)
# radio

(dm T (Lst . @)
   (=: radio Lst)
   (pass extra) )

(dm set> (Val)
   (extra Val)
   (when Val
      (mapc
         '(("X")
            (clr> (field "X")) )
         (: radio) ) ) )


(class +Relay)
# relay

(dm T (Lst . @)
   (=: relay Lst)
   (pass extra) )

(dm relay> (Val)
   (mapc
      '(("X")
         (if (atom "X")
            (set> (field "X") Val)
            (set> (field (car "X"))
               (if (or (atom (cdr "X")) (lst? (cadr "X")))
                  ((cdr "X") Val)
                  (with Val (eval (cdr "X"))) ) ) ) )
      (: relay) ) )

(dm upd> ()
   (extra)
   (relay> This (val> This)) )

(dm set> (Val)
   (let Old (val> This)
      (extra Val)
      (let Val (val> This)
         (unless (= Old Val)
            (relay> This Val) ) ) ) )

(dm end> ()
   (extra)
   (relay> This (val> This)) )


(class +Hot)
# hot

(dm T (Exe . @)
   (=: hot Exe)
   (pass extra)
   (hotField) )

(dm act> ()
   (eval (: hot)) )


(class +Init)
# init

(dm T (Exe . @)
   (=: init Exe)
   (pass extra) )

(dm init> ()
   (eval (: init))
   (extra) )


(class +Start)
# start

(dm T (Exe . @)
   (=: start Exe)
   (pass extra) )

(dm start> ()
   (eval (: start))
   (extra) )


(class +Set)
# set

(dm T (Foo . @)
   (=: set Foo)
   (pass extra) )

(dm set> (Val)
   ((: set) Val) )


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
# home ix lbl str sel ign arr able undo redo adv

(dm T ()
   (=: home *Top)
   (=: sel 0)
   (link This) )

(dm init> ())

(dm start> ())

(dm upd> ())

(dm stop> ())

(dm beg> ())

(dm chg> ()
   (=: str (rd))
   (=: sel (rd)) )

(dm chk> ())
(dm end> ())
(dm cho> ())

(dm log> ()
   (do> This
      (chg> This) ) )

(dm text> (S)
   (out *App
      (pr (: home id) "text" (: ix) S) ) )

(dm type> (S)
   (out *App
      (pr (: home id) "type" (: ix) S) ) )

(dm str> (Str)
   (unless (= Str (: str))
      (=: sel 0)
      (text> This (=: str Str)) ) )

(dm set> (Val)
   (text> This Val) )

(dm clr> ()
   (set> This) )

(dm val> ())

(dm act> ()
   (beep> (: home)) )

(dm key> (C))

(dm do> "Prg"
   (let "S" (: str)
      (run "Prg")
      (unless (= "S" (: str))
         (=: undo (cons "S" (: undo)))
         (=: redo) ) ) )

(dm undo> ()
   (=: redo (cons (: str) (: redo)))
   (str> This (car (: undo)))
   (unless (=: undo (cdr (: undo)))
      (=: touch)
      (and (: arr) (=: arr touch NIL)) ) )

(dm redo> ()
   (=: undo (cons (: str) (: undo)))
   (str> This (car (: redo)))
   (=: redo (cdr (: redo)))
   (=: touch T)
   (and (: arr) (=: arr touch T)) )

(dm focus> ()
   (focus> (: home) This)
   (beg> This) )

(dm able> ()
   (out *App
      (pr (: home id) "able" (: ix) (bool (eval (: able)))) ) )

(dm able?> ()
   (or
      (not (memq This (: home able)))
      (eval (: able)) ) )

(dm scr> (N)
   (scr> (: arr) N) )

(dm zapUndo> ()
   (=: touch)
   (=: undo)
   (=: redo) )


# Mark hot link field (blue foreground)
(de hotField ()
   (pr "fCol" `(hex "0000FF")) )

# Get field
(de field (X)
   (if (sym? X)
      (get (: home) X)
      (get (: home fields) (+ X (: ix))) ) )

# Get current chart data row
(de curr ()
   (pick
      '((F D) (and (memq This F) D))
      (: arr fields)
      (nth (: arr data) (: arr ofs)) ) )


(class +Button +field)
# exe

(dm T (Lbl Str Exe . @)
   (pr Lbl `(char "B") (=: str Str))
   (=: exe Exe)
   (=: ign T)
   (pass super) )

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
      (let (Val @  Fld (get (: home fields) (+ 1 (: ix))))
         (focus> Fld)
         (do> Fld
            (if (=T Val)
               (clr> This)
               (set> This Val) ) ) )
      (next> (: home)) ) )


(class +ChgButton +Button)
# chg

(dm T (Lbl Str Foo . @)
   (=: chg Foo)
   (pass super Lbl Str
      '(let
         (Fld (get (: home fields) (+ 1 (: ix)))
            Val ((: chg) (val> Fld)) )
         (when Val
            (focus> Fld)
            (do> Fld
               (if (=T Val)
                  (clr> This)
                  (set> This Val) ) ) )
         (next> (: home)) ) ) )


(class +ClrButton +Button)
# clr

(dm T (Lbl Str Lst . @)
   (=: clr Lst)
   (pass super Lbl Str
      '(prog
         (mapc
            '((X)
               (if (atom X)
                  (clr> (get (: home) X))
                  (set> (get (: home) (car X)) (eval (cdr X))) ) )
            (: clr) )
         (able> (: home))
         (focus1> (: home)) ) ) )


(class +Checkbox +field)

(dm T (Lbl . @)
   (pr (=: lbl Lbl) `(char "c"))
   (pass super) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Val)
   (super (=: str (bool Val))) )

(dm val> ()
   (bool (: str)) )


(class +Label +field)

(dm T (Lbl Str . @)
   (pr (=: lbl Lbl) `(char "L") Str)
   (=: ign T)
   (pass super) )


(class +DrawField +field)
# dx dy sx sy lst tmp

# (lbl dx dy sx sy)
(dm T (Lbl DX DY . @)
   (pr
      (=: lbl Lbl)
      `(char "D")
      (=: dx DX)
      (=: dy DY) )
   (pass super) )

(dm siz> (SX SY)
   (out *App
      (pr (: home id) "siz" (: ix) (=: sx SX) (=: sy SY)) ) )

(dm set> (Lst)
   (out *App
      (pr (: home id) "set" (: ix)
         (sum 'len> (=: lst Lst)) )
      (mapc 'pr> Lst) ) )

(dm tmp> (Lst)
   (out *App
      (pr (: home id) "tmp" (: ix)
         (sum 'len> (=: tmp Lst)) )
      (mapc 'pr> Lst) ) )

(dm clk> (M X Y))
(dm drg> (M X Y))

(dm new> (Typ . @)
   (prog1
      (pass new Typ This)
      (set> This (cons @ (: lst))) ) )


(class +PictField +field)
# dx dy img

# (lbl dx dy)
(dm T (Lbl DX DY . @)
   (pr
      (=: lbl Lbl)
      `(char "P")
      (=: dx DX)
      (=: dy DY) )
   (pass super) )

(dm set> (Img)
   (out *App
      (ifn (=: img Img)
         (pr (: home id) "img" (: ix) 0)
         (pr (: home id) "img" (: ix) (car (info Img)))
         (in Img (echo)) ) ) )

(dm val> ()
   (: img) )

(dm clk> (M X Y))
(dm drg> (M X Y))


(class +TextField +field)
# dx dy

# (lbl dx [dy])
# (lbl lst)
(dm T (Lbl . @)
   (pr (=: lbl Lbl))
   (if (num? (next))
      (pr `(char "T")                     # TextField or TextArea
         (=: dx (arg))
         (or (=: dy (next)) 0) )
      (pr `(char "C") (length (arg)))     # Choice
      (=: dx (apply max (mapcar length (arg))))
      (mapc pr (arg))
      (=: str (car (arg))) )
   (pass super) )

(dm feed> (N S)  # TextArea only
   (out *App
      (pr (: home id) "feed" (: ix) N S) ) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Val)
   (str> This Val) )

(dm val> ()
   (: str) )

(dm key> (C)
   C )

(de mkCho (Key Val)
   (cons Key
      (cons T
         (list 'setFocus (lit (or Val Key))) ) ) )


# Matchcode Field
(class +McField +Uppc +TextField)

(dm key> (C)
   (and
      (setq C (super C))
      (or (<= "0" C "9") (<= "A" C "Z") (sub? C "#$-@"))
      C ) )


# Secure Transmission Field Prefix
(class +Rsa)

(de outN ()
   (unless *OutN
      (or *InND (quit "No keys"))
      (out *App
         (pr (: home id) "rsa" (car *InND)) ) ) )

(dm T @
   (pass extra)
   (pr "crypt") )

(dm beg> ()
   (outN)
   (extra) )

(dm chg> ()
   (=: str (pack (decrypt *InND (rd))))
   (=: sel (rd)) )

(dm text> (S)
   (outN)
   (wait NIL *OutN)
   (extra (encrypt *OutN (chop S))) )

(dm feed> (N S)  # TextArea only
   (outN)
   (wait NIL *OutN)
   (extra N (encrypt *OutN (chop S))) )

(dm key> (Lst)
   (outN)
   (wait NIL *OutN)
   (encrypt *OutN (chop (extra (car (decrypt *InND Lst))))) )


# Password Field
(class +PwField +Rsa +TextField)

(dm T @
   (pass super)
   (pr "pw") )


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


# Numeric Fields
(class +DigField +Align +TextField)

(dm key> (C)
   (and (<= "0" C "9") C) )


(class +NumField +DigField)

(dm set> (Val)
   (super (format Val)) )

(dm val> ()
   (format (super)) )


(class +IntField +NumField)

(dm key> (C)
   (and
      (sub? C "+-0123456789")
      C ) )


(class +FixField  +Align +TextField)
# scl

(dm T (N . @)
   (=: scl N)
   (pass super) )

(dm key> (C)
   (and
      (sub? C "+-0,123.456789")
      C ) )

(dm set> (Val)
   (super (format Val (: scl) *Sep0 *Sep3)) )

(dm val> ()
   (let (S (super)  L (chop S))
      (unless (member *Sep0 L)
         (setq S (pack S *Sep0)) )
      (format S (: scl) *Sep0 *Sep3) ) )


# Numeric Field Prefix
(class +NegRed)

(dm set> (Val)
   (out *App
      (pr (: home id) "fCol" (: ix)
         (if (lt0 Val) `(hex "CC0000") 0) ) )
   (extra Val) )


(class +DateField +Limit +TextField)

(dm T @
   (pass super 12) )

(dm key> (C)
   (and
      (setq C (super C))
      (or (= C (cadr *DateFmt)) (sub? C "0123456789"))
      C ) )

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

(dm act> ()
   (if (val> This)
      (beep> (: home))
      (do> This
         (set> This (date)) ) ) )

(dm set> (Val)
   (super (datStr Val)) )

(dm val> ()
   (expDat (super)) )

(dm chk> ()
   (and
      (: str)
      (not (val> This))
      `(_ "Bad date format") ) )


(class +TimeField +Limit +TextField)

(dm T @
   (pass super 10) )

(dm key> (C)
   (and
      (setq C (super C))
      (sub? C ":0123456789")
      C ) )

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
      `(_ "Bad time format") ) )


(class +FileField +TextField)
# file org

(dm T (Exe . @)
   (=: file Exe)
   (pass super) )

(dm upd> ()
   (set> This
      (=: org
         (let F (eval (: file))
            (and F
               (call "test" "-f" F)
               (in F (till NIL T)) ) ) ) ) )

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

(dm act> ()
   (when (val> This)
      (let Val @
         (out *App
            (pr
               (: home id) "url"
               (if (sub? ":/" Val) Val (pack "http://" Val))
               "HTTP" ) ) ) ) )


(class +MailField +TextField)

(dm T @
   (pass super)
   (hotField) )

(dm act> ()
   (when (val> This)
      (out *App
         (pr (: home id) "url" (pack "mailto:" @) "MAIL") ) ) )


### Field Arrays ###
(class +array)
# home fields

(dm T ()
   (=: home *Top)
   (put *Top 'arrays
      (conc (get *Top 'arrays) (cons This)) ) )

(dm init> ())

(dm start> ())

(dm upd> ())

(dm stop> ())

(dm chk> ())
(dm end> ())

(dm set> ())
(dm val> ())
(dm stat> ())

(dm clr> ()
   (set> This) )

(dm PGUP> ()
   (beep> (: home)) )

(dm PGDN> ()
   (beep> (: home)) )

(dm BEG> ()
   (beep> (: home)) )

(dm END> ()
   (beep> (: home)) )

(dm UP> ()
   (beep> (: home)) )

(dm DN> ()
   (beep> (: home)) )

(dm DEL> ()
   (beep> (: home)) )

(dm INS> ()
   (beep> (: home)) )


(class +Array +array)
# put get

# (.. ttl cols foo lst [put [get]])
(dm T ("Ttl" "N" "foo" "Lst" "Put" "Get")
   (super)
   (pr "Ttl" 0)
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (mapc
      '((F) (link F) (put F 'arr This))
      (=: fields
         (make
            (while "Lst"
               (let *Lay '+
                  (do "N"
                     ("foo" (pop '"Lst"))
                     (NIL "Lst")
                     (setq *Lay '-) ) ) ) ) ) ) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Lst)
   (mapc 'set> (: fields) ((: put) Lst)) )

(dm val> ()
   ((: get)
      (mapcar 'val> (: fields)) ) )


(class +chart +array)
# rows cols put get ofs lock

(de scrl (N)
   (zapUndo)
   (get> This)
   (=: ofs N)
   (put> This)
   (setScroll) )

(de setScroll ()
   (out *App
      (pr (: home id) "scrl"
         (get (caar (: fields)) 'ix)
         (: ofs)  # val
         (: rows) # vis
         (size> This) ) ) )  # max

# (.. rows lst prg [put [get]])
(dm T ("N" "Lst" "Prg" "Put" "Get")
   (super)
   (=: rows "N")
   (pr (car "Lst") 0)
   (mapc
      '((S) (pr '- S 0))
      (cdr "Lst") )
   (=: cols (length "Prg"))
   (=: ofs 1)
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (mapc
      '((L)
         (mapc
            '((F)
               (link F)
               (put F 'arr This) )
            L ) )
      (=: fields
         (make
            (do "N"
               (let *Lay '+
                  (link
                     (make
                        (mapc
                           '((L) (eval L) (setq *Lay '-))
                           "Prg" ) ) ) ) ) ) ) )
   (=: lock
      (not
         (find
            '((F) (not (isa '+Lock F)))
            (: fields 1) ) ) ) )

(dm init> ()
   (setScroll) )

(dm row> (Fld)
   (default Fld (: home focus))
   (when
      (find
         '((L) (memq Fld L))
         (: fields) )
      (+ -1 (: ofs) (index @ (: fields))) ) )

(dm row2> ()
   (when
      (find
         '((L) (memq (: home focus2) L))
         (: fields) )
      (+ -1 (: ofs) (index @ (: fields))) ) )

(dm scr> (N)
   (scrl N) )

(dm PGUP> ()
   (scrl (max 1 (- (: ofs) (: rows)))) )

(dm PGDN> ()
   (scrl (+ (: ofs) (: rows))) )

(dm BEG> ()
   (scrl 1) )

(dm END> ()
   (scrl
      (max 1
         (- (size> This) (length (: fields)) -2) ) ) )

(dm UP> ()
   (scrl (max 1 (- (: ofs) 1))) )

(dm DN> ()
   (scrl (+ 1 (: ofs))) )


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

(dm end> ()
   (set> This (val> This)) )

(dm set> (Lst)
   (unless (= Lst (: data))
      (let N (- (length Lst) (: rows) -1)
         (when (> (: ofs) N)
            (=: ofs (max 1 N)) ) )
      (=: data (copy Lst)) )
   (put> This)
   (setScroll) )

(dm val> ()
   (get> This)
   (: data) )

(dm stat> ()
   (list
      (cons 'ofs (: ofs))
      (cons 'data (: data)) ) )

(dm DEL> ()
   (zapUndo)
   (get> This)
   (ifn (row> This)
      (beep> (: home))
      (=: clip (get (: data) @))
      (=: data
         (conc
            (head (- @ 1) (: data))
            (nth (: data) (+ @ 1)) ) )
      (put> This)
      (setScroll) ) )

(dm INS> ()
   (zapUndo)
   (get> This)
   (ifn (row> This)
      (beep> (: home))
      (=: data
         (conc
            (head (- @ 1) (: data))
            (list (: clip))
            (nth (: data) @) ) )
      (put> This)
      (setScroll) ) )


(class +ListChart +Chart)

(dm set> (Lst)
   (super (mapcar list Lst)) )

(dm val> ()
   (mapcar car (super)) )


# Chart Prefix
(class +Del)
# del

(dm T (Exe . @)
   (=: del Exe)
   (pass extra) )

(dm INS> ()
   (if (eval (: del))
      (extra)
      (beep> (: home)) ) )

(dm DEL> ()
   (if (eval (: del))
      (extra)
      (beep> (: home)) ) )


### DB GUI ###
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

(de stepButton (@Var @Cls @Hook)
   (let @Key
      (if (isa '+Key (get @Cls @Var))
         (fill '(get (: home obj) '@Var))
         (fill '(cons (get (: home obj) '@Var) (: home obj))) )
      (gui '(+Rid +Button) "" `(_ "Next data record")
         (list
            'let 'Q
            (fill '(init (tree '@Var '@Cls '@Hook) @Key T))
            '(step Q)
            '(if (and (step Q) (url> @))
               (url @)
               (beep> (: home)) ) ) ) ) )

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
            (gui '(+IndexChart)
               (cons (car "Rel") (cons (last "Rel") (lit "Hook")))
               8 NIL '((apply gui "Lst")) )
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
      (loop
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


### DB Form ###
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
   (=: obj Obj)  #? (=: obj (extern Obj))
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

(dm T (Exe Lbl Lst)
   (=: erObj Exe)
   (super Lst Lbl (mapcar car Lst)) )

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
# tree beg end

# (.. tree rows lst prg [put])
(dm T ("Tree" "N" "Lst" "Prg" "Put")
   (=: tree "Tree")
   (super "N" "Lst" "Prg" (or "Put" cons)) )

(dm put> ()
   (let Node
      (init
         (tree (car (: tree)) (cadr (: tree)) (eval (cddr (: tree))))
         (: beg) (: end) )
      (do (- (: ofs) 1)
         (step Node T) )
      (mapc
         '((F)
            (mapc
               '((F D) (set> F D))
               F
               ((: put) (step Node T)) ) )
         (: fields) ) ) )

(dm upd> ()
   (put> This)
   (setScroll) )

(dm get> ())

(dm size> ()
   (or
      (car
         (tree (car (: tree)) (cadr (: tree)) (eval (cddr (: tree)))) )
      0 ) )

(dm set> (Beg End)
   (=: beg Beg)
   (=: end End)
   (put> This)
   (setScroll) )


(class +RefChart +IndexChart)

(dm upd> ()
   (set> This (cons (: home obj)) (cons (: home obj) T)) )


# DB Query Chart
(class +QueryChart +Chart)
# iniq quer query

# (.. iniq rows lst prg [put [get]])
(dm T ("Exe" "N" "Lst" "Prg" "Put" "Get")
   (=: iniq "Exe")
   (super "N" "Lst" "Prg" (or "Put" cons) (or "Get" car)) )

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
   (<href> "Download" "*Rep")
   (while (args)
      (prin " | ")
      (<href> (next) (pack "@" (next)) (next)) )
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
         (list T Val @) )
      (T Val) ) )

# Text File Export
(de export ("Nm" . "Prg")
   (out (list "bin/lat1" (setq "Nm" (tmp "Nm" ".txt")))
      (run "Prg") )
   (url "Nm") )
