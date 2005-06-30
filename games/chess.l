# 12jun05abu
# (c) Software Lab. Alexander Burger

# *Board a1 .. h8
# *White *Black *WKing *BKing
# *Depth *Moved *Undo *Redo *Me *You

(load "lib/simul.l")

### Fields/Board ###
# x y color piece

(unless *Board
   (setq *Board (grid 8 8))
   (for X (1 2 3 4 5 6 7 8)
      (for Y (1 2 3 4 5 6 7 8)
         (with (get *Board X Y)
            (=: x X)
            (=: y Y)
            (=: color (not (bit? 1 (+ X Y)))) ) ) ) )

(de *Straight `west `east `north `south)

(de *Diagonal
   ((Fld) (cadr (val (caar (val Fld)))))     # Southwest
   ((Fld) (cddr (val (caar (val Fld)))))     # Northwest
   ((Fld) (cadr (val (cdar (val Fld)))))     # Southeast
   ((Fld) (cddr (val (cdar (val Fld))))) )   # Northeast

(de *DiaStraight
   ((Fld) (cadr (val (cadr (val (caar (val Fld)))))))    # South Southwest
   ((Fld) (caar (val (cadr (val (caar (val Fld)))))))    # West Southwest
   ((Fld) (caar (val (cddr (val (caar (val Fld)))))))    # West Northwest
   ((Fld) (cddr (val (cddr (val (caar (val Fld)))))))    # North Northwest
   ((Fld) (cddr (val (cddr (val (cdar (val Fld)))))))    # North Northeast
   ((Fld) (cdar (val (cddr (val (cdar (val Fld)))))))    # East Northeast
   ((Fld) (cdar (val (cadr (val (cdar (val Fld)))))))    # East Southeast
   ((Fld) (cadr (val (cadr (val (cdar (val Fld))))))) )  # South Southeast


