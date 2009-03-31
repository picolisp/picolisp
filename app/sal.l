# 03jan09abu
# (c) Software Lab. Alexander Burger

(must "Salutation" Customer)

(menu ,"Salutation"
   (ifn *ID
      (prog
         (<h3> NIL ,"Select" " " ,"Salutation")
         (form 'dialog (choDlg NIL ,"Salutations" '(nm +Sal))) )
      (<h3> NIL ,"Salutation")
      (form NIL
         (<h2> NIL (<id> (: nm)))
         (panel T (pack ,"Salutation" " '@1'") '(may Delete) '(choDlg NIL ,"Salutations" '(nm +Sal)) 'nm '+Sal)
         (<grid> 2
            ,"Salutation" (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Salutation" 40)
            ,"Greeting" (gui '(+E/R +TextField) '(hi : home obj) 40)
            ,"Sex" (gui '(+E/R +SexField) '(sex : home obj)) )
         (<spread> NIL (editButton T)) ) ) )

# vi:et:ts=3:sw=3
