# 24nov16abu
# (c) Software Lab. Alexander Burger

(setq
   *CPU "JVM"
   *OS (java (java "java.lang.System" "getProperty" "os.name")) )

############ lib.l ############

(de task (Key . Prg)
   (nond
      (Prg (del (assoc Key *Run) '*Run))
      ((num? Key) (quit "Bad Key" Key))
      ((assoc Key *Run)
         (push '*Run
            (conc
               (make
                  (when (lt0 (link Key))
                     (link (+ (eval (++ Prg) 1))) ) )
               (ifn (sym? (car Prg))
                  Prg
                  (cons
                     (cons 'job
                        (cons
                           (lit
                              (make
                                 (while (atom (car Prg))
                                    (link
                                       (cons (++ Prg) (eval (++ Prg) 1)) ) ) ) )
                           Prg ) ) ) ) ) ) )
      (NIL (quit "Key conflict" Key)) ) )

(de timeout (N)
   (if2 N (assoc -1 *Run)
      (set (cdr @) (+ N))
      (push '*Run (list -1 (+ N) '(bye)))
      (del @ '*Run) ) )

(de macro "Prg"
   (run (fill "Prg")) )

(de recur recurse
   (run (cdr recurse)) )

(de curry "Z"
   (let ("X" (++ "Z")  "Y" (++ "Z")  "P" (filter pat? "X"))
      (if2 "P" (diff "X" "P")
         (list "Y" (cons 'job (lit (env @)) (fill "Z" "P")))
         (cons "Y" (fill "Z" "P"))
         (list "Y" (cons 'job (lit (env @)) "Z"))
         (cons "Y" "Z") ) ) )

### Definitions ###
(de expr ("F")
   (set "F"
      (list '@ (list 'pass (box (getd "F")))) ) )

(de subr ("F")
   (set "F"
      (getd (cadr (cadr (getd "F")))) ) )

(de undef ("X" "C")
   (when (pair "X")
      (setq  "C" (cdr "X")  "X" (car "X")) )
   (ifn "C"
      (prog1 (val "X") (set "X"))
      (prog1
         (cdr (asoq "X" (val "C")))
         (set "C"
            (delq (asoq "X" (val "C")) (val "C")) ) ) ) )

(de redef "Lst"
   (let ("Old" (car "Lst")  "New" (name "Old"))
      (set
         "New" (getd "Old")
         "Old" "New"
         "Old" (fill (cdr "Lst") "Old") )
      "New" ) )

(de daemon ("X" . Prg)
   (prog1
      (nond
         ((pair "X")
            (or (pair (getd "X")) (expr "X")) )
         ((pair (cdr "X"))
            (method (car "X") (cdr "X")) )
         (NIL
            (method (car "X") (get (or (cddr "X") *Class) (cadr "X"))) ) )
      (con @ (append Prg (cdr @))) ) )

(de patch ("Lst" "Pat" . "Prg")
   (bind (fish pat? "Pat")
      (recur ("Lst")
         (loop
            (cond
               ((match "Pat" (car "Lst"))
                  (set "Lst" (run "Prg")) )
               ((pair (car "Lst"))
                  (recurse @) ) )
            (NIL (cdr "Lst"))
            (T (atom (cdr "Lst"))
               (when (match "Pat" (cdr "Lst"))
                  (con "Lst" (run "Prg")) ) )
            (setq "Lst" (cdr "Lst")) ) ) ) )

(de cache ("Var" X . Prg)
   (let K (cons (char (hash X)) X)
      (nond
         (Prg (caar (idx "Var" K)))
         ((setq "Var" (caar (idx "Var" K T)))
            (set (car K) (run Prg 1)) )
         ((n== "Var" (val "Var"))
            (set "Var" (run Prg 1)) )
         (NIL (val "Var")) ) ) )

### I/O ###
(de tab (Lst . @)
   (for N Lst
      (let V (next)
         (and (gt0 N) (space (- N (length V))))
         (prin V)
         (and (lt0 N) (args) (space (- 0 N (length V)))) ) )
   (prinl) )

(de beep ()
   (prin "^G") )

(de msg (X . @)
   (out 2
      (print X)
      (pass prinl) )
   X )

(de script (File . @)
   (load File) )

(de once Prg
   (unless (idx '*Once (file) T)
      (run Prg 1) ) )

(de pil @
   (when (== "Pil" '"Pil")
      (call "mkdir" "-p" (setq "Pil" `(pack (sys "HOME") "/.pil/"))) )
   (pass pack "Pil") )

# Temporary Files
(de tmp @
   (unless *Tmp
      (push '*Bye '(call "rm" "-r" *Tmp))
      (call "mkdir" "-p" (setq *Tmp (pil "tmp/" *Pid "/"))) )
   (pass pack *Tmp) )

### List ###
(de insert (N Lst X)
   (conc
      (cut (dec N) 'Lst)
      (cons X)
      Lst ) )

(de remove (N Lst)
   (conc
      (cut (dec N) 'Lst)
      (cdr Lst) ) )

(de place (N Lst X)
   (conc
      (cut (dec N) 'Lst)
      (cons X)
      (cdr Lst) ) )

(de uniq (Lst)
   (let R NIL
      (filter
         '((X)
            (not (idx 'R (cons (hash X) X) T)) )
         Lst ) ) )

(de group (Lst)
   (make
      (for X Lst
         (if (assoc (car X) (made))
            (conc @ (cons (cdr X)))
            (link (list (car X) (cdr X))) ) ) ) )

### Symbol ###
(de qsym "Sym"
   (cons (val "Sym") (getl "Sym")) )

(de loc (S X)
   (if (and (str? X) (= S X))
      X
      (and
         (pair X)
         (or
            (loc S (car X))
            (loc S (cdr X)) ) ) ) )

(de local Lst
   (mapc zap Lst) )

(de import Lst
   (for Sym Lst
      (unless (== Sym (intern Sym))
         (quit "Import conflict" Sym) ) ) )

### OOP ###
(de class Lst
   (let L (val (setq *Class (car Lst)))
      (def *Class
         (recur (L)
            (if (atom (car L))
               (cdr Lst)
               (cons (car L) (recurse (cdr L))) ) ) ) ) )

(de object ("Sym" "Val" . @)
   (putl "Sym")
   (def "Sym" "Val")
   (while (args)
      (put "Sym" (next) (next)) )
   "Sym" )

(de extend X
   (setq *Class (car X)) )

# Class variables
(de var X
   (if (pair (car X))
      (put (cdar X) (caar X) (cdr X))
      (put *Class (car X) (cdr X)) ) )

(de var: X
   (apply meta X This) )

### Math ###
(de scl ("N" . "Prg")
   (if "Prg"
      (let *Scl "N" (run "Prg"))
      (setq *Scl "N") ) )

(de sqrt (N F)
   (cond
      ((lt0 N) (quit "Bad argument" N))
      (N
         (and (num? F) (setq N (* N @)))
         (let (M 1  R 0)
            (while (>= N M)
               (setq M (>> -2 M)) )
            (loop
               (if (> (inc 'R M) N)
                  (dec 'R M)
                  (dec 'N R)
                  (inc 'R M) )
               (setq R (>> 1 R)  M (>> 2 M))
               (T (=0 M)) )
            (and F (> N R) (inc 'R))
            R ) ) ) )

# (Knuth Vol.2, p.442)
(de ** (X N)  # N th power of X
   (if (ge0 N)
      (let Y 1
         (loop
            (when (bit? 1 N)
               (setq Y (* Y X)) )
            (T (=0 (setq N (>> 1 N)))
               Y )
            (setq X (* X X)) ) )
      0 ) )

# Accumulate
(de accu (Var Key Val)
   (when Val
      (if (assoc Key (val Var))
         (con @ (+ Val (cdr @)))
         (push Var (cons Key Val)) ) ) )

# Flooding Algorithm
(de flood ("Lst" "Fun" "Init")
   (let G (mapcar '(("X") (cons "X" ("Fun" "X"))) "Lst")
      (for L G
         (for X (cdr L)
            (let A (asoq X G)
               (unless (memq (car L) (cdr A))
                  (con A (cons (car L) (cdr A))) ) ) ) )
      (make
         (recur ("Init")
            (for X "Init"
               (unless (memq X (made))
                  (link X)
                  (recurse (cdr (asoq X G))) ) ) ) ) ) )

### Pretty Printing ###
(de pretty (X N)
   (setq N (abs (space (or N 0))))
   (while (and (pair X) (== 'quote (car X)))
      (prin "'")
      (++ X) )
   (cond
      ((atom X) (print X))
      ((memq (car X) '(de dm))
         (_pretty
            (spPrt (++ X))
            (spPrt (++ X))
            (prtty1 X N Z) ) )
      ((memq (car X) '(let let?))
         (_pretty
            (cond
               ((atom (car X))
                  (spPrt (++ X))
                  (prtty? (++ X) N) )
               ((>= 12 (size (car X)))
                  (prin " (")
                  (let Z (++ X)
                     (prtty2 Z NIL Z) )
                  (prin ")") )
               (T
                  (nlPrt N)
                  (prin "(")
                  (let Z (++ X)
                     (prtty2 Z (+ N 3) Z) )
                  (prin " )") ) )
            (prtty1 X N Z) ) )
      ((== 'for (car X))
         (_pretty
            (cond
               ((or (atom (car X)) (atom (cdar X)))
                  (spPrt (++ X))
                  (prtty? (++ X) N) )
               ((>= 12 (size (car X)))
                  (spPrt (++ X)) )
               (T
                  (nlPrt N)
                  (prtty0 (++ X) (+ 3 N)) ) )
            (prtty1 X N Z) ) )
      ((== 'if2 (car X))
         (_pretty
            (when (>= 12 (size (head 2 X)))
               (spPrt (++ X))
               (spPrt (++ X)) )
            (prtty1 X N Z) ) )
      ((memq (car X) '(while until do state finally co))
         (prtty3 X N) )
      ((>= 12 (size X))
         (ifn (memq (car X) '(set setq default))
            (print X)
            (prin "(")
            (let Z X
               (printsp (++ X))
               (prtty2 X NIL Z) )
            (prin ")") ) )
      ((memq (car X) '(=: use recur tab new))
         (_pretty
            (space)
            (print (++ X))
            (prtty1 X N Z) ) )
      ((memq (car X) '(set setq default))
         (_pretty
            (if (cdddr X)
               (prog
                  (nlPrt N)
                  (prtty2 X N Z) )
               (spPrt (++ X))
               (nlPrt1 (++ X) N) ) ) )
      ((memq (car X) '(T NIL ! if ifn when unless case casq with catch push bind job in out))
         (prtty3 X N) )
      (T (prtty0 X N)) ) )

(de _pretty "Prg"
   (prin "(")
   (let Z X
      (print (++ X))
      (run "Prg") )
   (prin " )") )

(de prtty0 (X N)
   (prin "(")
   (let Z X
      (pretty (++ X) (- -3 N))
      (prtty1 X N Z) )
   (prin " )") )

(de prtty1 (X N Z)
   (loop
      (NIL X)
      (T (== Z X) (prin " ."))
      (T (atom X) (prin " . ") (print X))
      (nlPrt1 (++ X) N) ) )

(de prtty2 (X N Z)
   (loop
      (print (++ X))
      (NIL X)
      (T (== Z X) (prin " ."))
      (T (atom X) (prin " . ") (print X))
      (if N
         (prtty? (++ X) N)
         (space)
         (print (++ X)) )
      (NIL X)
      (T (== Z X) (prin " ."))
      (T (atom X) (prin " . ") (print X))
      (if N
         (nlPrt N)
         (space 2) ) ) )

(de prtty3 (X N)
   (prin "(")
   (let Z X
      (print (++ X))
      (when (or (atom (car X)) (>= 12 (size (car X))))
         (spPrt (++ X)) )
      (when X
         (prtty1 X N Z)
         (space) ) )
   (prin ")") )

(de prtty? (X N)
   (ifn (or (atom X) (>= 12 (size X)))
      (nlPrt1 X N)
      (spPrt X) ) )

(de spPrt (X)
   (space)
   (print X) )

(de nlPrt (N)
   (prinl)
   (space (+ 3 N)) )

(de nlPrt1 (X N)
   (prinl)
   (pretty X (+ 3 N)) )

(de pp ("X" C)
   (let *Dbg NIL
      (pretty
         (if (or C (pair "X"))
            (cons 'dm "X"
               (if (pair "X")
                  (method (car "X") (cdr "X"))
                  (method "X" C) ) )
            (cons 'de "X" (val "X")) ) )
      (prinl)
      "X" ) )

(de show ("X" . @)
   (let *Dbg NIL
      (setq "X" (pass get "X"))
      (when (sym? "X")
         (print "X" (val "X"))
         (prinl)
         (maps
            '((X)
               (space 3)
               (if (atom X)
                  (println X)
                  (println (cdr X) (car X)) ) )
            "X" ) )
      "X" ) )

(de view (X Y)
   (let *Dbg NIL
      (if (=T Y)
         (let N 0
            (recur (N X)
               (when X
                  (recurse (+ 3 N) (cddr X))
                  (space N)
                  (println (car X))
                  (recurse (+ 3 N) (cadr X)) ) ) )
         (let Z X
            (loop
               (T (atom X) (println X))
               (if (atom (car X))
                  (println '+-- (++ X))
                  (print '+---)
                  (view
                     (++ X)
                     (append Y (cons (if X "|   " "    "))) ) )
               (NIL X)
               (mapc prin Y)
               (T (== Z X) (println '*))
               (println '|)
               (mapc prin Y) ) ) ) ) )

### Assertions ###
(de assert Prg
   (when *Dbg
      (let A (if (cdr Prg) (cons 'and Prg) (car Prg))
         (cons
            (list 'unless A
               (list 'quit "'assert' failed" (lit A)) ) ) ) ) )

############ lib/misc.l ############

# *Allow *Tmp

(de *Day . (Mon Tue Wed Thu Fri Sat Sun .))
(de *Mon . (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec .))
(de *mon . (jan feb mar apr may jun jul aug sep oct nov dec .))

### Locale ###
(de *Ctry)
(de *Lang)
(de *Sep0 . ".")
(de *Sep3 . ",")
(de *CtryCode)
(de *DateFmt @Y "-" @M "-" @D)
(de *DayFmt "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
(de *MonFmt "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December")

(de locale (Ctry Lang . @)  # "DE" "de" ["app/loc/" ..]
   (load (if (setq *Ctry Ctry) (pack "@loc/" @ ".l") "@loc/NIL.l"))
   (ifn (setq *Lang Lang)
      (for S (idx '*Uni)
         (set S S) )
      (let L
         (sort
            (make
               ("loc" (pack "@loc/" Lang))
               (while (args)
                  ("loc" (pack (next) Lang)) ) ) )
         (balance '*Uni L T)
         (for S L
            (set (car (idx '*Uni S)) (val S)) ) ) ) )

(de "loc" (F)
   (in F
      (use X
         (while (setq X (read))
            (if (=T X)
               ("loc" (read))
               (set (link @) (name (read))) ) ) ) ) )

### String ###
(de align (X . @)
   (pack
      (if (pair X)
         (mapcar
            '((X) (need X (chop (next)) " "))
            X )
         (need X (chop (next)) " ") ) ) )

(de center (X . @)
   (pack
      (if (pair X)
         (let R 0
            (mapcar
               '((X)
                  (let (S (chop (next))  N (>> 1 (+ X (length S))))
                     (prog1
                        (need (+ N R) S " ")
                        (setq R (- X N)) ) ) )
               X ) )
         (let S (chop (next))
            (need (>> 1 (+ X (length S))) S " ") ) ) ) )

(de wrap (Max Lst)
   (setq Lst (split Lst " " "^J"))
   (pack
      (make
         (while Lst
            (if (>= (length (car Lst)) Max)
               (link (++ Lst) "^J")
               (chain
                  (make
                     (link (++ Lst))
                     (loop
                        (NIL Lst)
                        (T (>= (+ (length (car Lst)) (sum length (made))) Max)
                           (link "^J") )
                        (link " " (++ Lst)) ) ) ) ) ) ) ) )

### Number ###
(de pad (N Val)
   (pack (need N (chop Val) "0")) )

(de money (N Cur)
   (if Cur
      (pack (format N 2 *Sep0 *Sep3) " " Cur)
      (format N 2 *Sep0 *Sep3) ) )

(de round (N D)
   (if (> *Scl (default D 3))
      (format (*/ N (** 10 (- *Scl D))) D *Sep0 *Sep3)
      (format N *Scl *Sep0 *Sep3) ) )

# Binary notation
(de bin (X I)
   (cond
      ((num? X)
         (let (S (and (lt0 X) '-)  L (& 1 X)  A (cons 0 I))
            (until (=0 (setq X (>> 1 X)))
               (at A (push 'L " "))
               (push 'L (& 1 X)) )
            (pack S L) ) )
      ((setq X (filter '((C) (not (sp? C))) (chop X)))
         (let (S (and (= '- (car X)) (++ X))  N 0)
            (for C X
               (setq N (| (format C) (>> -1 N))) )
            (if S (- N) N) ) ) ) )

# Octal notation
(de oct (X I)
   (cond
      ((num? X)
         (let (S (and (lt0 X) '-)  L (& 7 X)  A (cons 0 I))
            (until (=0 (setq X (>> 3 X)))
               (at A (push 'L " "))
               (push 'L (& 7 X)) )
            (pack S L) ) )
      ((setq X (filter '((C) (not (sp? C))) (chop X)))
         (let (S (and (= '- (car X)) (++ X))  N 0)
            (for C X
               (setq N (| (format C) (>> -3 N))) )
            (if S (- N) N) ) ) ) )

# Hexadecimal notation
(de hex (X I)
   (cond
      ((num? X)
         (let (S (and (lt0 X) '-)  L (hex1 X)  A (cons 0 I))
            (until (=0 (setq X (>> 4 X)))
               (at A (push 'L " "))
               (push 'L (hex1 X)) )
            (pack S L) ) )
      ((setq X (filter '((C) (not (sp? C))) (chop X)))
         (let (S (and (= '- (car X)) (++ X))  N 0)
            (for C X
               (setq C (- (char C) `(char "0")))
               (and (> C 9) (dec 'C 7))
               (and (> C 22) (dec 'C 32))
               (setq N (| C (>> -4 N))) )
            (if S (- N) N) ) ) ) )

(de hex1 (N)
   (let C (& 15 N)
      (and (> C 9) (inc 'C 7))
      (char (+ C `(char "0"))) ) )

### Tree ###
(de balance ("Var" "Lst" "Flg")
   (unless "Flg" (set "Var"))
   (let "Len" (length "Lst")
      (recur ("Lst" "Len")
         (unless (=0 "Len")
            (let ("N" (>> 1 (inc "Len"))  "L" (nth "Lst" "N"))
               (idx "Var" (car "L") T)
               (recurse "Lst" (dec "N"))
               (recurse (cdr "L") (- "Len" "N")) ) ) ) ) )

(de depth (Idx)  #> (max . average)
   (let (C 0  D 0  N 0)
      (cons
         (recur (Idx N)
            (ifn Idx
               0
               (inc 'C)
               (inc 'D (inc 'N))
               (inc
                  (max
                     (recurse (cadr Idx) N)
                     (recurse (cddr Idx) N) ) ) ) )
         (or (=0 (setq @@ C)) (*/ D C)) ) ) )

### Allow ###
(de allowed Lst
   (setq *Allow (cons NIL (car Lst)))
   (balance *Allow (sort (cdr Lst))) )

(de allow (X Flg)
   (nond
      (*Allow)
      (Flg (idx *Allow X T))
      ((member X (cdr *Allow)) (queue '*Allow X)) )
   X )

### Telephone ###
(de telStr (S)
   (cond
      ((not S))
      ((and *CtryCode (pre? (pack *CtryCode " ") S))
         (pack 0 (cdddr (chop S))) )
      (T (pack "+" S)) ) )

(de expTel (S)
   (setq S
      (make
         (for (L (chop S) L)
            (ifn (sub? (car L) " -")
               (link (++ L))
               (let F NIL
                  (loop
                     (and (= '- (++ L)) (on F))
                     (NIL L)
                     (NIL (sub? (car L) " -")
                        (link (if F '- " ")) ) ) ) ) ) ) )
   (cond
      ((= "+" (car S)) (pack (cdr S)))
      ((head '("0" "0") S)
         (pack (cddr S)) )
      ((and *CtryCode (= "0" (car S)))
         (pack *CtryCode " " (cdr S)) ) ) )

### Date ###
# ISO date
(de dat$ (Dat C)
   (when (date Dat)
      (pack (car @) C (pad 2 (cadr @)) C (pad 2 (caddr @))) ) )

(de $dat (S C)
   (if C
      (and
         (= 3
            (length (setq S (split (chop S) C))) )
         (date
            (format (car S))               # Year
            (or (format (cadr S)) 0)       # Month
            (or (format (caddr S)) 0) ) )  # Day
      (and
         (format S)
         (date
            (/ @ 10000)       # Year
            (% (/ @ 100) 100) # Month
            (% @ 100) ) ) ) )

(de datSym (Dat)
   (when (date Dat)
      (pack
         (pad 2 (caddr @))
         (get *mon (cadr @))
         (pad 2 (% (car @) 100)) ) ) )

# Localized
(de datStr (D F)
   (when (setq D (date D))
      (let
         (@Y (if F (pad 2 (% (car D) 100)) (pad 4 (car D)))
            @M (pad 2 (cadr D))
            @D (pad 2 (caddr D)) )
         (pack (fill *DateFmt)) ) ) )

(de strDat (S)
   (use (@Y @M @D)
      (and
         (match *DateFmt (chop S))
         (date
            (format @Y)
            (or (format @M) 0)
            (or (format @D) 0) ) ) ) )

(de expDat (S)
   (use (@Y @M @D X)
      (unless (match *DateFmt (setq S (chop S)))
         (if
            (or
               (cdr (setq S (split S ".")))
               (>= 2 (length (car S))) )
            (setq
               @D (car S)
               @M (cadr S)
               @Y (caddr S) )
            (setq
               @D (head 2 (car S))
               @M (head 2 (nth (car S) 3))
               @Y (nth (car S) 5) ) ) )
      (and
         (setq @D (format @D))
         (date
            (nond
               (@Y (car (date (date))))
               ((setq X (format @Y)))
               ((>= X 100)
                  (+ X
                     (* 100 (/ (car (date (date))) 100)) ) )
               (NIL X) )
            (nond
               (@M (cadr (date (date))))
               ((setq X (format @M)) 0)
               ((n0 X) (cadr (date (date))))
               (NIL X) )
            @D ) ) ) )

# Day of the week
(de day (Dat Lst)
   (when Dat
      (get
         (or Lst *DayFmt)
         (inc (% (inc Dat) 7)) ) ) )

# Week of the year
(de week (Dat)
   (let W
      (-
         (_week Dat)
         (_week (date (car (date Dat)) 1 4))
         -1 )
      (if (=0 W) 53 W) ) )

(de _week (Dat)
   (/ (- Dat (% (inc Dat) 7)) 7) )

# Last day of month
(de ultimo (Y M)
   (dec
      (if (= 12 M)
         (date (inc Y) 1 1)
         (date Y (inc M) 1) ) ) )

### Time ###
(de tim$ (Tim F)
   (when Tim
      (setq Tim (time Tim))
      (pack (pad 2 (car Tim)) ":" (pad 2 (cadr Tim))
         (and F ":")
         (and F (pad 2 (caddr Tim))) ) ) )

(de $tim (S)
   (setq S (split (chop S) ":"))
   (unless (or (cdr S) (>= 2 (length (car S))))
      (setq S
         (list
            (head 2 (car S))
            (head 2 (nth (car S) 3))
            (nth (car S) 5) ) ) )
   (when (format (car S))
      (time @
         (or (format (cadr S)) 0)
         (or (format (caddr S)) 0) ) ) )

(de stamp (Dat Tim)
   (and (=T Dat) (setq Dat (date T)))
   (default Dat (date)  Tim (time T))
   (pack (dat$ Dat "-") " " (tim$ Tim T)) )


(de dirname (F)
   (pack (flip (member '/ (flip (chop F))))) )

(de basename (F)
   (pack (stem (chop F) '/)) )

# Print or eval
(de prEval (Prg Ofs)
   (default Ofs 1)
   (for X Prg
      (if (atom X)
         (prinl (eval X Ofs))
         (eval X Ofs) ) ) )

# Echo here-documents
(de here (S)
   (line)
   (echo S) )

# Unit tests
(de test (Pat . Prg)
   (bind (fish pat? Pat)
      (unless (match Pat (run Prg 1))
         (msg Prg)
         (quit "'test' failed" Pat) ) ) )

############ lib/pilog.l ############

# *Rule

(de be CL
   (clause CL) )

(de clause (CL)
   (with (car CL)
      (if (== *Rule This)
         (queue (:: T) (cdr CL))
         (=: T (cons (cdr CL)))
         (setq *Rule This) )
      This ) )

(de repeat ()
   (conc (get *Rule T) (get *Rule T)) )

(de asserta (CL)
   (push (prop CL 1 T) (cdr CL)) )

(de assertz (CL)
   (queue (prop CL 1 T) (cdr CL)) )

(de retract (X)
   (if (sym? X)
      (put X T)
      (put (car X) T
         (delete (cdr X) (get (car X) T)) ) ) )

(de rules @
   (while (args)
      (let S (next)
         (for ((N . L) (get S T) L)
            (prin N " (be ")
            (print S)
            (for X (++ L)
               (space)
               (print X) )
            (prinl ")")
            (T (== L (get S T))
               (println '(repeat)) ) )
         S ) ) )

### Pilog Interpreter ###
(de goal ("CL" . @)
   (let "Env" '(T)
      (while (args)
         (push '"Env"
            (cons (cons 0 (next)) 1 (next)) ) )
      (while (and "CL" (pat? (car "CL")))
         (push '"Env"
            (cons
               (cons 0 (++ "CL"))
               (cons 1 (eval (++ "CL"))) ) ) )
      (cons
         (cons
            (conc (list 1 (0) NIL "CL" NIL) "Env") ) ) ) )

(de fail ()
   (goal '((NIL))) )

(de pilog ("CL" . "Prg")
   (for ("Q" (goal "CL") (prove "Q"))
      (bind @ (run "Prg")) ) )

(de solve ("CL" . "Prg")
   (make
      (if "Prg"
         (for ("Q" (goal "CL") (prove "Q"))
            (link (bind @ (run "Prg"))) )
         (for ("Q" (goal "CL") (prove "Q"))
            (link @) ) ) ) )

(de query ("Q" "Dbg")
   (use "R"
      (loop
         (NIL (prove "Q" "Dbg"))
         (T (=T (setq "R" @)) T)
         (for X "R"
            (space)
            (print (car X))
            (print '=)
            (print (cdr X))
            (flush) )
         (T (line)) ) ) )

(de ? "CL"
   (let "L"
      (make
         (while (nor (pat? (car "CL")) (lst? (car "CL")))
            (link (++ "CL")) ) )
      (query (goal "CL") "L") ) )

### Basic Rules ###
(be repeat)
(repeat)

(be true)

(be not @P (1 (-> @P)) T (fail))
(be not @P)

(be call @P
   (2 (cons (-> @P))) )

(be or @L (^ @C (box (-> @L))) (_or @C))

(be _or (@C) (3 (pop (-> @C))))
(be _or (@C) (^ @ (not (val (-> @C)))) T (fail))
(repeat)

(be nil (@X) (^ @ (not (-> @X))))

(be equal (@X @X))

(be different (@X @X) T (fail))
(be different (@ @))

(be append (NIL @X @X))
(be append ((@A . @X) @Y (@A . @Z)) (append @X @Y @Z))

(be member (@X (@X . @)))
(be member (@X (@ . @Y)) (member @X @Y))

(be delete (@A (@A . @Z) @Z))
(be delete (@A (@X . @Y) (@X . @Z))
   (delete @A @Y @Z) )

(be permute ((@X) (@X)))
(be permute (@L (@X . @Y))
   (delete @X @L @D)
   (permute @D @Y) )

(be uniq (@B @X)
   (^ @
      (let X (-> @X)
         (not (idx (-> @B) (cons (hash X) X) T)) ) ) )

(be asserta (@C) (^ @ (asserta (-> @C))))

(be assertz (@C) (^ @ (assertz (-> @C))))

(be retract (@C)
   (2 (cons (-> @C)))
   (^ @ (retract (list (car (-> @C)) (cdr (-> @C))))) )

(be clause ("@H" "@B")
   (^ "@A" (get (-> "@H") T))
   (member "@B" "@A") )

(be show (@X) (^ @ (show (-> @X))))

(be for (@N @End) (for @N 1 @End 1))
(be for (@N @Beg @End) (for @N @Beg @End 1))
(be for (@N @Beg @End @Step) (equal @N @Beg))
(be for (@N @Beg @End @Step)
   (^ @I (box (-> @Beg)))
   (_for @N @I @End @Step) )

(be _for (@N @I @End @Step)
   (^ @
      (if (>= (-> @End) (val (-> @I)))
         (> (inc (-> @I) (-> @Step)) (-> @End))
         (> (-> @End) (dec (-> @I) (-> @Step))) ) )
   T
   (fail) )

(be _for (@N @I @End @Step)
   (^ @N (val (-> @I))) )

(repeat)

(be val (@V . @L)
   (^ @V (apply get (-> @L)))
   T )

(be lst (@V . @L)
   (^ @Lst (box (apply get (-> @L))))
   (_lst @V @Lst) )

(be _lst (@Val @Lst) (^ @ (not (val (-> @Lst)))) T (fail))
(be _lst (@Val @Lst) (^ @Val (pop (-> @Lst))))
(repeat)

(be map (@V . @L)
   (^ @Lst (box (apply get (-> @L))))
   (_map @V @Lst) )

(be _map (@Val @Lst) (^ @ (not (val (-> @Lst)))) T (fail))
(be _map (@Val @Lst) (^ @Val (prog1 (val (-> @Lst)) (pop (-> @Lst)))))
(repeat)


(be isa (@Typ . @L)
   (^ @
      (or
         (not (-> @Typ))
         (isa (-> @Typ) (apply get (-> @L))) ) ) )

(be same (@V . @L)
   (^ @
      (let V (-> @V)
         (or
            (not V)
            (let L (-> @L)
               ("same" (car L) (cdr L)) ) ) ) ) )

(de "same" (X L)
   (cond
      ((not L)
         (if (atom X)
            (= V X)
            (member V X) ) )
      ((atom X)
         ("same" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("same" (get Y (car L)) (cdr L)))
            X ) )
      (T ("same" (apply get (car L) X) (cdr L))) ) )

(be bool (@F . @L)
   (^ @
      (or
         (not (-> @F))
         (apply get (-> @L)) ) ) )

(be range (@N . @L)
   (^ @
      (let N (-> @N)
         (or
            (not N)
            (let L (-> @L)
               ("range" (car L) (cdr L)) ) ) ) ) )

(de "range" (X L)
   (cond
      ((not L)
         (if (atom X)
            (or
               (<= (car N) X (cdr N))
               (>= (car N) X (cdr N)) )
            (find
               '((Y)
                  (or
                     (<= (car N) Y (cdr N))
                     (>= (car N) Y (cdr N)) ) )
               X ) ) )
      ((atom X)
         ("range" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("range" (get Y (car L)) (cdr L)))
            X ) )
      (T ("range" (apply get (car L) X) (cdr L))) ) )

(be head (@S . @L)
   (^ @
      (let S (-> @S)
         (or
            (not S)
            (let L (-> @L)
               ("head" (car L) (cdr L)) ) ) ) ) )

(de "head" (X L)
   (cond
      ((not L)
         (if (atom X)
            (pre? S X)
            (find '((Y) (pre? S Y)) X) ) )
      ((atom X)
         ("head" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("head" (get Y (car L)) (cdr L)))
            X ) )
      (T ("head" (apply get (car L) X) (cdr L))) ) )

(be fold (@S . @L)
   (^ @
      (let S (-> @S)
         (or
            (not S)
            (let L (-> @L)
               ("fold" (car L) (cdr L)) ) ) ) ) )

(de "fold" (X L)
   (cond
      ((not L)
         (let P (fold S)
            (if (atom X)
               (pre? P (fold X))
               (find '((Y) (pre? P (fold Y))) X) ) ) )
      ((atom X)
         ("fold" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("fold" (get Y (car L)) (cdr L)))
            X ) )
      (T ("fold" (apply get (car L) X) (cdr L))) ) )

(be part (@S . @L)
   (^ @
      (let S (-> @S)
         (or
            (not S)
            (let L (-> @L)
               ("part" (car L) (cdr L)) ) ) ) ) )

(de "part" (X L)
   (cond
      ((not L)
         (let P (fold S)
            (if (atom X)
               (sub? P (fold X))
               (find '((Y) (sub? P (fold Y))) X) ) ) )
      ((atom X)
         ("part" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("part" (get Y (car L)) (cdr L)))
            X ) )
      (T ("part" (apply get (car L) X) (cdr L))) ) )

(be tolr (@S . @L)
   (^ @
      (let S (-> @S)
         (or
            (not S)
            (let L (-> @L)
               ("tolr" (car L) (cdr L)) ) ) ) ) )

(de "tolr" (X L)
   (cond
      ((not L)
         (if (atom X)
            (or (sub? S X) (pre? (ext:Snx S) (ext:Snx X)))
            (let P (ext:Snx S)
               (find
                  '((Y)
                     (or (sub? S Y) (pre? P (ext:Snx Y))) )
                  X ) ) ) )
      ((atom X)
         ("tolr" (get X (car L)) (cdr L)) )
      ((atom (car L))
         (pick
            '((Y) ("tolr" (get Y (car L)) (cdr L)))
            X ) )
      (T ("tolr" (apply get (car L) X) (cdr L))) ) )


(be _remote ((@Obj . @))
   (^ @ (not (val (-> @Sockets 2))))
   T
   (fail) )

(be _remote ((@Obj . @))
   (^ @Obj
      (let (Box (-> @Sockets 2)  Lst (val Box))
         (rot Lst)
         (loop
            (T ((cdar Lst)) @)
            (NIL (set Box (setq Lst (cdr Lst)))) ) ) ) )

(repeat)

############ lib/xm.l ############

# Check or write header
(de xml? (Flg)
   (if Flg
      (prinl "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
      (skip)
      (prog1
         (head '("<" "?" "x" "m" "l") (till ">"))
         (char) ) ) )

# Generate/Parse XML data
(de xml (Lst N)
   (if Lst
      (let Tag (++ Lst)
         (space (default N 0))
         (prin "<" Tag)
         (for X (++ Lst)
            (prin " " (car X) "=\"")
            (escXml (cdr X))
            (prin "\"") )
         (nond
            (Lst (prinl "/>"))
            ((or (cdr Lst) (pair (car Lst)))
               (prin ">")
               (escXml (car Lst))
               (prinl "</" Tag ">") )
            (NIL
               (prinl ">")
               (for X Lst
                  (if (pair X)
                     (xml X (+ 3 N))
                     (space (+ 3 N))
                     (escXml X)
                     (prinl) ) )
               (space N)
               (prinl "</" Tag ">") ) ) )
      (skip)
      (unless (= "<" (char))
         (quit "Bad XML") )
      (_xml (till " /<>" T)) ) )

(de _xml (Tok)
   (use X
      (make
         (link (intern Tok))
         (let L
            (make
               (loop
                  (NIL (skip) (quit "XML parse error"))
                  (T (member @ '`(chop "/>")))
                  (NIL (setq X (intern (till "=" T))))
                  (char)
                  (unless (= "\"" (char))
                     (quit "XML parse error" X) )
                  (link (cons X (pack (xmlEsc (till "\"")))))
                  (char) ) )
            (if (= "/" (char))
               (prog (char) (and L (link L)))
               (link L)
               (loop
                  (NIL (skip) (quit "XML parse error" Tok))
                  (T (and (= "<" (setq X (char))) (= "/" (peek)))
                     (char)
                     (unless (= Tok (till " /<>" T))
                        (quit "Unbalanced XML" Tok) )
                     (char) )
                  (if (= "<" X)
                     (and (_xml (till " /<>" T)) (link @))
                     (link
                        (pack (xmlEsc (trim (cons X (till "^J<"))))) ) ) ) ) ) ) ) )

(de xmlEsc (L)
   (use (@X @Z)
      (make
         (while L
            (ifn (match '("&" @X ";" @Z) L)
               (link (++ L))
               (link
                  (cond
                     ((= @X '`(chop "quot")) "\"")
                     ((= @X '`(chop "amp")) "&")
                     ((= @X '`(chop "lt")) "<")
                     ((= @X '`(chop "gt")) ">")
                     ((= @X '`(chop "apos")) "'")
                     ((= "#" (car @X))
                        (char
                           (if (= "x" (cadr @X))
                              (hex (cddr @X))
                              (format (cdr @X)) ) ) )
                     (T @X) ) )
               (setq L @Z) ) ) ) ) )

(de escXml (X)
   (for C (chop X)
      (if (member C '`(chop "\"&<"))
         (prin "&#" (char C) ";")
         (prin C) ) ) )


# Access functions
(de body (Lst . @)
   (while (and (setq Lst (cddr Lst)) (args))
      (setq Lst (assoc (next) Lst)) )
   Lst )

(de attr (Lst Key . @)
   (while (args)
      (setq
         Lst (assoc Key (cddr Lst))
         Key (next) ) )
   (cdr (assoc Key (cadr Lst))) )

############ lib/xmlrpc.l ############

# (xmlrpc "localhost" 8080 "foo.bar" 'int 41 'string "abc" ..)
(de xmlrpc (Host Port Meth . @)
   (let? Sock (connect Host Port)
      (let Xml (tmp 'xmlrpc)
         (out Xml
            (xml? T)
            (xml
               (list 'methodCall NIL
                  (list 'methodName NIL Meth)
                  (make
                     (link 'params NIL)
                     (while (args)
                        (link
                           (list 'param NIL
                              (list 'value NIL (list (next) NIL (next))) ) ) ) ) ) ) )
         (prog1
            (out Sock
               (prinl "POST /RPC2 HTTP/1.0^M")
               (prinl "Host: " Host "^M")
               (prinl "User-Agent: PicoLisp^M")
               (prinl "Content-Type: text/xml^M")
               (prinl "Accept-Charset: utf-8^M")
               (prinl "Content-Length: " (car (info Xml)) "^M")
               (prinl "^M")
               (in Xml (echo))
               (flush)
               (in Sock
                  (while (line))
                  (let? L (and (xml?) (xml))
                     (when (== 'methodResponse (car L))
                        (xmlrpcValue
                           (car (body L 'params 'param 'value)) ) ) ) ) )
            (close Sock) ) ) ) )

(de xmlrpcKey (Str)
   (or (format Str) (intern Str)) )

(de xmlrpcValue (Lst)
   (let X (caddr Lst)
      (casq (car Lst)
         (string X)
         ((i4 int) (format X))
         (boolean (= "1" X))
         (double (format X *Scl))
         (array
            (when (== 'data (car X))
               (mapcar
                  '((L)
                     (and (== 'value (car L)) (xmlrpcValue (caddr L))) )
                  (cddr X) ) ) )
         (struct
            (extract
               '((L)
                  (when (== 'member (car L))
                     (cons
                        (xmlrpcKey (caddr (assoc 'name L)))
                        (xmlrpcValue (caddr (assoc 'value L))) ) ) )
               (cddr Lst) ) ) ) ) )

############ lib/http.l ############

### HTTP-Client ###
(de client (Host Port How . Prg)
   (let? Sock (connect Host Port)
      (prog1
         (out Sock
            (if (atom How)
               (prinl "GET /" How " HTTP/1.0^M")
               (prinl "POST /" (car How) " HTTP/1.0^M")
               (prinl "Content-Length: " (size (cdr How)) "^M") )
            (prinl "User-Agent: PicoLisp^M")
            (prinl "Host: " Host "^M")
            (prinl "Accept-Charset: utf-8^M")
            (prinl "^M")
            (and (pair How) (prin (cdr @)))
            (flush)
            (in Sock (run Prg 1)) )
         (close Sock) ) ) )

############ Native Java ############

(de javac (Cls Ext Impl . @)
   (let (J (pack "tmp/" Cls ".java")  C (pack "tmp/" Cls ".class"))
      (call "mkdir" "-p" "tmp/")
      (out J
         (while (args)
            (prinl "import " (next) ";") )
         (prinl "public class " Cls
            (and Ext (pack " extends " @))
            (and Impl (pack " implements " (glue ", " Impl)))
            " {"  )
         (here "/**/")
         (prinl "}") )
      (call "javac" "-O" "-g:none" J)
      (push1 '*Bye (list 'call "rm" J C)) ) )

### Debug ###
`*Dbg

############ lib/debug.l ############

# Prompt
(de *Prompt
   (unless (== (symbols) 'pico) (symbols)) )

# Browsing
(de doc (Sym Browser)
   (call (or Browser (sys "BROWSER") "w3m")
      (pack
         "file:"
         (and (= `(char '/) (char (path "@"))) "//")
         (path "@doc/ref")
         (if Sym
            (let (L (chop Sym)  C (car L))
               (and
                  (member C '("*" "+"))
                  (cadr L)
                  (setq C @) )
               (cond
                  ((>= "Z" C "A"))
                  ((>= "z" C "a") (setq C (uppc C)))
                  (T (setq C "_")) )
               (pack C ".html#" Sym) )
            ".html" ) ) ) )

(de more ("M" "Fun")
   (let *Dbg NIL
      (if (pair "M")
         ((default "Fun" print) (++ "M"))
         (println (type "M"))
         (setq
            "Fun" (list '(X) (list 'pp 'X (lit "M")))
            "M" (mapcar car (filter pair (val "M"))) ) )
      (loop
         (flush)
         (T (atom "M") (prinl))
         (T (line) T)
         ("Fun" (++ "M")) ) ) )

(de what (S)
   (let *Dbg NIL
      (setq S (chop S))
      (filter
         '(("X") (match S (chop "X")))
         (all) ) ) )


(de who ("X" . "*Prg")
   (let (*Dbg NIL  "Who" '("Who" @ @@ @@@))
      (make (mapc "who" (all))) ) )

(de "who" ("Y")
   (unless (or (ext? "Y") (memq "Y" "Who"))
      (push '"Who" "Y")
      (ifn (= `(char "+") (char "Y"))
         (and (pair (val "Y")) ("nest" @) (link "Y"))
         (for "Z" (pair (val "Y"))
            (if (atom "Z")
               (and ("match" "Z") (link "Y"))
               (when ("nest" (cdr "Z"))
                  (link (cons (car "Z") "Y")) ) ) )
         (maps
            '(("Z")
               (if (atom "Z")
                  (and ("match" "Z") (link "Y"))
                  (when ("nest" (car "Z"))
                     (link (cons (cdr "Z") "Y")) ) ) )
            "Y" ) ) ) )

(de "nest" ("Y")
   ("nst1" "Y")
   ("nst2" "Y") )

(de "nst1" ("Y")
   (let "Z" (setq "Y" (strip "Y"))
      (loop
         (T (atom "Y") (and (sym? "Y") ("who" "Y")))
         (and (sym? (car "Y")) ("who" (car "Y")))
         (and (pair (car "Y")) ("nst1" @))
         (T (== "Z" (setq "Y" (cdr "Y")))) ) ) )

(de "nst2" ("Y")
   (let "Z" (setq "Y" (strip "Y"))
      (loop
         (T (atom "Y") ("match" "Y"))
         (T (or ("match" (car "Y")) ("nst2" (car "Y")))
            T )
         (T (== "Z" (setq "Y" (cdr "Y")))) ) ) )

(de "match" ("D")
   (and
      (cond
         ((str? "X") (and (str? "D") (= "X" "D")))
         ((sym? "X") (== "X" "D"))
         (T (match "X" "D")) )
      (or
         (not "*Prg")
         (let *Dbg (up 2 *Dbg) (run "*Prg")) ) ) )

(de has ("X")
   (let *Dbg NIL
      (filter
         '(("S") (= "X" (val "S")))
         (all) ) ) )

(de can (X)
   (let *Dbg NIL
      (extract
         '(("Y")
            (and
               (= `(char "+") (char "Y"))
               (asoq X (val "Y"))
               (cons X "Y") ) )
         (all) ) ) )

# Class dependencies
(de dep ("C")
   (let *Dbg NIL
      (dep1 0 "C")
      (dep2 3 "C")
      "C" ) )

(de dep1 (N "C")
   (for "X" (type "C")
      (dep1 (+ 3 N) "X") )
   (space N)
   (println "C") )

(de dep2 (N "C")
   (for "X" (all)
      (when
         (and
            (= `(char "+") (char "X"))
            (memq "C" (type "X")) )
         (space N)
         (println "X")
         (dep2 (+ 3 N) "X") ) ) )

# Inherited methods
(de methods (Obj)
   (make
      (let Mark NIL
         (recur (Obj)
            (for X (val Obj)
               (nond
                  ((pair X) (recurse X))
                  ((memq (car X) Mark)
                     (link (cons (car X) Obj))
                     (push 'Mark (car X)) ) ) ) ) ) ) )

# Single-Stepping
(de _dbg (Lst)
   (or
      (atom (car Lst))
      (num? (caar Lst))
      (flg? (caar Lst))
      (== '! (caar Lst))
      (set Lst (cons '! (car Lst))) ) )

(de _dbg2 (Lst)
   (map
      '((L)
         (if (and (pair (car L)) (flg? (caar L)))
            (map _dbg (cdar L))
            (_dbg L) ) )
      Lst ) )

(de dbg (Lst)
   (when (pair Lst)
      (casq (++ Lst)
         ((case casq state)
            (_dbg Lst)
            (for L (cdr Lst)
               (map _dbg (cdr L)) ) )
         ((cond nond)
            (for L Lst
               (map _dbg L) ) )
         (quote
            (when (fun? Lst)
               (map _dbg (cdr Lst)) ) )
         ((job use let let? recur)
            (map _dbg (cdr Lst)) )
         (loop
            (_dbg2 Lst) )
         ((bind do)
            (_dbg Lst)
            (_dbg2 (cdr Lst)) )
         (for
            (and (pair (car Lst)) (map _dbg (cdar Lst)))
            (_dbg2 (cdr Lst)) )
         (T (map _dbg Lst)) )
      T ) )

(de d () (let *Dbg NIL (dbg ^)))

(de debug ("X" C)
   (ifn (traced? "X" C)
      (let *Dbg NIL
         (when (pair "X")
            (setq C (cdr "X")  "X" (car "X")) )
         (or
            (dbg (if C (method "X" C) (getd "X")))
            (quit "Can't debug" "X") ) )
      (untrace "X" C)
      (debug "X" C)
      (trace "X" C) ) )

(de ubg (Lst)
   (when (pair Lst)
      (map
         '((L)
            (when (pair (car L))
               (when (== '! (caar L))
                  (set L (cdar L)) )
               (ubg (car L)) ) )
         Lst )
      T ) )

(de u () (let *Dbg NIL (ubg ^)))

(de unbug ("X" C)
   (let *Dbg NIL
      (when (pair "X")
         (setq C (cdr "X")  "X" (car "X")) )
      (or
         (ubg (if C (method "X" C) (getd "X")))
         (quit "Can't unbug" "X") ) ) )

# Tracing
(de traced? ("X" C)
   (setq "X"
      (if C
         (method "X" C)
         (getd "X") ) )
   (and
      (pair "X")
      (pair (cadr "X"))
      (== '$ (caadr "X")) ) )

# Convert ((X Y) A B) --> ((X Y) ($ foo (X Y) A B))
(de trace ("X" C)
   (let *Dbg NIL
      (when (pair "X")
         (setq C (cdr "X")  "X" (car "X")) )
      (if C
         (unless (traced? "X" C)
            (or (method "X" C) (quit "Can't trace" "X"))
            (con @
               (cons
                  (conc
                     (list '$ (cons "X" C) (car @))
                     (cdr @) ) ) ) )
         (unless (traced? "X")
            (and (sym? (getd "X")) (quit "Can't trace" "X"))
            (and (num? (getd "X")) (expr "X"))
            (set "X"
               (list
                  (car (getd "X"))
                  (conc (list '$ "X") (getd "X")) ) ) ) )
      "X" ) )

# Convert ((X Y) ($ foo (X Y) A B)) --> ((X Y) A B)
(de untrace ("X" C)
   (let *Dbg NIL
      (when (pair "X")
         (setq C (cdr "X")  "X" (car "X")) )
      (if C
         (when (traced? "X" C)
            (con
               (method "X" C)
               (cdddr (cadr (method "X" C))) ) )
         (when (traced? "X")
            (let X (set "X" (cddr (cadr (getd "X"))))
               (and
                  (== '@ (++ X))
                  (= 1 (length X))
                  (= 2 (length (car X)))
                  (== 'pass (caar X))
                  (sym? (cdadr X))
                  (subr "X") ) ) ) )
      "X" ) )

(de *NoTrace
   @ @@ @@@
   pp show more
   what who can dep d e debug u unbug trace untrace )

(de traceAll (Excl)
   (let *Dbg NIL
      (for "X" (all)
         (or
            (memq "X" Excl)
            (memq "X" *NoTrace)
            (= `(char "*") (char "X"))
            (cond
               ((= `(char "+") (char "X"))
                  (mapc trace
                     (extract
                        '(("Y")
                           (and
                              (pair "Y")
                              (fun? (cdr "Y"))
                              (cons (car "Y") "X") ) )
                        (val "X") ) ) )
               ((pair (getd "X"))
                  (trace "X") ) ) ) ) ) )

# Process Listing
(de proc @
   (apply call
      (make (while (args) (link "-C" (next))))
      "ps" "-H" "-o" "pid,ppid,start,size,pcpu,time,cmd" ) )

# Benchmarking
(de bench Prg
   (let U (usec)
      (prog1
         (run Prg 1)
         (out 2
            (prinl
               (format (*/ (- (usec) U) 1000) 3)
               " sec" ) ) ) ) )

############ lib/lint.l ############

(de noLint (X V)
   (if V
      (push1 '*NoLint (cons X V))
      (or (memq X *NoLint) (push '*NoLint X)) ) )

(de global? (S)
   (or
      (memq S '(NIL ^ @ @@ @@@ This T))
      (member (char S) '(`(char '*) `(char '+))) ) )

(de local? (S)
   (or
      (str? S)
      (member (char S) '(`(char '*) `(char '_))) ) )

(de dlsym? (S)
   (and
      (car (setq S (split (chop S) ':)))
      (cadr S)
      (low? (caar S)) ) )

(de lint1 ("X")
   (cond
      ((atom "X")
         (when (sym? "X")
            (cond
               ((memq "X" "*L") (setq "*Use" (delq "X" "*Use")))
               ((local? "X") (lint2 (val "X")))
               (T
                  (or
                     (getd "X")
                     (global? "X")
                     (member (cons "*X" "X") *NoLint)
                     (memq "X" "*Bnd")
                     (push '"*Bnd" "X") ) ) ) ) )
      ((num? (car "X")))
      (T
         (casq (car "X")
            ((: ::))
            (; (lint1 (cadr "X")))
            (quote
               (let F (fun? (cdr "X"))
                  (if (or (and (pair F) (not (fin @))) (== '@ F))
                     (use "*L" (lintFun (cdr "X")))
                     (lint2 (cdr "X")) ) ) )
            ((de dm)
               (let "*X" (cadr "X")
                  (lintFun (cddr "X")) ) )
            (recur
               (let recurse (cdr "X")
                  (lintFun recurse) ) )
            (task
               (lint1 (cadr "X"))
               (let "Y" (cddr "X")
                  (use "*L"
                     (while (num? (car "Y"))
                        (++ "Y") )
                     (while (and (car "Y") (sym? @))
                        (lintVar (++ "Y"))
                        (++ "Y") )
                     (mapc lint1 "Y") ) ) )
            (macro
               (lint2 (cdr "X")) )
            (let?
               (use "*L"
                  (lintVar (cadr "X"))
                  (mapc lint1 (cddr "X")) ) )
            (let
               (use "*L"
                  (if (atom (cadr "X"))
                     (lintVar (cadr "X"))
                     (for (L (cadr "X") L (cddr L))
                        (lintDup (car L)
                           (extract '((X F) (and F X))
                              (cddr L)
                              '(T NIL .) ) )
                        (lintVar (car L))
                        (lint1 (cadr L)) ) )
                  (mapc lint1 (cddr "X")) ) )
            (use
               (use "*L"
                  (if (atom (cadr "X"))
                     (lintVar (cadr "X"))
                     (mapc lintVar (cadr "X")) )
                  (mapc lint1 (cddr "X")) ) )
            (for
               (use "*L"
                  (let "Y" (cadr "X")
                     (cond
                        ((atom "Y")          # (for X (1 2 ..) ..)
                           (lint1 (caddr "X"))
                           (lintVar "Y")
                           (lintLoop (cdddr "X")) )
                        ((atom (cdr "Y"))    # (for (I . X) (1 2 ..) ..)
                           (lintVar (car "Y"))
                           (lint1 (caddr "X"))
                           (lintVar (cdr "Y"))
                           (lintLoop (cdddr "X")) )
                        ((atom (car "Y"))    # (for (X (1 2 ..) ..) ..)
                           (lint1 (cadr "Y"))
                           (lintVar (car "Y"))
                           (mapc lint1 (cddr "Y"))
                           (lintLoop (cddr "X")) )
                        (T                   # (for ((I . L) (1 2 ..) ..) ..)
                           (lintVar (caar "Y"))
                           (lint1 (cadr "Y"))
                           (lintVar (cdar "Y"))
                           (mapc lint1 (cddr "Y"))
                           (lintLoop (cddr "X")) ) ) ) ) )
            ((case casq state)
               (lint1 (cadr "X"))
               (for "X" (cddr "X")
                  (mapc lint1 (cdr "X")) ) )
            ((cond nond)
               (for "X" (cdr "X")
                  (mapc lint1 "X") ) )
            (loop
               (lintLoop (cdr "X")) )
            (do
               (lint1 (cadr "X"))
               (lintLoop (cddr "X")) )
            (=:
               (lint1 (last (cddr "X"))) )
            ((dec inc pop push push1 queue fifo val idx accu)
               (_lintq '(T)) )
            ((cut port)
               (_lintq '(NIL T)) )
            (set
               (_lintq '(T NIL .)) )
            (xchg
               (_lintq '(T T .)) )
            (T
               (cond
                  ((pair (car "X"))
                     (lint1 @)
                     (mapc lint2 (cdr "X")) )
                  ((memq (car "X") "*L")
                     (setq "*Use" (delq (car "X") "*Use"))
                     (mapc lint2 (cdr "X")) )
                  ((fun? (val (car "X")))
                     (if (num? @)
                        (mapc lint1 (cdr "X"))
                        (when (local? (car "X"))
                           (lint2 (val (car "X"))) )
                        (let "Y" (car (getd (++ "X")))
                           (while (and (pair "X") (pair "Y"))
                              (lint1 (++ "X"))
                              (++ "Y") )
                           (if (or (== '@ "Y") (= "Prg" "Y") (= "*Prg" "Y"))
                              (mapc lint1 "X")
                              (lint2 "X") ) ) ) )
                  (T
                     (or
                        (str? (car "X"))
                        (dlsym? (car "X"))
                        (== '@ (car "X"))
                        (memq (car "X") *NoLint)
                        (memq (car "X") "*Def")
                        (push '"*Def" (car "X")) )
                     (mapc lint1 (cdr "X")) ) ) ) ) ) ) )

(de lint2 (X Mark)
   (cond
      ((memq X Mark))
      ((atom X)
         (and (memq X "*L") (setq "*Use" (delq X "*Use"))) )
      (T (lint2 (car X))
         (lint2 (cdr X) (cons X Mark)) ) ) )

(de lintVar (X Flg)
   (cond
      ((or (not (sym? X)) (memq X '(NIL ^ meth quote T)))
         (push '"*Var" X) )
      ((not (global? X))
         (or
            Flg
            (member (cons "*X" X) *NoLint)
            (memq X "*Use")
            (push '"*Use" X) )
         (push '"*L" X) ) ) )

(de lintDup (X Lst)
   (and
      (memq X Lst)
      (not (member (cons "*X" X) *NoLint))
      (push '"*Dup" X) ) )

(de lintLoop ("Lst")
   (for "Y" "Lst"
      (if (and (pair "Y") (or (=T (car "Y")) (not (car "Y"))))
         (mapc lint1 (cdr "Y"))
         (lint1 "Y") ) ) )

(de _lintq (Lst)
   (mapc
      '((X Flg)
         (lint1 (if Flg (strip X) X)) )
      (cdr "X")
      Lst ) )

(de lintFun ("Lst")
   (let "A" (and (pair "Lst") (car "Lst"))
      (while (pair "A")
         (lintDup (car "A") (cdr "A"))
         (lintVar (++ "A") T) )
      (when "A"
         (lintVar "A") )
      (mapc lint1 (cdr "Lst")) ) )

(de lint ("X" "C")
   (let ("*L" NIL  "*Var" NIL  "*Dup" NIL  "*Def" NIL  "*Bnd" NIL  "*Use" NIL)
      (when (pair "X")
         (setq  "C" (cdr "X")  "X" (car "X")) )
      (cond
         ("C"  # Method
            (let "*X" (cons "X" "C")
               (lintFun (method "X" "C")) ) )
         ((pair (val "X"))  # Function
            (let "*X" "X"
               (lintFun (val "X")) ) )
         ((info "X")  # File name
            (let "*X" "X"
               (in "X" (while (read) (lint1 @))) ) )
         (T (quit "Can't lint" "X")) )
      (when (or "*Var" "*Dup" "*Def" "*Bnd" "*Use")
         (make
            # Bad variables
            (and "*Var" (link (cons 'var "*Var")))
            # Duplicate parameters
            (and "*Dup" (link (cons 'dup "*Dup")))
            # Undefined functions
            (and "*Def" (link (cons 'def "*Def")))
            # Unbound variables
            (and "*Bnd" (<> `(char '_) (char "X")) (link (cons 'bnd "*Bnd")))
            # Unused variables
            (and "*Use" (link (cons 'use "*Use"))) ) ) ) )

(de lintAll @
   (let *Dbg NIL
      (make
         (for "X" (all)
            (cond
               ((and (= `(char "+") (char "X")) (pair (val "X")))
                  (for "Y" @
                     (and
                        (pair "Y")
                        (fun? (cdr "Y"))
                        (lint (car "Y") "X")
                        (link (cons (cons (car "Y") "X") @)) ) ) )
               ((and (not (global? "X")) (pair (getd "X")) (lint "X"))
                  (link (cons "X" @)) ) ) )
         (while (args)
            (and (lint (next)) (link (cons (arg) @))) ) ) ) )

(noLint 'pretty 'Z)
(noLint '_pretty 'Z)

# vi:et:ts=3:sw=3
