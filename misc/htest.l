# 03dec03abu
# (c) Software Lab. Alexander Burger

(and (app) (rsa 40))

(default
   *Radio '((7 . "a"))
   *Area "Test Area Text^J^JBla bla"
   *Ok "Ja"
   *Dat NIL )

(de tst ()
   (set> (get *Top 'theChart)
      (make
         (for (C 33 (<= C 255) (+ 1 C))
            (link
               (list
                  C
                  (pack
                     (char C)
                     "   "
                     (ext:Snx (pack "|" (char C)))
                     "|" ) ) ) ) ) ) )

(de mm (A)
   (menu> *Top A "Test-Menu"
      (quote
         ("Alle" T  prinl 1)
         ("meine" NIL  prinl 2)
         ("Entlein" T  prinl 3) ) ) )

(setq *DlgStat '((NIL 123 "abc" 730000)))

(de dlg ()
   (dialog "Titel" '*DlgStat
      (quote
         (txt "Hinweistext")
         (----)
         (gui 'lbl '(+Mono +Label) "Val:" "123456")
         (----)
         (gui 'm1 '(+NumField) "Num" 20)
         (gui 'm2 '(+Fmt +TextField) uppc lowc "Msg" 20)
         (gui '(+DateField) "Date" 10)
         (row
            (okButton '(list (val> (: home m1)) (val> (: home m2))))
            (quitButton) ) ) ) )

(html "Test"
   (<head> "Test")

   (<post> "misc/htest.l"
      (<select> "Choice"
         (make
            (for (N 1 (< N 600) (+ 1 N))
               (link N) ) )
         '*N )
      (<select> "Ok" '("Ja" "Nein") '*Ok)

      <hr>
      (form '(+View +Form) NIL  800 700
         (quote
            (gui '(+IntField) "Zahlenfeld" 10)
            (----)
            (row
               (gui '(+Color +Uppc +TextField) (hex "9999FF") NIL  "Msg 1" 10)
               (gui '(+Limit +Align +TextField) 6 "Msg 2" 10)
               (gui '(+Able +Hot +Cho +Map +TextField)
                  '*Flg
                  '(println 'Very 'hot This)
                  '((K V) (lowc K))
                  '(("A" . 1) ("B" . 2) ("C" . 3) ("D" . 4))
                  "Msg 3" 10 )
               (gui '(+Button) " " "dlg"
                  '(println (dlg)) ) )
            (txt " " "Text 1" " " "Text 2")
            (row
               (gui '(+Relay +NumField)
                  '((fix (N) (ifn N 0 (* N 100))))
                  "Number" 12 )
               (gui 'fix '(+FixField) 2 "Fix" 12) )
            (row
               (gui '(+DateField) "Date" 10)
               (gui '(+Chk +TextField) "Mist" "+Chk" 20)
               (gui 'cho '(+TextField) "Auswahlfeld" '("ABC" "DEF" "GHI"))
               (gui 'chk '(+Map +Checkbox) '((T . 1)  (NIL . 2)) "Checkbox") )
            (----)
            (gui 'arr '(+Array) "Array" 4
               '((S) (gui '(+TextField) S 10))
               '(A B C D E F G) )
            (-|-)
            (txt)
            (gui '(+ListTextField) "ListText" 30)
            (---- T)
            (gui '(+Chart)
               4 '(" " "Nummer" "Text")
               (quote
                  (gui '(+PictField) "" 20 20)
                  (gui '(+NumField)  "" 10)
                  (gui '(+TextField) "" 25) ) )
            (row
               (txt " ")
               (flow
                  (gui '(+Button) "" "1" '(println 1))
                  (gui '(+Button) "" "2" '(println 2)) )
               (flow
                  (gui '(+Button) "" "A" '(println 'A))
                  (gui '(+Button) "" "B" '(println 'B))
                  (gui '(+Button) "" "C" '(println 'C)) ) )
            (-|- T)
            (gui 'theChart '(+Chart)
               4 '("Nummer 2" "Text 2" " " "Able")
               (quote
                  (gui '(+NumField)  "" 10)
                  (gui '(+TextField) "" 25)
                  (gui '(+Skip +Able +TextField) '*Flg "!!" 5) )
               '((L)
                  (list (car L) (cadr L) "Ok") )
               '((L)
                  (list (car L) (cadr L)) ) )
            (----)
            (row
               (gui '(+Button) "" "Ok"
                  '(prog
                     (prinl "Alles klar")
                     ((if *Flg off on) *Flg) ) )
               (gui '(+Able +Button)
                  '*Flg
                  "" "Mist"
                  '(prinl "Alles Mist") )
               (gui '(+Button) "" "Und?"
                  '(ask "?" "Alles Ok?") )
               (gui '(+Hot +Macro +TextField)
                  '(when
                     (dialog "Edit" (list (val> This))
                        (quote
                           (gui '(+Font +TextField) "Helvetica" 14 "" 62 25)
                           (----)
                           (row
                              (okButton '(list (val> (: home fields 1))))
                              (quitButton) ) ) )
                     (set> This (car @)) )
                  (quote
                     "Sehr geehrter Herr"
                     "Meine sehr verehrten Damen und Herren"
                     "Verehrte Damen und Herren"
                     "Vielen Dank" )
                  "Clear" 40 6 )
               (gui '(+Mono +Rsa +TextField) "Crypt" -20 4) )
            (----)
            (gui 'img '(+PictField) "Image" 300 200) ) )
      <hr>

      (<field> 10 "Datum" '*Dat "misc/htest.l?*Dat=12345")
      <p>
      (<area> 40 8 "Textarea" '*Area)
      (<upload> 30 "File to send" '*Upload)
      <p>
      (<submit> "Let's fetz")
      (<reset> "Eingabe Löschen")
      <hr>

      "<p>Checkbox"
      (<check> '*Chk1 "A")
      (<check> '*Chk2 "B")
      (<check> '*Chk3 "C")
   
      "<br>Radio"
      (<radio> '(*Radio . 7) "a" "A")
      (<radio> '(*Radio . 7) "b" "B")
      (<radio> '(*Radio . 7) "c" "C") )


   (prinl "Hello!")
   <br>
   (<b> "Ok")
   <hr>
   (<table> T "Table"
      '((- "Left") (* "Center") (+ "Right"))
      (<row> 1 2 3)
      (<row> "a" "b" "c") )
   <hr>
   (<list>
      'a
      '(prog
         (prinl "Sublist 1")
         (<list> 'b 'c) )
      'd
      '(prog
         (prinl "Sublist 2")
         (<list> 'e 'f) ) )
   (<pre>
      (prinl "a b c")
      (prinl "d e f") ) )
