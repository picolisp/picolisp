# 10apr03abu
# (c) Software Lab. Alexander Burger

(load "lib/gui.l" "lib/ps.l")

(setq *Scl 2)

(de *USt 0.0 7.0 16.0)

(de *Kategorien
   Betriebsausgaben Sonderausgaben
   Betriebseinnahmen Privateinnahmen Leerbuchungen )


(class +AD)
(rel ad     (+Ref +Date))                       # Aenderungsdatum

(dm upd> (X)
   (and X (n== X 'ad) (put> This 'ad (date))) )


(class +Firma +AD +Entity)
(rel nm     (+String))                          # Firmen-Name
(rel nr     (+String))                          # Steuernummer
(rel str    (+String))                          # Strasse
(rel plz    (+String))                          # PLZ
(rel ort    (+String))                          # Ort
(rel fnm    (+String))                          # Finanzamt-Name
(rel fstr   (+String))                          # Finanzamt-Strasse
(rel fpo    (+String))                          # Finanzamt-PLZ/Ort
(rel tel    (+String))                          # Tel
(rel fax    (+String))                          # Fax
(rel mail   (+String))                          # Mail
(rel bank   (+String))                          # Bank
(rel blz    (+Number))                          # Bankleitzahl
(rel kto    (+Number))                          # Kontonummer


(class +Kto +AD +Entity)
(rel nm     (+Key +String))                     # Name
(rel kat    (+Ref +Symbol))                     # Kategorie
(rel pr     (+Number))                          # Anteil-% (default 100)

(dm url> ()
   (pack "@konto?" This) )


(class +Pos +AD +Entity)
(rel dat    (+Ref +Date))                       # Datum
(rel kto    (+Need +Ref +Link) NIL (+Kto))      # Konto
(rel val    (+Ref +Number) NIL 2)               # Wert (brutto)
(rel ust    (+Number) 2)                        # USt
(rel txt    (+Sn +Idx +String))                 # Text
(rel afa    (+Ref +Number))                     # AFA Dauer
(rel aus    (+Number))                          # Ausbuchungs-Jahr
(rel info   (+String))                          # Info-Text

(dm url> ()
   (pack "@position?" This) )

(dm val> ()
   (*/
      (: val)
      (or (: kto pr) 100)
      100 T ) )

(dm net> ()
   (*/
      (if (: ust)
         (- (: val) @)
         (: val) )
      (or (: kto pr) 100)
      100 T ) )

(dm ust> ()
   (*/
      (: ust)
      (or (: kto pr) 100)
      100 T ) )

(dm afa> (Y)
   (let V (- (net> This))
      (if (=0 (: afa))
         (cons V 0)
         (let
            (D (date (: dat))
               N (/ V (: afa))
               A (if (> (cadr D) 6) (/ N 2) N) )
            (while (< (car D) Y)
               (dec 'V A)
               (setq A (min N (- V 100)))
               (inc D) )
            (cons V A) ) ) ) )


(class +UStField +FixField)

(dm chk> ()
   (or
      (super)
      (let (N (val> (get (: home fields) (- (: ix) 1)))  U (val> This))
         (and N U
            (xor (lt0 N) (lt0 U))
            "Vorzeichenfehler" ) ) ) )

(dm cho> ()
   (when (val> (get (: home fields) (- (: ix) 1)))
      (let V @
         (mapcar
            '((U)
               (let N (brust V U)
                  (mkCho
                     (pack
                        (align 5 (format U 2 *Sep0 *Sep3))
                        "% -> "
                        (money N) )
                     (and (n0 N) N) ) ) )
            *USt ) ) ) )


(de firma ()
   (html "Firma"
      (<head> "Firma")
      <hr>
      (new '(+ObjForm) '(+Firma) (firm) 800 400
         (quote
            (gui '(+E/R +TextField) '(nm : home obj)  "Name" 40)
            (gui '(+E/R +TextField) '(nr : home obj)  "Steuernummer" 20)
            (----)
            (row
               (txt "Strasse")
               (gui '(+E/R +TextField) '(str : home obj) " " 40) )
            (row
               (gui '(+E/R +TextField) '(plz : home obj) "PLZ/Ort" 7)
               (gui '(+E/R +TextField) '(ort : home obj) "" 40) )
            (----)
            (row
               (gui '(+E/R +TextField) '(tel : home obj) "Tel" 30)
               (gui '(+E/R +TextField) '(fnm : home obj) "Finanzamt" 30) )
            (row
               (gui '(+E/R +TextField) '(fax : home obj) "Fax" 30)
               (gui '(+E/R +TextField) '(fstr : home obj) " " 30) )
            (row
               (gui '(+E/R +MailField) '(mail : home obj) "EMail" 30)
               (gui '(+E/R +TextField) '(fpo : home obj) " " 30) )
            (----)
            (gui '(+E/R +TextField) '(bank : home obj) "Bank" 40)
            (gui '(+E/R +NumField) '(blz : home obj) "BLZ" 12)
            (gui '(+E/R +NumField) '(kto : home obj) "Konto" 12) ) )
      <hr> ) )

