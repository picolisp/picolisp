# 24nov16abu
# (c) Software Lab. Alexander Burger

(load "@lib/simul.l")

# Set up distance properties
# See "misc/travel.l" and "doc/travel"
(mapc
   '((L)
      (put (car L) (cadr L) (caddr L))
      (put (cadr L) (car L) (caddr L)) )
   (quote
      (Rheine Muenster 39)
      (Rheine Osnabrueck 42)
      (Muenster Osnabrueck 51)
      (Warendorf Muenster 28)
      (Warendorf Osnabrueck 43)
      (Warendorf Rheda 24)
      (Warendorf Guetersloh 27)
      (Osnabrueck Bielefeld 48)
      (Rheda Guetersloh 10)
      (Bielefeld Guetersloh 16)
      (Bielefeld Paderborn 39)
      (Paderborn Guetersloh 31)
      (Paderborn Rheda 32)
      (Paderborn Soest 41)
      (Soest Rheda 38)
      (Soest Beckum 26)
      (Beckum Rheda 24)
      (Beckum Warendorf 27)
      (Ahlen Warendorf 27)
      (Ahlen Muenster 46)
      (Ahlen Beckum 11)
      (Ahlen Soest 27) ) )

# Find a route from 'A' to 'B'
(de route (A B Lst)
   (if (get A B)
      (list A B)
      (and
         (pick
            '((X)
               (and
                  (not (memq X Lst))
                  (route X B (cons A Lst)) ) )
            (shuffle (mapcar cdr (getl A))) )
         (cons A @) ) ) )

# Minimize trip from 'A' to 'B'
(de trip (Pop Gen A B)
   (gen
      (make (do Pop (link (route A B))))  # Population
      '((Pop) (lt0 (dec 'Gen)))  # Condition
      '((X Y)  # Recombination
         (make
            (while (prog (link (++ X)) X)
               (when (member (car X) (cdr Y))
                  (setq Y @)
                  (xchg 'X 'Y) ) ) ) )
      '((L)  # Mutation
         (let (N (length L)  H (>> 1 N)  N1 (rand 1 H)  N2 (rand (inc H) N))
            (if (route (get L N1) (get L N2))
               (append
                  (head (dec N1) L)
                  @
                  (nth L (inc N2)) )
               L ) ) )
      '((L)  # Selection
         (let A (++ L)
            (-
               (sum
                  '((X) (get A (setq A X)))
                  L ) ) ) ) ) )

# Optimum hit percentage, e.g. (tst 12 8)
(de tst (Pop Gen)
   (let OK 0
      (do 100
         (when
            (=
               (trip Pop Gen 'Rheine 'Paderborn)
               '(Rheine Muenster Warendorf Rheda Paderborn) )
            (inc 'OK) ) )
      OK ) )
