# 08may16abu
# (c) Software Lab. Alexander Burger

### GUI ###
(de menu (Ttl . Prg)
   (action
      (html 0 Ttl *Css NIL
         (<ping> 7)
         (<layout>
            ((180 0 'menu)
               (<div> @
                  (expires)
                  (<menu>
                     (,"Home" "!work")
                     (,"logout" (and *Login "!stop"))
                     (NIL (<hr>))
                     (T ,"Data"
                        (,"Orders" (and (may Order) "app/ord.l"))
                        (,"Items" (and (may Item) "app/item.l"))
                        (,"Customers/Suppliers" (and (may Customer) "app/cusu.l"))
                        (,"Salutations" (and (may Customer) "app/sal.l")) )
                     (T ,"Report"
                        (,"Inventory" (and (may Report) "app/inventory.l"))
                        (,"Sales" (and (may Report) "app/sales.l")) )
                     (T ,"System"
                        (,"Role Administration" (and (may RoleAdmin) "@lib/role.l"))
                        (,"User Administration" (and *Login "@lib/user.l") (unless (may UserAdmin) *Login)) ) ) )
               ((NIL NIL 'main)
                  (<div> @ (run Prg 1)) ) ) ) ) ) )

(de work ()
   (setq *Url "!work")
   (and (app) (setq *Menu 3))
   (menu "PicoLisp App"
      (<h2> NIL "PicoLisp App")
      (<img> "@img/7fachLogo.png" "7fach Logo" NIL "50%")
      (----)
      (form NIL
         (gui '(+Init +Map +TextField)
            (cons *Ctry *Lang)
            *Locales
            (mapcar car *Locales)
            ',"Language" )
         (gui '(+Button) ',"Change"
            '(let V (val> (field -1))
               (locale (car V) (cdr V) "app/loc/") ) ) )
      (loginForm) ) )

(de stop ()
   (logout)
   (work) )

# Search dialogs
(de choSal (Dst)
   (choDlg Dst ,"Salutations" '(nm +Sal)) )

(de choCuSu (Dst)
   (diaform '(Dst)
      (<grid> "--.-.-."
         ,"Number" (gui 'nr '(+Var +NumField) '*CuSuNr 10)
         ,"Name" (gui 'nm '(+Focus +Var +TextField) '*CuSuNm 30)
         ,"Phone" (gui 'tel '(+Var +TelField) '*CuSuTel 20)
         (searchButton '(init> (: home query)))
         ,"Zip" (gui 'plz '(+Var +TextField) '*CuSuPlz 10)
         ,"City" (gui 'ort '(+Var +TextField) '*CuSuOrt 30)
         ,"Mobile" (gui 'mob '(+Var +TelField) '*CuSuMob 20)
         (resetButton '(nr nm tel plz ort mob query)) )
      (gui 'query '(+QueryChart) (cho)
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
                  (part @Ort @@ ort)
                  (fold @Mob @@ mob) ) ) )
         9
         '((This) (list This (: nr) This (: nm2) (: em) (: plz) (: ort) (: tel) (: mob))) )
      (<table> 'chart (choTtl ,"Customers/Suppliers" 'nr '+CuSu)
         (quote
            (btn)
            (align "#")
            (NIL ,"Name")
            (NIL)
            (NIL ,"EMail")
            (NIL ,"Zip")
            (NIL ,"City")
            (NIL ,"Phone")
            (NIL ,"Mobile") )
         (do (cho)
            (<row> (alternating)
               (gui 1 '(+DstButton) Dst)
               (gui 2 '(+NumField))
               (gui 3 '(+ObjView +TextField) '(: nm))
               (gui 4 '(+TextField))
               (gui 5 '(+MailField))
               (gui 6 '(+TextField))
               (gui 7 '(+TextField))
               (gui 8 '(+TelField))
               (gui 9 '(+TelField)) ) ) )
      (<spread>
         (scroll (cho))
         (newButton T Dst '(+CuSu)
            '(nr genKey 'nr '+CuSu)
            'nm *CuSuNm
            'plz *CuSuPlz
            'ort *CuSuOrt
            'tel *CuSuTel
            'mob *CuSuMob )
         (cancelButton) ) ) )

(de choItem (Dst)
   (diaform '(Dst)
      (<grid> "--.-."
         ,"Number" (gui 'nr '(+Focus +Var +NumField) '*ItemNr 10)
         ,"Supplier" (gui 'sup '(+Var +TextField) '*ItemSup 20)
         (searchButton '(init> (: home query)))
         ,"Description" (gui 'nm '(+Var +TextField) '*ItemNm 30)
         ,"Price" (gui 'pr '(+Var +FixField) '*ItemPr 2 12)
         (resetButton '(nr nm pr sup query)) )
      (gui 'query '(+QueryChart) (cho)
         '(goal
            (quote
               @Nr (and *ItemNr (cons @ T))
               @Nm *ItemNm
               @Pr (and *ItemPr (cons @ T))
               @Sup *ItemSup
               (select (@@)
                  ((nr +Item @Nr) (nm +Item @Nm) (pr +Item @Pr) (nm +CuSu @Sup (sup +Item)))
                  (range @Nr @@ nr)
                  (part @Nm @@ nm)
                  (range @Pr @@ pr)
                  (tolr @Sup @@ sup nm) ) ) )
         6
         '((This) (list This (: nr) This (: sup) (: sup ort) (: pr))) )
      (<table> 'chart (choTtl ,"Items" 'nr '+Item)
         (quote
            (btn)
            (align "#")
            (NIL ,"Description")
            (NIL ,"Supplier")
            (NIL ,"City")
            (align ,"Price") )
         (do (cho)
            (<row> (alternating)
               (gui 1 '(+DstButton) Dst)
               (gui 2 '(+NumField))
               (gui 3 '(+ObjView +TextField) '(: nm))
               (gui 4 '(+ObjView +TextField) '(: nm))
               (gui 5 '(+TextField))
               (gui 6 '(+FixField) 2) ) ) )
      (<spread>
         (scroll (cho))
         (newButton T Dst '(+Item)
            '(nr genKey 'nr '+Item)
            'nm *ItemNm
            'pr *ItemPr )
         (cancelButton) ) ) )

(de choOrd (Dst)
   (diaform '(Dst)
      (<grid> "--.-.-."
         ,"Number" (gui 'nr '(+Focus +Var +NumField) '*OrdNr 10)
         ,"Customer" (gui 'cus '(+Var +TextField) '*OrdCus 20)
         ,"City" (gui 'ort '(+Var +TextField) '*OrdOrt 20)
         (searchButton '(init> (: home query)))
         ,"Date" (gui 'dat '(+Var +DateField) '*OrdDat 10)
         ,"Supplier" (gui 'sup '(+Var +TextField) '*OrdSup 20)
         ,"Item" (gui 'item '(+Var +TextField) '*OrdItem 20)
         (resetButton '(nr cus ort dat sup item query)) )
      (gui 'query '(+QueryChart) (cho)
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
                  (part @Ort @@ cus ort)
                  (part @Item @@ pos itm nm)
                  (tolr @Sup @@ pos itm sup nm) ) ) )
         9
         '((This)
            (list This (: nr) This
               (: cus) (: cus ort)
               (: pos 1 itm sup) (: pos 1 itm)
               (: pos 2 itm sup) (: pos 2 itm) ) ) )
      (<table> 'chart (choTtl ,"Orders" 'nr '+Ord)
         (quote
            (btn)
            (align "#")
            (NIL ,"Date")
            (NIL ,"Customer")
            (NIL ,"City")
            (NIL ,"Supplier" "(1)")
            (NIL ,"Item" "(1)")
            (NIL ,"Supplier" "(2)")
            (NIL ,"Item" "(2)") )
         (do (cho)
            (<row> (alternating)
               (gui 1 '(+DstButton) Dst)
               (gui 2 '(+NumField))
               (gui 3 '(+ObjView +DateField) '(: dat))
               (gui 4 '(+ObjView +TextField) '(: nm))
               (gui 5 '(+TextField))
               (gui 6 '(+ObjView +TextField) '(: nm))
               (gui 7 '(+ObjView +TextField) '(: nm))
               (gui 8 '(+ObjView +TextField) '(: nm))
               (gui 9 '(+ObjView +TextField) '(: nm)) ) ) )
      (<spread>
         (scroll (cho))
         (newButton T Dst '(+Ord)
            '(nr genKey 'nr '+Ord)
            'dat (date) )
         (cancelButton) ) ) )

# vi:et:ts=3:sw=3
