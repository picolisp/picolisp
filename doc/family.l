# 13may04abu
# (c) Software Lab. Alexander Burger

(load "lib/ps.l")

### DB ###
(class +Person +Entity)
(rel nm     (+Need +Sn +Idx +String))           # Name
(rel pa     (+Joint) kids (+Man))               # Father
(rel ma     (+Joint) kids (+Woman))             # Mother
(rel mate   (+Joint) mate (+Person))            # Partner
(rel job    (+Ref +String))                     # Occupation
(rel dat    (+Ref +Date))                       # born
(rel fin    (+Ref +Date))                       # died
(rel txt    (+String))                          # Info

(dm url> ()
   (pack "@person?" (ht:Fmt This)) )


(class +Man +Person)
(rel kids   (+List +Joint) pa (+Person))        # Children

(class +Woman +Person)
(rel kids   (+List +Joint) ma (+Person))        # Children


# Pilog Query
(de qPerson (Nm Pa Ma Mate Job Dat1 Dat2)
   (goal
      (quote
         @Nm Nm
         @Pa Pa
         @Ma Ma
         @Mate Mate
         @Job Job
         @Dat (and (or Dat1 Dat2) (cons Dat1 (or Dat2 T)))
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
            (range @Dat @@ dat) ) ) ) )