(de konto (Kto)
   (html "Konto"
      (<head> "Konto")
      <hr>
      (new '(+ObjForm) '(+Kto) Kto 800 200
         (quote
            (row
               (gui '(+E/R +TextField) '(nm : home obj) "Bezeichnung" 30)
               (stepButton 'nm '+Kto) )
            (----)
            (gui '(+E/R +SymField) '(kat : home obj) "Kategorie" *Kategorien)
            (----)
               (gui '(+E/R +NumField) '(pr : home obj) "Anteil [%]" 3)
            (----)
            (row
               (choButton '(choDialog "Konto" '(nm +Kto)))
               (delButton) ) ) )
      <hr> ) )

(de position (Pos)
   (html "Position"
      (<head> "Position")
      <hr>
      (new '(+ObjForm) '(+Pos) Pos 800 400
         (quote
            (row
               (gui '(+E/R +DateField)
                  '(dat : home obj)
                  "Datum" 10 )
               (stepButton 'dat '+Pos) )
            (gui '(+E/R +Obj +TextField)
               '(kto : home obj)
               '(nm +Kto)
               "Konto" 20 )
            (----)
            (gui '(+E/R +TextField) '(txt : home obj) "Text" 60)
            (----)
            (row
               (gui '(+E/R +NumField) '(afa : home obj) "AFA" 3)
               (gui '(+E/R +NumField) '(aus : home obj) "ausgebucht" 4) )
            (----)
            (row
               (gui '(+E/R +NegRed +FixField) '(val : home obj) 2 "Wert" 12)
               (gui 'ust '(+E/R +NegRed +UStField) '(ust : home obj) 2 "USt" 11) )
            (----)
            (gui '(+E/R +TextField) '(info : home obj) "Info" 60 8)
            (----)
            (row
               (delButton)
               (gui '(+Button) " " "Konto"
                  '(choDialog "Konto" '(nm +Kto)) ) ) ) )
      <hr> ) )

(de qPos ()
   (goal
      (quote
         @Dat (and *QYear (cons (date *QYear *QMonth 1) T))
         @Txt *QTxt
         @Kto *QKto
         @Val *QVal
         @Ad (and *QAd (cons *QAd T))
         (select (@Pos)
            ((dat +Pos @Dat)
               (txt +Pos @Txt)
               (nm +Kto @Kto (kto +Pos))
               (val +Pos @Val)
               (ad +AD @Ad) )
            (range @Dat @Pos dat)
            (tolr @Txt @Pos txt)
            (head @Kto @Pos kto nm)
            (same @Val @Pos val)
            (range @Ad @Pos ad) ) ) ) )

(de posYears ()
   (let (Tree (tree 'dat '+Pos)  Max (car (date (date))))
      (ifn (cdr Tree)
         (list (car (date (date))))
         (make
            (for (N (car (date (car (minKey Tree)))) (<= N Max) (+ 1 N))
               (link N) ) ) ) ) )

(de tax ()
   (app)
   (html "Software Lab"
      (new '(+Form) 800 500
         (quote
            (row
               (gui '(+Var +NumField) '*QYear "" (posYears))
               (gui '(+Var +Map +TextField) '*QMonth *MonMap "" *MonFmt)
               (gui 'txt '(+Var +Bg +Hint +TextField)
                  '*QTxt
                  '((db txt +Pos @ @P) (val @T @P txt))
                  "Text" 20 )
               (gui 'kto '(+Var +Hint +TextField)
                  '*QKto
                  '((db nm +Kto @ @K) (val @T @K nm))
                  "Konto" 15 )
               (gui 'val '(+Var +FixField) '*QVal 2 "Wert" 9)
               (gui 'ad '(+Var +DateField) '*QAd "AD" 10) )
            (----)
            (row
               (gui '(+ClrButton) "" "Zurücksetzen"
                  '(txt kto val ad query) )
               (gui '(+Button) "" "Heute"
                  '(set> (: home ad) (date)) )
               (gui 'hot '(+Button) "" "Suchen (F4)"
                  '(set> (: home query) (qPos)) )
               (gui '(+Able +Button)
                  '(and
                     (val> (: home dat))
                     (row2> (: home query))
                     (val> (: home focus2)) )
                  " " "Kopie"
                  '(when (get (: home query data) (row2> (: home query)))
                     (put!> (clone!> @) 'upd 'dat (val> (: home dat)))
                     (upd> (: home query))
                     (focus> (: home focus2)) ) )
               (gui 'dat '(+DateField) "" 10)
               (gui '(+Button) " " "Firma" '(url "@firma"))
               (gui '(+Button) "" "Konto" '(choDialog "Konto" '(nm +Kto)))
               (gui '(+Button) " " "USt" '(url "@ustvor" NIL *QYear *QMonth))
               (gui '(+Button) "" "G/V" '(url "@gewinn" NIL *QYear))
               (gui 'sum '(+Skip +Lock +FixField) 2 "(+)" 12) )
            (---- T)
            (gui 'query '(+QueryChart) NIL
               12 '("Datum" "Wert" "USt" "Text" "Konto")
               (quote
                  (gui '(+Hot +DateField) '(and (curr) (url (url> @))) "" 10)
                  (gui '(+NegRed +FixField) 2 "" 12)
                  (gui '(+NegRed +UStField) 2 "" 11)
                  (gui '(+Hint +TextField)
                     '((db txt +Pos @ @P) (val @T @P txt))
                     "" 40 )
                  (gui '(+Obj +TextField) '(nm +Kto) "" 20) )
               '((P)
                  (with P
                     (list (: dat) (: val) (: ust) (: txt) (: kto)) ) )
               '((L D)
                  (cond
                     (D
                        (dbSync)
                        (put> D 'dat (car L))
                        (put> D 'val (cadr L))
                        (put> D 'ust (caddr L))
                        (put> D 'txt (cadddr L))
                        (put> D 'kto (get L 5))
                        (commit 'upd)
                        D )
                     ((car L)
                        (new! 'upd '(+Pos)
                           'dat (car L)
                           'val (cadr L)
                           'ust (caddr L)
                           'txt (cadddr L)
                           'kto (get L 5) ) ) ) ) )
            (row
               (gui '(+Button) "" " \^ " '(sort> (: home query) '(: dat)))
               (flow
                  (gui '(+Button) "" " \^ " '(sort> (: home query) '(: val)))
                  (gui '(+Button) "" " + "
                     '(set> (: home sum)
                        (sum
                           '((X) (get X 'val))
                           (val> (: home query)) ) ) ) )
               (flow
                  (gui '(+Button) "" " \^ " '(sort> (: home query) '(: ust)))
                  (gui '(+Button) "" " + "
                     '(set> (: home sum)
                        (sum
                           '((X) (get X 'ust))
                           (val> (: home query)) ) ) ) )
               (gui '(+Button) "" " \^ " '(sort> (: home query) '(: txt)))
               (gui '(+Button) "" " \^ " '(sort> (: home query) '(: kto nm))) ) ) ) ) )

(de firm @
   (if (args)
      (pass get (fetch (val *DB) 'firm))
      (fetch (val *DB) 'firm) ) )

(de brust (Val Proz)
   (default Val 0 Proz 0)
   (*/ Val Proz (+ 100.00 Proz) T) )

(de prUms (X Y DX DY N)
   (window X Y DX DY
      (ps (format (/ N 1.0)) T) ) )

(de prBetrag (X Y DX DY N)
   (window X Y DX DY
      (table (80 20)
         (ps (format (/ N 1.0)) T)
         (ps (pad 2 (% (abs N) 1.0)) T) ) ) )

(de recUms ("Sym" "foo" "Lst")
   (record "Sym" '-)
   (let (SN 0  SU 0)
      (mapc
         '((Pos)
            (with Pos
               (when (== "Sym" (: kto kat))
                  (let (B (val> This)  N (if (: afa) 0 (net> This))  U (ust> This))
                     (inc 'SN N)
                     (inc 'SU U)
                     (record
                        (href This (datSym (: dat)))
                        (money B)
                        (if (: afa) "+AFA+" (money N))
                        (money U)
                        (if (and (: kto pr) (<> @ 100))
                           (pack (: kto nm) " (" (: kto pr) "%)")
                           (: kto nm) )
                        (: txt) )
                     ("foo" B N U) ) ) ) )
         "Lst" )
      (<row> NIL NIL '<hr> '-)
      (record NIL '- (money SN) (money SU)) ) )

# Umsatzsteuer-Voranmeldung
(de ustvor (Y M)
   (let (Ums 0  Frei 0  USt 0  VSt 0)
      (html "Umsatzsteuer"
         (report "Ums" (pack "Umsätze " (get *MonFmt M) " " Y))
         (<table> T NIL
            '((-) (- "Datum") (+ "Wert") (+ "USt") (- "Text"))
            (mapc
               '((Pos)
                  (with Pos
                     (let (N (net> This)  U (ust> This))
                        (case (: kto kat)
                           (Betriebseinnahmen
                              (record "U: "
                                 (datSym (: dat))
                                 (money (: val))
                                 (money (: ust))
                                 (: txt) )
                              (if (or (not U) (=0 U))
                                 (inc 'Frei N)
                                 (inc 'Ums N)
                                 (inc 'USt U) ) )
                           (Betriebsausgaben
                              (record "V: "
                                 (datSym (: dat))
                                 (money (: val))
                                 (money (: ust))
                                 (: txt) )
                              (inc 'VSt U) ) ) ) ) )
               (collect 'dat '+Pos
                  (date Y M 1)
                  (if (= 12 M)
                     (date Y M 31)
                     (- (date Y (+ M 1) 1) 1) ) ) ) )
         (<href> "PDF"
            (pack "@ustvor.pdf?" (htFmt Ums Frei USt VSt))
            "PDF" ) ) ) )

(de ustvor.pdf (Ums Frei USt VSt)
   (psOut T "rel"
      (a4)
      (font "Times-Roman")
      (window 115 34 100 20
         (ps (firm 'nr)) )
      (window 100 104 200 80
         (font 13 (ps (firm 'fnm)))
         (down 12)
         (ps (firm 'fstr))
         (down 22)
         (ps (firm 'fpo)) )
      (window 80 222 200 80
         (font 13 (ps (firm 'nm)))
         (down 8)
         (ps (firm 'str))
         (ps (pack (firm 'plz) " " (firm 'ort)))
         (down 8)
         (ps (pack "Tel. " (firm 'tel))) )

      (window
         (if (<= *QMonth 6) 374 456)
         (+ 132 (* 19 (% (- *QMonth 1) 6)))
         23
         17
         (ps "X") )

      (unless (=0 Frei)
         (prUms 352 448 80 18 Frei) )  # Steuerfreie Umsaetze [48]
      (prUms 352 507 80 18 Ums)        # Steuerpflichtige Umsaetze 16% [51]
      (prBetrag 494 507 100 18 USt)
      (prBetrag 494 790 100 18 USt)    # Uebertrag
      (page T)

      (prBetrag 466 13 100 18 USt)        # Uebertrag
      (prBetrag 466 164 100 18 USt)       # Umsatzsteuer
      (prBetrag 466 202 100 18 (- VSt))   # Vorsteuer [66]
      (setq U (+ USt VSt))
      (prBetrag 466 334 100 18 U)         # Verbleibender Betrag
      (prBetrag 466 428 100 18 U)         # Vorauszahlung [83]
      (page) ) )

# Gewinn/Verlust-Rechnung
(de gewinn (Y)
   (let
      (Ums 0  USt 0  Frei 0  Aus 0  VSt 0  Afa 0
         Lst (collect 'dat '+Pos (date Y 1 1) (date Y 12 31)) )
      (html "Gewinnermittlung"
         (report (pack "GV-" Y) (pack "Gewinn/Verlust " Y))
         (<table> NIL Y
            '((- "Datum") (+ "Brutto") (+ "Netto") (+ "USt") (- "Konto") (- "Text"))

            (recUms 'Betriebseinnahmen
               '((B N U)
                  (if (or (not U) (=0 U))
                     (inc 'Frei B)
                     (inc 'Ums N)
                     (inc 'USt U) ) )
               Lst )

            (recUms 'Betriebsausgaben
               '((B N U)
                  (inc 'Aus N)
                  (inc 'VSt U) )
               Lst ) )
         <p>
         (<table> NIL "Anlagevermögen"
            (quote
               (- "Datum")
               (+ "Kauf")
               (- "Text")
               (+ "AFA")
               (+ "Stand")
               (+ "Abschreibung") )
            (mapc
               '((P)
                  (with P
                     (unless (and (: aus) (>= @ Y))
                        (let A (afa> P Y)
                           (dec 'Afa (cdr A))
                           (record
                              (href This (datSym (: dat)))
                              (money (- (net> This)))
                              (if (and (: kto pr) (<> @ 100))
                                 (pack (: txt) " (" (: kto pr) "%)")
                                 (: txt) )
                              (: afa)
                              (money (car A))
                              (money (cdr A)) ) ) ) ) )
               (sortBy
                  '((P) (get P 'dat))
                  (collect 'afa '+Pos) ) )
            (<row> NIL NIL NIL NIL NIL '<hr>)
            (record NIL NIL NIL NIL NIL (money Afa)) )
         <p>
         (<table> NIL "Betriebsseinnahmen" '((-) (+))
            (<row> "Steuerpflichtige Umsätze (netto)" (money Ums))
            (<row> "Umsatzsteuer" (money USt))
            (<row> "Steuerfreie Umsätze" (money Frei))
            (<row> '<hr> '-)
            (<row> NIL (money (+ Ums USt Frei))) )
         <p>
         (<table> NIL "Betriebsausgaben" '((-) (+))
            (<row> "Ausgaben (netto)" (money Aus))
            (<row> "Abschreibungen" (money Afa))
            (<row> "Vorsteuer" (money VSt))
            (<row> '<hr> '-)
            (<row> NIL (money (+ Aus Afa VSt))) )
         <p>
         (<br> "*** Gewinn:" (money (+ Ums USt Frei Aus Afa VSt)) "***")
         <p>
         (let (U 0  YY (pad 2 (% Y 100)))
            (<table> NIL "Umsatzsteuer-Vorauszahlungen"
               '((- "Datum") (+ "USt") (- "Text"))
               (mapc
                  '((Mon)
                     (with (db 'txt '+Pos (pack Mon YY) 'kto (db 'nm '+Kto "Umsatzsteuer"))
                        (inc 'U (: val))
                        (record
                           (href This (datSym (: dat)))
                           (money (: val))
                           (: txt) ) ) )
                  '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec") )
               (<row> NIL '<hr>)
               (record NIL (money U)) )
            <p>
            (<br> "Umsatzsteuer + Vorsteuer:" (money (+ USt VSt)))
            (<br> "*** noch zu entrichten:" (money (+ USt VSt U)) "***") )
         <p>
         (<table> NIL "Sonderausgaben" '((-) (+))
            (<row> "Krankenversicherung"
               (money
                  (sum
                     '((P)
                        (with P
                           (and (= "Krankenversicherung" (: txt)) (: val)) ) )
                     Lst ) ) )
            (<row> "Unfallversicherung"
               (money
                  (sum
                     '((P)
                        (with P
                           (and (= "Unfallversicherung" (: txt)) (: val)) ) )
                     Lst ) ) )
            (<row> "Lebensversicherung"
               (money
                  (sum
                     '((P)
                        (with P
                           (and (= "Lebensversicherung" (: txt)) (: val)) ) )
                     Lst ) ) )
            (<row> "Privathaftpflicht"
               (money
                  (sum
                     '((P)
                        (with P
                           (and (= "Privathaftpflicht" (: txt)) (: val)) ) )
                     Lst ) ) ) )
         <p>
         (let S 0
            (<table> NIL "Spenden"
               '((- "Datum") (- "Text") (+ "Betrag"))
               (mapc
                  '((P)
                     (with P
                        (when (= "Spenden" (: kto nm))
                           (inc 'S (: val))
                           (record
                              (href This (datSym (: dat)))
                              (: txt)
                              (money (: val)) ) ) ) )
                  Lst )
               (<row> NIL NIL '<hr>)
               (record NIL NIL (money S)) ) )
         (let S 0
            (<table> NIL "Eigenanteil Gesundheitskosten"
               '((- "Datum") (- "Text") (+ "Betrag"))
               (mapc
                  '((P)
                     (with P
                        (when (= "Gesundheitskosten" (: kto nm))
                           (inc 'S (: val))
                           (record
                              (href This (datSym (: dat)))
                              (: txt)
                              (money (: val)) ) ) ) )
                  Lst )
               (<row> NIL NIL '<hr>)
               (record NIL NIL (money S)) ) ) ) ) )


(de main ()
   (locale "DE" "de")
   (setq
      *QYear (car (date (date)))
      *QMonth 1
      *MonMap (let N 0
         (mapcar
            '((M) (cons M (inc 'N)))
            *MonFmt ) ) )
   (pool "tax.db") )

(de go ()
   (rollback)
   (server 8080 (url1 "@tax")) )

# Check
(de chk ()
   (and (dbck) (quit 'dbck @))
   (dbCheck)
   (dangling 'nm '+Kto)
   (dangling 'kat '+Kto)
   (dangling 'dat '+Pos)
   (dangling 'val '+Pos)
   (dangling 'txt '+Pos) )
