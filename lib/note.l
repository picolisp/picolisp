# 13mar05abu
# (c) Software Lab. Alexander Burger

### Event-Note-System ###
# *NoteAll *NoteUsr *NoteDat *NoteTxt *Attach

(mapc allow '(*Attach "@edNotes"))


(class +Note +Entity)
(rel usr    (+Dep +List +Ref +Link)             # User
   (con dat)
   NIL (+User) )
(rel dat    (+Date))                            # Date
(rel con    (+Aux +Ref +Any) (dat))             # Context
(rel l      (+Blob))                            # Note file


# Note selection
(de selNotes (Usr Con Dat)
   (default Dat T)
   (use @Note
      (solve
         (quote
            @Usr Usr
            @Con Con
            @CDx (and Con (cons (cons Con) (cons Con Dat)))
            (select (@Note)
               ((usr +Note @Usr) (con +Note @CDx))
               (@ >= Dat (get (-> @Note) 'dat))
               (same @Usr @Note usr)
               (same @Con @Note con) ) )
         @Note ) ) )


# Note editing
(class +NoteForm +Form)
# con usr

(dm T (Con . @)
   (=: con Con)
   (super 800 (+ 400 (*/ (length *NoteAll) 15 6))
      (quote
         (row
            (gui '(+Button) "An Benutzer" "alle" '(set> (: home usr) *NoteAll))
            (gui '(+Button) "" "keiner" '(clr> (: home usr))) )
         (----)
         (gui 'usr '(+Var +Array) '*NoteUsr "" 6
            '((This)
               (gui '(+Map +Checkbox)
                  (cons (cons T This))
                  (: nm) ) )
            *NoteAll )
         (----)
         (gui '(+Var +DateField) '*NoteDat "Zustellung erst ab" 10)
         (----)
         (row
            (gui '(+Var +ListTextField) '*NoteTxt "^J" "" 60 16)
            (gui '(+Able +Button)
               '(find bool *NoteUsr)
               "" "Notiz versenden"
               '("send"
                  (filter bool *NoteUsr)
                  (: home con)
                  *NoteDat
                  *NoteTxt ) ) ) ) ) )


(de edNotes (Con Note Att)
   (must edNotes)
   (when Note
      (del!> Note 'usr *Login) )
   (when Att
      (call 'rm (tmp "note" '/ Att)) )
   (html "Notizen"
      (for Note (selNotes *Login Con (date))
         (load (blob Note 'l))
         (prinl '<hr>) )
      (when (may NoteEdit)
         (<head> "Neue Notiz")
         (default *NoteAll (collect 'nm '+User))
         (form '(+NoteForm) Con)
         (let P (tmp "note")
            (call 'mkdir "-p" P)
            (when *Attach
               (call 'mv (tmp *Attach) P)
               (off *Attach) )
            (when (dir P)
               (<table> NIL NIL '((-) (+) (-))
                  (for F (dir P)
                     (<row>
                        F
                        (pack "(" (*/ (car (info (pack P '/ F))) 1024) " kB)")
                        '(<button> "entfernen"
                           (pack "@edNotes?" (ht:Fmt Con NIL F)) ) ) ) ) ) )
         (<post> (pack "@edNotes?" (ht:Fmt Con))
            (<upload> 40 "" '*Attach)
            (<submit> "Anhang hinzufügen") ) ) ) )

# Send note
(de "send" (Lst Con Dat Txt)
   (let P (tmp "note")
      (with (new! '(+Note)  'usr Lst  'con Con  'dat Dat  'l T)
         (out (blob This 'l)
            (println
               (list '<head>
                  (pack
                     "Notiz von " (get *Login 'nm)
                     " (" (stamp) ")" ) ) )
            (println (list 'mapc '<br> (lit Txt)))
            (when (dir P)
               (println '(prinl "<p>"))
               (for Nm @
                  (let F (pack P '/ Nm)
                     (println
                        (list 'out (list 'tmp Nm) (list 'here (car (info F)))) )
                     (in F (echo))
                     (println '(space))
                     (println (list '<button> Nm (list 'tmp Nm))) ) )
               (println '(prinl "</p>")) )
            (println
               (list '<p> T
                  (list '<href>
                     "Notiz löschen"
                     (pack "@edNotes?" (ht:Fmt Con This)) ) ) ) ) )
      (off *NoteUsr *NoteDat *NoteTxt)
      (call 'rm "-r" P)
      (url (pack "@edNotes?" (: home con))) ) )

# Note button
(de noteButton (@Exe Lbl)
   (gui '(+Rid +Able +Button)
      (fill
         '(let Con @Exe
            (if (and *Login Con (selNotes *Login Con (date)))
               (bCol `(hex "FF0000"))
               (bCol `(hex "C0C0C0"))
               (and Con (may NoteEdit)) ) ) )
      Lbl '!
      (fill '(url (pack "@edNotes?" (ht:Fmt @Exe)))) ) )