### GUI ###
(de choPerson (Ret)
   (dialog "Choose/Create Person" '*PrsDlgStat
      (quote
         (txt "Search fields:")
         (----)
         (row
            (gui 'nm '(+Bg +TextField) "Name" 23)
            (gui 'job '(+TextField) "Occupation" 23)
            (flow
               (gui 'dat1 '(+DateField) "born" 10)
               (gui 'dat2 '(+DateField) "" 10) ) )
         (row
            (gui 'pa '(+Bg +TextField) "Father" 23)
            (gui 'ma '(+Bg +TextField) "Mother" 23)
            (gui 'mate '(+Bg +TextField) "Partner" 23) )
         (----)
         (row
            (gui '(+ClrButton) "" "Reset"
               '(nm pa ma mate job dat1 dat2 query) )
            (gui 'hot '(+Button) "" "Search (F4)"
               '(set> (: home query)
                  (qPerson
                     (val> (: home nm))
                     (val> (: home pa))
                     (val> (: home ma))
                     (val> (: home mate))
                     (val> (: home job))
                     (val> (: home dat1))
                     (val> (: home dat2)) ) ) ) )
         (---- T)
         (gui 'query '(+QueryChart) '(qPerson)
            6 '("Name" "Father" "Mother" "Partner" "Occupation" "born")
            (quote
               (gui
                  (if Ret '(+Rv +ObjView +TextField) '(+ObjView +TextField))
                  '(: nm) "" 20 )
               (gui '(+ObjView +TextField) '(: nm) "" 15)
               (gui '(+ObjView +TextField) '(: nm) "" 15)
               (gui '(+ObjView +TextField) '(: nm) "" 15)
               (gui '(+Lock +TextField) "" 15)
               (gui '(+Lock +DateField) "" 10) )
            '((P)
               (with P
                  (list This (: pa) (: ma) (: mate) (: job) (: dat)) ) ) )
         (----)
         (row
            (hotButton "Choose")
            (gui '(+Button) "" "New Man" '(newUrl '(+Man)))
            (gui '(+Button) "" "New Woman" '(newUrl '(+Woman)))
            (quitButton) ) ) ) )

# Person HTML Page
(de person (*ID)
   (app)
   (html (get (default *ID (seq *DB)) 'nm)
      (<head> "Family")
      (form '(+ObjForm) '(+Person) *ID 800 450
         (quote
            (row
               (gui '(+E/R +TextField) '(nm : home obj) "Name" 40)
               (gui '(+Set +ClassField)
                  '((Val)
                     (let Old (val (: home obj))
                        (extra Val)
                        (unless (= Val Old)
                           (upd> (: home)) ) ) )
                  '(: home obj) "Sex"
                  '(("Male" +Man) ("Female" +Woman)) ) )
            (row
               (gui '(+E/R +TextField) '(job : home obj) "Occupation" 40)
               (gui '(+E/R +DateField) '(dat : home obj) "born" 10)
               (gui '(+E/R +DateField) '(fin : home obj) "died" 10) )
            (----)
            (row
               (gui '(+SetButton) "Father" '-> '(choPerson T))
               (gui '(+E/R +Obj +TextField) '(pa : home obj) '(nm +Man) "" 30)
               (gui '(+SetButton) "Mother" '-> '(choPerson T))
               (gui '(+E/R +Obj +TextField) '(ma : home obj) '(nm +Woman) "" 30) )
            (row
               (gui '(+SetButton) "Partner" '-> '(choPerson T))
               (gui '(+E/R +Obj +TextField) '(mate : home obj) '(nm +Person) "" 30) )
            (---- T)
            (gui '(+E/R +Chart)
               '(kids : home obj)
               4 '(" " "Children" "born" "Father" "Mother")
               (quote
                  (gui '(+SetButton) "" '-> '(choPerson T))
                  (gui '(+Obj +TextField) '(nm +Person) "" 30)
                  (gui '(+Skip +Lock +DateField) "" 10)
                  (gui '(+ObjView +TextField) '(: nm) "" 20)
                  (gui '(+ObjView +TextField) '(: nm) "" 20) )
               '((P)
                  (with P
                     (list '-> This (: dat) (: pa) (: ma)) ) )
               cadr )
            (----)
            (gui '(+E/R +TextField) '(txt : home obj) "" 80 4)
            (----)
            (row
               (choButton '(choPerson))
               (delButton)
               (gui '(+Button) "Report:" "Contemporaries"
                  '(url "@contemporaries" NIL (: home obj)) )
               (gui '(+Button) "" "Tree View"
                  '(url "@treeReport" NIL (: home obj)) ) ) ) )
      <hr> ) )


### Reports ###
# Show all contemporaries of a person
(de contemporaries (Prs)
   (with Prs
      (html "Contemporaries"
         (ifn (: dat)
            (<head> (pack "No birth dat for " (: nm)))
            (report "Contemporaries"
               (pack "Contemporaries of " (: nm))
               "Print PDF" 'contemporaries.pdf "PDF" )
            (let (Cnt 0  Dat (: dat)  Fin (or (: fin) (+ Dat 36525)))
               (<table> T (pack (datStr (: dat)) " ... " (datStr (: fin)))
                  (quote
                     (- "Name") (- "Occupation") (- "born") (- "died")
                     (- "Father") (- "Mother") (- "Partner") )
                  (mapc
                     '((P)
                        (with P
                           (unless (or (== P Prs) (> Dat (: fin)) (< Fin (: dat)))
                              (inc 'Cnt)
                              (record
                                 (href This (: nm))
                                 (: job)
                                 (datStr (: dat))
                                 (datStr (: fin))
                                 (href (: pa) (: pa nm))
                                 (href (: ma) (: ma nm))
                                 (href (: mate) (: mate nm)) ) ) ) )
                     (sortBy
                        '((P) (get P 'nm))
                        (collect 'dat '+Person (- Dat 36525) Fin) ) ) )
               (<br> "<hr>Total:" Cnt)
               (<br>) ) ) ) ) )

(de contemporaries.pdf ()
   (psOut T "Contemporaries"
      (in (list "bin/utf2" (tmp "Contemporaries.txt"))
         (let (Page 1  Fmt (200 120 50 50 120 120 120)  Ttl (line T)  L)
            (a4L)
            (font (7 . "Arial"))
            (indent 30 10)
            (down 12)
            (font 9 (ps Ttl))
            (down 12)
            (table Fmt
               (ps "Name")
               (ps "Occupation")
               (ps "born")
               (ps "died")
               (ps "Father")
               (ps "Mother")
               (ps "Partner") )
            (down 6)
            (pages 560
               (page T)
               (down 12)
               (ps (pack Ttl ", Page " (inc 'Page)))
               (down 12) )
            (whilst (setq L (split (line) "^I"))
               (hline 4)
               (down 8)
               (table Fmt
                  (font "Arial-Bold" (ps (head 50 (car L))))
                  (ps (head 30 (cadr L)))
                  (ps (get L 3))
                  (ps (get L 4))
                  (ps (head 30 (get L 5)))
                  (ps (head 30 (get L 6)))
                  (ps (head 30 (get L 7))) )
                  (down 4) )
            (page) ) ) ) )

# Tree display of a person's descendants
(de treeReport (Prs)
   (html "Family Tree View"
      (<head> "Family Tree View")
      (prinl "<UL>")
      (treeRep Prs)
      (prinl "</UL>") ) )

(de treeRep (Prs)
   (with Prs
      (prin "<LI>")
      (<href> (: nm) (url> Prs))
      (when (: mate)
         (prin " -- ")
         (<href> (: mate nm) (url> (: mate))) )
      (prinl)
      (when (: kids)
         (prinl "<UL>")
         (mapc treeRep (: kids))
         (prinl "</UL>") ) ) )


### RUN ###
(de main ()
   (pool "doc/family.db")
   (unless (seq *DB)
      (new T '(+Man) 'nm "Adam"
         'mate (new T '(+Woman) 'nm "Eve") )
      (commit) ) )

(de go ()
   (rollback)
   (server 8080 "@start") )

(de start ()
   (load "lib/gui.l")
   (person) )

(de htm ()
   (load "lib/htm.l")
   (person) )
