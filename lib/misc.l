# 27dec02abu
# (c) Software Lab. Alexander Burger

### Locale ###
(off *Ctry *Lang)
(de *Str)
(de *Sep0 . ".")
(de *Sep3 . ",")
(de *DateFmt @Y "-" @M "-" @D)
(de *DayFmt Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
(de *MonFmt January February March April May June July August September October November December)
(de *Help "loc/help/en.l")

(de _ Str
   (if (member (car Str) *Str)
      (car @)
      (push '*Str (car Str)) ) )

(de locale (Ctry Lang Dir)  # "DE" "de" ["app/loc/"]
   (load (if (setq *Ctry Ctry) (pack "loc/" @) "loc/NIL"))
   (ifn (setq *Lang Lang)
      (mapc '(("S") (set "S" "S")) *Str)
      (locStr (pack "loc/" Lang))
      (and Dir (locStr (pack Dir Lang))) ) )

(de locStr (F)
   (in F
      (for ("K" (read) "K" (read))
         (let "V" (read)
            (if (member "K" *Str)
               (set (car @) "V")
               (set "K" "V")
               (push '*Str "K") ) ) ) ) )

### Math ###
# (Knuth Vol.2, p.442)
(de ** (X N)  # N th power of X
   (let Y 1
      (do NIL
         (when (bit? 1 N)
            (setq Y (* Y X)) )
         (T (=0 (setq N (>> 1 N)))
            Y )
         (setq X (* X X)) ) ) )

(de accu (Var Key Val)
   (default Val 1)
   (if (assoc Key (val Var))
      (con @ (+ Val (cdr @)))
      (push Var (cons Key Val)) ) )

### String ###
(de align (N Val)
   (pack
      (need N
         (chop (if (sym? Val) Val (format Val)))
         " " ) ) )

(de center (N Val)
   (align (>> 1 (+ N (length Val))) Val) )

(de glue (Str Lst)
   (pack
      (maplist
         '((L)
            (cons
               (car L)
               (and (cdr L) Str) ) )
         Lst ) ) )

(de tolr (P D)
   (or
      (sub? P D)
      (pre? (ext:Snx P) (ext:Snx D)) ) )

### Number ###
(de pad (N Val)
   (pack
      (need N
         (chop (if (sym? Val) Val (format Val)))
         "0" ) ) )

(de oct (X)
   (if (num? X)
      (let L (_oct X)
         (until (=0 (setq X (>> 3 X)))
            (push 'L (_oct X)) )
         (pack L) )
      (and (sym? X) (setq X (chop X)))
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
      (and (sym? X) (setq X (chop X)))
      (let N 0
         (while X
            (let C (- (char (pop 'X)) `(char "0"))
               (and (> C 9) (dec 'C 7))
               (setq N (+ C (>> -4 N))) ) )
         N ) ) )

(de _hex (N)
   (let C (& 15 N)
      (and (> C 9) (inc 'C 7))
      (char (+ C `(char "0"))) ) )

(de money (N Cur)
   (if Cur
      (pack (format N 2 *Sep0 *Sep3) " " Cur)
      (format N 2 *Sep0 *Sep3) ) )

### Date ###
# ISO date
(de dat$ (Dat C)
   (when Dat
      (setq Dat (date Dat))
      (pack (car Dat) C (pad 2 (cadr Dat)) C (pad 2 (caddr Dat))) ) )

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
   (when Dat
      (setq Dat (date Dat))
      (pack (pad 2 (caddr Dat)) (month (cadr Dat)) (pad 2 (% (car Dat) 100))) ) )

# Localized
(de datStr (D F)
   (when D
      (setq D (date D))
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
(de day (N)
   (get *DayFmt (+ 1 (% (+ 1 N) 7))) )

# Week of the year
(de week (Dat)
   (-
      (_week Dat)
      (_week (date (car (date Dat)) 1 4))
      -1 ) )

(de _week (Dat)
   (/ (- Dat (% (+ Dat 1) 7)) 7) )

# Month name
(de month (N)
   (get '(jan feb mar apr may jun jul aug sep oct nov dec) N) )

### Time ###
(de tim$ (Tim F)
   (when Tim
      (setq Tim (time Tim))
      (pack (car Tim) ":" (pad 2 (cadr Tim))
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
   (default
      Dat (date)
      Tim (time) )
   (setq Tim (time Tim))
   (pack
      (dat$ Dat "-")
      " "
      (pack
         (pad 2 (car Tim)) ":"
         (pad 2 (cadr Tim)) ":"
         (pad 2 (caddr Tim)) ) ) )

### I/O ###
# Directory contents
(de dir (Dir)
   (use L
      (make
         (in (list "sh" "-c" (pack "ls " Dir))
            (until (=T (setq L (line T)))
               (link L) ) ) ) ) )

(de dirname (F)
   (pack
      (reverse (cdr (member "/" (reverse (chop F))))) ) )

# Print or eval
(de prEval ("Prg")
   (while "Prg"
      ((if (atom (car "Prg")) prinl eval) (pop '"Prg")) ) )

# Send Mail
(de mail (Addr Sub CC . "Prg")
   (out (list "mail" "-s" Sub "-c" CC Addr)
      (prEval "Prg") ) )

### Base 64 ###
(de fmt64 (X)
   (if (num? X)
      (let L (_fmt64 X)
         (until (=0 (setq X (>> 6 X)))
            (push 'L (_fmt64 X)) )
         (pack L) )
      (and (sym? X) (setq X (chop X)))
      (let N 0
         (while X
            (let C (- (char (pop 'X)) `(char "0"))
               (and (> C 42) (dec 'C 6))
               (and (> C 11) (dec 'C 5))
               (setq N (+ C (>> -6 N))) ) )
         N ) ) )

(de _fmt64 (N)
   (let C (& 63 N)
      (and (> C 11) (inc 'C 5))
      (and (> C 42) (inc 'C 6))
      (char (+ C `(char "0"))) ) )

(de objID (S)
   (fmt64 (>> 6 (hex S))) )

(de idAdr (S)
   (hex (>> -6 (fmt64 S))) )

### System ###
(de test ("Val" . "Prg")
   (unless (= "Val" (run "Prg"))
      (println 'fail "Prg") ) )
