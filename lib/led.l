# 25nov16abu
# (c) Software Lab. Alexander Burger

# Line editor
# vi-mode, just a subset:
#  - Only single-key commands
#  - No repeat count

(mapc undef
   '(*Led msg fkey revise) )

(setq
   "Line"      NIL      # Holds current input line
   "LPos"      1        # Position in line (1 .. length)
   "HPos"      1        # Position in history
   "UndoLine"  NIL      # Undo
   "UndoPos"   0
   "Line1"     NIL      # Initial line
   "Insert"    T        # Insert mode flag
   "FKey"      NIL      # Function key bindings
   "Clip"      NIL      # Cut/Copy/Paste buffer
   "Item"      NIL      # Item to find
   "Found"     NIL      # Find stack
   "Complete"  NIL      # Input completion

   "HistMax"   1000     # History limit
   "Revisions" NIL      # 'revise' history

   *History             # History of input lines
   (in (pack "+" (pil "history"))
      (make (until (eof) (link (line T)))) )
   "Hist0"     *History )


# Basic editing routine
(de chgLine (L N)
   (let (D (length "Line")  Tsm)
      (for (P (dec "LPos") (gt0 P) (dec P))  # To start of old line
         (unless
            (and
               *Tsm
               (= "\"" (get "Line" P))
               (skipQ "LPos" P "Line") )
            (prin "^H") ) )
      (for (P . C) (setq "Line" L)  # Output new line
         (cond
            ((> " " C)
               (dec 'D)
               (prin "_") )
            ((or (not *Tsm) (<> "\"" C) (escQ P L))
               (dec 'D)
               (prin C) )
            (T
               (prin
                  (and Tsm (cdr *Tsm))
                  (unless (skipQ N P L)
                     (dec 'D)
                     C )
                  (and (onOff Tsm) (car *Tsm)) ) ) ) )
      (and Tsm (prin (cdr *Tsm)))
      (space D)  # Clear rest of old line
      (do D (prin "^H"))
      (setq "LPos" (inc (length L)))
      (until (= N "LPos")  # To new position
         (unless
            (and
               *Tsm
               (= "\"" (get "Line" "LPos"))
               (skipQ N "LPos" "Line") )
            (prin "^H") )
         (dec '"LPos") ) )
   (flush) )

# Skipped double quote
(de skipQ (N P L)
   (nor
      (>= (inc N) P (dec N))
      (= "\""  (get L (dec P)))
      (= "\"" (get L (inc P)))
      (escQ P L) ) )

# Escaped double quote
(de escQ ()
   (let Esc NIL
      (for I (dec P)
         ((if (= "\\" (get L I)) onOff off) Esc) ) ) )

# Check for delimiter
(de delim? (C)
   (member C '`(chop " ^I^J^M\"'()[]`~")) )

# Move left
(de lMove ()
   (chgLine "Line" (max 1 (dec "LPos"))) )

# Move to beginning
(de bMove ()
   (chgLine "Line" 1) )

# Move right
(de rMove (F)
   (chgLine "Line"
      (min
         (inc "LPos")
         (if F
            (inc (length "Line"))
            (length "Line") ) ) ) )

# Move to end of line
(de eMove ()
   (chgLine "Line" (length "Line")) )

# Move beyond end of line
(de xMove ()
   (chgLine "Line" (inc (length "Line"))) )

# Move up
(de uMove ()
   (when (< "HPos" (length *History))
      (setHist (inc "HPos")) ) )

# Move down
(de dMove ()
   (unless (=0 "HPos")
      (setHist (dec "HPos")) ) )

# Move word left
(de lWord ()
   (use (N L)
      (chgLine "Line"
         (if (>= 1 (setq N "LPos"))
            1
            (loop
               (T (= 1 (dec 'N)) 1)
               (setq L (nth "Line" (dec N)))
               (T (and (delim? (car L)) (not (delim? (cadr L))))
                  N ) ) ) ) ) )

# Move word right
(de _right Prg
   (use (M N L)
      (setq M (length "Line"))
      (chgLine "Line"
         (if (>= (setq N "LPos") M)
            M
            (run Prg) ) ) ) )

(de rWord ()
   (_right
      (loop
         (T (= M (inc 'N)) M)
         (setq L (nth "Line" (dec N)))
         (T (and (delim? (car L)) (not (delim? (cadr L))))
            N ) ) ) )

(de rEnd ()
   (_right
      (loop
         (T (= M (inc 'N)) M)
         (setq L (nth "Line" N))
         (T (and (not (delim? (car L))) (delim? (cadr L)))
            N ) ) ) )

# Match left parenthesis
(de lPar ()
   (let (N 1  I (dec "LPos"))
      (loop
         (T (=0 I))
         (case (get "Line" I)
            (")" (inc 'N))
            ("(" (dec 'N)) )
         (T (=0 N) (chgLine "Line" I))
         (dec 'I) ) ) )

# Match right parenthesis
(de rPar ()
   (let (N 1  I (inc "LPos"))
      (loop
         (T (> I (length "Line")))
         (case (get "Line" I)
            ("(" (inc 'N))
            (")" (dec 'N)) )
         (T (=0 N) (chgLine "Line" I))
         (inc 'I) ) ) )

# Clear to end of line
(de clrEol ()
   (let N (dec "LPos")
      (if (=0 N)
         (chgLine NIL 1)
         (chgLine (head N "Line") N) ) ) )

# Insert a char
(de insChar (C)
   (chgLine (insert "LPos" "Line" C) (inc "LPos")) )

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
         (sp? (get L "LPos"))
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
            (head (dec "LPos") "Line")
            "Clip"
            (nth "Line" "LPos") )
         (+ "LPos" (length "Clip") -1) ) ) )

# Set history line
(de setHist (N)
   (chgLine
      (if (=0 (setq "HPos" N))
         "Line1"
         (chop (get *History "HPos")) )
      1 ) )

# Searching
(de ledSearch (L)
   (let (H (nth *History (inc "HPos"))  S (find '((X) (match "Item" (chop X))) H))
      (chgLine
         (ifn S
            (prog (beep) L)
            (push '"Found" "HPos")
            (inc '"HPos" (index S H))
            (chop S) )
         1 ) ) )

# TAB expansion
(de expandTab ()
   (let ("L" (head (dec "LPos") "Line")  "S" "L")
      (while (find "skipFun" "S")
         (++ "S") )
      (ifn "S"
         (prog
            (off "Complete")
            (do 3 (insChar " ")) )
         (ifn
            (default "Complete"
               (let "N" (inc (length "S"))
                  (mapcar
                     '((X)
                        (setq X (nth (chop X) "N"))
                        (cons
                           (+ "LPos" (length X))
                           (append "L" X (nth "Line" "LPos")) ) )
                     ("tabFun" (pack "S")) ) ) )
            (beep)
            (chgLine (cdar "Complete") (caar "Complete"))
            (rot "Complete") ) ) ) )

# Insert mode
(de insMode ("C")
   (if (= "C" "^I")
      (expandTab)
      (off "Complete")
      (case "C"
         (("^H" "^?")
            (if (> "LPos" 1)
               (chgLine (remove (dec "LPos") "Line") (dec "LPos"))
               (beep) ) )
         ("^V" (insChar (key)))
         ("^E" (and edit (edit '*History)))
         ("^F" (saveHistory))
         ("^["
            (loop
               (NIL
                  (make
                     (while (and (setq "C" (key 40)) (<> "C" "^["))
                        (link "C") ) )
                  (off "Insert")
                  (lMove) )
               (when (assoc (pack "^[" @) "FKey")
                  (let *Dbg "*Dbg" (run (cdr @))) )
               (NIL "C") ) )
         (T
            (if (assoc "C" "FKey")
               (let *Dbg "*Dbg" (run (cdr @)))
               (when (= "C" ")")
                  (chgLine "Line" (prog1 "LPos" (lPar) (wait 200))) )
               (insChar "C") ) ) ) ) )

# Command mode
(de cmdMode ("C")
   (case "C"
      ("g" (prinl) (println "Clip"))
      ("$" (eMove))
      ("%"
         (case (get "Line" "LPos")
            (")" (lPar))
            ("(" (rPar))
            (T (beep)) ) )
      ("/"
         (let "L" "Line"
            (_getLine '("/") '((C) (= C "/")))
            (unless (=T "Line")
               (setq "Item" (append '(@) (cdr "Line") '(@)))
               (ledSearch "L")
               (off "Insert") ) ) )
      ("0" (bMove))
      ("A" (doUndo) (xMove) (on "Insert"))
      ("a" (doUndo) ((if (= "LPos" (length "Line")) xMove rMove)) (on "Insert"))
      ("b" (lWord))
      ("c" (doUndo) (delWord NIL) (on "Insert"))
      ("C" (doUndo) (clrEol) (xMove) (on "Insert"))
      ("d" (doUndo) (delWord T))
      ("D" (doUndo) (clrEol))
      ("e" (rEnd))
      ("f"
         (ifn (setq "C" (index (key) (nth "Line" (inc "LPos"))))
            (beep)
            (chgLine "Line" (+ "C" "LPos")) ) )
      ("h" (lMove))
      ("i" (doUndo) (on "Insert"))
      ("I" (doUndo) (bMove) (on "Insert"))
      ("j" (dMove))
      ("k" (uMove))
      ("l" (rMove))
      ("n" (ledSearch "Line"))
      ("N" (if "Found" (setHist (++ "Found")) (beep)))
      ("p" (doUndo) ((if (= "LPos" (length "Line")) xMove rMove)) (doPaste))
      ("P" (doUndo) (doPaste))
      ("r" (ifn "Line" (beep) (doUndo) (rplChar (key))))
      ("s" (doUndo) (delChar) (on "Insert"))
      ("S" (doUndo) (chgLine NIL 1) (on "Insert"))
      ("U" (setHist "HPos"))
      ("u"
         (let ("L" "Line"  "P" "LPos")
            (chgLine "UndoLine" "UndoPos")
            (setq  "UndoLine" "L"  "UndoPos" "P") ) )
      ("w" (rWord))
      ("x" (doUndo) (delChar))
      ("X" (lMove) (doUndo) (delChar))
      ("~"
         (doUndo)
         (rplChar
            ((if (low? (setq "C" (get "Line" "LPos"))) uppc lowc) "C") )
         (rMove) )
      (T (beep)) ) )

# Get a line from console
(de _getLine ("L" "skipFun")
   (use "C"
      (chgLine "L" (inc (length "L")))
      (on "Insert")
      (until (member (setq "C" (let *Dbg "*Dbg" (key))) '("^J" "^M"))
         (or "C" (bye))
         ((if "Insert" insMode cmdMode) "C") )
      (eMove) ) )

# Polite messages
(de msg (X . @)
   (let (L "Line"  P "LPos")
      (chgLine NIL 1)
      (out 2
         (print X)
         (pass prinl) )
      (chgLine L P) )
   X )

# Function keys
(de fkey (Key . Prg)
   (setq "FKey"
      (cond
         ((not Key) "FKey")
         ((not Prg) (delete (assoc Key "FKey") "FKey"))
         ((assoc Key "FKey")
            (cons (cons Key Prg) (delete @ "FKey")) )
         (T (cons (cons Key Prg) "FKey")) ) ) )

(fkey "^D" (prinl) (bye))
(fkey "^X" (prin (cdr *Tsm)) (prinl) (quit))
(when (sys "TERM")
   (fkey "^[[A" (uMove) (xMove))
   (fkey "^[[B" (dMove) (xMove))
   (fkey "^[[C" (rMove T))
   (fkey "^[[D" (lMove)) )

# Main editing functions
(de _led ("Line1" "tabFun" "skipFun")
   (default "tabFun"
      '((S)
         (conc
            (filter '((X) (pre? S X)) (all))
            (let P (rot (split (chop S) "/"))
               (setq
                  S (pack (car P))
                  P (and (cdr P) (pack (glue "/" @) "/")) )
               (extract '((X) (and (pre? S X) (pack P X)))
                  (dir P T) ) ) ) ) )
   (zero "HPos")
   (_getLine "Line1" (or "skipFun" delim?))
   (prinl (cdr *Tsm)) )

(de revise ("X" "tabFun" "skipFun")
   (let (*History "Revisions"  "*Dbg" *Dbg  *Dbg)
      (_led (chop "X") "tabFun" "skipFun")
      (let? L (pack "Line")
         (unless (= L (car "Revisions"))
            (push '"Revisions" L) )
         (off "Line")
         (one "LPos")
         L ) ) )

(de saveHistory ()
   (unless (= *History "Hist0")
      (out (pil "history")
         (mapc prinl *History) ) ) )

# Enable line editing
(de *Led
   (let ("*Dbg" *Dbg  *Dbg)
      (push1 '*Bye '(saveHistory))
      (push1 '*Fork '(del '(saveHistory) '*Bye))
      (_led)
      (let L (pack "Line")
         (or
            (>= 3 (length "Line"))
            (sp? (car "Line"))
            (= L (car *History))
            (push '*History L) )
         (and (nth *History "HistMax") (con @))
         (off "Line")
         (one "LPos")
         L ) ) )

(mapc zap
   (quote
      chgLine skipQ escQ delim? lMove bMove rMove eMove xMove uMove dMove lWord
      _right rWord rEnd lPar rPar clrEol insChar del1 delChar delWord rplChar
      doUndo doPaste setHist ledSearch expandTab insMode cmdMode _getLine _led
      saveHistory ) )

# vi:et:ts=3:sw=3
