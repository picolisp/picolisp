# 23feb08abu
# (c) Software Lab. Alexander Burger

### Entity/Relations ###
#
#           nr    nm                   nr    nm               nm
#            |    |                     |    |                |
#          +-*----*-+                 +-*----*-+           +--*-----+
#          |        |             sup |        |           |        |
#    str --*  CuSu  O-----------------*  Item  *-- inv     |  Role  @-- perm
#          |        |                 |        |           |        |
#          +-*-*--O-+                 +----O---+           +----@---+
#            | |  |                        |                    | usr
#   nm  tel -+ |  |                        |                    |
#    |         |  |                        | itm                | role
#  +-*-----+   |  |   +-------+        +---*---+           +----*---+
#  |       |   |  |   |       |    ord |       |           |        |
#  |  Sal  +---+  +---*  Ord  @--------*  Pos  |      nm --*  User  *-- pw
#  |       |      cus |       | pos    |       |           |        |
#  +-*---*-+          +-*---*-+        +-*---*-+           +--------+
#    |   |              |   |            |   |
#   hi   sex           nr  dat          pr   cnt

(extend +Role)

(dm url> (Tab)
   (and (may RoleAdmin) (list "app/role.l" '*ID This)) )


(extend +User)
(rel nam (+String))                             # Full Name
(rel tel (+String))                             # Phone
(rel em  (+String))                             # EMail

(dm url> (Tab)
   (and (may UserAdmin) (list "app/user.l" '*ID This)) )


# Salutation
(class +Sal +Entity)
(rel nm  (+Key +String))                        # Salutation
(rel hi  (+String))                             # Greeting
(rel sex (+Any))                                # T:male, 0:female

(dm url> (Tab)
   (and (may Customer) (list "app/sal.l" '*ID This)) )

(dm hi> (Nm)
   (or (text (: hi) Nm) ,"Dear Sir or Madam,") )


# Customer/Supplier
(class +CuSu +Entity)
(rel nr  (+Need +Key +Number))                  # Customer/Supplier Number
(rel sal (+Link) (+Sal))                        # Salutation
(rel nm  (+Sn +Idx +String))                    # Name
(rel nm2 (+String))                             # Name 2
(rel str (+Ref +String))                        # Street
(rel plz (+Ref +String))                        # Zip
(rel ort (+Ref +String))                        # City
(rel cty (+Ref +String))                        # Country
(rel tel (+Fold +Ref +String))                  # Phone
(rel fax (+String))                             # Fax
(rel mob (+Fold +Ref +String))                  # Mobile
(rel em  (+String))                             # EMail
(rel txt (+Blob))                               # Memo

(dm url> (Tab)
   (and (may Customer) (list "app/cusu.l"  '*Tab Tab  '*ID This)) )


# Item
(class +Item +Entity)
(rel nr  (+Need +Key +Number))                  # Item Number
(rel nm  (+Sn +Idx +String))                    # Item Description
(rel sup (+Ref +Link) NIL (+CuSu))              # Supplier
(rel inv (+Number))                             # Inventory
(rel pr  (+Ref +Number) NIL 2)                  # Price
(rel txt (+Blob))                               # Memo
(rel jpg (+Blob))                               # Picture

(dm url> (Tab)
   (and (may Item) (list "app/item.l" '*ID This)) )

(dm cnt> ()
   (-
      (or (: inv) 0)
      (sum '((This) (: cnt))
         (collect 'itm '+Pos This) ) ) )


# Order
(class +Ord +Entity)
(rel nr  (+Need +Key +Number))                  # Order Number
(rel dat (+Need +Ref +Date))                    # Order date
(rel cus (+Ref +Link) NIL (+CuSu))              # Customer
(rel pos (+List +Joint) ord (+Pos))             # Positions

(dm url> (Tab)
   (and (may Order) (list "app/ord.l" '*ID This)) )

(dm sum> ()
   (sum 'sum> (: pos)) )


(class +Pos +Entity)
(rel ord (+Dep +Joint) (art) pos (+Ord))        # Order
(rel itm (+Ref +Link) NIL (+Item))              # Item
(rel pr  (+Number) 2)                           # Price
(rel cnt (+Number))                             # Quantity

(dm sum> ()
   (* (: pr) (: cnt)) )


# Database sizes
(dbs
   (1 +Role +User +Sal)                         # (1 . 128)
   (2 +CuSu)                                    # (2 . 256)
   (1 +Item +Ord)                               # (3 . 128)
   (0 +Pos)                                     # (4 . 64)
   (2 (+Role nm) (+User nm) (+Sal nm))          # (5 . 256)
   (3 (+CuSu nr nm str plz ort cty tel mob))    # (6 . 512)
   (3 (+Item nr nm sup pr))                     # (7 . 512)
   (3 (+Ord nr dat cus) (+Pos itm)) )           # (8 . 512)

# vi:et:ts=3:sw=3
