# 25dec10abu
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
(de *DayFmt "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
(de *MonFmt "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December")

(de locale (Ctry Lang App)  # "DE" "de" ["app/loc/"]
   (load (if (setq *Ctry Ctry) (pack "@loc/" @ ".l") "@loc/NIL.l"))
   (ifn (setq *Lang Lang)
      (for S (idx '*Uni)
         (set S S) )
      (let L
         (sort
            (make
               ("loc" (pack "@loc/" Lang))
               (and App ("loc" (pack App Lang))) ) )
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

### Math ###
(de sqrt (N F)
   (cond
      ((lt0 N) (quit "Bad argument" N))
      (N
         (let (A 1  B 0)
            (while (>= N A)
               (setq A (>> -2 A)) )
            (loop
               (if (> (inc 'B A) N)
                  (dec 'B A)
                  (dec 'N B)
                  (inc 'B A) )
               (setq B (>> 1 B)  A (>> 2 A))
               (T (=0 A)) )
            (and F (> N B) (inc 'B))
            B ) ) ) )

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

### Number ###
(de pad (N Val)
   (pack (need N (chop Val) "0")) )

(de money (N Cur)
   (if Cur
      (pack (format N 2 *Sep0 *Sep3) " " Cur)
      (format N 2 *Sep0 *Sep3) ) )

(de round (N D)
   (if (>= *Scl D)
      (format (*/ N (** 10 (- *Scl D))) D *Sep0 *Sep3)
      (format N *Scl *Sep0 *Sep3) ) )

# Binary notation
(de bin (X)
   (cond
      ((num? X)
         (let (S (and (lt0 X) '-)  L (& 1 X))
            (until (=0 (setq X (>> 1 X)))
               (push 'L (& 1 X)) )
            (pack S L) ) )
      ((setq X (chop X))
         (let (S (and (= '- (car X)) (pop 'X))  N 0)
            (for C X
               (setq N (| (format C) (>> -1 N))) )
            (if S (- N) N) ) ) ) )

# Octal notation
(de oct (X)
   (cond
      ((num? X)
         (let (S (and (lt0 X) '-)  L (& 7 X))
            (until (=0 (setq X (>> 3 X)))
               (push 'L (& 7 X)) )
            (pack S L) ) )
      ((setq X (chop X))
         (let (S (and (= '- (car X)) (pop 'X))  N 0)
            (for C X
               (setq N (| (format C) (>> -3 N))) )
            (if S (- N) N) ) ) ) )

# Hexadecimal notation
(de hex (X)
   (cond
      ((num? X)
         (let (S (and (lt0 X) '-)  L (hex1 X))
            (until (=0 (setq X (>> 4 X)))
               (push 'L (hex1 X)) )
            (pack S L) ) )
      ((setq X (chop X))
         (let (S (and (= '- (car X)) (pop 'X))  N 0)
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

# Hexadecimal/Alpha notation
(de hax (X)
   (if (num? X)
      (pack
         (mapcar
            '((C)
               (when (> (setq C (- (char C) `(char "0"))) 9)
                  (dec 'C 7) )
               (char (+ `(char "@") C)) )
            (chop (hex X)) ) )
      (hex
         (mapcar
            '((C)
               (when (> (setq C (- (char C) `(char "@"))) 9)
                  (inc 'C 7) )
               (char (+ `(char "0") C)) )
            (chop X) ) ) ) )

# Base 64 notation
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

### Allow ###
(de allowed Lst
   (setq *Allow (cons NIL (car Lst)))
   (balance *Allow (sort (cdr Lst))) )

(de allow (X Flg)
   (nond
      (*Allow)
      (Flg (idx *Allow X T))
      ((member X (cdr *Allow))
         (conc *Allow (cons X)) ) )
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
   (get
      (or Lst *DayFmt)
      (inc (% (inc Dat) 7)) ) )

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

### I/O ###
(de chdir ("Dir" . "Prg")
   (let? "Old" (cd "Dir")
      (finally (cd "Old")
         (run "Prg") ) ) )

(de dirname (F)
   (pack (flip (member '/ (flip (chop F))))) )

(de basename (F)
   (pack (stem (chop F) '/)) )

# Temporary Files
(de tmp @
   (unless *Tmp
      (push '*Bye '(call 'rm "-r" *Tmp))
      (push '*Fork '(off *Tmp) '(del '(call 'rm "-r" *Tmp) '*Bye))
      (call 'mkdir "-p" (setq *Tmp (pack "tmp/" *Pid "/"))) )
   (pass pack *Tmp) )


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

# Send mail
(de mail (Host Port From To Sub Att . Prg)
   (let? S (connect Host Port)
      (let B (pack "==" (date) "-" (time T) "==")
         (prog1
            (and
               (pre? "220 " (in S (line T)))
               (out S (prinl "HELO " (cdr (member "@" (chop From))) "^M"))
               (pre? "250 " (in S (line T)))
               (out S (prinl "MAIL FROM:" From "^M"))
               (pre? "250 " (in S (line T)))
               (if (atom To)
                  (_rcpt To)
                  (find bool (mapcar _rcpt To)) )
               (out S (prinl "DATA^M"))
               (pre? "354 " (in S (line T)))
               (out S
                  (prinl "From: " From "^M")
                  (prinl "To: " (or (fin To) (glue "," To)) "^M")
                  (prinl "Subject: " Sub "^M")
                  (prinl "User-Agent: PicoLisp^M")
                  (prinl "MIME-Version: 1.0^M")
                  (when Att
                     (prinl "Content-Type: multipart/mixed; boundary=\"" B "\"^M")
                     (prinl "^M")
                     (prinl "--" B "^M") )
                  (prinl "Content-Type: text/plain; charset=utf-8^M")
                  (prinl "Content-Transfer-Encoding: 8bit^M")
                  (prinl "^M")
                  (prEval Prg 2)
                  (prinl "^M")
                  (when Att
                     (loop
                        (prinl "--" B "^M")
                        (prinl
                           "Content-Type: "
                           (or (caddr Att) "application/octet-stream")
                           "; name=\""
                           (cadr Att)
                           "\"^M" )
                        (prinl "Content-Transfer-Encoding: base64^M")
                        (prinl "^M")
                        (in (car Att)
                           (while
                              (do 15
                                 (NIL (ext:Base64 (rd 1) (rd 1) (rd 1)))
                                 T )
                              (prinl) ) )
                        (prinl)
                        (prinl "^M")
                        (NIL (setq Att (cdddr Att))) )
                     (prinl "--" B "--^M") )
                  (prinl ".^M")
                  (prinl "QUIT^M") )
               T )
            (close S) ) ) ) )

(de _rcpt (To)
   (out S (prinl "RCPT TO:" To "^M"))
   (pre? "250 " (in S (line T))) )

### Assertions ###
(de assert Prg
   (when *Dbg
      (cons
         (list 'unless
            (if (cdr Prg) (cons 'and Prg) (car Prg))
            (list 'quit "'assert' failed" (lit (car Prg))) ) ) ) )

(de test (Pat . Prg)
   (bind (fish pat? Pat)
      (unless (match Pat (run Prg 1))
         (msg Prg)
         (quit "'test' failed" Pat) ) ) )

# vi:et:ts=3:sw=3
