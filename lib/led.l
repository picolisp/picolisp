# 27jan03abu
# (c) Software Lab. Alexander Burger

# Line editor (vi-mode)
# Just a subset:
#  - Only single-key commands
#  - No repeat count

(setq
   "Line"      NIL      # Holds current input line
   "LPos"      1        # Position in line (1 .. length)
   "HPos"      1        # Position in history
   "UndoLine"  NIL      # Undo
   "UndoPos"   0
   "Insert"    T        # Insert mode flag
   "FKey"      NIL      # Function key bindings
   "Clip"      NIL      # Cut/Copy/Paste buffer
   "Item"      NIL      # Item to find
   "Found"     NIL      # Find stack
   "Complete"  NIL      # Input completion

   "HistMax"   4000     # History limit

   "History"            # History of input lines
   (and
      (open "@.picoHistory")
      (close @)
      (in "@.picoHistory"
         (make
            (whilst (line)
               (link @) ) ) ) ) )

# Output character
(de ledChr (C)
   (prin (if (< C " ") "_" C))
   (flush) )

# Output backspaces
(de backsp (N)
   (do N (prin "^H"))
   (flush) )

# Check for delimiter
(de delim? (C)
   (member C '`(chop '" ^I^J^M\"#'()[]`~")) )

# Line positioning
(de posLine (N)
   (if (< N "LPos")
      (backsp (- "LPos" (setq "LPos" N)))
      (while (< "LPos" N)
         (ledChr (get "Line" "LPos"))
         (inc '"LPos") ) ) )

# Basic editing routine
(de chgLine (L N)
   (backsp (- "LPos" 1))  # To start of old line
   (setq "LPos" N)
   (mapc ledChr L)  # Draw new line
   (setq N (- (length "Line") (length L)))  # Clear rest of old line
   (space N)
   (backsp N)
   (backsp (- (length (setq "Line" L)) "LPos" -1)) )  # To new position

# Move left
(de lMove ()
   (posLine (max 1 (- "LPos" 1))) )

# Move to beginning
(de bMove ()
   (posLine 1) )

# Move right
(de rMove ()
   (posLine
      (if (>= "LPos" (length "Line"))
         "LPos"
         (+ 1 "LPos") ) ) )

# Move to end of line
(de eMove ()
   (posLine (length "Line")) )

# Move beyond end of line
(de xMove ()
   (posLine (+ 1 (length "Line"))) )

# Move word left
(de lWord ()
   (use (N L)
      (posLine
         (if (>= 1 (setq N "LPos"))
            1
            (loop
               (T (= 1 (dec 'N)) 1)
               (setq L (nth "Line" (- N 1)))
               (T (and (delim? (car L)) (not (delim? (cadr L))))
                  N ) ) ) ) ) )

# Move word right
(de rWord ()
   (use (M N L)
      (setq M (length "Line"))
      (posLine
         (if (<= M (setq N "LPos"))
            M
            (loop
               (T (= M (inc 'N)) M)
               (setq L (nth "Line" (- N 1)))
               (T (and (delim? (car L)) (not (delim? (cadr L))))
                  N ) ) ) ) ) )

# Match left parenthesis
(de lPar ()
   (let (N 1  I (- "LPos" 1))
      (loop
         (T (=0 I))
         (case (get "Line" I)
            (")" (inc 'N))
            ("(" (dec 'N)) )
         (T (=0 N) (posLine I))
         (dec 'I) ) ) )

# Match right parenthesis
(de rPar ()
   (let (N 1  I (+ "LPos" 1))
      (loop
         (T (> I (length "Line")))
         (case (get "Line" I)
            ("(" (inc 'N))
            (")" (dec 'N)) )
         (T (=0 N) (posLine I))
         (inc 'I) ) ) )

# Clear to end of line
(de clrEol ()
   (let N (- "LPos" 1)
      (if (=0 N)
         (chgLine NIL 1)
         (chgLine (head N "Line") N) ) ) )

# Insert a char
(de insChar (C)
   (chgLine (insert "LPos" "Line" C) (+ "LPos" 1)) )

(de del1 (L)
   (ifn (nth L "LPos")
      L
      (setq "Clip" (append "Clip" (list (get L "LPos"))))
      (remove "LPos" L) ) )

# Delete a char
(de delChar ()
   (use L
      (off "Clip")
      (chgLine
         (setq L (del1 "Line"))
         (max 1 (min "LPos" (length L))) ) ) )

# Delete a word (F: with trailing blank)
(de delWord (F)
   (let L "Line"
      (off "Clip")
      (ifn (= "(" (get L "LPos"))
         (while (and (nth L "LPos") (not (delim? (get L "LPos"))))
            (setq L (del1 L)) )
         (for (N 1 (and (setq L (del1 L)) (< 0 N)))
            (case (get L "LPos")
               ("(" (inc 'N))
               (")" (dec 'N)) ) ) )
      (and
         F
         (= " " (get L "LPos"))
         (setq L (del1 L)) )
      (chgLine L (max 1 (min "LPos" (length L)))) ) )

# Replace char
(de rplChar (C)
   (chgLine
      (insert "LPos" (remove "LPos" "Line") C)
      "LPos" ) )

# Undo mechanism
(de doUndo ()
   (setq  "UndoLine" "Line"  "UndoPos"  "LPos") )

# Paste clip
(de doPaste ()
   (if (= 1 "LPos")
      (chgLine (append "Clip" "Line") 1)
      (chgLine
         (append
            (head (- "LPos" 1) "Line")
            "Clip"
            (nth "Line" "LPos") )
         (+ "LPos" (length "Clip") -1) ) ) )

# Set history line
(de setHist (N)
   (chgLine
      (unless (=0 (setq "HPos" N))
         (get "History" "HPos") )
      1 ) )

# Searching
(de ledSearch (L)
   (use (H S)
      (setq H (nth "History" (+ 1 "HPos")))
      (chgLine
         (ifn (setq S (find '((X) (match "Item" X)) H))
            (prog (beep) L)
            (push '"Found" "HPos")
            (inc '"HPos" (index S H))
            S )
         1 ) ) )

# TAB expansion
(de expandTab ()
   (use (L S N)
      (setq
         L (head (- "LPos" 1) "Line")
         S L )
      (while (find delim? S)
         (pop 'S) )
      (ifn S
         (prog
            (off "Complete")
            (do 3 (insChar " ")) )
         (setq N (length S))
         (ifn
            (or
               "Complete"
               (setq "Complete"
                  (make
                     (all
                        '(("X")
                           (when (= S (head N (setq "X" (chop "X"))))
                              (setq "X" (nth "X" (+ N 1)))
                              (link
                                 (cons
                                    (+ "LPos" (length "X"))
                                    (append
                                       L
                                       "X"
                                       (nth "Line" "LPos") ) ) ) ) ) ) ) ) )
            (beep)
            (setq S (car "Complete"))
            (chgLine (cdr S) (car S))
            (rot "Complete") ) ) ) )

# Insert mode
(de insMode (C)
   (if (= C "^I")
      (expandTab)
      (off "Complete")
      (case C
         (("^H" "^?")
            (when (> "LPos" 1)
               (chgLine (remove (- "LPos" 1) "Line") (- "LPos" 1)) ) )
         ("^V" (insChar (key)))
         ("^["
            (loop
               (NIL
                  (make
                     (while (and (setq C (key 50)) (<> C "^["))
                        (link C) ) )
                  (off "Insert")
                  (lMove) )
               (and
                  (assoc (pack "^[" @) "FKey")
                  (run (cdr @)) )
               (NIL C) ) )
         (T
            (when (= C ")")
               (posLine (prog1 "LPos" (lPar) (wait 200))) )
            (insChar C) ) ) ) )

# Command mode
(de cmdMode (C)
   (case C
      ("g" (prinl) (println "Clip"))
      ("$" (eMove))
      ("%"
         (case (get "Line" "LPos")
            (")" (lPar))
            ("(" (rPar))
            (T (beep)) ) )
      ("/"
         (let L "Line"
            (chgLine '("/") 2)
            (_getLine)
            (unless (=T "Line")
               (setq "Item" (append '(@) (cdr "Line") '(@)))
               (ledSearch L)
               (off "Insert") ) ) )
      ("0" (bMove))
      ("A" (doUndo) (xMove) (on "Insert"))
      ("a" (doUndo) ((if (= "LPos" (length "Line")) xMove rMove)) (on "Insert"))
      ("b" (lWord))
      ("c" (doUndo) (delWord NIL) (on "Insert"))
      ("C" (doUndo) (clrEol) (xMove) (on "Insert"))
      ("d" (doUndo) (delWord T))
      ("D" (doUndo) (clrEol))
      ("f"
         (ifn (setq C (index (key) (nth "Line" (+ 1 "LPos"))))
            (beep)
            (posLine (+ C "LPos")) ) )
      ("h" (lMove))
      ("i" (doUndo) (on "Insert"))
      ("I" (doUndo) (bMove) (on "Insert"))
      ("j" (unless (=0 "HPos") (setHist (- "HPos" 1))))
      ("k" (when (< "HPos" (length "History")) (setHist (+ 1 "HPos"))))
      ("l" (rMove))
      ("n" (ledSearch "Line"))
      ("N" (if "Found" (setHist (pop '"Found")) (beep)))
      ("p" (doUndo) ((if (= "LPos" (length "Line")) xMove rMove)) (doPaste))
      ("P" (doUndo) (doPaste))
      ("r" (ifn "Line" (beep) (doUndo) (rplChar (key))))
      ("s" (doUndo) (delChar) (on "Insert"))
      ("S" (doUndo) (chgLine NIL 1) (on "Insert"))
      ("U" (setHist "HPos"))
      ("u"
         (let (L "Line"  P "LPos")
            (chgLine "UndoLine" "UndoPos")
            (setq  "UndoLine" L  "UndoPos" P) ) )
      ("w" (rWord))
      ("x" (doUndo) (delChar))
      ("X" (lMove) (doUndo) (delChar))
      ("~"
         (doUndo)
         (rplChar
            ((if (<= "A" (setq C (get "Line" "LPos")) "Z") lowc uppc) C) )
         (rMove) )
      (T (beep)) ) )

# Get a line from console
(de _getLine ()
   (use C
      (on "Insert")
      (until
         (member
            (setq C (let *Dbg "Dbg" (key)))
            '("^J" "^M") )
         (or C (bye))
         ((if "Insert" insMode cmdMode) C) ) ) )

# Function keys
(de fkey (Key . Prg)
   (setq "FKey"
      (cond
         ((not Key) "FKey")
         ((not Prg) (delete (assoc Key "FKey") "FKey"))
         ((assoc Key "FKey")
            (cons (cons Key Prg) (delete @ "FKey")) )
         (T (cons (cons Key Prg) "FKey")) ) ) )

# Enable line editing
(de *Led
   (let ("Dbg" *Dbg  *Dbg NIL)
      (?push '*Bye
         '(out "@.picoHistory"
            (mapc prinl "History") ) )
      (setq "LPos" 1  "HPos" 0)
      (_getLine)
      (prinl)
      (and
         (< 3 (length "Line"))
         (<> " " (car "Line"))
         (<> "Line" (car "History"))
         (push '"History" "Line") )
      (and (nth "History" "HistMax") (con @))
      (prog1 (pack "Line") (off "Line")) ) )
