# 13sep04abu
# (c) Software Lab. Alexander Burger

# *Board

(load "lib/simul.l")

# Tic-Tac-Toe
(de ttt Args
   (cond
      ((not Args)
         (setq *Board (make (do 3 (link (need 3))))) )
      ((not (yourMove (car Args) (cadr Args)))
         (prinl "Illegal move!") )
      ((find3 T *Board) (prinl "Congratulation, you won!"))
      ((not (myMove)) (prinl "No moves"))
      ((find3 0 *Board) (prinl "Sorry, you lost!")) )
   (for Y (3 2 1)
      (prinl "   +---+---+---+")
      (prin " " Y)
      (for X (1 2 3)
         (prin " | " (or (get *Board X Y) " ")) )
      (prinl " |") )
   (prinl "   +---+---+---+")
   (prinl "     a   b   c")
   Args )

(de yourMove (X Y)
   (and
      (sym? X)
      (>= 3 (setq X (- (char X) 96)) 1)
      (num? Y)
      (>= 3 Y 1)
      (not (get *Board X Y))
      (set (nth *Board X Y) T) ) )

(de myMove ()
   (when
      (game NIL 8
         *Board
         '((Flg Pos)       # Moves
            (unless (find3 (or (not Flg) 0) Pos)
               (make
                  (for (X . L) Pos
                     (for (Y . P) L
                        (or P (link (cons X Y))) ) ) ) ) )
         '((Flg Pos Mov)   # Move
            (place (car Mov) Pos
               (place (cdr Mov) (get Pos (car Mov))
                  (or Flg 0) ) ) )
         '((Flg Pos)       # Cost
            (if (find3 (or Flg 0) Pos) -100 0) ) )
      (set
         (nth *Board (caar (cadr @)) (cdar (cadr @)))
         0 ) ) )

(de find3 (P Pos)
   (find
      '((X Y DX DY)
         (do 3
            (NIL (= P (get Pos X Y)))
            (inc 'X DX)
            (inc 'Y DY)
            T ) )
      (1 1 1 1 2 3 1 1)
      (1 2 3 1 1 1 1 3)
      (1 1 1 0 0 0 1 1)
      (0 0 0 1 1 1 1 -1) ) )
