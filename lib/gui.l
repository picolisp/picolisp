# 29sep06abu
# (c) Software Lab. Alexander Burger

### Java Applet GUI ###
# *AWT *Font *Color *Apps *AppId *AppPort *Top *Lay *Siz *Bar *DlgStk *Help

(on *AWT)
(allow "java/pico.jar")

(default *APorts 0)

(de url (Str Tar . @)
   (when Str
      (with *Top
         (when (: app)
            (out @
               (pr 'url
                  (pack
                     (baseHRef)
                     *SesId
                     Str
                     (and (args) (pack "?" (pass 'ht:Fmt))) )
                  (or Tar (if *Frame "MAIN" "_self")) ) ) ) ) ) )

(de bar (Ttl X Y Prg)
   (prinl Ttl '<hr>)
   (setq *Bar (new '(+Form) X Y Prg))
   (navi) )


(class +Applet)
# url app outN menu

(dm T (A Lst DX DY . @)
   (unless *Apps
      (one *AppId)
      (task (port *APorts '*AppPort)
         (let? S (accept @)
            (ifn
               (in S
                  (and
                     (= *SesId (rd))
                     (rd)
                     (get *Apps (- *AppId @)) ) )
               (close S)
               (push '*Key
                  (list (put @ 'app S) (list 'ev> (lit @) S)) )
               (out S (pr (car *InND))) ) ) )
      (task -40000 80000
         (with *Top
            (when (: app)
               (out @ (pr 'ping)) ) ) ) )
   (prin "<APPLET CODE=\"" A ".class\" ARCHIVE=\"" *SesId (pop 'Lst))
   (while Lst
      (prin ","  *SesId (pop 'Lst)) )
   (prinl "\" WIDTH=" DX " HEIGHT=" DY ">")
   (prinl "<PARAM NAME=\"size\" VALUE=\"" (car *Font) "\">")
   (prinl "<PARAM NAME=\"font\" VALUE=\"" (cdr *Font) "\">")
   (prinl "<PARAM NAME=\"back\" VALUE=\"" (car *Color) "\">")
   (prinl "<PARAM NAME=\"fore\" VALUE=\"" (cdr *Color) "\">")
   (prinl "<PARAM NAME=\"rand\" VALUE=\"" (in "/dev/urandom" (rd 7)) "\">")
   (prinl "<PARAM NAME=\"ID\" VALUE=\"" *AppId "\">")
   (prinl "<PARAM NAME=\"port\" VALUE=\"" *AppPort "\">")
   (prinl "<PARAM NAME=\"sid\" VALUE=\"" *SesId "\">")
   (while (args)
      (prin "<PARAM NAME=\"" (next) "\" VALUE=\"")
      (ht:Prin (next))
      (prinl "\">") )
   (prinl "</APPLET>")
   (=: url *Url)
   (push '*Apps This)
   (and (nth *Apps 40) (con @))
   (inc '*AppId) )

(dm ev> (App)
   (in App
      (let S (rd)
         (cond
            ((not S)
               (close App)
               (task App)
               (=: app)
               (and (== This *Top) (off *Top)) )
            ((num? S) (timeout *Timeout))
            ((= meth (val S))
               (send S (setq *Top This)) )
            (T (msg S " -> " *Pid)) ) ) ) )

(dm init> ())

(dm start> ())

(dm stop> ()
   (when (: app)
      (out @ (pr 'done)) ) )

(dm upd> ())

(dm esc> ()
   (beep> This) )

(dm rsa> ()
   (=: outN (rd)) )

(dm cmd> ()
   (eval (nth (: menu) (rd) 3)) )

(dm beep> ()
   (when (: app)
      (out @ (pr 'beep)) ) )

(dm play> (Url Flg)
   (when (: app)
      (out @
         (pr 'play (and Url (pack (baseHRef) *SesId Url)) Flg) ) ) )

(dm menu> (Ttl Lst)
   (when (: app)
      (out @
         (pr 'menu Ttl (length Lst))
         (for L (=: menu Lst)
            (pr (car L) (eval (cadr L))) ) ) ) )


### Applet Form ###
(class +Form +Applet)
# init fields arrays focus focus2 hot able lock rv

(de form @
   (if (pair (next))
      (pass new @)
      (pass new) ) )

(de back (Col))
(de fore (Col))

(de gui @
   (pr *Lay)
   (cond
      ((pair (next)) (pass new @))
      ((and (not (: fields)) (get *Top (arg)))
         (quit "gui conflict" (arg)) )
      (T (put *Top (arg) (pass new))) )
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


(dm T (DX DY Prg . @)
   (let X (assoc Prg *Siz)
      (super "Front" '("java/pico.jar")
         (or (cadr X) DX)
         (or (cddr X) DY) ) )
   (=: init Prg)
   (set This
      (conc
         (prog1
            (rest)
            (for L @
               (def (car L) meth) ) )
         (val This) ) ) )

(dm init> ()
   (super)
   (when (: app)
      (out @
         (pr 'make)
         (let *Lay '*
            (=: fields (make (run (: init)))) )
         (pr NIL) )
      (for (I . F) (: fields)
         (put F 'ix I)
         (init> F) )
      (mapc 'init> (: arrays)) ) )

(dm siz> ()
   (let X (cons (rd) (rd))
      (if (assoc (: init) *Siz)
         (con @ X)
         (push '*Siz (cons (: init) X)) ) ) )

(dm start> ()
   (super)
   (mapc 'start> (: fields))
   (mapc 'start> (: arrays))
   (upd> This)
   (focus1> This) )

(dm focus1> ()
   (and
      (or
         (find
            '((F)
               (and (isa '+TextField F) (able?> F)) )
            (: fields) )
         (find 'able?> (: fields)) )
      (focus> @) ) )

(dm upd> ()
   (super)
   (mapc 'upd> (: fields))
   (mapc 'upd> (: arrays))
   (able> This) )

(dm stop> ()
   (fieldEnd T)
   (mapc 'stop> (: fields))
   (mapc 'stop> (: arrays))
   (super) )

(dm at> ()
   (ifn (: top)
      (mapc 'stop> *DlgStk)
      (while (memq This (cdr *DlgStk))
         (stop> (car *DlgStk)) ) ) )

(dm able> ()
   (unless (: lock)
      (mapc 'able> (: able)) ) )

(dm lock> (Flg)
   (when (: app)
      (out @
         (pr 'lock (bool (=: lock Flg))) ) ) )

(dm focus> (F)
   (when (: app)
      (out @
         (pr 'focus (get F 'ix)) )
      (=: focus F) ) )

(dm next> ()
   (when (: app)
      (out @ (pr 'next)) ) )

(dm menu> (F Ttl Lst)
   (when (: app)
      (out @
         (pr 'menu (get F 'ix) Ttl (length Lst))
         (for L (=: menu Lst)
            (pr (car L) (eval (cadr L))) ) ) ) )

(dm help> ()
   (let (Url (chop (: url))  Lang (or *Lang "en"))
      (if (= "@" (car Url))
         (let S (intern (pack Lang "." (cdr Url)))
            (when (getd S)
               (prog1 (pack "@" S) (allow @)) ) )
         (let F
            (ifn (member "/" Url)
               (pack Lang "." Url)
               (setq Url (reverse Url))
               (set (member "/" Url) (list "/" Lang "."))
               (pack (flip Url)) )
            (and (info F) (allow F)) ) ) ) )

# Events
# ix
(dm clk> ()
   (clk> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm dbl> ()
   (dbl> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm drg> ()
   (drg> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm adv> ()
   (put (: fields) (rd) 'adv (rd)) )

(dm act> ()
   (let F (get (: fields) (rd))
      (and (fieldEnd) (act> F))
      (and (: app) (out @ (pr 'ack))) ) )

(dm tip> ()
   (tip> (get (: fields) (rd))) )

# sym
(dm key> ()
   (let (F (get (: fields) (rd))  X (rd))
      (when (== F (: focus))
         (ifn (key> F X)
            (beep> This)
            (type> F @) ) ) ) )

(dm ret> ()
   (let F (get (: fields) (rd))
      (when (== F (: focus))
         (use (B L)
            (ifn
               (and
                  (setq B (: focus arr))
                  (isa '+Chart B)
                  (setq L
                     (seek
                        '((L) (memq F (car L)))
                        (get B 'fields) ) )
                  (not
                     (find 'able?> (cdr (memq F (car L)))) )
                  (not
                     (find '((L) (find 'able?> L)) (cdr L)) ) )
               (next> This)
               (focus> (car (last (get B 'fields))))
               (send 'DN> B) ) ) ) ) )

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
   (if (: lock)
      (beep> This)
      (_boxSend DEL>) ) )

(dm INS> ()
   (if (: lock)
      (beep> This)
      (_boxSend INS>) ) )


# Help
(dm F1> ()
   (url (or (help> This) *Help)) )

# Choice
(dm F2> ()
   (if (and (not (: lock)) (: focus) (cho> (: focus)))
      (menu> This (: focus) ,"F2-Choice" @)
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
   (dialog ,"Settings"
      (list
         (car *Font) (cdr *Font)
         (>> 16 (car *Color))
         (& 255 (>> 8 (car *Color)))
         (& 255 (car *Color))
         (>> 16 (cdr *Color))
         (& 255 (>> 8 (cdr *Color)))
         (& 255 (cdr *Color)) )
      (quote
         (gui '(+NumField) ,"Font Size" 3)
         (gui '(+Map +TextField) '((-)) ,"Font"
            '(- "Serif" "SansSerif" "Monospaced" "Dialog" "DialogInput") )
         (----)
         (row
            (gui '(+NumField) ,"Background" 3)
            (gui '(+NumField) "" 3)
            (gui '(+NumField) "" 3) )
         (row
            (gui '(+NumField) ,"Foreground" 3)
            (gui '(+NumField) "" 3)
            (gui '(+NumField) "" 3) )
         (----)
         (row
            (okButton
               '(setq
                  *Font (cons
                     (val> (: home fields 1))
                     (val> (: home fields 2)) )
                  *Color (cons
                     (|
                        (>> -16 (val> (: home fields 3)))
                        (>> -8 (val> (: home fields 4)))
                        (val> (: home fields 5)) )
                     (|
                        (>> -16 (val> (: home fields 6)))
                        (>> -8 (val> (: home fields 7)))
                        (val> (: home fields 8)) ) ) ) )
            (quitButton) ) ) ) )

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
   (chg> (get (: fields) (rd))) )

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
   (for L (: fields)
      (mapc 'zapUndo> L) ) )

# Enter value into current focus field
(de setFocus (Val)
   (do> (: focus)
      (set> This Val) )
   (able> This)
   (next> This) )

# Field end processing
(de fieldEnd (Ign)
   (cond
      ((not (: focus)) T)
      ((: focus ign) T)
      ((or (chk> (: focus)) (and (: focus arr) (chk> (: focus arr))))
         (let Err @
            (or
               Ign
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
      (T (=: "last")
         (end> (: focus))
         (and (: focus arr) (end> @))
         T ) ) )

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
# top on args

(de _dlg (Ttl)
   (when (get (=: top *Top) 'app)
      (=: outN (: top outN))
      (use Port
         (let Sock (port *APorts 'Port)
            (out @
               (pr 'dialog Port *SesId Ttl) )
            (prog1
               (let? S (accept Sock)
                  (if (in S (= *SesId (rd)))
                     (push '*Key
                        (list (=: app S) (list 'ev> (lit This) S)) )
                     (close S)
                     NIL ) )
               (close Sock) ) ) ) ) )

(dm T ("Ttl" "Lst" "Args" . @)
   (when (_dlg "Ttl")
      (=: init "Lst")
      (=: args "Args")
      (set This (conc (rest) (val This)))
      (wait NIL (: on)) ) )

(dm init> ()
   (push '*DlgStk This)
   (=: on T)
   (super)
   (mapc
      '((V F) (and V (set> F V)))
      (if (lst? (: args))
         (: args)
         (car (val (: args))) )
      (filter '((This) (not (: ign))) (: fields)) )
   (unless (lst? (: args))
      (mapc
         '((L B)
            (while L
               (put B (caar L) (cdr (pop 'L))) ) )
         (cdr (val (: args)))
         (: arrays) ) ) )

(dm stop> ()
   (unless (lst? (: args))
      (set (: args)
         (cons
            (mapcar 'val>
               (filter '((This) (not (: ign))) (: fields)) )
            (mapcar 'stat> (: arrays)) ) ) )
   (super)
   (=: on)
   (pop '*DlgStk)
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
               (row (okButton NIL ,"Yes") (quitButton ,"No")) ) ) )
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
                  (okButton NIL ,"Yes")
                  (gui '(+Button) "" ,"No"
                     '(prog (=: home rv 0) (stop> (: home))) )
                  (quitButton) ) ) ) )
      (wait NIL (not (: on)))
      (when (=T (: rv))
         (eval "Exe") )
      (: rv) ) )

(de dialog ("Ttl" "Args" "Lst" . @)
   (with (pass new '(+Dialog) "Ttl" "Lst" "Args")
      (wait NIL (not (: on)))
      (: rv) ) )

# Dialog Buttons
(de okButton (@Exe Str Able)
   (gui '(+Able +Button) (or Able T) "" (or Str "Ok")
      (cons 'prog
         (ifn @Exe
            '((=: home rv T) (stop> (: home)))
            (list
               (fill '(=: home rv @Exe))
               '(stop> (: home)) ) ) ) ) )

(de quitButton (Str)
   (gui '(+Rid +Button) "" (or Str ,"Cancel")
      '(stop> (: home)) ) )


### Busy/Progress indicator ###
(====)
(off "Busy")

(class +BusyDialog +Dialog)
# prg work cnt

(dm T (Ttl Cnt Prg Lst)
   (=: work Cnt)
   (=: prg Prg)
   (setq "Busy" This)
   (super Ttl Lst) )

(dm start> ()
   (super)
   (=: rv (run (: prg)))
   (stop> This) )

(dm stop> ()
   (super)
   (off "Busy") )


# Busy/Progress utilities
(de busy ("Cnt" "Msg" . "Prg")
   (ifn *Top
      (run "Prg")
      (catch "busy"
         (with
            (new '(+BusyDialog) ,"Please wait" "Cnt" "Prg"
               (quote
                  (if (atom "Msg")
                     (txt "Msg")
                     (mapc txt "Msg") )
                  (----)
                  (row
                     (quitButton)
                     (gui 'cnt '(+Mono +Label) '-> "Cnt") ) ) )
            (wait NIL (not "Busy"))
            (: rv) ) ) ) )

(de work ()
   (when *Top
      (ifn "Busy"
         (throw "busy")
         (with "Busy"
            (set> (: cnt)
               (format (abs (dec (:: work)))) ) )
         (while (poll (: app))
            (ev> This (: app))
            (or (: app) (throw "busy")) ) ) ) )
(====)


### Field Prefix Classes ###
(class +Sync)

(dm T @
   (pass extra)
   (pr 'sync) )


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
         (pack (nth (chop (car @)) (inc (: sel))))
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
               (setq X (chop X))
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
                        (lit (nth M (inc (length @)))) ) ) ) )
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


(class +Lowc)

(dm key> (C)
   (lowc (extra C)) )


# Field enable/disable
(class +Able)
# able

(dm T (Exe . @)
   (=: able Exe)
   (put *Top 'able
      (cons This (get *Top 'able)) )
   (pass extra)
   (pr 'able) )

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
   (pr 'rid) )

(dm upd> ()
   (extra)
   (and
      (: home lock)
      (memq This (: home able))
      (able> This) ) )


# Field display
(class +Font)

# "Serif" "SansSerif" "Monospaced" "Dialog" "DialogInput"
(dm T (Name Size . @)
   (pass extra)
   (pr Name Size) )


(class +Mono +Font)

(dm T @
   (pass super "Monospaced" 0) )


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
      (and (> (length (: str)) (: lim)) ,"Text too long")
      (extra) ) )


(class +Color)
# bCol fCol

(dm T (B F . @)
   (pass extra)
   (and B (pr 'bCol (=: bCol B)))
   (and F (pr 'fCol (=: fCol F))) )


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

(dm do> "Prg"
   (let "S" (: str)
      (run "Prg")
      (unless (= "S" (: str))
         (eval (: chg))
         (=: undo (cons "S" (: undo)))
         (=: redo) ) ) )

(dm undo> ()
   (extra)
   (eval (: chg)) )

(dm redo> ()
   (extra)
   (eval (: chg)) )


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


(class +Tip)
# tip

(dm T (Str . @)
   (=: tip Str)
   (pass extra)
   (pr 'tip) )

(dm tip> ()
   (when (: home app)
      (out @
         (pr 'tip (: ix) (: tip)) ) ) )


### Form Field Classes ###
(class +field)
# home ix lbl str sel ign arr able undo redo adv growX growY

(de bCol (Col)
   (when (: home app)
      (out @
         (pr 'bCol (: ix) Col) ) ) )

(de fCol (Col)
   (when (: home app)
      (out @
         (pr 'fCol (: ix) Col) ) ) )

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
   (do> This
      (=: str (rd))
      (=: sel (rd)) ) )

(dm chk> ())
(dm end> ())
(dm cho> ())

(dm text> (S)
   (when (: home app)
      (out @
         (pr 'text (: ix) S) ) ) )

(dm type> (S)
   (when (: home app)
      (out @
         (pr 'type (: ix) S) ) ) )

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

(dm tip> ())

(dm key> (C))

(dm do> "Prg"
   (let "S" (: str)
      (run "Prg")
      (unless (= "S" (: str))
         (=: undo (cons "S" (: undo)))
         (=: redo) ) ) )

(dm undo> ()
   (=: redo (cons (: str) (: redo)))
   (str> This (pop (:: undo))) )

(dm redo> ()
   (=: undo (cons (: str) (: undo)))
   (str> This (pop (:: redo))) )

(dm focus> ()
   (focus> (: home) This)
   (beg> This) )

(dm able> ()
   (when (: home app)
      (out @
         (pr 'able (: ix) (bool (eval (: able)))) ) ) )

(dm grow> (DX DY)
   (when (: home app)
      (out @
         (pr 'grow (: ix)
            (if (= DX (: growX))
               0
               (prog1
                  (- (or DX 0) (or (: growX) 0))
                  (=: growX DX) ) )
            (if (= DY (: growY))
               0
               (prog1
                  (- (or DY 0) (or (: growY) 0))
                  (=: growY DY) ) ) ) ) ) )

(dm able?> ()
   (or
      (not (memq This (: home able)))
      (eval (: able)) ) )

(dm scr> (N)
   (scr> (: arr) N) )

(dm zapUndo> ()
   (=: undo)
   (=: redo) )


# Mark hot link field (blue foreground)
(de hotField ()
   (pr 'fCol (=: fCol `(hex "0000FF"))) )

# Get field
(de field (X . @)
   (if (sym? X)
      (pass get (: home) X)
      (pass get (: home fields) (+ X (: ix))) ) )

# Get current chart data row
(de curr @
   (pass get
      (pick
         '((F D) (and (memq This F) D))
         (: arr fields)
         (nth (: arr data) (: arr ofs)) ) ) )


(class +Button +field)
# exe

(dm T (Lbl Str Exe . @)
   (pr Lbl `(char "B") (=: str Str))
   (=: exe Exe)
   (=: ign T)
   (pass super) )

(dm act> ()
   (when (able?> This)
      (eval (: exe)) ) )

(dm set> (Val)
   (=: str Val)
   (super Val) )

(dm val> ()
   (: str) )


(class +setButton +Button)


(class +SetButton +setButton)

(dm act> ()
   (when (super)
      (let
         (Val @
            Fld (get (: home fields) ((if (== '-> (: str)) inc dec) (: ix))) )
         (focus> Fld)
         (do> Fld
            (if (=T Val)
               (clr> This)
               (set> This Val) ) ) )
      (next> (: home)) ) )


(class +ChgButton +setButton)
# chg

(dm T (Lbl Str Foo . @)
   (=: chg Foo)
   (pass super Lbl Str
      '(let
         (Fld
            (get (: home fields) ((if (== '-> (: str)) inc dec) (: ix)))
            Val ((: chg) (val> Fld)) )
         (when Val
            (focus> Fld)
            (do> Fld
               (if (=T Val)
                  (clr> This)
                  (set> This Val) ) ) )
         (next> (: home)) ) ) )


(class +ClrButton +setButton)
# clr

(dm T (Lbl Str Lst . @)
   (=: clr Lst)
   (pass super Lbl Str
      '(prog
         (for X (: clr)
            (if (atom X)
               (clr> (field X))
               (set> (field (car X)) (eval (cdr X))) ) )
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
   (when (: home app)
      (out @
         (pr 'siz (: ix) (=: sx SX) (=: sy SY)) ) ) )

(dm set> (Lst)
   (when (: home app)
      (out @
         (pr 'set (: ix)
            (sum 'len> (=: lst Lst)) )
         (mapc 'pr> Lst) ) ) )

(dm tmp> (Lst)
   (when (: home app)
      (out @
         (pr 'tmp (: ix)
            (sum 'len> (=: tmp Lst)) )
         (mapc 'pr> Lst) ) ) )

(dm clk> (M X Y))
(dm dbl> (M X Y))
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
   (when (: home app)
      (out @
         (ifn (=: img Img)
            (pr 'img (: ix) 0)
            (pr 'img (: ix) (car (info Img)))
            (in Img (echo)) ) ) ) )

(dm val> ()
   (: img) )

(dm clk> (M X Y))
(dm dbl> (M X Y))
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
   (when (: home app)
      (out @
         (pr 'feed (: ix) N S) ) ) )

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

(dm key> (C)
   (and
      (setq C (super C))
      (or (<= "0" C "9") (<= "A" C "Z") (sub? C "#$-@"))
      C ) )


# Secure Transmission Field Prefix
(class +Rsa)

(dm T @
   (or *InND (quit "No keys"))
   (pass extra)
   (pr 'rsa) )

(dm chg> ()
   (=: str (pack (decrypt *InND (rd))))
   (=: sel (rd)) )

(dm text> (S)
   (extra (encrypt (: home outN) (chop S))) )

(dm feed> (N S)  # TextArea only
   (extra N (encrypt (: home outN) (chop S))) )

(dm key> (Lst)
   (encrypt
      (: home outN)
      (chop (extra (car (decrypt *InND Lst)))) ) )


# Password Field
(class +PwField +Rsa +TextField)

(dm T @
   (pass super)
   (pr 'pw) )


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
   (fCol
      (if (lt0 Val)
         `(hex "CC0000")
         (or (: fCol) 0) ) )
   (extra Val) )


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


(class +DateField +Limit +TextField)

(dm T @
   (pass super 12) )

(dm key> (C)
   (and
      (setq C (super C))
      (or (sub? C "0123456789") (member C *DateFmt))
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

(dm set> (Val)
   (super (datStr Val)) )

(dm val> ()
   (expDat (super)) )

(dm chk> ()
   (and
      (: str)
      (not (val> This))
      ,"Bad date format" ) )


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

(dm act> ()
   (let? Val (val> This)
      (when (: home app)
         (out @
            (pr 'url
               (if (sub? ":/" Val) Val (pack "http://" Val))
               "HTTP" ) ) ) ) )


(class +MailField +TextField)

(dm T @
   (pass super)
   (hotField) )

(dm act> ()
   (let? Val (val> This)
      (when (: home app)
         (out @
            (pr 'url (pack "mailto:" Val) "MAIL") ) ) ) )


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
(dm T ("Ttl" "N" "Foo" "Lst" "Put" "Get")
   (super)
   (pr "Ttl" 0)
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (mapc
      '((F)
         (link F)
         (put F 'arr This) )
      (=: fields
         (make
            (while "Lst"
               (let *Lay '+
                  (do "N"
                     ("Foo" (pop '"Lst"))
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
   (let Fld (: home focus)
      (when (find '((L) (memq Fld L)) (: fields))
         (beg> Fld) ) )
   (setScroll) )

(de setScroll ()
   (when (: home app)
      (out @
         (pr 'scrl
            (: fields 1 1 ix)
            (: ofs)  # val
            (: rows) # vis
            (size> This) ) ) ) )  # max

# (.. rows lst prg [put [get]])
(dm T ("N" "Lst" "Prg" "Put" "Get")
   (super)
   (=: rows 0)
   (pr (car "Lst") 0)
   (for S (cdr "Lst")
      (pr '- S 0) )
   (=: cols (length "Prg"))
   (=: ofs 1)
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (mapc
      '((L)
         (for F L
            (link F)
            (put F 'arr This) ) )
      (=: fields
         (make
            (do "N"
               (inc (:: rows))
               (let *Lay '+
                  (link
                     (make
                        (for L "Prg"
                           (eval L)
                           (setq *Lay '-) ) ) ) ) ) ) ) )
   (=: lock
      (not
         (find
            '((F)
               (or
                  (isa '+setButton F)
                  (nor (isa '+Button F) (isa '+Lock F)) ) )
            (: fields 1) ) ) ) )

(dm init> ()
   (setScroll) )

(dm row> (Fld)
   (default Fld (: home focus2))
   (when
      (find
         '((L) (memq Fld L))
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
   (scrl (max 1 (dec (: ofs)))) )

(dm DN> ()
   (scrl (inc (: ofs))) )


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
                     (mapcar 'val> (car F))
                     (car D)
                     (car F) ) ) ) )
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
            (=: ofs (max 1 N)) ) ) )
   (=: data (copy Lst))
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
      (=: data (remove @ (: data)))
      (put> This)
      (setScroll) ) )

(dm INS> ()
   (zapUndo)
   (get> This)
   (ifn (row> This)
      (beep> (: home))
      (=: data (insert @ (: data) (: clip)))
      (put> This)
      (setScroll) ) )

(de bubbleButton ()
   (when (> (: rows) 1)
      (gui '(+Able +Set +Button)
         '(curr)
         '((V) (extra '^) (=: str))
         "" '^
         '(let (N (row> (: arr) This)  L (val> (: arr)))
            (ifn (nth L N)
               (beep> (: home))
               (set> (: arr)
                  (conc
                     (cut (- N 2) 'L)
                     (cons (cadr L))
                     (cons (car L))
                     (cddr L) ) ) ) ) ) ) )

(de delRowButton (@Msg @Chart @Foo)
   (macro
      (gui '(+Able +Button)
         '(and (row> @Chart) (get @Chart 'data @))
         "" @Msg
         '(when (ask @Msg (pack @Msg '?))
            ('@Foo (row> @Chart))
            (upd> @Chart) ) ) ) )


(class +ListChart +Chart)

(dm set> (Lst)
   (super (mapcar list Lst)) )

(dm val> ()
   (mapcar car (super)) )


### Chart Prefix Classes ###
(class +NoClip)

(dm DEL> ()
   (zapUndo)
   (get> This)
   (ifn (row> This)
      (beep> (: home))
      (=: data (remove @ (: data)))
      (put> This)
      (setScroll) ) )


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

(undef 'upd)
(de upd Lst
   (wipe Lst)
   (for F *DbForms
      (and (has> F Lst) (upd> F)) ) )

(de newDlg ("Typ" . @)
   (prog1
      (pass new! "Typ")
      (and (dlg> (put *Top 'rv @)) (eval @)) ) )

(de newUrl @
   (prog1
      (pass new!)
      (url (url> (put *Top 'rv @))) ) )

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
      '(or (: home focus2 obj) (isa '+Hot (: home focus2)))
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
      (gui '(+Rid +Able +Button)
         (fill
            '(let Q (init (tree '@Var '@Cls '@Hook) @Key T)
               (step Q)
               (step Q) ) )
         "" ,"Next data record"
         (fill
            '(let Q (init (tree '@Var '@Cls '@Hook) @Key T)
               (step Q)
               (if (and (step Q) (url> @))
                  (url @)
                  (beep> (: home)) ) )
            '(@Var @Cls @Hook @Key) ) ) ) )

(de choButton (Exe)
   (gui 'hot '(+Rid +Button) "" ,"Choose/New (F4)" Exe) )

(de cloneButton ()
   (gui '(+Rid +Button) "" ,"New/Copy"
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
         "Fld" (cond
            ((not (next)) '(+Obj +TextField))
            ((=T (arg)) '(+Rv +Obj +TextField))
            (T (arg)) )
         "Pre" (next)
         "Post" (next) )
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
               (gui '(+Able +Button) '(val> (: home fields 1)) "" ,"Choose"
                  '(act> (: home fields 1)) )
               (gui '(+Button) "" ,"New"
                  '(with (: home fields 1)
                     (if (meta (: objTyp) (: objVar) 'hook)
                        (newUrl (: objTyp) @ (eval (: objHook)))
                        (newUrl (: objTyp)) ) ) ) )
            (---- T)
            (gui '(+QueryChart)
               '(goal
                  (list
                     (list 'db (car "Rel") (last "Rel") "Hook" '@@) ) )
               8 NIL
               (list
                  (make
                     (link 'gui (lit (cons '+Lock "Fld")))
                     (and "Pre" (link (lit "Pre")))
                     (link (lit "Rel"))
                     (and "Hook" (link (lit (lit "Hook"))))
                     (and "Post" (link (lit "Post")))
                     (link "" 40) ) )
               cons
               car )
            (----)
            (row (hotButton ,"Choose") (quitButton)) ) ) ) )
(====)


# Field Input Prefix
(class +Hint +Sync)
# hint

(dm T (CL . @)
   (pass super)
   (=: hint (append CL '((@ pre? (-> @1) (-> @@))))) )

(dm key> (C)
   (use (H Q S)
      (setq
         H (pack
            (head (: sel) (chop (: str)))
            (setq C (extra C)) )
         Q (goal (: hint) '@1 H) )
      (loop
         (NIL (asoq '@@ (prove Q)) C)
         (T (pre? H (setq S (cdr @)))
            (pack (nth (chop S) (inc (: sel)))) ) ) ) )

(dm cho> ()
   (let (H (pack (head (: sel) (chop (: str))))  Q (goal (: hint) '@1 H))
      (mapcan
         '((X)
            (if (pair X)
               (when (pre? H (car X))
                  (cons (mkCho (car X) (cdr X))) )
               (when (pre? H X)
                  (cons (mkCho X X)) ) ) )
         (use (L X)
            (make
               (loop
                  (NIL (setq L (prove Q)))
                  (setq X
                     (if (assoc '@@@ L)
                        (cons (cdr (assoc '@@ L)) (cdr @))
                        (cdr (assoc '@@ L)) ) )
                  (unless (member X (made))
                     (link X) )
                  (T (>= (length (made)) 40)) ) ) ) ) ) )


### DB Form ###
(class +DbForm +Form)

(dm start> ()
   (push '*DbForms This)
   (super) )

(dm stop> ()
   (super)
   (setq *DbForms (delq This *DbForms)) )

(dm has> (Lst))


### Object Linkage ###
(class +ObjForm +DbForm)
# typ obj

(dm T (Typ Obj . @)
   (=: typ Typ)
   (=: obj Obj)
   (pass super) )

(dm upd> ()
   (lock> This (or (: lock) (: obj T)))
   (super) )

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
   (when (_dlg "Ttl")
      (=: typ "Typ")
      (=: obj "Obj")
      (=: init "Lst")
      (wait NIL (: on)) ) )

(dm init> ()
   (push '*DlgStk This)
   (=: on T)
   (super) )

(dm stop> ()
   (super)
   (=: on)
   (pop '*DlgStk)
   (setq *Top (: top)) )

(de objDialog ("Ttl" "Typ" "Obj" "Exe" "Lst")
   (with (new '(+View +ObjDialog) "Exe" "Ttl" "Typ" "Obj" "Lst")
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
   (extra
      (and
         (eval (: erObj))
         (put!> @ (: erVar) (bool Val))
         (allow (blob (eval (: erObj)) (: erVar))) ) ) )


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

(dm T @
   (pass extra)
   (pr 'bCol (=: bCol `(hex "E0E0FF"))) )


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
         ((num? V) (goal (query> This V))) ) ) )

(dm T (Rel . @)
   (=: objVar (car Rel))
   (=: objTyp (cdr Rel))
   (when (meta (: objTyp) (: objVar) 'hook)
      (=: objHook (next)) )
   (pass super)
   (hotField) )

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

(dm key> (C)
   (when (setq C (extra C))
      (ifn (asoq '@@ (prove (objQuery C)))
         C
         (pack
            (nth
               (chop (get (=: obj (cdr @)) (: objVar)))
               (inc (: sel)) ) ) ) ) )

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
   (if (num? X)
      (list  # ((db var +Cls (<N> . T) @@))
         (make
            (link 'db (: objVar) (last (: objTyp)))
            (when (: objHook)
               (link (eval @)) )
            (link (cons X T) '@@) ) )
      (list  # ((db var +Cls "Str" @@) (head "Str" @@ var))
         (make
            (link 'db (: objVar) (last (: objTyp)))
            (when (: objHook)
               (link (eval @)) )
            (link X '@@) )
         (list 'head X '@@ (: objVar)) ) ) )


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
   (ifn (and (: obj) (url> @))
      (beep> (: home))
      (url @) ) )


# +Obj/+ObjView Prefix
(class +Dlg)

(dm act> ()
   (ifn (and (: obj) (dlg> @))
      (beep> (: home))
      (eval @)
      (upd> (: home)) ) )


# +Obj Prefix
(class +Auto)

(dm val> (Flg)
   (or
      (extra Flg)
      (and
         (: str)
         (new! (: objTyp) (: objVar) (: str)) ) ) )


# +Obj Prefix for +Dialog return value
(class +Rv)

(dm act> ()
   (ifn (: obj)
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


(class +HintObj +Query +Obj)
# objHint

(dm T (CL . @)
   (pass super
      '((Str)
         (cons '@1 (cons Str (: objHint))) ) )
   (=: objHint
      (append CL
         (cons (list 'head '@1 '@@ (: objVar))) ) ) )

(dm val> (Flg)
   (if Flg
      (super T)
      (and
         (= (extra) (get (: obj) (: objVar)))
         (: obj) ) ) )


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
   (put> This)
   (setScroll) )

(dm get> ())

(dm size> ()
   (count
      (tree
         (car (: tree))
         (cadr (: tree))
         (eval (cddr (: tree))) ) ) )

(dm set> (Beg End)
   (=: ofs 1)
   (=: beg Beg)
   (=: end End)
   (put> This)
   (setScroll) )


(class +RefChart +IndexChart)

(dm upd> ()
   (set> This (cons (: home obj)) (cons (: home obj) T)) )


# Chart scroller
(class +Scrl +Sync)
# scrl

(dm T (Foo . @)
   (=: scrl Foo)
   (pass super) )

(dm key> (C)
   (prog1 (extra C)
      (let ("S" (pack (: str) @)  "Foo" (: scrl))
         (with (pick '(("F") (get "F" 'arr)) (memq This (: home fields)))
            (scrl
               (if (find '(("D") ("Foo" "S" "D")) (: data))
                  (index @ (: data))
                  1 ) ) ) ) ) )


# DB Query Chart
(class +QueryChart +Chart)
# iniq quer query

# (.. iniq rows lst prg [put [get]])
(dm T ("Exe" "N" "Lst" "Prg" "Put" "Get")
   (=: iniq "Exe")
   (super "N" "Lst" "Prg" (or "Put" cons) (or "Get" car)) )

(dm start> ()
   (or
      (: query)
      (pair (: home args))
      (cdr (val (: home args)))
      (=: query (eval (: iniq))) ) )

(dm put> ()
   (while
      (and
         (>
            (: ofs)
            (- (length (: data)) (: rows)) )
         (asoq '@@ (prove (: quer))) )
      (=: data (conc (: data) (cons (cdr @)))) )
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
            (list 'lst '@@
               (by '((This) (eval Exe)) sort (: data)) ) ) ) ) )

(dm clr> ()
   (set> This (fail)) )

(dm stat> ()
   (cons
      (cons 'query (: query))
      (super) ) )

(dm DEL> ()
   (super)
   (and (: clip) (lose!> @)) )

(dm INS> ()
   (super)
   (and (: clip) (keep!> @)) )

# Text File Export
(de export ("Nm" . "Prg")
   (out (list "bin/lat1" (setq "Nm" (tmp "Nm" ".txt")))
      (run "Prg") )
   (url "Nm") )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
