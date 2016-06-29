# 15apr16abu
# (c) Software Lab. Alexander Burger

(must "Salutation" Customer)

(menu ,"Salutation"
   (idForm ,"Salutation" '(choSal) 'nm '+Sal T '(may Delete) '((: nm))
      (<grid> 2
         ,"Salutation" (gui '(+E/R +Cue +TextField) '(nm : home obj) ,"Salutation" 40)
         ,"Greeting" (gui '(+E/R +TextField) '(hi : home obj) 40)
         ,"Sex" (gui '(+E/R +SexField) '(sex : home obj)) )
      (<spread> NIL (editButton T)) ) )

# vi:et:ts=3:sw=3
