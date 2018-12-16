# 16dec18abu
# (c) Software Lab. Alexander Burger

(symbols 'vip 'pico)
(local) [
   *CmdWin *Flat *Chr *Complete *Repeat *Change *Count *Cnt *Search *Clip *Lines
   *Columns *TagStack *Spell *F10 *F11 *F12 ]

### Curses library interface ###
(local) curses
(de curses @
   (pass native
      `(or
         (find
            '((S) (n0 (native "@" "dlopen" 'N S 257)))
            '("libncursesw.so" "libncursesw.so.6" "libncursesw.so.5") )
         (quit "No CURSES found") ) ) )

### VIP Editor ###
(local) [
   *Buffers +Buffer fName rplFile fileBuffer rdLines delim? markup load> save>
   status ]
(class +Buffer)
# text file key undo redo dirt pos lastX lastY <c>

(dm T (File Y)
   (and (=: file File) (queue '*Buffers This))
   (=: pos (or Y 1))
   (=: lastX (=: lastY 1)) )

(de fName (File)
   (if (pre? "~/" File)
      (pack (sys "HOME") "/" (cddr (chop File)))
      File ) )

(de rplFile (File)
   (pack (replace (chop File) "%" (: buffer file))) )

(de fileBuffer (File Y)
   (when File
      (use (R @P)
         (unless (=0 (native "@" "realpath" 'N (fName File) '(R (4096 C . 4096))))
            (setq File
               (pack
                  (cond
                     ((match (conc (chop (pwd)) '(@P)) R)
                        (cdr @P) )
                     ((match (conc (chop (sys "HOME")) '(@P)) R)
                        (cons "~/" (cdr @P)) )
                     (T R) ) ) ) ) ) )
   (or
      (find '((This) (= File (: file))) *Buffers)
      (new '(+Buffer) File Y) ) )

(de rdLines ()
   (make (until (eof) (link (line)))) )

(de delim? (C Str)
   (or
      (member C '`(cons NIL (chop " \t\n\r\"'(),[]`{}")))
      (sub? C Str) ) )

