# 14oct14abu
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

# Salutation
(class +Sal +Entity)
(rel nm (+Key +String))                # Salutation
(rel hi (+String))                     # Greeting
(rel sex (+Any))                       # T:male, 0:female

(dm url> (Tab)
   (and (may Customer) (list "app/sal.l" '*ID This)) )

(dm hi> (Nm)
   (or (text (: hi) Nm) ,"Dear Sir or Madam,") )


# Customer/Supplier
(class +CuSu +Entity)
(rel nr (+Need +Key +Number))          # Customer/Supplier Number
(rel sal (+Link) (+Sal))               # Salutation
(rel nm (+Sn +IdxFold +String))        # Name
(rel nm2 (+String))                    # Name 2
(rel str (+String))                    # Street
(rel plz (+Ref +String))               # Zip
(rel ort (+IdxFold +String))           # City
(rel tel (+Fold +Ref +String))         # Phone
(rel fax (+String))                    # Fax
(rel mob (+Fold +Ref +String))         # Mobile
(rel em (+String))                     # EMail
(rel txt (+Blob))                      # Memo

(dm url> (Tab)
   (and (may Customer) (list "app/cusu.l"  '*Tab Tab  '*ID This)) )

(dm check> ()
   (make
      (or (: nr) (link ,"No customer number"))
      (or (: nm) (link ,"No customer name"))
      (unless (and (: str) (: plz) (: ort))
         (link ,"Incomplete customer address") ) ) )


# Item
(class +Item +Entity)
(rel nr (+Need +Key +Number))          # Item Number
(rel nm (+IdxFold +String))            # Item Description
(rel sup (+Ref +Link) NIL (+CuSu))     # Supplier
(rel inv (+Number))                    # Inventory
(rel pr (+Ref +Number) NIL 2)          # Price
(rel txt (+Blob))                      # Memo
(rel jpg (+Blob))                      # Picture

(dm url> (Tab)
   (and (may Item) (list "app/item.l" '*ID This)) )

(dm cnt> ()
   (-
      (or (: inv) 0)
      (sum '((This) (: cnt))
         (collect 'itm '+Pos This) ) ) )

(dm check> ()
   (make
      (or (: nr) (link ,"No item number"))
      (or (: nm) (link ,"No item description")) ) )


# Order
(class +Ord +Entity)
(rel nr (+Need +Key +Number))          # Order Number
(rel dat (+Need +Ref +Date))           # Order date
(rel cus (+Ref +Link) NIL (+CuSu))     # Customer
(rel pos (+List +Joint) ord (+Pos))    # Positions

(dm lose> ()
   (mapc 'lose> (: pos))
   (super) )

(dm url> (Tab)
   (and (may Order) (list "app/ord.l" '*ID This)) )

(dm sum> ()
   (sum 'sum> (: pos)) )

(dm check> ()
   (make
      (or (: nr) (link ,"No order number"))
      (or (: dat) (link ,"No order date"))
      (if (: cus)
         (chain (check> @))
         (link ,"No customer") )
      (if (: pos)
         (chain (mapcan 'check> @))
         (link ,"No positions") ) ) )


(class +Pos +Entity)
(rel ord (+Dep +Joint)                 # Order
   (itm)
   pos (+Ord) )
(rel itm (+Ref +Link) NIL (+Item))     # Item
(rel pr (+Number) 2)                   # Price
(rel cnt (+Number))                    # Quantity

(dm sum> ()
   (* (: pr) (: cnt)) )

(dm check> ()
   (make
      (if (: itm)
         (chain (check> @))
         (link ,"Position without item") )
      (or (: pr) (link ,"Position without price"))
      (or (: cnt) (link ,"Position without quantity")) ) )


# Database sizes
(dbs
   (3 +Role +User +Sal (+User pw))              # 512 Prevalent objects
   (0 +Pos)                                     # A:64 Tiny objects
   (1 +Item +Ord)                               # B:128 Small objects
   (2 +CuSu)                                    # C:256 Normal objects
   (2 (+Role nm) (+User nm) (+Sal nm))          # D:256 Small indexes
   (4 (+CuSu nr plz tel mob))                   # E:1024 Normal indexes
   (4 (+CuSu nm))                               # F:1024
   (4 (+CuSu ort))                              # G:1024
   (4 (+Item nr sup pr))                        # H:1024
   (4 (+Item nm))                               # I:1024
   (4 (+Ord nr dat cus))                        # J:1024
   (4 (+Pos itm)) )                             # K:1024

# vi:et:ts=3:sw=3
