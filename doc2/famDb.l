# 15dec02abu
# (c) Software Lab. Alexander Burger

(load "lib/gui.l")

### DB ###
(class +Person +Entity)
(rel nm     (+Key +String))                     # Name
(rel pa     (+Joint) kids (+Man))               # Father
(rel ma     (+Joint) kids (+Woman))             # Mother
(rel mate   (+Joint) mate (+Person))            # Partner
(rel job    (+String))                          # Occupation
(rel dat    (+Date))                            # Date of birth
(rel fin    (+Date))                            # Date of death
(rel txt    (+String))                          # Info

(dm url> ()
   (pack "@person?" This) )


(class +Man +Person)
(rel kids   (+List +Joint) pa (+Person))        # Children

(class +Woman +Person)
(rel kids   (+List +Joint) ma (+Person))        # Children


### GUI ###
(de person (*ID)
   (app)
   (html (get (default *ID (seq *DB)) 'nm)
      (<head> "Family")
      (new '(+ObjForm) '(+Person) *ID 800 500
         (quote
            (row
               (gui '(+E/R +TextField) '(nm : home obj) "Name" 30)
               (gui '(+Set +ClassField)
                  '((V)
                     (unless (= V (val (: home obj)))
                        (extra V)
                        (upd> (: home)) ) )
                  '(: home obj) "Sex"
                  '(("Male" +Man) ("Female" +Woman)) ) )
            (row
               (gui '(+E/R +TextField) '(job : home obj) "Occupation" 30)
               (gui '(+E/R +DateField) '(dat : home obj) "born" 10)
               (gui '(+E/R +DateField) '(fin : home obj) "died" 10) )
            (----)
            (row
               (gui '(+E/R +Obj +TextField) '(pa : home obj) '(nm +Man)
                  "Father" 30 )
               (gui '(+E/R +Obj +TextField) '(ma : home obj) '(nm +Woman)
                  "Mother" 30 ) )
            (gui '(+E/R +Obj +TextField) '(mate : home obj) '(nm +Person)
               "Partner" 30 )
            (---- T)
            (gui '(+E/R +Chart)
               '(kids : home obj)
               5 '("Children" "born" "Father" "Mother")
               (quote
                  (gui '(+Obj +TextField) '(nm +Person) "" 30)
                  (gui '(+Skip +Lock +DateField) "" 10)
                  (gui '(+ObjView +TextField) '(: nm) "" 20)
                  (gui '(+ObjView +TextField) '(: nm) "" 20) )
               '((P)
                  (with P
                     (list This (: dat) (: pa) (: ma)) ) )
               car )
            (----)
            (gui '(+E/R +TextField) '(txt : home obj) "" 60 6)
            (----)
            (row
               (gui '(+Button) "Choose/Create" "Man"
                  '(choDialog "Man" '(nm +Man)) )
               (gui '(+Button) "" "Woman"
                  '(choDialog "Woman" '(nm +Woman)) ) )
            (delButton) ) )
      <hr> ) )


### RUN ###
(de main ()
   (pool "fam.db")
   (unless (seq *DB)
      (new T '(+Man))
      (commit) ) )

(de go ()
   (server 8080 "@person") )


### Pilog ###
(be person (@Prs) (db nm +Person @Prs))

(be male (@Prs) (isa +Man @Prs))
(be female (@Prs) (isa +Woman @Prs))

(be man (@Prs) (person @Prs) (male @Prs))
(be woman (@Prs) (person @Prs) (female @Prs))

(be name (@N @Prs) (val @N @Prs nm) T)
(be name (@N @Prs) (db nm +Person @N @Prs))

(be father (@F @C) (val @F @C pa) T)
(be father (@F @C) (@ -> @F) T (lst @C @F kids))
(be father (@F @C) (db nm +Person @C) (val @F @C pa))

(be mother (@M @C) (val @M @C ma) T)
(be mother (@M @C) (@ -> @M) T (lst @C @M kids))
(be mother (@M @C) (db nm +Person @C) (val @M @C ma))

(be parents (@M @F @C) (mother @M @C) (father @F @C))

(be sibling (@X @Y) (parents @M @F @X) (parents @M @F @Y) (different @X @Y))
(be brother (@B @X) (sibling @B @X) (male @B))
(be sister (@S @X) (sibling @S @X) (female @S))

(be grandfather (@G @C) (father @F @C) (father @G @F))
(be grandfather (@G @C) (mother @M @C) (father @G @M))

(be grandmother (@G @C) (father @F @C) (mother @G @F))
(be grandmother (@G @C) (mother @M @C) (mother @G @M))

(be uncle (@X @C) (father @F @C) (brother @X @F))
(be uncle (@X @C) (mother @M @C) (brother @X @M))

(be aunt (@X @C) (father @F @C) (sister @X @F))
(be aunt (@X @C) (mother @M @C) (sister @X @M))