(de markup (Lst)
   (let (S 'text  N 1)
      (for L Lst
         (let P NIL
            (while L
               (let C (++ L)
                  (state 'S
                     (text (and (= "\"" C) 'string)
                        (set C 0) )
                     (text
                        (and
                           (= "#" C)
                           (delim? P)
                           (if L 'comment 'text) )
                        (set C N)
                        (when (= "{" (car L))
                           (set (++ L) (inc 'N)) ) )
                     (text 'text
                        (set (setq P C))
                        (and (= "\\" C) L (set (++ L))) )
                     (string (and (= "\"" C) 'text)
                        (set (setq P C) 0) )
                     (string (and (= "\\" C) (not L) 'skip)
                        (set C T) )
                     (string 'string
                        (set C T)
                        (and (= "\\" C) L (set (++ L) T)) )
                     (skip (and (sp? C) 'skip)
                        (set C) )
                     (skip (and (= "\"" C) 'text)
                        (set (setq P C) 0) )
                     (skip 'string
                        (set C T) )
                     (comment
                        (cond
                           ((=1 (set (setq P C) N))
                              (if L 'comment 'text) )
                           ((and
                                 (= "}" C)
                                 (= "#" (car L))
                                 (=1 (set (++ L) (dec 'N))) )
                              'text )
                           (T
                              (and
                                 (= "#" C)
                                 (= "{" (car L))
                                 (set (++ L) (inc 'N)) )
                              'comment ) ) ) ) ) ) ) ) ) )

(dm load> ()
   (markup
      (=: text
         (let? File (fName (: file))
            (let? I (info File)
               (if (=T (car I))
                  (let D (chop File)
                     (unless (= "/" (last D))
                        (conc D (list (char `(char "/")))) )
                     (mapcar
                        '((F)
                           (conc
                              (chop (setq F (pack D F)))
                              (when (=T (car (info F)))
                                 (list (char `(char "/"))) ) ) )
                        (sort (dir File)) ) )
                  (gc (+ 4 (*/ (car I) 65536)))  # 2 cells / char
                  (if (sys "CCRYPT" (: key))
                     (pipe
                        (in File (out '("ccrypt" "-d" "-ECCRYPT") (echo)))
                        (rdLines) )
                     (in File (rdLines)) ) ) ) ) ) )
   (=: undo (=: redo (=: dirt)))
   (=: pos (min1 (: pos) (length (: text)))) )

(dm save> ()
   (when (fName (: file))
      (unless (=T (car (info @)))
         (if (sys "CCRYPT" (: key))
            (pipe
               (out '("ccrypt" "-e" "-ECCRYPT")
                  (mapc prinl (: text)) )
               (out (fName (: file)) (echo)) )
            (out (fName (: file)) (mapc prinl (: text))) ) )
      (=: dirt (: undo))
      (for (This *CmdWin (setq This (: next)))
         (status) ) ) )


(local) [*Window +Window]
(class +Window)
# buffer top lines status ptr winX winY posX posY prev next last mark

(dm T (Buffer Top Height WinX WinY PosX PosY Prev Mark)
   (=: buffer Buffer)
   (=: top Top)
   (when (=: prev Prev)
      (when (=: next (: prev next))
         (=: next prev This) )
      (=: prev next This)
      (curses "wattr_on" NIL
         (=: status (curses "newwin" 'N 1 *Columns (+ Top (dec 'Height)) 0))
         262144 ) )  # A_REVERSE
   (=: ptr (curses "newwin" 'N (=: lines Height) *Columns Top 0))
   (curses "keypad" NIL (: ptr) 1)
   (=: winX WinX)
   (=: winY WinY)
   (=: posX PosX)
   (=: posY PosY)
   (=: mark Mark) )


(local) [
   min1 beep delwin cursor addLine chgLine unmark redraw repaint scroll goto
   chgwin eqwin getch getch2 reload done change undo redo jmp@@ cnt@@ goCol
   goLeft goRight goUp goDown goAbs goFind word lword end lend getWord _forward
   goForward _backward goBackward goPFore goPBack shift shiftY indent cutX cutN
   paste join tglCase insChar incNum overwrite _bs insMode cmdMode cmdPipe evRpt
   move chgRight jmpMark wordFun moveSearch patMatch parMatch pipeN nextBuf
   shell shFile prCmd reset command vi ]

(de min1 (A B)
   (max 1 (min A B)) )

(de beep ()
   (curses "beep") )

(de delwin ()
   (when (=: prev next (: next))
      (=: next prev (: prev)) )
   (curses "delwin" NIL (: ptr))
   (curses "delwin" NIL (: status)) )

(de cursor ()
   (curses "wmove" NIL (: ptr)
      (- (: posY) (: winY))
      (- (: posX) (: winX)) ) )

(de addLine (Y L N)
   (curses "wmove" NIL (: ptr) Y 0)
   (for C (nth L (: winX))
      (T (lt0 (dec 'N)))
      (curses "wattrset" NIL (: ptr)
         (cond
            (*Flat 0)
            ((=T (val C))
               (ifn (>= "^_" C "^A")
                  131072  # A_UNDERLINE
                  (setq C (char (+ 64 (char C))))
                  `(+ 131072 512) ) )  # A_UNDERLINE + COLOR_PAIR(2)
            ((>= "^_" C "^A")
               (setq C (char (+ 64 (char C))))
               512 )  # COLOR_PAIR(2)
            ((gt0 (val C)) 256)  # COLOR_PAIR(1)
            (T 0) ) )
      (curses "waddnstr" NIL (: ptr) C  -1) ) )

(de chgLine (L)
   (cursor)
   (curses "wclrtoeol" NIL (: ptr))
   (addLine (- (: posY) (: winY)) L *Columns)
   (cursor) )

(de unmark ()
   (when (: mark)
      (out @ (println (: posX) (: posY)))
      (=: mark) ) )

(de status ()
   (when (: status)
      (curses "mvwaddstr" NIL @ 0 0
         (let
            (N (length (: buffer text))
               A (pack
                  (index (: buffer) *Buffers)
                  "/"
                  (length *Buffers)
                  " "
                  (: buffer file)
                  (unless (= (: buffer undo) (: buffer dirt)) " [+]") )
               Z (pack
                  (: mark)
                  " "
                  (: posX) "," (: posY) "/" N " "
                  (if (gt0 (dec N))
                     (*/ 100 (dec (: posY)) @)
                     0 )
                  "%" ) )
            (pack A (need (- *Columns (length A) (length Z)) " ") Z) ) )
      (curses "wrefresh" NIL (: status)) ) )

(de redraw (Flg)
   (curses "werase" NIL (: ptr))
   (for (Y . L) (nth (: buffer text) (: winY))
      (addLine (dec Y) L *Columns)
      (T (= Y (: lines))) )
   (or Flg (status)) )

(de repaint ()
   (for (This *CmdWin This (: next))
      (redraw)
      (curses "wrefresh" NIL (: ptr)) ) )

(de scroll (N)
   (curses "scrollok" NIL (: ptr) 1)
   (curses "wscrl" NIL (: ptr) N)
   (curses "scrollok" NIL (: ptr) 0) )

(de goto (X Y Flg)
   (if
      (and
         (not Flg)
         (>= (inc (: posY)) Y (dec (: posY)))
         (>= (+ (: winX) *Columns -1) X (: winX)) )
      (cond
         ((= Y (inc (: posY)))
            (when
               (and
                  (>= (- (: posY) (: winY)) (/ (: lines) 2))
                  (nth (: buffer text) (+ (: lines) (: winY))) )
               (scroll 1)
               (addLine (dec (: lines)) (car @) *Columns)
               (inc (:: winY)) ) )
         ((= Y (dec (: posY)))
            (when
               (and
                  (> (: winY) 1)
                  (>= (/ (: lines) 2) (- (: posY) (: winY))) )
               (scroll -1)
               (addLine 0 (get (: buffer text) (dec (:: winY))) *Columns) ) ) )
      (=: winX
         (if (>= *Columns X)
            1
            (- X (/ *Columns 4)) ) )
      (=: winY
         (min1
            (- Y (/ (: lines) 2))
            (- (length (: buffer text)) (: lines) -1) ) )
      (unless Flg (redraw T)) )
   (when Flg (redraw T))
   (unless (== This *Window)
      (curses "wrefresh" NIL (: ptr)) )
   (=: posX X)
   (=: buffer pos (=: posY Y))
   (status) )

(de chgwin (Lines Top)
   (curses "wresize" NIL (: ptr) (=: lines Lines) *Columns)
   (when Top
      (curses "mvwin" NIL (: ptr) (=: top @) 0) )
   (when (: status)
      (curses "mvwin" NIL @ (+ (: top) Lines) 0) )
   (goto (: posX) (: posY) T) )

(de eqwin ()
   (let
      (H (dec *Lines)
         D (*/ H
            (let N 0
               (for (This *CmdWin (: next) @)
                  (inc 'N) ) ) ) )
      (with *CmdWin (chgwin 1 H))
      (when (>= D 3)
         (for (This *CmdWin (setq This (: next)))
            (if (: next)
               (chgwin (dec D) (dec 'H D))
               (chgwin (dec H) 0) ) ) )
      (cursor) ) )

(de getch ()
   (loop
      (curses "wget_wch" NIL (: ptr) '(*Chr (4 . I)))
      (NIL (= 410 *Chr)  # KEY_RESIZE
         (setq *Chr (unless (= 27 *Chr) (char *Chr))) )
      (setq
         *Lines (car (struct "LINES" '(I)))
         *Columns (car (struct "COLS" '(I))) )
      (eqwin) ) )

(de getch2 (C)
   (when C
      (if (= "^V" C)
         (prog2
            (mapc curses '("nocbreak" "raw"))
            (or (getch) "^[")
            (mapc curses '("noraw" "cbreak")) )
         C ) ) )

(de reload (File N)
   (unless (== This *CmdWin)
      (when File
         (unless
            (==
               (=: last (: buffer))
               (=: buffer (fileBuffer File)) )
            (unmark) ) )
      (load> (: buffer))
      (goto 1 (or N (: buffer pos)) T)
      (repaint) ) )

(de done (Flg)
   (when Flg
      (unless (= (: buffer undo) (: buffer dirt))
         (save> (: buffer)) ) )
   (unmark)
   (nond
      ((; *CmdWin next next) (throw 'done Flg))
      ((n== This *CmdWin))
      ((== This (; *CmdWin next))
         (delwin)
         (let (N (: lines)  Top (: top))
            (with (setq *Window (: prev))
               (chgwin (+ 1 N (: lines)) Top) ) ) )
      (NIL
         (delwin)
         (let N (: lines)
            (with (setq *Window (: next))
               (chgwin (+ 1 N (: lines))) ) ) ) ) )

(de change Prg
   (let
      (Pos (nth (: buffer text) (: posY))
         Env
         (env
            'PosX1 (: posX)  'PosY1 (: posY)
            'OldA (car Pos)  'OldD (cdr Pos)
            'NewD (: buffer text)
            '(Pos PosX2 PosY2 NewA) ) )
      (let? Res
         (job Env
            (prog1
               (run Prg)
               (setq
                  PosX2 (: posX)  PosY2 (: posY)
                  NewA (if Pos (car @) (: buffer text)) )
               (and Pos (setq NewD (cdr @))) ) )
         (=: buffer redo NIL)
         (push (:: buffer undo)
            (cons Env
               '(ifn Pos
                  (=: buffer text NewD)
                  (set Pos OldA)
                  (con Pos OldD) )
               '(ifn Pos
                  (=: buffer text NewA)
                  (set Pos NewA)
                  (con Pos NewD) ) ) )
         (markup (: buffer text))
         (goto (: posX) (: posY) T)
         (repaint)
         Res ) ) )

(de undo ()
   (ifn (pop (:: buffer undo))
      (beep)
      (let U @
         (push (:: buffer redo) U)
         (bind (car U)
            (eval (cadr U))
            (markup (: buffer text))
            (goto PosX1 PosY1 T)
            (repaint) ) ) ) )

(de redo ()
   (ifn (pop (:: buffer redo))
      (beep)
      (let R @
         (push (:: buffer undo) R)
         (bind (car R)
            (eval (cddr R))
            (markup (: buffer text))
            (goto PosX2 PosY2 T)
            (repaint) ) ) ) )

(de jmp@@ (Y)
   (=: buffer lastX (: posX))
   (=: buffer lastY (: posY))
   (setq @@ Y) )

(de cnt@@ ()
   (- @@ (: posY) -1) )

(de goCol (N)
   (setq @@ (: posY))
   N )

(de goLeft (N)
   (goCol (max 1 (- (: posX) N))) )

(de goRight (N I)
   (goCol
      (min1
         (or (=T N) (+ (: posX) N))
         (+
            (or I 0)
            (length (get (: buffer text) (: posY))) ) ) ) )

(de goUp (N)
   (jmp@@ (max 1 (- (: posY) N)))
   (min1 (: posX) (length (get (: buffer text) @@))) )

(de goDown (N I)
   (jmp@@
      (min1
         (or (=T N) (+ (: posY) N))
         (+ (or I 0) (length (: buffer text))) ) )
   (min1 (: posX) (length (get (: buffer text) @@))) )

(de goAbs (X Y I)
   (jmp@@
      (min1 Y
         (+ (or I 0) (length (: buffer text))) ) )
   (min1 X (length (get (: buffer text) @@))) )

(de goFind (C D N I)
   (setq @@ (: posY))
   (let (Lst (get (: buffer text) (: posY))  L (nth Lst (: posX)))
      (do N (setq L (member C (cdr L))))
      (if L
         (+ D (or I 0) (offset L Lst))
         (beep) ) ) )

(de word (L C)
   (and
      (delim? C)
      (or
         (sub? (car L) "\"()[]")
         (not (delim? (car L))) ) ) )

(de lword (L C)
   (and (sp? C) (not (sp? (car L))) ) )

(de end (L)
   (and (not (delim? (car L))) (delim? (cadr L))) )

(de lend (L)
   (and (not (sp? (car L))) (sp? (cadr L))) )

(de getWord (Flg Str)
   (make
      (let Lst (get (: buffer text) (: posY))
         (when Flg
            (for C (nth Lst (: posX))
               (T (delim? C))
               (link C) ) )
         (for
            (L (nth Lst (dec (: posX)))
               (not (delim? (car L)))
               (prior L Lst) )
            (yoke (car L)) ) ) ) )

(de _forward (Lst C)
   (for ((X . L) Lst  L  (cdr L))
      (T (and (Fun L C) (=0 (dec 'N)))
         (jmp@@ Y)
         (+ (or I 0) X) )
      (setq C (car L))
      NIL ) )

(de goForward (Fun N I)
   (let (Y (: posY)  Pos (nth (: buffer text) Y)  L (nth (++ Pos) (: posX)))
      (if (_forward (cdr L) (car L))
         (+ (: posX) @)
         (loop
            (NIL Pos (beep))
            (inc 'Y)
            (T (_forward (++ Pos)) @) ) ) ) )

(de _backward (Lst L)
   (use P
      (loop
         (NIL L)
         (setq P (prior L Lst))
         (T (and (Fun L (car P)) (=0 (dec 'N)))
            (jmp@@ Y)
            (offset L Lst) )
         (setq L P)
         NIL ) ) )

(de goBackward (Fun N)
   (let (Y (: posY)  Pos (nth (: buffer text) Y))
      (or
         (_backward
            (car Pos)
            (nth (car Pos) (dec (: posX))) )
         (loop
            (NIL (setq Pos (prior Pos (: buffer text)))
               (beep) )
            (dec 'Y)
            (T (_backward (car Pos) (tail 1 (car Pos))) @ ) ) ) ) )

(de goPFore (Cnt D I)
   (let (Y (: posY)  Pos (nth (: buffer text) Y))
      (loop
         (NIL (cdr Pos)
            (jmp@@ Y)
            (max 1 (+ (or I 0) (length (car Pos)))) )
         (inc 'Y)
         (T
            (and
               (car Pos)
               (not (cadr Pos))
               (=0 (dec 'Cnt)) )
            (jmp@@ (+ Y D))
            1 )
         (++ Pos) ) ) )

(de goPBack (Cnt)
   (let (Y (: posY)  Pos (nth (: buffer text) Y))
      (loop
         (NIL (setq Pos (prior Pos (: buffer text))))
         (dec 'Y)
         (T
            (and
               (not (car Pos))
               (cadr Pos)
               (=0 (dec 'Cnt)) ) ) )
      (jmp@@ Y)
      1 ) )

(de shift (N Flg)
   (change
      (let? P Pos
         (do N
            (when (car P)
               (if Flg
                  (do 3 (push P (char 32)))
                  (do 3
                     (NIL (sp? (caar P)))
                     (pop P) ) ) )
            (NIL (cdr P))
            (setq P (con P (cons (car @) (cdr @)))) )
         (=: posX 1) ) ) )

(de shiftY (X Flg)
   (shift (cnt@@) Flg) )

(de indent ()
   (change
      (let? P Pos
         (when (clip (car P))
            (let (N (*/ (offset @ (trim (car P))) 3)  Sup N)
               (set P @)
               (loop
                  (do (* N 3) (push P (char 32)))
                  (for C (car P)
                     (unless (val C)
                        (case C
                           ("(" (inc 'N))
                           (")" (dec 'N))
                           ("[" (push 'Sup N) (inc 'N))
                           ("]" (setq N (++ Sup))) ) ) )
                  (NIL (clip (cadr P)) T)
                  (setq P (con P (cons @ (cddr P)))) ) ) ) ) ) )

(de cutX (X Flg)
   (when X
      (let Y @@
         (unless (> (list Y X) (list (: posY) (: posX)))
            (xchg 'X (:: posX)  'Y (:: posY)) )
         (change
            (when Pos
               (let (L (car Pos)  DX (: posX))
                  (and
                     (set *Clip
                        (make
                           (if Flg
                              (set Pos (cut (dec DX) 'L))
                              (setq L (nth L DX)) )
                           (while (>= (dec 'Y) (: posY))
                              (link L)
                              (setq L (cadr Pos))
                              (if Flg
                                 (con Pos (cddr Pos))
                                 (++ Pos) )
                              (one DX) )
                           (link (cut (- X DX) 'L))
                           (when Flg
                              (set Pos (conc (car Pos) L))
                              (=: posX (min1 (: posX) (length (car Pos)))) )
                           (setq @@ (unless L 1)) ) )
                     Flg ) ) ) ) ) ) )

(de cutN (N)
   (change
      (when Pos
         (off @@)
         (set *Clip
            (cons T
               (if (setq Pos (prior Pos (: buffer text)))
                  (make
                     (setq OldA (car @)  OldD (cdr @))
                     (do N
                        (link (cadr Pos))
                        (NIL (con Pos (cddr Pos))
                           (one @@)
                           (dec (:: posY)) ) )
                     (=: posX 1) )
                  (cut N (:: buffer text)) ) ) ) ) ) )

(de paste (Lst Flg)
   (change
      (let P (or Pos (=: buffer text (cons)))
         (ifn (=T (car Lst))
            (let L (car P)
               (cond
                  ((=0 Flg) (setq PosX1 (=: posX 1)))
                  ((=1 Flg)
                     (and
                        (get (: buffer text) (: posY) 1)
                        (get (: buffer text) (: posY) (inc (:: posX)))
                        (inc 'PosX1) ) )
                  (Flg
                     (=: posX
                        (max 1
                           (inc (length (get (: buffer text) (: posY)))) ) ) ) )
               (set P
                  (conc (cut (dec (: posX)) 'L) (mapcar name (++ Lst))) )
               (for S Lst
                  (setq P (con P (cons (mapcar name S) (cdr P))))
                  (inc (:: posY)) )
               (=: posX (max 1 (length (car P))))
               (set P (append (car P) L)) )
            (=: posX 1)
            (ifn Flg
               (for L (cdr Lst)
                  (con P (cons (car P) (cdr P)))
                  (set P (mapcar name L))
                  (setq P (cdr P)) )
               (inc (:: posY))
               (for L (cdr Lst)
                  (setq P (con P (cons (mapcar name L) (cdr P)))) ) ) )
         T ) ) )

(de join (Cnt)
   (change
      (do Cnt
         (NIL (cdr Pos))
         (set Pos
            (append
               (car Pos)
               (cons (char 32) (clip (cadr Pos))) ) )
         (con Pos (cddr Pos)) )
      T ) )

(de tglCase (Cnt)
   (change
      (let? C (get Pos 1 (: posX))
         (do Cnt
            (set Pos
               (place (: posX) (car Pos)
                  ((if (upp? C) lowc uppc) C) ) )
            (NIL (setq C (get Pos 1 (inc (: posX)))))
            (inc (:: posX)) )
         T ) ) )

(de insChar (C Cnt)
   (change
      (when (car Pos)
         (do Cnt
            (set Pos (place (: posX) (car Pos) (name C)))
            (NIL (get Pos 1 (inc (:: posX)))) )
         (dec (:: posX)) ) ) )

(de incNum (Cnt)
   (change
      (let (I (: posX)  L (car Pos)  S (get L I))
         (ifn (format S)
            (set Pos
               (place (: posX) L (char (+ Cnt (char S)))) )
            (while
               (and
                  (gt0 (dec 'I))
                  (format (get L @)) )
               (setq S (pack @ S)) )
            (inc (:: posX)
               (-
                  (length
                     (set Pos
                        (conc
                           (head I L)
                           (need
                              (if (= `(char "0") (char S)) (length S) 1)
                              (chop (max 0 (+ Cnt (format S))))
                              (char `(char "0")) )
                           (tail (- (: posX)) L) ) ) )
                  (length L) ) ) ) ) ) )

(de overwrite (Lst)
   (change
      (let
         (P (or Pos (=: buffer text (cons)))
            L (conc (cut (dec (: posX)) P) (car Lst)) )
         (set P
            (append L
               (cdr (nth (car P) (length (++ Lst)))) ) )
         (=: posX (max 1 (length L))) ) ) )

(de _bs ()
   (++ Chg)
   (dec (:: posX))
   (unless Rpl
      (set P (remove (: posX) (car P))) ) )

(de insMode (Flg Win Rpl . @)
   (change
      (let (P (or Pos (=: buffer text (cons)))  Chg)
         (cond
            ((=0 Flg)
               (con P (cons (car P) (cdr P)))
               (set P)
               (goto 1 (: posY) T) )
            ((=1 Flg))
            (Flg
               (setq P (con P (cons NIL (cdr P))))
               (goto 1 (inc (: posY)) T)
               (setq Chg (0)) ) )
         (cursor)
         (while
            (case (or (next) (getch))
               (NIL)
               (("\n" "\r")
                  (cond
                     (Rpl (beep) T)
                     ((== This *CmdWin)
                        (nil (command (or Win This) (car P))) )
                     (T
                        (push 'Chg 0)
                        (con P
                           (cons (nth (car P) (: posX)) (cdr P)) )
                        (set P (head (dec (: posX)) (car P)))
                        (setq P (cdr P))
                        (goto 1 (inc (: posY)) T)
                        (cursor)
                        T ) ) )
               (("^H" "^?" `(char 263))  # [BACKSPACE]
                  (when (and Chg (n0 (car Chg)))
                     (_bs)
                     (chgLine (car P)) )
                  T )
               (T
                  (let S (list @)
                     (nond
                        ((= @ "\t") (off *Complete))
                        ((unless Rpl (setq S (pack (getWord))))
                           (setq S
                              (make
                                 (do (- 3 (% (dec (: posX)) 3))
                                    (link (char 32)) ) ) ) )
                        (NIL
                           (default *Complete
                              (conc
                                 (list S)
                                 (filter '((P) (pre? S P)) (all))
                                 (let P (rot (split (chop S) "/"))
                                    (setq
                                       S (pack (car P))
                                       P (and (cdr P) (pack (glue "/" @) "/")) )
                                    (extract
                                       '((X)
                                          (let? F (and (pre? S X) (pack P X))
                                             (if (=T (car (info (fName F))))
                                                (pack F "/")
                                                F ) ) )
                                       (dir (fName P) T) ) ) ) )
                           (do (length (car *Complete)) (_bs))
                           (setq S (chop (car (rot *Complete)))) ) )
                     (when (= "^V" (car S))
                        (set S (or (next) (getch2 "^V"))) )
                     (for C S
                        (push 'Chg C)
                        (set P
                           ((if (and Rpl (car P)) place insert)
                              (: posX)
                              (car P)
                              C ) )
                        (inc (:: posX)) )
                     (goto (: posX) (: posY)) )
                  (chgLine (car P))
                  T ) ) )
         (=: posX (max 1 (dec (: posX))))
         (cond
            ((=0 Flg) (push 'Chg 0))
            ((=1 Flg) (and (> PosX1 1) (dec 'PosX1))) )
         (split (reverse Chg) 0) ) ) )

(de cmdMode @
   (let Win (if (== This *CmdWin) (: next) This)
      (with *CmdWin
         (pass insMode (: buffer text) Win NIL) ) ) )

(de cmdPipe (N)
   (apply cmdMode (chop (pack ":" N "!"))) )

(de evRpt (Exe)
   (eval (setq *Repeat Exe) 1) )

(de move @
   (let M (conc (rest) (1))
      (case *Change
         (NIL (and (eval (rest)) (goto @ @@)))
         ("!" (eval (rest)) (cmdPipe (cnt@@)))  # External filter
         (">" (evRpt (list 'shiftY M T)))  # Shift right
         ("<" (evRpt (list 'shiftY M)))  # Shift left
         ("c"  # Change
            (when (cutX (eval M) T)
               (and @@
                  (get (: buffer text) (: posY) 1)
                  (inc (:: posX)) )
               (let L (insMode @@)
                  (setq *Repeat
                     (list 'prog
                        (list 'cutX M T)
                        (list 'paste (lit L) '@@)) ) ) ) )
         ("d" (evRpt (list 'cutX M T)))  # Delete
         ("y" (cutX (eval M)))  # Yank
         (T (beep)) ) ) )

(de chgRight (X)
   (setq *Change "c")
   (move 'goRight X) )

(de jmpMark (C D X)
   (cond
      ((= C D)
         (move 'goAbs
            (or X (: buffer lastX))
            (: buffer lastY) ) )
      ((get (: buffer) (intern C))
         (move 'goAbs (default X (car @)) (cdr @)) ) ) )

(de wordFun (@W)
   (setq @W (append @W '("@Z")))
   (setq *Search
      (curry (@W) (L C)
         (and
            (delim? C "~")
            (match '@W L)
            (delim? (car "@Z") "~")
            (not
               (find
                  '((C)
                     (and (= C `(char 64)) (find delim? (val C))) )
                  '@W ) ) ) ) ) )

(de moveSearch (Fun1 Fun2)
   (move Fun1 (lit Fun2) *Cnt) )

(de patMatch (Fun Pat)
   (moveSearch Fun
      (setq *Search
         (if (= "\\" (car Pat))
            (let @Pat (cdr Pat)
               (curry (@Pat) (L) (head '@Pat L)) )
            (let @Pat
               (if (= "$" (last Pat))
                  (head -1 Pat)
                  (append Pat '(@)) )
               (ifn (= "\^" (car @Pat))
                  (curry (@Pat) (L) (match '@Pat L))
                  (++ @Pat)
                  (curry (@Pat) (L C)
                     (unless C (match '@Pat L)) ) ) ) ) ) ) )

(de *Spell
   "hunspell" "-l" "-d" "en_US,de_DE" )

(de spell ()
   (moveSearch 'goForward
      (setq *Search
         (let @W
            (pipe
               (out *Spell
                  (let Pos (nth (: buffer text) (: posY))
                     (prinl
                        (seek
                           '((L) (not (fold (car L))))
                           (nth (++ Pos) (: posX)) ) )
                     (mapc prinl Pos) ) )
               (conc (line) '("@Z")) )
            (curry (@W) (L C)
               (and
                  (not (fold C))
                  (match '@W L)
                  (not (fold (car "@Z"))) ) ) ) ) ) )

(de parMatch (Fun1 @Par1 @Sup1 @ParO @ParC @SupO @SupC)
   (moveSearch Fun1
      (let (Par @Par1  Sup @Sup1)
         (curry (Par Sup @Par1 @Sup1 @ParO @ParC @SupO @SupC) (L C)
            (unless (caar L)
               (and
                  (case (car L)
                     (@ParO (nil (inc 'Par)))
                     (@ParC (or (not C) (= (dec 'Par) 0 Sup)))
                     (@SupO (nil (push 'Sup Par) (zero Par)))
                     (@SupC
                        (or
                           (not C)
                           (= (setq Par (++ Sup)) 0 Sup) ) ) )
                  (setq Par @Par1  Sup @Sup1) ) ) ) ) ) )

(de pipeN (Cnt Line)
   (evRpt
      (fill
         '(when (cdr (cutN Cnt))
            (pipe (out (list "bash" "-c" Line) (mapc prinl @))
               (paste (cons T (rdLines)) @@) ) )
         '(Line Cnt) ) ) )

(de nextBuf (B)
   (let? M (member (: buffer) *Buffers)
      (=: last (: buffer))
      (=: buffer
         (nond
            (B (car (or (cdr M) *Buffers)))
            ((=T B) B)
            (NIL
               (car (or (prior M *Buffers) (tail 1 *Buffers))) ) ) )
      (unmark)
      (unless (: buffer text)
         (load> (: buffer)) )
      (goto 1 (: buffer pos) T) ) )

(de shell (S)
   (curses "endwin")
   (do *Columns (prin "#"))
   (call "bash" "-c" S)
   (prin "[====] ")
   (flush)
   (getch) )

(de shFile (S)
   (when (: buffer file)
      (shell (text S (path (fName @)) *Cnt)) ) )

(de prCmd (L)
   (with *CmdWin
      (paste (cons T L) T)
      (inc (:: posY) (dec (length L))) ) )

(de reset ()
   (off *Count *Change)
   (setq *Clip '\"\") )

### Commands ###
(de command (This Line)
   (case (++ Line)
      ("/" (patMatch 'goForward Line))  # Search forward
      ("?" (patMatch 'goBackward Line))  # Search backward
      ("&" (moveSearch 'goForward (wordFun Line)))  # Search word
      (":"
         (let Cnt 0
            (while (format (car Line))
               (setq Cnt (+ @ (* 10 Cnt)))
               (++ Line) )
            (let C (++ Line)
               (when (>= "z" C "a")
                  (until (sp? (car Line))
                     (setq C (pack C (++ Line))) ) )
               (setq Line (pack (clip Line)))
               (case C
                  (" "  # Eval
                     (out (tmp "repl")
                        (println '-> (run (str (pack Line)))) )
                     (in (tmp "repl")
                        (prCmd (rdLines)) ) )
                  ("!"  # External filter
                     (when Line
                        (if (=0 Cnt)
                           (shell (rplFile Line))
                           (pipeN Cnt Line) ) ) )
                  ("copy"  # Copy to system clipboard
                     (out '("copy")  # System dependent script
                        (let V (val *Clip)
                           (if (=T (car V))
                              (mapc prinl (cdr V))
                              (prin V) ) ) ) )
                  ("ix.io"  # Paste to http://ix.io
                     (pipe
                        (out '("curl" "-sF" "f:1=<-" "ix.io")
                           (mapc prinl (: buffer text)) )
                        (prCmd (rdLines)) ) )
                  ("bak" (shFile "mv @1 @1- && cp -p @1- @1"))  # Backup to <file>-
                  ("kab"  # Restore from <file>-
                     (shFile "mv @1- @1 && cp -p @1 @1-")
                     (reload) )
                  ("ls"  # List buffers
                     (prCmd
                        (make
                           (for (I . This) *Buffers
                              (link (chop (pack ":" I " " (: file)))) ) ) ) )
                  ("key" (=: buffer key Line) (reload))
                  ("m"
                     (when (info (=: mark (rplFile Line)))
                        (in (: mark) (move 'goAbs (read) (read))) ) )
                  ("n" (nextBuf))  # Next buffer
                  ("N" (nextBuf T))  # Previous buffer
                  ("e" (reload (rplFile Line)))  # (Edit) Reload buffer
                  ("r"  # Read file contents
                     (let F (fName (rplFile Line))
                        (when (info F)
                           (in F (paste (cons T (rdLines)) 1)) ) ) )
                  ("w"  # (Write) Save buffer
                     (if Line
                        (out (fName (rplFile @))
                           (mapc prinl (: buffer text)) )
                        (save> (: buffer)) ) )
                  ("x" (done T))  # (Exit) Save buffer and close window
                  ("q" (done))  # (Quit) Close window
                  ("bx"  # Buffer exchange
                     (let X (memq (: buffer) *Buffers)
                        (if (cdr X)
                           (xchg X @)
                           (beep) ) ) )
                  ("bd"  # Buffer delete
                     (when (cdr *Buffers)
                        (let Buf (: buffer)
                           (for (This *CmdWin (setq This (: next)))
                              (when (== Buf (: buffer))
                                 (if (; *CmdWin next next) (done) (nextBuf)) ) )
                           (del Buf '*Buffers)
                           (=: last) ) ) )
                  (T
                     (if (get *Buffers Cnt)
                        (nextBuf @)
                        (beep) ) ) ) ) )
         (with *CmdWin
            (redraw)
            (curses "wrefresh" NIL (: ptr)) ) )
      (T (beep)) ) )

### VIP Entry Point ###
(de vi (Lst)  # ("file.l" (pat) (99 . "file.l") (T . "file.l"))
   (off *Buffers)
   (when (=0 (native "@" "isatty" 'I 0))
      (with (fileBuffer (tmp "stdin"))
         (out (: file) (in 0 (echo))) ) )
   (for X Lst
      (cond
         ((not X))
         ((atom X) (fileBuffer X))
         ((not (cdr X)) (wordFun (car X)))
         (T
            (fileBuffer
               (cdr X)
               (or (num? (car X)) T) ) ) ) )
   (unless *Buffers
      (fileBuffer (tmp "empty")) )
   (native "@" "setlocale" NIL 0 "")  # LC_CTYPE: UTF-8
   (sys "ESCDELAY" "60")
   (let F (native "@" "fopen" 'N "/dev/tty" "r+")
      (curses "set_term" NIL (curses "newterm" 'N 0 F F)) )
   (finally (curses "endwin")
      (curses "start_color")
      (curses "use_default_colors")
      (curses "init_pair" NIL 1 6 0)  # COLOR_CYAN COLOR_BLACK
      (curses "init_pair" NIL 2 1 0)  # COLOR_RED COLOR_BLACK
      (curses "cbreak")
      (curses "noecho")
      (native "@" "LINES" T)
      (native "@" "COLS" T)
      (setq
         *Lines (car (struct "LINES" '(I)))
         *Columns (car (struct "COLS" '(I))) )
      (reset)
      (setq *CmdWin
         (new '(+Window) (new '(+Buffer)) (dec *Lines) 1 1 1 1 1) )
      (with (car *Buffers)
         (load> This)
         (new '(+Window) This
            0 (dec *Lines)
            1
            (min1
               (- (: pos) (/ (- *Lines 2) 2))
               (- (length (: text)) *Lines -3) )
            1 (: pos)
            *CmdWin ) )
      (with (setq *Window (; *CmdWin next)) (redraw))
      (catch 'done
         (loop
            (setq *Cnt (max 1 (format *Count)))
            (with *Window
               (=: posX
                  (min1 (: posX)
                     (length
                        (get (: buffer text)
                           (=: posY
                              (min1 (: posY) (length (: buffer text))) ) ) ) ) )
               (cursor)
               (case (getch)
                  ("0"
                     (if *Count
                        (queue '*Count "0")
                        (move 'goAbs 1 (: posY))  # Go to beginning of line
                        (off *Change) ) )
                  (("1" "2" "3" "4" "5" "6" "7" "8" "9")  # ["Count" prefix]
                     (queue '*Count *Chr) )
                  ("\"" (setq *Clip (intern (pack '"\"" (getch)))))  # "Register" prefix
                  (("!" "<" ">" "c" "d" "y")  # ["Change" prefix]
                     (cond
                        ((= *Chr *Change)
                           (case *Chr
                              ("!" (cmdPipe *Cnt))  # [!!] External filter
                              (">" (evRpt (list 'shift *Cnt T)))  # [>>] Shift line(s) right
                              ("<" (evRpt (list 'shift *Cnt)))  # [<<] Shift line(s) left
                              ("c" (=: posX 1) (chgRight T))  # [cc] Change whole line
                              ("d" (evRpt (list 'cutN *Cnt)))  # [dd] Delete line(s)
                              ("y"  # [yy] Yank line(s)
                                 (set *Clip
                                    (cons T
                                       (head *Cnt (nth (: buffer text) (: posY))) ) ) ) )
                           (reset) )
                        (*Change (off *Change))
                        (T (setq *Change *Chr)) ) )
                  (T
                     (case *Chr
                        (NIL)
                        (("\n" "\r")
                           (if (== This *CmdWin)
                              (command (: next) (get (: buffer text) (: posY)))
                              (cmdMode) ) )
                        ("." (if *Repeat (eval @) (beep)))  # Repeat last change
                        (("j" `(char 258)) (move 'goDown *Cnt))  # [DOWN] Move down
                        ((" " "^F" `(char 338)) (move 'goDown (: lines)))  # [NPAGE] Page down
                        (("k" `(char 259)) (move 'goUp *Cnt))  # [UP] Move up
                        (("^B" `(char 339)) (move 'goUp (: lines)))  # [PPAGE] Page up
                        ("h" (move 'goLeft *Cnt))  # Move left
                        ("l" (move 'goRight *Cnt))  # Move right
                        (`(char 260)  # [LEFT] Scroll left
                           (when (> (: winX) 1)
                              (when (>= (- (: posX) (dec (:: winX))) *Columns)
                                 (dec (:: posX)) ) )
                           (redraw) )
                        (`(char 261)  # [RIGHT] Scroll right
                           (cond
                              ((> (: posX) (: winX)) (inc (:: winX)))
                              ((cdr (nth (: buffer text) (: posY) (: posX)))
                                 (inc (:: posX))
                                 (inc (:: winX)) ) )
                           (redraw) )
                        ("|" (move 'goCol *Cnt))  # Go to column
                        ("$" (move 'goRight T))  # Go to end of line
                        ("G" (move 'goAbs 1 (or (format *Count) T)))  # Go to end of text
                        ("f" (and (getch2 (getch)) (move 'goFind @ 0 *Cnt)))  # Find character
                        ("t" (and (getch2 (getch)) (move 'goFind @ -1 *Cnt)))  # Till character
                        ("w" (move 'goForward 'word *Cnt))  # Word forward
                        ("W" (move 'goForward 'lword *Cnt))  # Long word forward
                        ("b" (move 'goBackward 'word *Cnt))  # Word backward
                        ("B" (move 'goBackward 'lword *Cnt))  # Long word backward
                        ("e" (move 'goForward 'end *Cnt))  # End of word
                        ("E" (move 'goForward 'lend *Cnt))  # End of long word
                        ("{" (move 'goPBack *Cnt))  # Paragraph(s) backward
                        ("}" (move 'goPFore *Cnt 0))  # Paragraph(s) forward
                        ("'" (jmpMark (getch) "'" 1))  # Jump to mark line
                        ("`" (jmpMark (getch) "`")) # Jump to mark position
                        ("~" (evRpt (list 'tglCase *Cnt)))  # Toggle case
                        (":" (cmdMode (char `(char ":"))))  # Command
                        ("/" (cmdMode (char `(char "/"))))  # Search forward
                        ("?" (cmdMode (char `(char "?"))))  # Search backward
                        ("&" (cmdMode (char `(char "&"))))  # Search word
                        ("n"  # Search next
                           (if *Search
                              (move 'goForward (lit @) *Cnt)
                              (beep) ) )
                        ("N"  # Search previous
                           (if *Search
                              (move 'goBackward (lit @) *Cnt)
                              (beep) ) )
                        ("*"  # Search word under cursor
                           (and (getWord T "~") (moveSearch 'goForward (wordFun @))) )
                        ("#"  # Search word under cursor backward
                           (and (getWord T "~") (moveSearch 'goBackward (wordFun @))) )
                        ("%"  # Matching parenthesis
                           (case (get (: buffer text) (: posY) (: posX))
                              ("(" (parMatch 'goForward 1 0 "(" ")" "[" "]"))
                              ("[" (parMatch 'goForward 0 (0 . 0) "(" ")" "[" "]"))
                              (")" (parMatch 'goBackward 1 0 ")" "(" "]" "["))
                              ("]" (parMatch 'goBackward 0 (0 . 0) ")" "(" "]" "["))
                              (T (beep)) ) )
                        ("i"  # Insert
                           (when (insMode)
                              (setq *Repeat (list 'paste (lit @))) ) )
                        ("I"  # Insert at beginning of line
                           (=: posX 1)
                           (when (insMode)
                              (setq *Repeat (list 'paste (lit @) 0)) ) )
                        ("a"  # Append
                           (when (get (: buffer text) (: posY) 1)
                              (inc (:: posX)) )
                           (when (insMode 1)
                              (setq *Repeat (list 'paste (lit @) 1)) ) )
                        ("A"  # Append to end of line
                           (goto
                              (inc (length (get (: buffer text) (: posY))))
                              (: posY) )
                           (when (insMode 1)
                              (setq *Repeat (list 'paste (lit @) T)) ) )
                        ("o"  # Open new line below current line
                           (setq *Repeat (list 'paste (lit (insMode T)) T)) )
                        ("O"  # Open new line above current line
                           (setq *Repeat (list 'paste (lit (insMode 0)) 0)) )
                        ("x" (setq *Change "d") (move 'goRight *Cnt))  # Delete characters
                        ("X" (setq *Change "d") (move 'goLeft *Cnt))  # Delete characters left
                        ("D" (setq *Change "d") (move 'goRight T))  # Delete rest of line
                        ("p" (evRpt (list 'paste (lit (val *Clip)) 1)))  # Paste after current position
                        ("P" (evRpt (list 'paste (lit (val *Clip)))))  # Paste before current position
                        ("J" (evRpt (list 'join *Cnt)))  # Join lines
                        ("m"  # Set mark
                           (put (: buffer) (intern (getch))
                              (cons (: posX) (: posY)) ) )
                        ("r"  # Replace character(s)
                           (and (getch2 (getch)) (evRpt (list 'insChar @ *Cnt))) )
                        ("R"  # Replace
                           (when (insMode NIL NIL T)
                              (setq *Repeat (list 'overwrite (lit @))) ) )
                        ("s" (chgRight 1))  # Substitute character
                        ("C" (chgRight T))  # Change rest of line
                        ("S" (=: posX 1) (chgRight T))  # Change whole line
                        ("," (evRpt '(indent)))  # Fix indentation
                        ("^A" (evRpt (list 'incNum *Cnt)))
                        ("^X" (evRpt (list 'incNum (- *Cnt))))
                        ("u" (undo))  # Undo
                        ("^R" (redo))  # Redo
                        ("g"  # ["Go" prefix]
                           (case (getch)
                              ("f" (reload (pack (getWord T))))  # [gf] Edit file under cursor
                              ("g" (move 'goAbs 1 1))  # [gg] Go to beginning of text
                              (T (beep)) ) )
                        ("+"  # Increase window size
                           (loop
                              (NIL (setq This (: prev))
                                 (for (This (; *Window next) This (: next))
                                    (T (> (: lines) 1)
                                       (with *Window
                                          (chgwin (inc (: lines)) (dec (: top)))
                                          (for (This (: next) (=1 (: lines)) (: next))
                                             (chgwin 1 (dec (: top))) ) )
                                       (chgwin (dec (: lines))) ) ) )
                              (T (> (: lines) 1)
                                 (with *Window
                                    (chgwin (inc (: lines)))
                                    (for (This (: prev) (=1 (: lines)) (: prev))
                                       (chgwin 1 (inc (: top))) ) )
                                 (chgwin (dec (: lines)) (inc (: top))) ) ) )
                        ("-"  # Decrease window size
                           (cond
                              ((=1 ( : lines)))
                              ((: prev)
                                 (chgwin (dec (: lines)))
                                 (with (: prev)
                                    (chgwin (inc (: lines)) (dec (: top))) ) )
                              (T
                                 (chgwin (dec (: lines)) (inc (: top)))
                                 (with (: next)
                                    (chgwin (inc (: lines))) ) ) ) )
                        ("=" (eqwin))  # Set all windows to equal size
                        ("^]"  # Edit symbol
                           (ifn (get (any (pack (getWord T))) '*Dbg 1)
                              (beep)
                              (push '*TagStack (: posY) (: buffer file))
                              (reload (cdr @) (car @)) ) )
                        ("^T"  # Pop tag stack
                           (if *TagStack
                              (reload (pop '*TagStack) (pop '*TagStack))
                              (beep) ) )
                        (`(char (+ 264 1))  # [F1] Highlight on/off
                           (onOff *Flat)
                           (repaint) )
                        (`(char (+ 264 2))  # [F2] Show chages to <file>-
                           (shFile
                              (if (sys "CCRYPT" (: buffer key))
                                 "diff -Bb <(ccrypt -c -ECCRYPT @1-) <(ccrypt -c -ECCRYPT @1)"
                                 "diff -Bb @1- @1" ) ) )
                        (`(char (+ 264 3))  # [F3] Custom dif
                           (shFile "dif @1 @2") )
                        (`(char (+ 264 4))  # [F4] Format paragraph
                           (goPFore 1 -1)
                           (pipeN (cnt@@) "fmt") )
                        (`(char (+ 264 5))  # [F5] Previous buffer
                           (nextBuf T) )
                        (`(char (+ 264 6))  # [F6] Next buffer
                           (nextBuf) )
                        (`(char (+ 264 7))  # [F7] Load file
                           (let? F (fName (: buffer file))
                              (and (info F) (catch '(NIL) (load F))) ) )
                        ## (`(char (+ 264 8)) ())  # [F8]
                        ## (`(char (+ 264 9)) ())  # [F9]
                        (`(char (+ 264 10)) (run *F10))  # [F10] Custom key
                        (`(char (+ 264 11)) (run *F11))  # [F11] Custom key
                        (`(char (+ 264 12)) (run *F12))  # [F12] Custom key
                        ("\\"  # Select or toggle buffer
                           (nextBuf
                              (if *Count
                                 (get *Buffers (format @))
                                 (or (: last) (car *Buffers)) ) ) )
                        ("z" (spell))
                        (("q" "^W")  # ["Window" prefix]
                           (case (getch)
                              ("s"  # [qs] Split window
                                 (unless (== This *CmdWin)
                                    (let (Old (inc (: lines))  New (/ Old 2))
                                       (with
                                          (new '(+Window) (: buffer)
                                             (+ (: top) New) (- Old New)
                                             (: winX) (: winY)
                                             (: posX) (: posY)
                                             (: prev)
                                             (: mark) )
                                          (goto (: posX) (: posY) T) )
                                       (=: mark)
                                       (chgwin (dec New)) ) ) )
                              ("x"  # [qx] Exchange windows
                                 (and
                                    (; *CmdWin next next)
                                    (n== This *CmdWin)
                                    (let W (if (== (: prev) *CmdWin) (: next) (: prev))
                                       (for P '(buffer winX winY posX posY)
                                          (xchg (prop This P) (prop W P)) )
                                       (goto (: posX) (: posY) T)
                                       (with W
                                          (goto (: posX) (: posY) T) ) ) ) )
                              ("k" (and (: next) (setq *Window @)))  # [qk] Above window
                              ("j" (and (: prev) (setq *Window @)))  # [qj] Below window
                              ("q" (done))  # [qq] (Quit) Close window
                              (T (beep)) ) )
                        ("Z" (done T))
                        (T (beep)) )
                     (reset) ) ) ) ) ) ) )

(when (info (pil "viprc"))
   (load (pil "viprc")) )

`*Dbg

(symbols '(pico)
   (let Src (path "@src64/")
      (in "@src64/tags"
         (use (L F)
            (while (setq L (line))
               (if (= L '("^L"))
                  (setq F (pack Src (car (split (line) ","))))
                  (put
                     (intern
                        (pack (car (setq L (split (cdr L) "^A" ",")))) )
                     '*Dbg
                     (list (cons (format (cadr L)) F)) ) ) ) ) ) ) )

(undef 'pico~vi)
(de pico~vi ("X" C)
   (and
      (vi
         (list
            (cond
               ((pair "X")
                  (get (cdr "X") '*Dbg -1 (car "X")) )
               (C (get C '*Dbg -1 "X"))
               (T (or (get "X" '*Dbg 1) "X")) ) ) )
      "X" ) )

# vi:et:ts=3:sw=3
