# 24mar07abu
# (c) Software Lab. Alexander Burger

### GUI ###
(de menu Prg
   (action
      (html 0 "Pico App" *Css NIL
         (<div> '(id . menu)
            (<menu>
               (,"Home" "@start")
               (,"logout" (and *Login "@stop"))
               (NIL (<hr>))
               (T ,"Data"
                  (,"Customer/Supplier" (and (may Customer) "app/cusu.l"))
                  (,"Item" (and (may Item) "app/item.l"))
                  (,"Order" (and (may Order) "app/ord.l")) )
               (T ,"Report"
                  (,"Inventory" (and (may Report) "app/inventory.l"))
                  (,"Sales" (and (may Report) "app/sales.l")) )
               (T ,"System"
                  (,"Role Administration" (and (may RoleAdmin) "app/role.l"))
                  (,"User Administration" (and (may UserAdmin) "app/user.l")) ) ) )
         (<div> '(id . main) (run Prg 1)) ) ) )

(de start ()
   (setq *Url "@start")
   (app)
   (menu
      (<h2> NIL "Pico App")
      (<img> "img/7fach.gif" "7fach Logo")
      (form NIL
         (gui '(+Init +Map +TextField)
            (cons *Ctry *Lang)
            '(("English" NIL . NIL) ("Deutsch" "DE" . "de") ("日本語" "JP" . "jp"))
            '("English" "Deutsch" "日本語")
            ,"Language" )
         (gui '(+Button) ',"Change"
            '(let V (val> (field -1))
               (locale (car V) (cdr V) "app/loc/") ) ) )
      (form NIL
         (<grid> 2
            ,"Name" (gui 'nm '(+Able +TextField) '(not *Login) 30)
            ,"Password" (gui 'pw '(+Able +PwField) '(not *Login) 30) )
         (<spread>
            (and *Login (<span> 'bold (ht:Prin "'" (get *Login 'nm) ,"' logged in")))
            (gui '(+Button) '(if *Login ,"logout" ,"login")
               '(cond
                  (*Login (logout))
                  ((login (val> (: home nm)) (val> (: home pw)))
                     (clr> (: home pw)) )
                  (T (err ,"Permission denied")) ) ) ) ) ) )

(de stop ()
   (logout)
   (start) )

# Search dialogs
(de choCuSu (Dst)
   (diaform '(Dst)
      (<grid> "--.-.-."
         ,"Number" (gui 'nr '(+Var +NumField) '*CuSuNr 10)
         ,"Name" (gui 'nm '(+Var +TextField) '*CuSuNm 30)
         ,"Phone" (gui 'tel '(+Var +TelField) '*CuSuTel 20)
         (gui '(+JS +Button) ,"Search" '(init> (: home query)))
         ,"Zip" (gui 'plz '(+Var +TextField) '*CuSuPlz 10)
         ,"City" (gui 'ort '(+Var +TextField) '*CuSuOrt 30)
         ,"Mobile" (gui 'mob '(+Var +TelField) '*CuSuMob 20)
         (gui '(+JS +ClrButton) ,"Reset" '(nr nm tel plz ort mob query)) )
      (gui 'query '(+QueryChart) 8
         '(goal
            (quote
               @Nr (and *CuSuNr (cons @ T))
               @Nm *CuSuNm
               @Tel *CuSuTel
               @Plz *CuSuPlz
               @Ort *CuSuOrt
               @Mob *CuSuMob
               (select (@@)
                  ((nr +CuSu @Nr) (nm +CuSu @Nm) (tel +CuSu @Tel)
                     (plz +CuSu @Plz) (ort +CuSu @Ort) (mob +CuSu @Mob) )
                  (range @Nr @@ nr)
                  (tolr @Nm @@ nm)
                  (fold @Tel @@ tel)
                  (head @Plz @@ plz)
                  (head @Ort @@ ort)
                  (fold @Mob @@ mob) ) ) )
         (if (flg? Dst) 8 9)
         '((This) (list This This (: plz) (: ort) (: tel) (: fax) (: mob) (: em))) )
      (<table> 'chart ,"Customer/Supplier"
         (quote
            (align "#")
            (NIL ,"Name")
            (NIL ,"Zip")
            (NIL ,"City")
            (NIL ,"Phone")
            (NIL ,"Fax")
            (NIL ,"Mobile")
            (NIL ,"EMail")
            (btn) )
         (do 8
            (<row> (alternating)
               (gui 1 '(+ObjView +NumField) '(: nr))
               (gui 2 '(+ObjView +TextField) '(: nm))
               (gui 3 '(+TextField))
               (gui 4 '(+TextField))
               (gui 5 '(+TelField))
               (gui 6 '(+TelField))
               (gui 7 '(+TelField))
               (gui 8 '(+MailField))
               (unless (flg? Dst)
                  (gui 9 '(+DstButton) Dst -7) ) ) ) )
      (<spread>
         (scroll 8)
         (when (=T Dst)
            (gui '(+Button) ,"New"
               '(newUrl '(+CuSu) '(nr genKey 'nr '+CuSu)) ) )
         (cancelButton) ) ) )

(de choItem (Dst)
   (diaform '(Dst)
      (<grid> "--.-."
         ,"Number" (gui 'nr '(+Var +NumField) '*ItemNr 10)
         ,"Supplier" (gui 'sup '(+Var +TextField) '*ItemSup 20)
         (gui '(+JS +Button) ,"Search" '(init> (: home query)))
         ,"Description" (gui 'nm '(+Var +TextField) '*ItemNm 30)
         ,"Price" (gui 'pr '(+Var +FixField) '*ItemPr 2 12)
         (gui '(+JS +ClrButton) ,"Reset" '(nr nm pr sup query)) )
      (gui 'query '(+QueryChart) 8
         '(goal
            (quote
               @Nr (and *ItemNr (cons @ T))
               @Nm *ItemNm
               @Pr (and *ItemPr (cons @ T))
               @Sup *ItemSup
               (select (@@)
                  ((nr +Item @Nr) (nm +Item @Nm) (pr +Item @Pr) (nm +CuSu @Sup (sup +Item)))
                  (range @Nr @@ nr)
                  (tolr @Nm @@ nm)
                  (range @Pr @@ pr)
                  (tolr @Sup @@ sup nm) ) ) )
         (if (flg? Dst) 5 6)
         '((This) (list This This (: sup) (: sup ort) (: pr))) )
      (<table> 'chart ,"Item"
         (quote
            (align "#")
            (NIL ,"Description")
            (NIL ,"Supplier")
            (NIL ,"City")
            (align ,"Price")
            (btn) )
         (do 8
            (<row> (alternating)
               (gui 1 '(+ObjView +NumField) '(: nr))
               (gui 2 '(+ObjView +TextField) '(: nm))
               (gui 3 '(+ObjView +TextField) '(: nm))
               (gui 4 '(+TextField))
               (gui 5 '(+FixField) 2)
               (unless (flg? Dst)
                  (gui 6 '(+DstButton) Dst -4) ) ) ) )
      (<spread>
         (scroll 8)
         (when (=T Dst)
            (gui '(+Button) ,"New"
               '(newUrl '(+Item) '(nr genKey 'nr '+Item)) ) )
         (cancelButton) ) ) )

(de choOrd (Dst)
   (diaform '(Dst)
      (<grid> "--.-.-."
         ,"Number" (gui 'nr '(+Var +NumField) '*OrdNr 10)
         ,"Customer" (gui 'cus '(+Var +TextField) '*OrdCus 20)
         ,"City" (gui 'ort '(+Var +TextField) '*OrdOrt 20)
         (gui '(+JS +Button) ,"Search" '(init> (: home query)))
         ,"Date" (gui 'dat '(+Var +DateField) '*OrdDat 10)
         ,"Supplier" (gui 'sup '(+Var +TextField) '*OrdSup 20)
         ,"Item" (gui 'item '(+Var +TextField) '*OrdItem 20)
         (gui '(+JS +ClrButton) ,"Reset" '(nr cus ort dat sup item query)) )
      (gui 'query '(+QueryChart) 8
         '(goal
            (quote
               @Nr (cons (or *OrdNr T))
               @Dat (cons (or *OrdDat T))
               @Cus *OrdCus
               @Ort *OrdOrt
               @Sup *OrdSup
               @Item *OrdItem
               (select (@@)
                  ((nr +Ord @Nr) (dat +Ord @Dat)
                     (nm +CuSu @Cus (cus +Ord))
                     (ort +CuSu @Ort (cus +Ord))
                     (nm +Item @Item (itm +Pos) ord)
                     (nm +CuSu @Sup (sup +Item) (itm +Pos) ord) )
                  (range @Nr @@ nr)
                  (range @Dat @@ dat)
                  (tolr @Cus @@ cus nm)
                  (head @Ort @@ cus ort)
                  (tolr @Item @@ pos itm nm)
                  (tolr @Sup @@ pos itm sup nm) ) ) )
         (if (flg? Dst) 8 9)
         '((This)
            (list This This
               (: cus) (: cus ort)
               (: pos 1 itm sup) (: pos 1 itm)
               (: pos 2 itm sup) (: pos 2 itm) ) ) )
      (<table> 'chart ,"Order"
         (quote
            (align "#")
            (NIL ,"Date")
            (NIL ,"Customer")
            (NIL ,"City")
            (NIL ,"Supplier" "(1)")
            (NIL ,"Item" "(1)")
            (NIL ,"Supplier" "(2)")
            (NIL ,"Item" "(2)")
            (btn) )
         (do 8
            (<row> (alternating)
               (gui 1 '(+ObjView +NumField) '(: nr))
               (gui 2 '(+ObjView +DateField) '(: dat))
               (gui 3 '(+ObjView +TextField) '(: nm))
               (gui 4 '(+TextField))
               (gui 5 '(+ObjView +TextField) '(: nm))
               (gui 6 '(+ObjView +TextField) '(: nm))
               (gui 7 '(+ObjView +TextField) '(: nm))
               (gui 8 '(+ObjView +TextField) '(: nm))
               (unless (flg? Dst)
                  (gui 9 '(+DstButton) Dst -7) ) ) ) )
      (<spread>
         (scroll 8)
         (when (=T Dst)
            (gui '(+Button) ,"New"
               '(newUrl '(+Ord) '(nr genKey 'nr '+Ord) 'dat (date)) ) )
         (cancelButton) ) ) )