# 23jun15abu
# (c) Software Lab. Alexander Burger

# Easter date algorithm from J.M. Oudin (1940)
(de easter (Year)
   (let
      (C (/ Year 100)
         N (% Year 19)  # Metonic cycle
         I (%
            (+
               (- C (/ C 4) (/ (- C (/ (- C 17) 25)) 3))
               (* 19 N)
               15 )
            30 ) )
      (dec 'I (* (/ I 28) (- 1 (* (/ I 28) (/ 29 (inc I)) (/ (- 21 N) 11)))))
      (let
         (L (- I (% (+ Year (/ Year 4) I 2 (- C) (/ C 4)) 7))
            Mon (+ 3 (/ (+ L 40) 44)) )
         (date Year Mon (+ L 28 (* (/ Mon 4) -31))) ) ) )

# Feiertage
(de feier (X Year)
   (if (sym? X)
      (case X
         (Neujahr
            (date Year 1 1) )
         ((Maifeiertag "1. Mai" "Tag der Arbeit")
            (date Year 5 1) )
         (("Tag der deutschen Einheit" "Deutsche Einheit")
            (date Year 10 3) )
         ((Weihnachten "1. Weihnachtstag")
            (date Year 12 25) )
         ("2. Weihnachtstag"
            (date Year 12 26) )
         #{(Rosenmontag
            (- (easter Year) 48) )}#
         #{(Aschermittwoch
            (- (easter Year) 46) )}#
         (Karfreitag
            (- (easter Year) 2) )
         ((Ostern Ostersonntag)
            (easter Year) )
         (Ostermontag
            (+ (easter Year) 1) )
         ((Himmelfahrt "Christi Himmelfahrt")
            (+ (easter Year) 39) )
         ((Pfingsten Pfingstsonntag)
            (+ (easter Year) 49) )
         (Pfingstsmontag
            (+ (easter Year) 50) )
         #{(Fronleichnam
            (+ (easter Year) 60) )}# )
      (let L (date X)
         (cdr
            (or
               (assoc (cdr L)
                  (quote
                     ((1 1) . Neujahr)
                     ((5 1) . Maifeiertag)
                     ((10 3) . "Tag der deutschen Einheit")
                     ((12 25) . Weihnachten)
                     ((12 26) . "2. Weihnachtstag") ) )
               (assoc (- X (easter (car L)))
                  (quote
                     (-48 . Rosenmontag)
                     (-46 . Aschermittwoch)
                     (-2 . Karfreitag)
                     (0 . Ostern)
                     (1 . Ostermontag)
                     (39 . Himmelfahrt)
                     (49 . Pfingsten)
                     (50 . Pfingstsmontag)
                     (60 . Fronleichnam) ) ) ) ) ) ) )

# Werktag
(de werktag (Dat)
   (nor
      (member (% Dat 7) (4 5))  # Sa So
      (feier Dat) ) )
