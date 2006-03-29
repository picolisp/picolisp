# 13mar06abu
# (c) Software Lab. Alexander Burger

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
(de *DayFmt Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
(de *MonFmt January February March April May June July August September October November December)
(de *Help "loc/help/en.l")

(de locale (Ctry Lang App)  # "DE" "de" ["app/loc/"]
   (load (if (setq *Ctry Ctry) (pack "@loc/" @) "@loc/NIL"))
   (ifn (setq *Lang Lang)
      (for "S" *Uni (set "S" "S"))
      (locStr (pack "@loc/" Lang))
      (and App (locStr (pack App Lang))) ) )

(de locStr (F)
   (in F
      (for ("K" (read) "K" (read))
         (let "V" (read)
            (if (member "K" *Uni)
               (set (car @) "V")
               (set "K" "V")
               (push '*Uni "K") ) ) ) ) )

### Math ###
# (Knuth Vol.2, p.442)
(de ** (X N)  # N th power of X
   (let Y 1
      (loop
         (when (bit? 1 N)
            (setq Y (* Y X)) )
         (T (=0 (setq N (>> 1 N)))
            Y )
         (setq X (* X X)) ) ) )

(de accu (Var Key Val)
   (when Val
      (if (assoc Key (val Var))
         (con @ (+ Val (cdr @)))
         (push Var (cons Key Val)) ) ) )

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
               (link (pop 'Lst) "^J")
               (chain
                  (make
                     (link (pop 'Lst))
                     (loop
                        (NIL Lst)
                        (T (>= (+ (length (car Lst)) (sum length (made))) Max)
                           (link "^J") )
                        (link " " (pop 'Lst)) ) ) ) ) ) ) ) )

(de glue (Str Lst)
   (pack
      (maplist
         '((L)
            (cons
               (car L)
               (and (cdr L) Str) ) )
         Lst ) ) )

### Number ###
(de pad (N Val)
   (pack (need N (chop Val) "0")) )

(de oct (X)
   (if (num? X)
      (let L (_oct X)
         (until (=0 (setq X (>> 3 X)))
            (push 'L (_oct X)) )
         (pack L) )
      (setq X (chop X))
      (let N 0
         (while X
            (setq N
               (+
                  (- (char (pop 'X)) `(char "0"))
                  (>> -3 N) ) ) )
         N ) ) )

(de _oct (N)
   (char (+ (& N 7) `(char "0"))) )

(de hex (X)
   (if (num? X)
      (let L (_hex X)
         (until (=0 (setq X (>> 4 X)))
            (push 'L (_hex X)) )
         (pack L) )
      (let N 0
         (for C (chop X)
            (setq C (- (char C) `(char "0")))
            (and (> C 9) (dec 'C 7))
            (setq N (+ C (>> -4 N))) )
         N ) ) )

(de _hex (N)
   (let C (& 15 N)
      (and (> C 9) (inc 'C 7))
      (char (+ C `(char "0"))) ) )

(de money (N Cur)
   (if Cur
      (pack (format N 2 *Sep0 *Sep3) " " Cur)
      (format N 2 *Sep0 *Sep3) ) )

### Tree ###
(de balance ("Var" "Lst")
   (let "Len" (length "Lst")
      (recur ("Lst" "Len")
         (unless (=0 "Len")
            (let ("N" (>> 1 (inc "Len"))  "L" (nth "Lst" "N"))
               (idx "Var" (car "L") T)
               (recurse "Lst" (dec "N"))
               (recurse (cdr "L") (- "Len" "N")) ) ) ) ) )

### Allow ###
(de allowed Lst
   (setq *Allow (cons NIL (car Lst)))
   (balance *Allow (sort (cdr Lst))) )

(de allow (X)
   (and *Allow (idx *Allow X T))
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
               (link (pop 'L))
               (let F NIL
                  (loop
                     (and (= '- (pop 'L)) (on F))
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
            (format (pack (car S)))                # Year
            (or (format (pack (cadr S))) 0)        # Month
            (or (format (pack (caddr S))) 0) ) )   # Day
      (and
         (setq S (format S))
         (date
            (/ S 10000)       # Year
            (% (/ S 100) 100) # Month
            (% S 100) ) ) ) )

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
            (format (pack @Y))
            (or (format (pack @M)) 0)
            (or (format (pack @D)) 0) ) ) ) )

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
         (setq @D (format (pack @D)))
         (date
            (cond
               ((not @Y)
                  (car (date (date))) )
               ((not (setq X (format (pack @Y)))))
               ((< X 100)
                  (+ X
                     (* 100 (/ (car (date (date))) 100)) ) )
               (T X) )
            (cond
               ((not @M)
                  (cadr (date (date))) )
               ((not (setq X (format (pack @M))))
                  0 )
               ((=0 X)
                  (cadr (date (date))) )
               (T X) )
            @D ) ) ) )

# Day of the week
(de day (Dat Lst)
   (get
      (or Lst *DayFmt)
      (inc (% (inc Dat) 7)) ) )

# Week of the year
(de week (Dat)
   (-
      (_week Dat)
      (_week (date (car (date Dat)) 1 4))
      -1 ) )

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
   (when (format (pack (car S)))
      (time @
         (or (format (pack (cadr S))) 0)
         (or (format (pack (caddr S))) 0) ) ) )

(de stamp (Dat Tim)
   (default  Dat (date)  Tim (time))
   (pack (dat$ Dat "-") " " (tim$ Tim T)) )

### I/O ###
(de chdir ("Dir" . "Prg")
   (let? "Old" (cd "Dir")
      (finally (cd "Old")
         (run "Prg") ) ) )

(de dirname (F)
   (pack
      (flip (cdr (member "/" (reverse (chop F))))) ) )

# Temporary Files
(?push '*Fork '(off *Tmp))
(?push '*Bye '(and *Tmp (call 'rm "-r" *Tmp)))

(de tmp @
   (unless *Tmp
      (call 'mkdir "-p" (setq *Tmp (pack "tmp/" *Pid "/"))) )
   (pass pack *Tmp) )


# Print or eval
(de prEval ("Prg")
   (while "Prg"
      ((if (atom (car "Prg")) prinl eval) (pop '"Prg")) ) )

# Echo here-documents
(de here (X)
   (line)
   (echo X) )

# Send mail
(de mail ("Host" "Port" "From" "To" "Sub" "Att" . "Prg")
   (let? "S" (connect "Host" "Port")
      (let ("B" (pack "==" (date) "-" (time) "=="))
         (prog1
            (and
               (pre? "220 " (in "S" (line T)))
               (out "S" (prinl "HELO " (cdr (member "@" (chop "From"))) "^M"))
               (pre? "250 " (in "S" (line T)))
               (out "S" (prinl "MAIL FROM:" "From" "^M"))
               (pre? "250 " (in "S" (line T)))
               (out "S" (prinl "RCPT TO:" "To" "^M"))
               (pre? "250 " (in "S" (line T)))
               (out "S" (prinl "DATA^M"))
               (pre? "354 " (in "S" (line T)))
               (out "S"
                  (prinl "From: " "From" "^M")
                  (prinl "To: " "To" "^M")
                  (prinl "Subject: " "Sub" "^M")
                  (prinl "User-Agent: PicoLisp^M")
                  (prinl "MIME-Version: 1.0^M")
                  (when "Att"
                     (prinl "Content-Type: multipart/mixed; boundary=\"" "B" "\"^M")
                     (prinl "^M")
                     (prinl "--" "B" "^M") )
                  (prinl "Content-Type: text/plain; charset=utf-8^M")
                  (prinl "Content-Transfer-Encoding: 8bit^M")
                  (prinl "^M")
                  (prEval "Prg")
                  (prinl "^M")
                  (when "Att"
                     (loop
                        (prinl "--" "B" "^M")
                        (prinl
                           "Content-Type: "
                           (or (caddr "Att") "application/octet-stream")
                           "; name=\""
                           (cadr "Att")
                           "\"^M" )
                        (prinl "Content-Transfer-Encoding: base64^M")
                        (prinl "^M")
                        (in (list "uuencode" "-m" (car "Att") (cadr "Att"))
                           (line)
                           (echo '====) )
                        (prinl "^M")
                        (NIL (setq "Att" (cdddr "Att"))) )
                     (prinl "--" "B" "--^M") )
                  (prinl ".^M")
                  (prinl "QUIT^M") )
               T )
            (close "S") ) ) ) )

### Base 64 ###
(de fmt64 (X)
   (if (num? X)
      (let L (_fmt64 X)
         (until (=0 (setq X (>> 6 X)))
            (push 'L (_fmt64 X)) )
         (pack L) )
      (let N 0
         (for C (chop X)
            (setq C (- (char C) `(char "0")))
            (and (> C 42) (dec 'C 6))
            (and (> C 11) (dec 'C 5))
            (setq N (+ C (>> -6 N))) )
         N ) ) )

(de _fmt64 (N)
   (let C (& 63 N)
      (and (> C 11) (inc 'C 5))
      (and (> C 42) (inc 'C 6))
      (char (+ C `(char "0"))) ) )

### System ###
(de gcc (S L . @)
   (out (tmp S ".c")
      (chdir '@ (prinl "#include \"" (pwd) "/src/pico.h\""))
      (here "/**/") )
   (apply call L 'gcc "-o" (tmp S)
      "-shared" "-nostartfiles" "-nostdlib" "-export-dynamic"
      "-O" "-falign-functions" "-fomit-frame-pointer"
      "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
      "-Wuninitialized" "-Wstrict-prototypes"
      "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") )
   (while (args)
      (def (next) (tmp S ': (arg))) ) )

(de test ("Pat" . "Prg")
   (unless (match "Pat" (run "Prg"))
      (println 'fail "Prg") ) )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
