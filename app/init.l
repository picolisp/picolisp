# 24mar07abu
# (c) Software Lab. Alexander Burger

### Role ###
(obj ((+Role) nm "Administration") perm `*Perms)
(obj ((+Role) nm "Accounting") perm (Customer Item Order Report Delete))
(obj ((+Role) nm "Assistance") perm (Order))

(commit)

### User ###
(obj ((+User) nm "admin") pw "admin" nam "Administrator" role `(db 'nm '+Role "Administration"))
(obj ((+User) nm "ben") pw "ben" nam "Ben Affleck" role `(db 'nm '+Role "Accounting"))
(obj ((+User) nm "jodie") pw "jodie" nam "Jodie Foster" role `(db 'nm '+Role "Accounting"))
(obj ((+User) nm "sandy") pw "sandy" nam "Sandra Bullock" role `(db 'nm '+Role "Accounting"))
(obj ((+User) nm "depp") pw "depp" nam "Johnny Depp" role `(db 'nm '+Role "Assistance"))
(obj ((+User) nm "tom") pw "tom" nam "Tom Hanks" role `(db 'nm '+Role "Assistance"))
(commit)

### Customer/Supplier ###
(obj ((+CuSu) nr 1)
   nm "General Supplement Corporation"
   nm2 "Eastern Division"
   str "Wildcat Lane"
   plz "3425"
   ort "Freetown"
   cty "Atlantica"
   tel "37 4967 6846-0"
   fax "37 4967 68462"
   mob "37 176 86303"
   em "info@gsc.tld" )
(obj ((+CuSu) nr 2)
   nm "Seven Oaks Ltd."
   str "Sunny Side Heights 202"
   plz "1795"
   ort "Winterburg"
   cty "Atlantica"
   tel "37 6295 5855-0"
   fax "37 6295 58557"
   em "info@seven-oaks.tld" )
(obj ((+CuSu) nr 3)
   nm "Miller"
   nm2 "Thomas Edwin"
   str "Running Lane 17"
   plz "1208"
   ort "Kaufstadt"
   cty "Atlantica"
   tel "37 4773 82534"
   mob "37 129 276877"
   em "tem@shoppers.tld" )
(commit)

### Item ###
(obj ((+Item) nr 1) nm "Main Part" sup `(db 'nr '+CuSu 1) inv 100 pr 29900)
(obj ((+Item) nr 2) nm "Spare Part" sup `(db 'nr '+CuSu 2) inv 100 pr 1250)
(obj ((+Item) nr 3) nm "Auxiliary Construction" sup `(db 'nr '+CuSu 1) inv 100 pr 15700)
(obj ((+Item) nr 4) nm "Enhancement Additive" sup `(db 'nr '+CuSu 2) inv 100 pr 999)
(obj ((+Item) nr 5) nm "Metal Fittings" sup `(db 'nr '+CuSu 1) inv 100 pr 7980)
(obj ((+Item) nr 6) nm "Gadget Appliance" sup `(db 'nr '+CuSu 2) inv 100 pr 12500)
(commit)

### Order ###
(let Ord (new! '(+Ord) 'nr 1  'dat (date 2007 2 14)  'cus (db 'nr '+CuSu 3))
   (put!> Ord 'pos
      (list
         (new! '(+Pos) 'itm (db 'nr '+Item 1)  'pr 29900  'cnt 1)
         (new! '(+Pos) 'itm (db 'nr '+Item 2)  'pr 1250  'cnt 8)
         (new! '(+Pos) 'itm (db 'nr '+Item 4)  'pr 999  'cnt 20) ) ) )