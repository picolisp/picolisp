# 22oct03abu
# (c) Software Lab. Alexander Burger

(de travel (A B)
   (mini car
      (solve
         (quote
            @A A
            @B B
            (path @A @B @P @N) )
         (cons @N @P) ) ) )


(be path (@A @B @P @N) (path1 @A @B (@A) @P @N))

(be path1 (@A @A @L (@A) 0))
(be path1 (@A @B @L (@A . @P) @N)
   (edge @A @Z @X)
   (not (member @Z @L))
   (path1 @Z @B (@Z . @L) @P @Y)
   (@N + (-> @X) (-> @Y)) )

(be edge (@A @B @N) (vect @A @B @N))
(be edge (@A @B @N) (vect @B @A @N))

(be vect (Rheine Muenster 39))
(be vect (Rheine Osnabrueck 42))
(be vect (Muenster Osnabrueck 51))
(be vect (Warendorf Muenster 28))
(be vect (Warendorf Osnabrueck 43))
(be vect (Warendorf Rheda 24))
(be vect (Warendorf Guetersloh 27))
(be vect (Osnabrueck Bielefeld 48))
(be vect (Rheda Guetersloh 10))
(be vect (Bielefeld Guetersloh 16))
(be vect (Bielefeld Paderborn 39))
(be vect (Paderborn Guetersloh 31))
(be vect (Paderborn Rheda 32))
(be vect (Paderborn Soest 41))
(be vect (Soest Rheda 38))
(be vect (Soest Beckum 26))
(be vect (Beckum Rheda 24))
(be vect (Beckum Warendorf 27))
(be vect (Ahlen Warendorf 27))
(be vect (Ahlen Muenster 46))
(be vect (Ahlen Beckum 11))
(be vect (Ahlen Soest 27))

(test
   '(123 Rheine Muenster Warendorf Rheda Paderborn)
   (travel 'Rheine 'Paderborn) )
