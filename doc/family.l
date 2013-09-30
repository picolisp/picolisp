# 19jul13abu
# (c) Software Lab. Alexander Burger

(load "@lib/http.l" "@lib/xhtml.l" "@lib/form.l" "@lib/ps.l")

### DB ###
(class +Person +Entity)
(rel nm (+Need +Sn +Idx +String))      # Name
(rel pa (+Joint) kids (+Man))          # Father
(rel ma (+Joint) kids (+Woman))        # Mother
(rel mate (+Joint) mate (+Person))     # Partner
(rel job (+Ref +String))               # Occupation
(rel dat (+Ref +Date))                 # born
(rel fin (+Ref +Date))                 # died
(rel txt (+String))                    # Info

(dm url> (Tab)
   (list "!person" '*ID This) )


(class +Man +Person)
(rel kids (+List +Joint) pa (+Person)) # Children

(class +Woman +Person)
(rel kids (+List +Joint) ma (+Person)) # Children

(dbs
   (0)                                 # (1 . 64)
   (2 +Person)                         # (2 . 256)
   (3 (+Person nm))                    # (3 . 512)
   (3 (+Person job dat fin)) )         # (4 . 512)


### GUI ###
(de choPerson (Dst)
   (diaform '(Dst)
      (<grid> "--.-.-."
         "Name" (gui 'nm '(+Focus +Var +TextField) '*PrsNm 20)
         "Occupation" (gui 'job '(+Var +TextField) '*PrsJob 20)
         "born" (prog
            (gui 'dat1 '(+Var +DateField) '*PrsDat1 10)
            (gui 'dat2 '(+Var +DateField) '*PrsDat2 10) )
         (searchButton '(init> (: home query)))
         "Father" (gui 'pa '(+Var +TextField) '*PrsPa 20)
         "Mother" (gui 'ma '(+Var +TextField) '*PrsMa 20)
         "Partner" (gui 'mate '(+Var +TextField) '*PrsMate 20)
         (resetButton '(nm pa ma mate job dat1 dat2 query)) )
      (gui 'query '(+QueryChart) (cho)
         '(goal
            (quote
               @Nm *PrsNm
               @Pa *PrsPa
               @Ma *PrsMa
               @Mate *PrsMate
               @Job *PrsJob
               @Dat (and (or *PrsDat1 *PrsDat2) (cons *PrsDat1 (or *PrsDat2 T)))
               (select (@@)
                  ((nm +Person @Nm)
                     (nm +Person @Pa kids)
                     (nm +Person @Ma kids)
                     (nm +Person @Mate mate)
                     (job +Person @Job)
                     (dat +Person @Dat) )
                  (tolr @Nm @@ nm)
                  (tolr @Pa @@ pa nm)
                  (tolr @Ma @@ ma nm)
                  (tolr @Mate @@ mate nm)
                  (head @Job @@ job)
                  (range @Dat @@ dat) ) ) )
         7
         '((This) (list This This (: pa) (: ma) (: mate) (: job) (: dat))) )
      (<table> 'chart NIL
         '((btn) (NIL "Name") (NIL "Father") (NIL "Mother") (NIL "Partner") (NIL "Occupation") (NIL "born"))
         (do (cho)
            (<row> (alternating)
               (gui 1 '(+DstButton) Dst)
               (gui 2 '(+ObjView +TextField) '(: nm))
               (gui 3 '(+ObjView +TextField) '(: nm))
               (gui 4 '(+ObjView +TextField) '(: nm))
               (gui 5 '(+ObjView +TextField) '(: nm))
               (gui 6 '(+TextField))
               (gui 7 '(+DateField)) ) ) )
      (<spread>
         (scroll (cho))
         (<nbsp> 4)
         (prin "Man")
         (newButton T Dst '(+Man) 'nm *PrsNm)
         (<nbsp>)
         (prin "Woman")
         (newButton T Dst '(+Woman) 'nm *PrsNm)
         (<nbsp> 4)
         (cancelButton) ) ) )

# Person HTML Page
(de person ()
   (app)
   (action
      (html 0 (get (default *ID (val *DB)) 'nm) "@lib.css" NIL
         (form NIL
            (<h2> NIL (<id> (: nm)))
            (panel T "Person '@1'" T '(choPerson) 'nm '+Person)
            (<p> NIL
               (gui '(+E/R +TextField) '(nm : home obj) 40 "Name")
               (gui '(+ClassField) '(: home obj) '(("Male" +Man) ("Female" +Woman))) )
            (<grid> 5
               "Occupation" (gui '(+E/R +TextField) '(job : home obj) 20)
               "Father" (choPerson 0)
               (gui '(+E/R +Obj +TextField) '(pa : home obj) '(nm +Man) 30)
               "born" (gui '(+E/R +DateField) '(dat : home obj) 10)
               "Mother" (choPerson 0)
               (gui '(+E/R +Obj +TextField) '(ma : home obj) '(nm +Woman) 30)
               "died" (gui '(+E/R +DateField) '(fin : home obj) 10)
               "Partner" (choPerson 0)
               (gui '(+E/R +Obj +TextField) '(mate : home obj) '(nm +Person) 30) )
            (gui '(+E/R +Chart) '(kids : home obj) 5
               '((This) (list NIL This (: dat) (: pa) (: ma)))
               cadr )
            (<table> NIL NIL
               '(NIL (NIL "Children") (NIL "born") (NIL "Father") (NIL "Mother"))
               (do 4
                  (<row> NIL
                     (choPerson 1)
                     (gui 2 '(+Obj +TextField) '(nm +Person) 20)
                     (gui 3 '(+E/R +DateField) '(dat curr) 10)
                     (gui 4 '(+ObjView +TextField) '(: nm) 20)
                     (gui 5 '(+ObjView +TextField) '(: nm) 20) ) )
               (<row> NIL NIL (scroll 4)) )
            (----)
            (gui '(+E/R +TextField) '(txt : home obj) 40 4)
            (gui '(+Rid +Button) "Contemporaries"
               '(url "!contemporaries" (: home obj)) )
            (gui '(+Rid +Button) "Tree View"
               '(url "!treeReport" (: home obj)) )
            (editButton T) ) ) ) )


### Reports ###
# Show all contemporaries of a person
(de contemporaries (*ID)
   (action
      (html 0 "Contemporaries" "@lib.css" NIL
         (form NIL
            (<h3> NIL (<id> "Contemporaries of " (: nm)))
            (ifn (: obj dat)
               (<h3> NIL (ht:Prin "No birth date for " (: obj nm)))
               (gui '(+QueryChart) 12
                  '(goal
                     (quote
                        @Obj (: home obj)
                        @Dat (: home obj dat)
                        @Beg (- (: home obj dat) 36525)
                        @Fin (or (: home obj fin) (+ (: home obj dat) 36525))
                        (db dat +Person (@Beg . @Fin) @@)
                        (different @@ @Obj)
                        (^ @ (>= (get (-> @@) 'fin) (-> @Dat)))
                        (^ @ (<= (get (-> @@) 'dat) (-> @Fin))) ) )
                  7
                  '((This)
                     (list This (: job) (: dat) (: fin) (: pa) (: ma) (: mate)) ) )
               (<table> NIL (pack (datStr (: obj dat)) " - " (datStr (: obj fin)))
                  (quote
                     (NIL "Name") (NIL "Occupation") (NIL "born") (NIL "died")
                     (NIL "Father") (NIL "Mother") (NIL "Partner") )
                  (do 12
                     (<row> NIL
                        (gui 1 '(+ObjView +TextField) '(: nm))
                        (gui 2 '(+TextField))
                        (gui 3 '(+DateField))
                        (gui 4 '(+DateField))
                        (gui 5 '(+ObjView +TextField) '(: nm))
                        (gui 6 '(+ObjView +TextField) '(: nm))
                        (gui 7 '(+ObjView +TextField) '(: nm)) ) ) )
               (scroll 12)
               (----)
               (gui '(+Rid +Button) "Textfile"
                  '(let Txt (tmp "Contemporaries.txt")
                     (out Txt (txt> (chart)))
                     (url Txt) ) )
               (gui '(+Rid +Button) "PDF"
                  '(psOut NIL "Contemporaries"
                     (out (tmp "Contemporaries.txt")
                        (txt> (chart)) )
                     (in (tmp "Contemporaries.txt")
                        (let (Page 1  Fmt (200 120 50 50 120 120 120)  Ttl (line T))
                           (a4L "Contemporaries")
                           (font (7 . "Helvetica"))
                           (indent 30 10)
                           (down 12)
                           (font 9 (ps Ttl))
                           (down 12)
                           (table Fmt
                              "Name" "Occupation" "born" "died" "Father" "Mother" "Partner" )
                           (down 6)
                           (pages 560
                              (page T)
                              (down 12)
                              (ps (pack Ttl ", Page " (inc 'Page)))
                              (down 12) )
                           (until (eof)
                              (let L (split (line) "^I")
                                 (down 8)
                                 (table Fmt
                                    (font "Helvetica-Bold" (ps (head 50 (car L))))
                                    (ps (head 30 (cadr L)))
                                    (ps (get L 3))
                                    (ps (get L 4))
                                    (ps (head 30 (get L 5)))
                                    (ps (head 30 (get L 6)))
                                    (ps (head 30 (get L 7))) )
                                 (down 4) ) ) ) )
                     (page) ) ) ) ) ) ) )

# Tree display of a person's descendants
(de treeReport (This)
   (html 0 "Family Tree View" "@lib.css" NIL
      (<h3> NIL "Family Tree View")
      (<ul> NIL
         (recur (This)
            (when (try 'url> This 1)
               (<li> NIL
                  (<href> (: nm) (mkUrl @))
                  (when (try 'url> (: mate) 1)
                     (prin " -- ")
                     (<href> (: mate nm) (mkUrl @)) ) )
               (when (: kids)
                  (<ul> NIL (mapc recurse (: kids))) ) ) ) ) ) )

### RUN ###
(de main ()
   (pool "family/" *Dbs)
   (unless (val *DB)
      (put>
         (set *DB (request '(+Man) 'nm "Adam"))
         'mate
         (request '(+Woman) 'nm "Eve") )
      (commit) ) )

(de go ()
   (rollback)
   (server 8080 "!person") )

# vi:et:ts=3:sw=3
