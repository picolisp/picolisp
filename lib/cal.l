# 17sep02abu
# (c) Software Lab. Alexander Burger

# Easter date
(de easter (Year)
   (unless (<= 1900 Year 2099)
      (quit "Illegal Year" Year) )
   (let
      (A (% Year 19)
         B (% Year 4)
         C (% Year 7)
         D (% (+ 24 (* 19 A)) 30)
         E (% (+ 5 (* 2 B) (* 4 C) (* 6 D)) 7)
         Day (+ 22 D E)
         Mon 3 )
      (and (> Day 31) (setq  Day (+ D E -9)  Mon 4))
      (and (= Day 26) (= Mon 4) (setq Day 19))
      (and (= Day 25) (= Mon 4) (= D 28) (= E 6) (> A 10) (setq Day 18))
      (date Year Mon Day) ) )

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
         (Rosenmontag
            (- (easter Year) 48) )
         (Aschermittwoch
            (- (easter Year) 46) )
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
         (Fronleichnam
            (+ (easter Year) 60) ) )
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
