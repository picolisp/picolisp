# 24nov16abu
# (c) Software Lab. Alexander Burger

### RC Flight Simulator for 64-bit PicoLisp ###

# *FocLen *Scene *Model
# *DT *Throttle *Speed *Altitude

(scl 6)  # Keep in sync with `SCL' in C lib

(load "@lib/z3d.l" "@lib/term.l")

# Color Constant Definitions from "/usr/lib/X11/rgb.txt"
(def 'Black     (hex "000000"))
(def 'Blue      (hex "0000FF"))
(def 'Brown     (hex "A52A2A"))
(def 'DarkGreen (hex "006400"))
(def 'DarkGrey  (hex "A9A9A9"))
(def 'Grey      (hex "BEBEBE"))
(def 'LightBlue (hex "ADD8E6"))
(def 'Red       (hex "FF0000"))
(def 'Yellow    (hex "FFFF00"))
(def 'White     (hex "FFFFFF"))

# Create model
(de model (Obj Lst Pos)
   (default Pos `(* 8 12))
   (apply struct
      (conc
         (extract                                        # Faces
            '((M)
               (unless (and (car M) (sym? @))
                  (inc 'Pos 8)
                  (cons
                     (struct
                        (native "@" "malloc" 'N
                           (+ `(* 4 4) (* 8 (length (cddr M)))) )
                        'N
                        (cons (or (num? (car M)) `(hex "1000000")) 4)
                        (cons
                           (or
                              (num? (cadr M))
                              (if (cadr M)
                                 `(hex "2000000")
                                 `(hex "1000000") ) )
                           4 )
                        (- (/ (length (cddr M)) 3))
                        -42
                        (cons 1.0 (cddr M)) )
                     8 ) ) )
            (cddddr Lst) )
         (cons (0 . 8))
         (extract                                        # Submodels
            '((M)
               (when (and (car M) (sym? @))
                  (inc 'Pos 8)
                  (cons
                     (if (cdr M)
                        (model Obj M Pos)
                        (put Obj (car M) Pos)
                        0 )
                     8 ) ) )
            (cddddr Lst) )
         '((0 . 8)) )
      (put Obj (++ Lst)
         (native "@" "malloc" 'N
            (+ `(* 8 12) (* 8 (length (cdr Lst)))) ) )   # (+ 2 CDDDR)
      'N                                                 # Return structure pointer
      (cons 1.0 (head 3 Lst))                            # pos
      (1.0  1.0 0.0 0.0  0.0 1.0 0.0  0.0 0.0 1.0) ) )   # rot

# Simulation
(de *DT . 0.020)
(de *Tower . 12.0)

(de MUL Args
   (let D 1.0
      (make
         (link '*/ (++ Args) (++ Args))
         (while Args
            (setq D (* D 1.0))
            (link (++ Args)) )
         (link D) ) ) )

(de damp ("Var" Val)
   (set "Var" (>> 1 (+ Val (val "Var")))) )

(class +Model)
# mass power rc lc tx tz pitch torq stab
# body leftAileron rightAileron rudder elevator propeller blade disk
# ele ail rud thr thrust vx vy vz fx fy fz dx dy dz

(dm T ()
   (=: mass 910.0)               # kg
   (=: power 3924.0)             # N
   (=: rc -1.4)                  # kg/m
   (=: lc -250.0)                # kg/m
   (=: trim 30)                  # Trimmung
   (=: lim1 0.8)                 # tan(a)
   (=: lim2 0.24)
   (=: tx 1.2)                   # Touchdown
   (=: tz -1.9)
   (=: pitch 0.26)
   (=: torq -10000.0)            # Drehmoment
   (=: stab (0.01 0.01 0.02))    # Stabilitaet
   (model This
      '(body 0.0 0.0 1.50
         # Flaeche oben
         (`Blue `Blue -0.15 +0.30 +1.05  +1.20  0.00 +1.05  +1.20 +3.90 +1.05  +0.90 +4.20 +1.05  -0.20 +3.90 +1.05  -0.60 +2.20 +1.05  -0.60 +0.60 +1.05)
         (`Blue `Blue -0.60 -0.60 +1.05  -0.60 -2.20 +1.05  -0.20 -3.90 +1.05  +0.90 -4.20 +1.05  +1.20 -3.90 +1.05  +1.20  0.00 +1.05  -0.15 -0.30 +1.05)
         (`Blue `Blue +1.20  0.00 +1.05  -0.15 -0.30 +1.05  -0.15 +0.30 +1.05)
         # Querruder
         (rightAileron -0.60 +2.20 +1.05
            (`Red `Red +0.40 +1.70  0.00  +0.72 +1.78 0.00  +0.72 +1.90 0.00  +0.40 +2.10 0.00  0.00 +1.80 0.00  0.00 +1.70 0.00)
            (`Red `Red +0.40 +1.70  0.00   0.00 +1.70 0.00   0.00  0.00 0.00) )
         (leftAileron -0.60 -2.20 +1.05
            (`Red `Red +0.40 -1.70 0.00  +0.72 -1.78 0.00  +0.72 -1.90 0.00  +0.40 -2.10 0.00  0.00 -1.80 0.00  0.00 -1.70 0.00)
            (`Red `Red +0.40 -1.70 0.00   0.00 -1.70 0.00   0.00  0.00 0.00) )
         # Flaeche rechts unten
         (`Blue `Blue +0.90 +0.20 -0.60  +0.90 +3.90 -0.30  +0.60 +4.20 -0.30  -0.90 +3.90 -0.30  -0.90 +0.20 -0.60)
         # Flaeche links unten
         (`Blue `Blue -0.90 -0.20 -0.60  -0.90 -3.90 -0.30  +0.60 -4.20 -0.30  +0.90 -3.90 -0.30  +0.90 -0.20 -0.60)
         # Streben links
         (`Brown `Brown -0.20 -2.55 +1.05  -0.50 -2.55 -0.37  -0.60 -2.55 -0.37  -0.30 -2.55 +1.05)
         (`Brown `Brown -0.50 -2.55 -0.37  -0.50 -2.55 -0.37  +0.80 -2.55 +0.90  +0.80 -2.55 +1.05)
         (`Brown `Brown +0.90 -2.55 +1.05  +0.60 -2.55 -0.37  +0.50 -2.55 -0.37  +0.80 -2.55 +1.05)
         # Streben rechts
         (`Brown `Brown -0.20 +2.55 +1.05  -0.50 +2.55 -0.37  -0.60 +2.55 -0.37  -0.30 +2.55 +1.05)
         (`Brown `Brown -0.50 +2.55 -0.37  -0.50 +2.55 -0.37  +0.80 +2.55 +0.90  +0.80 +2.55 +1.05)
         (`Brown `Brown +0.90 +2.55 +1.05  +0.60 +2.55 -0.37  +0.50 +2.55 -0.37  +0.80 +2.55 +1.05)
         # Motorlager
         (`Grey NIL +1.80 +0.30 +0.30  +1.80 -0.30 +0.30  +1.80 -0.30 -0.30  +1.80 +0.30 -0.30)
         # Rumpfnase
         (`Blue NIL +1.20  0.00 +0.60  +1.80 -0.30 +0.30  +1.80 +0.30 +0.30)
         (`Blue NIL +1.20  0.00 +0.60  +1.20 -0.45 +0.30  +1.80 -0.30 +0.30)
         (`Blue NIL +1.80 +0.30 +0.30  +1.20 +0.45 +0.30  +1.20  0.00 +0.60)
         (`Blue NIL +1.20 -0.45 +0.30  +1.20 -0.45 -0.30  +1.80 -0.30 -0.30  +1.80 -0.30 +0.30)
         (`Blue NIL +1.80 +0.30 +0.30  +1.80 +0.30 -0.30  +1.20 +0.45 -0.30  +1.20 +0.45 +0.30)
         (`Blue NIL +1.20 -0.45 -0.30  +1.20 -0.30 -0.60  +1.80 -0.30 -0.30)
         (`Blue NIL +1.80 +0.30 -0.30  +1.20 +0.30 -0.60  +1.20 +0.45 -0.30)
         (`Blue NIL +1.20 -0.30 -0.60  +1.20 +0.30 -0.60  +1.80 +0.30 -0.30  +1.80 -0.30 -0.30)
         # Rumpfseite rechts
         (`Red NIL +1.20 +0.45 +0.30  +1.20 +0.45 -0.30  -1.50 +0.45 -0.30  -1.50 +0.45 +0.30  -1.20 +0.45 +0.45  -0.90 +0.45 +0.45)
         (`Red NIL -1.50 +0.45 +0.30  -1.50 +0.45 -0.30  -4.80  0.00 -0.30 -4.80   0.00  0.00)
         # Rumpfseite links
         (`Red NIL -0.90 -0.45 +0.45  -1.20 -0.45 +0.45  -1.50 -0.45 +0.30  -1.50 -0.45 -0.30  +1.20 -0.45 -0.30  +1.20 -0.45 +0.30)
         (`Red NIL -4.80  0.00  0.00  -4.80  0.00 -0.30  -1.50 -0.45 -0.30  -1.50 -0.45 +0.30)
         # Rumpfoberteil vorne
         (`Red NIL +1.20 0.00 +0.60  +1.20 +0.45 +0.30  -0.90 +0.45 +0.45  -0.60 0.00 +0.60)
         (`Red NIL -0.60 0.00 +0.60  -0.90 -0.45 +0.45  +1.20 -0.45 +0.30  +1.20 0.00 +0.60)
         # Cockpit
         (`Brown NIL -0.60  0.00 +0.60  -0.90 +0.45 +0.45  -0.90 -0.45 +0.45)
         (`Black NIL -0.90 +0.45 +0.45  -1.20 +0.45 +0.45  -1.20 -0.45 +0.45  -0.90  -0.45  +0.45)
         (`Black NIL -1.20 +0.45 +0.45  -1.35  0.00 +0.54  -1.20 -0.45 +0.45)
         # Rumpfoberteil hinten
         (`Red NIL -1.35  0.00 +0.54  -1.20 +0.45 +0.45  -4.80  0.00  0.00)
         (`Red NIL -1.20 +0.45 +0.45  -1.50 +0.45 +0.30  -4.80  0.00  0.00)
         (`Red NIL -4.80  0.00  0.00  -1.20 -0.45 +0.45  -1.35  0.00 +0.54)
         (`Red NIL -4.80  0.00  0.00  -1.50 -0.45 +0.30  -1.20 -0.45 +0.45)
         # Rumpfboden
         (`Red NIL +1.20 +0.45 -0.30  +1.20 +0.30 -0.60  -1.50 +0.30 -0.60  -1.50 +0.45 -0.30)
         (`Red NIL +1.20 +0.30 -0.60  +1.20 -0.30 -0.60  -1.50 -0.30 -0.60  -1.50 +0.30 -0.60)
         (`Red NIL -1.50 -0.45 -0.30  -1.50 -0.30 -0.60  +1.20 -0.30 -0.60  +1.20 -0.45 -0.30)
         (`Red NIL -4.80  0.00 -0.30  -1.50 -0.30 -0.60  -1.50 -0.45 -0.30)
         (`Red NIL -4.80  0.00 -0.30  -1.50 +0.30 -0.60  -1.50 -0.30 -0.60)
         (`Red NIL -1.50 +0.45 -0.30  -1.50 +0.30 -0.60  -4.80  0.00 -0.30)
         # Hoehenleitwerk
         (`Red `Red -3.60 +0.15 0.00  -4.20 +1.80 0.00  -4.50 +1.80 0.00  -4.50 +0.06 0.00)
         (`Red `Red -4.50 -0.06 0.00  -4.50 -1.80 0.00  -4.20 -1.80 0.00  -3.60 -0.15 0.00)
         # Hoehenruder
         (elevator -4.50 0.00 0.00
            (`Blue `Blue 0.00 +1.80 0.00  -0.60 +1.50 0.00  -0.60 +0.60 0.00  0.00 +0.06 0.00)
            (`Blue `Blue 0.00 -0.06 0.00  -0.60 -0.60 0.00  -0.60 -1.50 0.00  0.00 -1.80 0.00) )
         # Seitenleitwerk
         (`Red `Red -4.80 0.00 0.00  -3.60 0.00 +0.15  -4.20 0.00 +0.90  -4.80 0.00 +1.05)
         # Seitenruder
         (rudder -4.80 0.00 0.00
            (`Blue `Blue 0.00 0.00 +1.05  0.00 0.00 -0.30  -0.45 0.00 +0.30  -0.45 0.00 +0.90) )
         # Schatten Nase
         (NIL T +0.90 -0.30 -0.20  +1.70 0.00 -0.20  +0.90 +0.30 -0.20)
         # Schatten Flaechen
         (NIL T +0.90 -3.00 -0.20  +0.90 +3.00 -0.20  -0.90 +3.00 -0.20  -0.90 -3.00 -0.20)
         # Schatten Rumpf
         (NIL T -0.90 -0.40 -0.20  -0.90 +0.40 -0.20  -4.70 0.00 -0.20)
         # Schatten Leitwerk
         (NIL T -3.60 0.00 -0.20  -4.20 +1.80 -0.20  -4.50 +1.80 -0.20  -4.50 -1.80 -0.20  -4.20 -1.80 -0.20)
         # Spinner
         (`Blue NIL +1.80 +0.15 -0.15  +1.80 +0.15 +0.15  +2.10 0.00 0.00)
         (`Blue NIL +1.80 -0.15 -0.15  +1.80 +0.15 -0.15  +2.10 0.00 0.00)
         (`Blue NIL +1.80 -0.15 +0.15  +1.80 -0.15 -0.15  +2.10 0.00 0.00)
         (`Blue NIL +1.80 +0.15 +0.15  +1.80 -0.15 +0.15  +2.10 0.00 0.00)
         # Fahrwerk
         (`Grey `Grey +1.20 +0.30 -0.60  +1.20 +0.90 -1.47  +1.20 +1.00 -1.47  +1.20 +0.40 -0.60)
         (`Grey `Grey +1.20 -0.30 -0.60  +1.20 -0.90 -1.47  +1.20 -1.00 -1.47  +1.20 -0.40 -0.60)
         (`Grey `Grey +1.20 -1.20 -1.47  +1.20 -1.20 -1.53  +1.20 +1.20 -1.53  +1.20 +1.20 -1.47)
         (`Grey `Grey +1.20 +0.90 -1.53  +1.20 +0.90 -1.47  +0.30 +0.30 -0.60  +0.18 +0.30 -0.60)
         (`Grey `Grey +1.20 -0.90 -1.53  +1.20 -0.90 -1.47  +0.30 -0.30 -0.60  +0.18 -0.30 -0.60)
         # Rad rechts
         (`Yellow `Yellow +1.20 +1.20 -1.20  +1.38 +1.20 -1.25  +1.50 +1.20 -1.37  +1.55 +1.20 -1.55  +1.50 +1.20 -1.73  +1.38 +1.20 -1.85  +1.20 +1.20 -1.90  +1.02 +1.20 -1.85  +0.90 +1.20 -1.72  +0.85 +1.20 -1.55  +0.90 +1.20 -1.37  +1.02 +1.20 -1.25)
         # Schatten Rad rechts
         (NIL T +1.60 +1.00 -1.55  +1.60 +1.40 -1.55  +0.80 +1.40 -1.55  +0.80 +1.00 -1.55)
         # Rad links
         (`Yellow `Yellow +1.20 -1.20 -1.20  +1.38 -1.20 -1.25  +1.50 -1.20 -1.37  +1.55 -1.20 -1.55  +1.50 -1.20 -1.73  +1.38 -1.20 -1.85  +1.20 -1.20 -1.90  +1.02 -1.20 -1.85  +0.90 -1.20 -1.72  +0.85 -1.20 -1.55  +0.90 -1.20 -1.37  +1.02 -1.20 -1.25)
         # Schatten Rad links
         (NIL T +1.60 -1.00 -1.55  +1.60 -1.40 -1.55  +0.80 -1.40 -1.55  +0.80 -1.00 -1.55)
         # Platzhalter
         (propeller) ) )
   (model This
      '(blade +1.95 0.00 0.00
         (`Black `Black -0.05 0.00 0.00  +0.05 0.00 0.00  +0.02 +0.40 -0.50  +0.00 +0.90 -0.90  -0.02 +0.50 -0.40  -0.05 0.00 0.00  -0.02 -0.50 +0.40  +0.00 -0.90 +0.90  +0.02 -0.40 +0.50  +0.05 0.00 0.00) ) )
   (model This
      '(disk +1.95 0.00 0.00
         (NIL NIL +0.00 -0.30 +1.20  +0.00 -0.90 +0.90  +0.00 -1.20 +0.30  +0.00 -1.20 -0.30  +0.00 -0.90 -0.90  +0.00 -0.30 -1.20  +0.00 +0.30 -1.20  +0.00 +0.90 -0.90  +0.00 +1.20 -0.30  +0.00 +1.20 +0.30  +0.00 +0.90 +0.90  +0.00 +0.30 +1.20) ) )
   (=: ele (=: ail (=: rud (=: thr (=: thrust 0)))))
   (=: vx (=: vy (=: vz 0)))
   (=: fx (=: fy (=: fz 0)))
   (=: dx (=: dy (=: dz 0)))
   (z3dDX (: body) -100.0)
   (z3dDY (: body) -200.0)
   (z3dYrot (: body) 0.26)
   (inc (:: propeller) (: body))
   (=: blade (cons (: blade) 8))
   (=: disk (cons (: disk) 8))
   (struct (: propeller) NIL (: blade)) )

(dm dir> (VarX VarY)
   (let B (struct (: body) (1.0 . 3))
      (z3dSpot VarX VarY
         (+ (car B) (>> 3 (: vx)) (>> 2 (: vz)))
         (+ (cadr B) (>> 3 (: vy)) (>> 2 (: vz)))
         (-
            (+ (caddr B) (>> 3 (: vz)) (>> 2 (: vz)))
            *Tower ) ) ) )

(dm down> ()
   (when (> (: ele) -100)
      (dec (:: ele) 20)
      (z3dArot (: elevator) +0.2) ) )

(dm up> ()
   (when (> 100 (: ele))
      (inc (:: ele) 20)
      (z3dArot (: elevator) -0.2) ) )

(dm left> ()
   (when (> (: ail) -100)
      (dec (:: ail) 20)
      (dec (:: rud) 20)
      (z3dArot (: leftAileron) +0.2)
      (z3dArot (: rightAileron) +0.2)
      (z3dArot (: rudder) +0.2) ) )

(dm right> ()
   (when (> 100 (: ail))
      (inc (:: ail) 20)
      (inc (:: rud) 20)
      (z3dArot (: leftAileron) -0.2)
      (z3dArot (: rightAileron) -0.2)
      (z3dArot (: rudder) -0.2) ) )

(dm throt> (X)
   (=: thr
      (cond
         ((not X) 0)
         ((=T X) 100)
         ((lt0 X) (max 10 (- (: thr) 25)))
         ((=0 (: thr)) 10)
         ((= 10 (: thr)) 25)
         (T (min 100 (+ 25 (: thr)))) ) ) )

(dm sim> ()
   (cond
      ((gt0 (: ele))
         (dec (:: ele))
         (z3dArot (: elevator) +0.01) )
      ((lt0 (: ele))
         (inc (:: ele))
         (z3dArot (: elevator) -0.01) ) )
   (cond
      ((gt0 (: ail))
         (dec (:: ail))
         (dec (:: rud))
         (z3dArot (: leftAileron) +0.01)
         (z3dArot (: rightAileron) +0.01)
         (z3dArot (: rudder) +0.01) )
      ((lt0 (: ail))
         (inc (:: ail))
         (inc (:: rud))
         (z3dArot (: leftAileron) -0.01)
         (z3dArot (: rightAileron) -0.01)
         (z3dArot (: rudder) -0.01) ) )
   (cond
      ((> (: thr) (: thrust))
         (inc (:: thrust)) )
      ((> (: thrust) (: thr))
         (dec (:: thrust)) ) )
   (struct (: propeller) NIL
      (if (> 20 (: thrust))
         (: blade)
         (: disk) ) )
   (unless (=0 (: thrust))
      (z3dXrot
         (if (> 20 (: thrust))
            (: blade 1)
            (: disk 1) )
         0.2 ) )
   (use (Touch VX VY VZ Body Taxi Stick A FX FY FZ DX DY DZ)
      (z3dRotate (: body) (: tx) 0 (: tz) NIL NIL 'Touch)
      (z3dRotate (: body) (: vx) (: vy) (: vz) 'VX 'VY 'VZ T)
      (setq
         Body (struct (: body) (1.0 . 12))
         Taxi (> 0.1 (+ (caddr Body) Touch))
         Stick (>= 1.0 (+ VX VY))
         FX (+ (*/ (: thrust) (: power) 100) `(MUL (: rc) VX (abs VX)))
         FZ (+
            (cond
               ((> 0.1 VX) 0)
               ((> (abs (setq A (*/ 1.0 VZ VX))) (: lim2))
                  0 )
               ((>= (: lim1) A)
                  `(MUL VX VX (: lc) A) )
               (T `(MUL VX VX (: lc) (- (: lim2) A))) )
            `(MUL 8.0 (: rc) VZ (abs VZ)) ) )
      (ifn Taxi
         (setq FY `(MUL 4.0 (: rc) VY (abs VY)))
         (let F (>> 2 (: mass))
            (cond
               ((> 0.1 (abs VX))
                  (and (>= F FX) (zero FX)) )
               ((gt0 VX)
                  (dec 'FX F) )
               (T (inc 'FX F)) )
            (setq FY (if (lt0 VY) (* 12 F) (* -12 F))) )
         (z3dYrot (: body)
            (>> 3 (- (: pitch) (get Body 6))) ) )  # rot.a.z
      (unless Stick
         (z3dYrot (: body)
            (+
               (*/ VX (+ (: ele) (: trim)) 80000)
               `(MUL VZ (: stab 2)) ) )
         (if Taxi
            (prog
               (z3dZrot (: body) (*/ VX (: rud) 80000))
               (z3dXrot (: body) (get Body 9)) )  # rot.b.z
            (z3dXrot (: body)  # roll
               (+
                  (- (*/ VX (: ail) 80000) (/ VY 400))
                  (*/ (: thrust) (: torq) (: mass))
                  `(MUL (get Body 9) (: stab 1)) ) )  # rot.b.z
            (z3dZrot (: body)
               (+
                  (*/ VX (: rud) 80000)
                  `(MUL VY (: stab 3)) ) ) ) )
      # World system
      (z3dRotate (: body) FX FY FZ 'FX 'FY 'FZ)
      (dec 'FZ `(MUL (: mass) 9.81))
      # Accelerate
      (setq
         A (*/ 1.0 *DT (: mass))
         DX `(MUL A (damp (:: fx) FX))
         DY `(MUL A (damp (:: fy) FY))
         DZ `(MUL A (damp (:: fz) FZ)) )
      (if (and Stick (> 0.001 (+ `(MUL DX DX) `(MUL DY DY))))
         (=: vx (=: vy (=: dx (=: dy 0))))
         (inc (:: vx) (damp (:: dx) DX))
         (inc (:: vy) (damp (:: dy) DY)) )
      (inc (:: vz) (damp (:: dz) DZ))
      (when (and Taxi (lt0 (: vz)))
         (when (> -6.0 (: vz))
            (=: thr (=: thrust 0))
            (=: vx (=: vy 0))
            (struct (: propeller) NIL (: blade)) )
         (z3dZ (: body) (- Touch))
         (=: vz 0) )
      # Translate
      (z3dDX (: body) `(MUL (: vx) *DT))
      (z3dDY (: body) `(MUL (: vy) *DT))
      (z3dDZ (: body) `(MUL (: vz) *DT))
      # Instruments
      (setq
         *Throttle (: thr)
         *Speed (*/ VX 3.6 `(* 1.0 1.0))
         *Altitude (/ (caddr Body) 1.0) ) ) )

(dm draw> ()
   (z3dDraw (: body)) )

# Scene
(class +Scene)
# env

(dm T ()
   (model This
      '(runway1 -120.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (model This
      '(runway2 -80.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (model This
      '(runway3 -40.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (model This
      '(runway4 0.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (model This
      '(runway5 +40.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (model This
      '(runway6 +80.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (model This
      '(runway7 +120.0 -200.0 -0.02
         (`DarkGrey NIL +20.0 -20.0 0  +20.0 +20.0 0  -20.0 +20.0 0  -20.0 -20.0 0)
         (`White NIL +10.0 -1.0 0  +10.0 +1.0 0  -10.0 +1.0 0  -10.0 -1.0 0) ) )
   (=: env
      (list
         (: runway1)
         (: runway2)
         (: runway3)
         (: runway4)
         (: runway5)
         (: runway6)
         (: runway7) ) ) )

(dm sim> ())

(dm draw> ()
   (mapc z3dDraw (: env)) )

# Key Controls
(fkey *XtIns   (and (> 32000.0 *FocLen) (setq *FocLen (>> -1 *FocLen))))
(fkey *XtDel   (and (> *FocLen 2000.0) (setq *FocLen (>> 1 *FocLen))))
(fkey *XtUp    (down> *Model))
(fkey *XtDown  (up> *Model))
(fkey *XtLeft  (left> *Model))
(fkey *XtRight (right> *Model))
(fkey *XtHome  (throt> *Model T))
(fkey *XtPgDn  (throt> *Model -1))
(fkey *XtPgUp  (throt> *Model +1))
(fkey *XtEnd   (throt> *Model))

# Init/Run
(de main ()
   (setq
      *FocLen 8000.0
      *Scene (new '(+Scene))
      *Model (new '(+Model)) ) )

(de go ()
   (when (z3dWindow "RC Simulator" 800 600)
      (quit @) )
   (zero "MSec")
   (task `(*/ -1000 *DT 1.0) 0  # -Milliseconds
      (let R (assoc @ *Run)
         (sim> *Scene)
         (sim> *Model)
         (use (Yaw Pitch)
            (dir> *Model 'Yaw 'Pitch)
            (z3dCamera *FocLen Yaw Pitch  0 0 *Tower  LightBlue DarkGreen) )
         (draw> *Scene)
         (draw> *Model)
         (z3dPut)
         (z3dText 20 580 (pack *Throttle " %"))
         (z3dText 120 580 (pack *Speed " km/h"))
         (z3dText 220 580 (pack *Altitude " m"))
         (z3dText 320 580
            (case *FocLen
               (2000.0 "(--)")
               (4000.0 "(-)")
               (16000.0 "(+)")
               (32000.0 "(++)") ) )
         (z3dSync)
         (let M (*/ (usec) 1000)
            (setq "MSec"
               (- M
                  (set (cdr R)
                     (min -2 (- M "MSec" `(*/ 1000 *DT 1.0))) ) ) ) ) ) ) )

# vi:et:ts=3:sw=3
