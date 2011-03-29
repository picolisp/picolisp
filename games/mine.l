# 08feb11abu
# (c) Software Lab. Alexander Burger

(load "@lib/term.l")

# Spielfeldbelegung:
# NIL    Verdeckt: Leeres Feld
# T      Verdeckt: Mine
# 0-8    Aufgedeckt, Nachbarminen

(seed (in "/dev/urandom" (rd 8)))

# Globale Konstanten
(de *Minen . 24)  # Anzahl der Minen
(de *FeldX . 12)  # Feldgroesse X
(de *FeldY . 12)  # Feldgroesse Y

(de *NachbarX -1  0 +1 -1  +1 -1  0 +1)
(de *NachbarY -1 -1 -1  0   0 +1 +1 +1)

# Globale Variablen
(de *Feld)        # Datenbereich des Minenfeldes


# Eine Mine legen
(de legeMine ()
   (use (X Y)
      (while
         (get *Feld
            (setq Y (rand 1 *FeldY))
            (setq X (rand 1 *FeldX)) ) )
      (set (nth *Feld Y X) T) ) )

# *Feld anzeigen
(de anzeigen (Flg)
   (let (N 0 Y 0)
      (for L *Feld
         (prin (align 2 (inc 'Y)) " ")
         (for C L
            (prin
               " "
               (cond
                  ((not C) (inc 'N) "-")
                  (Flg C)
                  ((=T C) "-")
                  (T C) ) ) )
         (prinl) )
      (prin "   ")
      (for C *FeldX
         (prin " " (char (+ 64 C))) )
      (prinl)
      (prinl "<" N ">  ") ) )

# Ein Feld ausrechnen
(de wertFeld (X Y)
   (when
      (=0
         (set (nth *Feld Y X)
            (cnt
               '((DX DY)
                  (=T (get *Feld (+ Y DY) (+ X DX))) )
               *NachbarX
               *NachbarY ) ) )
      (mapc
         '((DX DY)
            (and
               (>= *FeldX (inc 'DX X) 1)
               (>= *FeldY (inc 'DY Y) 1)
               (not (member (cons DX DY) *Visit))
               (push '*Visit (cons DX DY))
               (wertFeld DX DY) ) )
         *NachbarX
         *NachbarY ) ) )

# Hauptfunktion
(de main (N)
   (when N
      (setq *Minen N) )
   (setq *Feld
      (make (do *FeldY (link (need *FeldX)))) )
   (do *Minen (legeMine)) )

(de go ()
   (use (K X Y)
      (anzeigen)
      (xtUp (+ 2 *FeldY))
      (xtRight 4)
      (one X Y)
      (catch NIL
         (until (= "^[" (setq K (key)))
            (case K
               ("j"
                  (unless (= Y *FeldY)
                     (xtDown 1)
                     (inc 'Y) ) )
               ("k"
                  (unless (= Y 1)
                     (xtUp 1)
                     (dec 'Y) ) )
               ("l"
                  (unless (= X *FeldX)
                     (xtRight 2)
                     (inc 'X) ) )
               ("h"
                  (unless (= X 1)
                     (xtLeft 2)
                     (dec 'X) ) )
               ((" " "^J" "^M")
                  (xtLeft (+ 2 (* 2 X)))
                  (xtUp (dec Y))
                  (when (=T (get *Feld Y X))
                     (anzeigen T)
                     (prinl "*** BUMM ***")
                     (throw) )
                  (let *Visit NIL
                     (wertFeld X Y) )
                  (anzeigen)
                  (unless (find '((L) (memq NIL L)) *Feld)
                     (prinl ">>> Gewonnen! <<<")
                     (throw) )
                  (xtUp (- *FeldY Y -3))
                  (xtRight (+ 2 (* 2 X))) ) ) )
         (xtLeft (+ 2 (* 2 X)))
         (xtDown (+ 3 (- *FeldY Y))) ) ) )

# vi:et:ts=3:sw=3