### Pieces ###
(de piece (Typ Fld)
   (prog1
      (def
         (pack
            (mapcar '((Cls) (cdr (chop Cls))) Typ) )
         Typ )
      (init> @ Fld) ) )

(de ahead (Color Fld)
   ((if Color south north) Fld) )

(de behind (Color Fld)
   ((if Color north south) Fld) )


(class +White)
# color ahead

(dm init> (Fld)
   (=: ahead north)
   (extra Fld) )

(dm name> ()
   (pack " " (extra) " ") )

(dm move> (Fld)
   (cond
      ((not Fld) (setq *White (delq This *White)))
      ((not (: field)) (push '*White This)) )
   (extra Fld) )


(class +Black)

(dm init> (Fld)
   (=: color T)
   (=: ahead south)
   (extra Fld) )

(dm name> ()
   (pack '< (extra) '>) )

(dm move> (Fld)
   (cond
      ((not Fld) (setq *Black (delq This *Black)))
      ((not (: field)) (push '*Black This)) )
   (extra Fld) )


(class +piece)
# field

(dm init> (Fld)
   (move> This Fld) )

(dm move> (Fld)
   (and (: field) (put @ 'piece NIL))
   (and (=: field Fld) (put @ 'piece This)) )


(class +King +piece)

(dm init> (Fld)
   (=: val 126)
   (super Fld) )

(dm name> () 'K)

(dm moves> ()
   (unless (attack (: field) (not (: color)))
      (make
         (unless (memq This *Moved)
            (castle west T)
            (castle east) )
         (try1Move *Straight)
         (try1Move *Diagonal) ) ) )


(class +Queen +piece)

(dm init> (Fld)
   (=: val 72)
   (super Fld) )

(dm name> () 'Q)

(dm moves> ()
   (make (tryMoves *Straight) (tryMoves *Diagonal)) )


(class +Rook +piece)

(dm init> (Fld)
   (=: val 40)
   (super Fld) )

(dm name> () 'R)

(dm moves> ()
   (make (tryMoves *Straight)) )


(class +Bishop +piece)

(dm init> (Fld)
   (=: val 28)
   (super Fld) )

(dm name> () 'B)

(dm moves> ()
   (make (tryMoves *Diagonal)) )


(class +Knight +piece)

(dm init> (Fld)
   (=: val 26)
   (super Fld) )

(dm name> () 'N)

(dm moves> ()
   (make (try1Move *DiaStraight)) )


(class +Pawn +piece)

(dm init> (Fld)
   (=: val 8)
   (super Fld) )

(dm name> () 'P)

(dm moves> ()
   (let (Fld1 ((: ahead) (: field))  Fld2 ((: ahead) Fld1))
      (make
         (and
            (tryPawnMove Fld1 Fld2)
            (not (memq This *Moved))
            (tryPawnMove Fld2 T) )
         (tryPawnCapt (west Fld1) Fld2 (west (: field)))
         (tryPawnCapt (east Fld1) Fld2 (east (: field))) ) ) )


### Move Logic ###
(de king (Color . @)
   (pass get (if Color *BKing *WKing)) )

(de isaPawn (Pce Color)
   (and
      (isa '+Pawn Pce)
      (== Color (get Pce 'color))
      Pce ) )

(de isaKnight (Pce Color)
   (and
      (isa '+Knight Pce)
      (== Color (get Pce 'color))
      Pce ) )

(de isaKing (Pce Color)
   (and
      (isa '+King Pce)
      (== Color (get Pce 'color))
      Pce ) )

(de try1Move (Lst)
   (for Dir Lst
      (let? Fld (Dir (: field))
         (ifn (get Fld 'piece)
            (link (list This (cons This Fld)))
            (unless (== (: color) (get @ 'color))
               (link
                  (list This
                     (cons (get Fld 'piece))
                     (cons This Fld) ) ) ) ) ) ) )

(de tryMoves (Lst)
   (for Dir Lst
      (let Fld (: field)
         (loop
            (NIL (setq Fld (Dir Fld)))
            (T (get Fld 'piece)
               (unless (== (: color) (get @ 'color))
                  (link
                     (list This
                        (cons (get Fld 'piece))
                        (cons This Fld) ) ) ) )
            (link (list This (cons This Fld))) ) ) ) )

(de tryPawnMove (Fld Flg)
   (unless (get Fld 'piece)
      (if Flg
         (link (list This (cons This Fld)))
         (for Cls '(+Queen +Knight +Rook +Bishop)
            (link
               (list This
                  (cons This)
                  (cons (piece (list (car (type This)) Cls)) Fld) ) ) ) ) ) )

(de tryPawnCapt (Fld1 Flg Fld2)
   (if (get Fld1 'piece)
      (unless (== (: color) (get @ 'color))
         (if Flg
            (link
               (list This
                  (cons (get Fld1 'piece))
                  (cons This Fld1) ) )
            (for Cls '(+Queen +Knight +Rook +Bishop)
               (link
                  (list This
                     (cons (get Fld1 'piece))
                     (cons This)
                     (cons (piece (list (car (type This)) Cls)) Fld1) ) ) ) ) )
      (let? Pce (get Fld2 'piece)
         (and
            (== Pce (car *Moved))
            (>= 5 (: field y) 4)
            (isaPawn Pce (not (: color)))
            (not (memq Pce (cdr *Moved)))
            (link (list This (cons Pce) (cons This Fld1))) ) ) ) )

(de castle (Dir Long)
   (use (Fld1 Fld2 Fld Pce)
      (or
         (get (setq Fld1 (Dir (: field))) 'piece)
         (attack Fld1 (not (: color)))
         (get (setq Fld2 (Dir Fld1)  Fld Fld2) 'piece)
         (when Long
            (or
               (get (setq Fld (Dir Fld)) 'piece)
               (attack Fld (not (: color))) ) )
         (and
            (== '+Rook
               (cadr (type (setq Pce (get (Dir Fld) 'piece)))) )
            (not (memq Pce *Moved))
            (link (list This (cons This Fld2) (cons Pce Fld1))) ) ) ) ) )

(de moves (Color)
   (filter
      '((Lst)
         (prog2
            (move (car Lst))
            (not (attack (king Color 'field) (not Color)))
            (move (cdr Lst)) ) )
      (mapcan
         '((Pce)
            (mapcar
               '((Lst)
                  (cons Lst
                     (flip
                        (mapcar
                           '((Mov) (cons (car Mov) (get Mov 1 'field)))
                           (cdr Lst) ) ) ) )
               (moves> Pce) ) )
         (if Color *Black *White) ) ) )

(de move (Lst)
   (if (atom (car Lst))
      (push '*Moved (pop 'Lst))
      (pop '*Moved) )
   (for Mov Lst
      (move> (car Mov) (cdr Mov)) ) )


### Evaluation ###
(de attack (Fld Color)
   (or
      (isaPawn (get (east (behind Color Fld)) 'piece) Color)
      (isaPawn (get (west (behind Color Fld)) 'piece) Color)
      (pick
         '((Dir)
            (let? Fld (Dir Fld)
               (let Pce (get Fld 'piece)
                  (or
                     (isaKing Pce Color)
                     (loop
                        (T Pce
                           (and
                              (== Color (get Pce 'color))
                              (memq (cadr (type Pce)) '(+Rook +Queen))
                              Pce ) )
                        (NIL (setq Fld (Dir Fld)))
                        (setq Pce (get Fld 'piece)) ) ) ) ) )
         *Straight )
      (pick
         '((Dir)
            (let? Fld (Dir Fld)
               (let Pce (get Fld 'piece)
                  (or
                     (isaKing Pce Color)
                     (loop
                        (T Pce
                           (and
                              (== Color (get Pce 'color))
                              (memq (cadr (type Pce)) '(+Bishop +Queen))
                              Pce ) )
                        (NIL (setq Fld (Dir Fld)))
                        (setq Pce (get Fld 'piece)) ) ) ) ) )
         *Diagonal )
      (pick
         '((Dir)
            (isaKnight (get (Dir Fld) 'piece) Color) )
         *DiaStraight ) ) )

(de attacks (Fld Color)
   (make
      (and
         (make
            (for Dir *DiaStraight
               (with (isaKnight (get (Dir Fld) 'piece) Color)
                  (link (: val)) ) ) )
         (link @) )
      (let (P1 (east (behind Color Fld))  P2 (west (behind Color Fld)))
         (for Dir *Diagonal
            (let? Fld (Dir Fld)
               (and
                  (make
                     (let Pce (get Fld 'piece)
                        (cond
                           ((isaKing Pce Color) (link (get Pce 'val)))
                           ((and (or (== Fld P1) (== Fld P2)) (isaPawn Pce Color))
                              (link (get Pce 'val))
                              (loop
                                 (NIL (setq Fld (Dir Fld)))
                                 (setq Pce (get Fld 'piece))
                                 (T
                                    (and Pce
                                       (nand
                                          (== Color (get Pce 'color))
                                          (memq (cadr (type Pce)) '(+Bishop +Queen))
                                          (link (get Pce 'val)) ) ) ) ) )
                           (T
                              (loop
                                 (T
                                    (and Pce
                                       (nand
                                          (== Color (get Pce 'color))
                                          (memq (cadr (type Pce)) '(+Bishop +Queen))
                                          (link (get Pce 'val)) ) ) )
                                 (NIL (setq Fld (Dir Fld)))
                                 (setq Pce (get Fld 'piece)) ) ) ) ) )
                  (link @) ) ) ) )
      (for Dir *Straight
         (let? Fld (Dir Fld)
            (and
               (make
                  (let Pce (get Fld 'piece)
                     (if (isaKing Pce Color)
                        (link (get Pce 'val))
                        (loop
                           (T
                              (and Pce
                                 (nand
                                    (== Color (get Pce 'color))
                                    (memq (cadr (type Pce)) '(+Rook +Queen))
                                    (link (get Pce 'val)) ) ) )
                           (NIL (setq Fld (Dir Fld)))
                           (setq Pce (get Fld 'piece)) ) ) ) )
               (link @) ) ) ) ) )

(de fight (Var)
   (when (set Var (sort (val Var)))
      (prog1
         (pop (val Var))
         (unless (car (val Var))
            (pop Var) ) ) ) )

(de battle (Prey Attacker Defender)
   (let Gain 0
      (use (Att Def)
         (loop
            (NIL (setq Att (fight 'Attacker)) Gain)
            (NIL (setq Def (fight 'Defender)) (+ Gain Prey))
            (T (> Att Prey)
               (loop
                  (T (> Att Def) Gain)
                  (NIL (setq Att (fight 'Attacker)) Gain)
                  (NIL (setq Def (fight 'Defender)) (+ Gain Prey)) ) )
            (inc 'Gain Prey)
            (T (> Def Att)
               (setq Prey Att)
               (loop
                  (NIL (setq Att (fight 'Attacker)) (- Gain Prey))
                  (T (> Def Att) Gain)
                  (NIL (setq Def (fight 'Defender)) Gain) ) )
            (dec 'Gain Att)
            (setq Prey Def) ) ) ) )

# Ref. Sargon, Dan and Kate Spracklen, Hayden 1978
(de cost (Color)
   (let (Ctl 0  Mat 0  Lose 0  Win1 NIL  Win2 NIL  Flg NIL)
      (use (White Black Col Same B)
         (for Lst *Board
            (for This Lst
               (setq White (attacks This NIL)  Black (attacks This T))
               ((if Color inc dec)
                  'Ctl
                  (- (sum length White) (sum length Black)) )
               (let? Val (: piece val)
                  (setq Col (: piece color) Same (== Col Color))
                  (unless
                     (=0
                        (setq B
                           (if Col (battle Val White Black) (battle Val White Black)) ) )
                     (dec 'Val 4)
                     (if Same
                        (setq
                           Lose (max Lose B)
                           Flg (or (== (: piece) (car *Moved)) Flg) )
                        (when (> B Win1)
                           (xchg 'B 'Win1)
                           (setq Win2 (max Win2 B)) ) ) )
                  ((if Same dec inc) 'Mat Val) ) ) ) )
      (unless (=0 Lose) (dec 'Lose 4))
      (if Flg
         (* 4 (+ Mat Lose))
         (when (and Win1 Win2)
            (dec 'Lose (>> 1 (- Win2 4))) )
         (+ Ctl (* 4 (+ Mat Lose))) ) ) )


### Game ###
(de display ()
   (for Y (8 7 6 5 4 3 2 1)
      (prinl "   +---+---+---+---+---+---+---+---+")
      (prin " " Y " ")
      (for X (1 2 3 4 5 6 7 8)
         (prin
            '|
            (with (get *Board X Y)
               (cond
                  ((: piece) (name> @))
                  ((: color) " - ")
                  (T "   ") ) ) ) )
      (prinl '|) )
   (prinl "   +---+---+---+---+---+---+---+---+")
   (prinl "     a   b   c   d   e   f   g   h")
   T )

(de myMove ()
   (when (game *Me *Depth moves move cost)
      (move (car (push '*Undo (cadr @))))
      (display)
      (cons (car @) (cdar (cadr @))) ) )

(de yourMove (From To)
   (when
      (find
         '((Lst)
            (and
               (== (caar Lst) (get From 'piece))
               (find
                  '((Mov) (== To (cdr Mov)))
                  (cdar Lst) ) ) )
         (moves *You) )
      (move (car (push '*Undo @))) ) )

(de main (Init)
   (off *White *Black *Moved *Undo *Redo *You)
   (default *Depth 3)
   (on *Me)
   (for Lst *Board (for This Lst (=: piece)))
   (if Init
      (for L Init
         (let Pce (piece (cadr L) (car L))
            (or (caddr L) (push '*Moved Pce)) ) )
      (mapc
         '((Cls Lst)
            (piece (list '+White Cls) (car Lst))
            (piece '(+White +Pawn) (cadr Lst))
            (piece '(+Black +Pawn) (get Lst 7))
            (piece (list '+Black Cls) (get Lst 8)) )
         '(+Rook +Knight +Bishop +Queen +King +Bishop +Knight +Rook)
         *Board ) )
   (setq
      *WKing (find '((Pce) (isa '+King Pce)) *White)
      *BKing (find '((Pce) (isa '+King Pce)) *Black) )
   (display) )

(de go Args
   (cond
      ((not Args)
         (xchg '*Me '*You)
         (myMove) )
      ((== '- (car Args))
         (when *Undo
            (move (cdr (push '*Redo (pop '*Undo))))
            (move (cdr (push '*Redo (pop '*Undo))))
            (display) ) )
      ((== '+ (car Args))
         (when *Redo
            (move (car (push '*Undo (pop '*Redo))))
            (move (car (push '*Undo (pop '*Redo))))
            (display) ) )
      ((yourMove (car Args) (cadr Args))
         (myMove) )
      (T '?) ) )
