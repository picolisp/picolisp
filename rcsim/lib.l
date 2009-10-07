# 26aug09abu
# (c) Software Lab. Alexander Burger

# *Pilot *Scene *Model
# *DT *Thr *Speed *Climb *Alt

(load "simul/lib.l")

(de *DT . 0.020)
(de *Tower . 12.0)

(de start ()
   (task -20 0 (simulate))
   (setq "Time" (time)) )

(de stop ()
   (task -20) )

(de draw ()
   (at (0 . 100)
      (let N (time)
         (rate> *Pilot (- N "Time"))
         (setq "Time" N) ) )
   (draw> *Scene) )

(de simulate ()
   (sim> *Scene)
   (sim> *Model) )

(de MUL Args
   (let D 1.0
      (make
         (link '*/ (pop 'Args) (pop 'Args))
         (while Args
            (setq D (* D 1.0))
            (link (pop 'Args)) )
         (link D) ) ) )

(de dist (X Y)
   (sqrt (+ (* X X) (* Y Y))) )

(de damp ("Var" Val)
   (set "Var" (>> 1 (+ Val (val "Var")))) )

(de doppler (F X Y VX VY)
   (let N (dist X Y)
      (if (=0 N)
         F
         (- F
            (*/ F
               (+ `(MUL X VX) `(MUL Y VY))
               (* N 150) ) ) ) ) )


(class +Model)
# mass power rc lc limit tx tz pitch torq stab
# body leftAileron rightAileron rudder elevator propeller blade disk
# ele ail rud thr thrust vx vy vz fx fy fz dx dy dz

(dm T ()
   (load "rcsim/fokker.l")
   (=: ele (=: ail (=: rud (=: thr (=: thrust 0)))))
   (=: vx (=: vy (=: vz 0)))
   (=: fx (=: fy (=: fz 0)))
   (=: dx (=: dy (=: dz 0)))
   (z3d:dx -100.0 (: body))
   (z3d:dy -200.0 (: body))
   (blade> This) )

(dm dir> ()
   (let B (val (: body))
      (z3d:Spot
         (+ (car B) (>> 3 (: vx)) (>> 2 (: vz)))
         (+ (cadr B) (>> 3 (: vy)) (>> 2 (: vz)))
         (+ (caddr B) (>> 3 (: vz)) (>> 2 (: vz)))
         0 0 *Tower ) ) )

(dm blade> ()
   (set (: propeller) (val (: blade))) )

(dm disk> ()
   (set (: propeller) (val (: disk))) )


(dm down> ()
   (when (> (: ele) -100)
      (dec (:: ele) 20)
      (z3d:Arot +0.2 (: elevator)) ) )

(dm up> ()
   (when (> 100 (: ele))
      (inc (:: ele) 20)
      (z3d:Arot -0.2 (: elevator)) ) )

(dm left> ()
   (when (> (: ail) -100)
      (dec (:: ail) 20)
      (dec (:: rud) 20)
      (z3d:Arot +0.2 (: leftAileron))
      (z3d:Arot +0.2 (: rightAileron))
      (z3d:Arot +0.2 (: rudder)) ) )

(dm right> ()
   (when (> 100 (: ail))
      (inc (:: ail) 20)
      (inc (:: rud) 20)
      (z3d:Arot -0.2 (: leftAileron))
      (z3d:Arot -0.2 (: rightAileron))
      (z3d:Arot -0.2 (: rudder)) ) )

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
         (z3d:Arot +0.01 (: elevator)) )
      ((lt0 (: ele))
         (inc (:: ele))
         (z3d:Arot -0.01 (: elevator)) ) )
   (cond
      ((gt0 (: ail))
         (dec (:: ail))
         (dec (:: rud))
         (z3d:Arot +0.01 (: leftAileron))
         (z3d:Arot +0.01 (: rightAileron))
         (z3d:Arot +0.01 (: rudder)) )
      ((lt0 (: ail))
         (inc (:: ail))
         (inc (:: rud))
         (z3d:Arot -0.01 (: leftAileron))
         (z3d:Arot -0.01 (: rightAileron))
         (z3d:Arot -0.01 (: rudder)) ) )
   (cond
      ((> (: thr) (: thrust))
         (inc (:: thrust)) )
      ((> (: thrust) (: thr))
         (dec (:: thrust)) ) )
   (if (> 20 (: thrust))
      (blade> This)
      (disk> This) )
   (unless (=0 (: thrust))
      (z3d:Xrot 0.2 (: propeller)) )
   (use (Touch VX VY VZ Body Taxi Stick A FX FY FZ DX DY DZ)
      (z3d:Rotate (: tx) 0 (: tz) (: body) NIL NIL 'Touch)
      (z3d:Rotate (: vx) (: vy) (: vz) (: body) 'VX 'VY 'VZ T)
      (setq
         Body (val (: body))
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
         (z3d:Yrot
            (>> 3 (- (: pitch) (get Body 6)))  # rot.a.z
            (: body) ) )
      (unless Stick
         (z3d:Yrot
            (+
               (*/ VX (+ (: ele) (: trim)) 80000)
               `(MUL VZ (: stab 2)) )
            (: body) )
         (if Taxi
            (prog
               (z3d:Zrot (*/ VX (: rud) 80000) (: body))
               (z3d:Xrot (get Body 9) (: body)) )  # rot.b.z
            (z3d:Xrot  # roll
               (+
                  (- (*/ VX (: ail) 80000) (/ VY 400))
                  (*/ (: thrust) (: torq) (: mass))
                  `(MUL (get Body 9) (: stab 1)) )  # rot.b.z
               (: body) )
            (z3d:Zrot
               (+
                  (*/ VX (: rud) 80000)
                  `(MUL VY (: stab 3)) )
               (: body) ) ) )

      # World system
      (z3d:Rotate FX FY FZ (: body) 'FX 'FY 'FZ)
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
            (blade> This) )
         (set (cddr Body) (- Touch))
         (=: vz 0) )

      # Translate
      (inc Body `(MUL (: vx) *DT))
      (inc (cdr Body) `(MUL (: vy) *DT))
      (inc (cddr Body) `(MUL (: vz) *DT))

      # Sound/Display
      (tone> *Scene
         (max 0
            (- 100
               (/ (dist (car Body) (cadr Body)) 40.0) ) )
         (cond
            ((=0 (: thrust)) 0)
            ((> 22 (: thrust)) 11)
            (T
               (doppler
                  (>> 1 (+ (: thrust) (/ VX 0.5)))
                  (car Body)
                  (cadr Body)
                  (: vx)
                  (: vy) ) ) ) )
      (unless (= *Thr (: thr))
         (thr> *Pilot (setq *Thr (: thr))) )
      (unless (= *Speed (setq A (*/ VX 3.6 `(* 1.0 1.0))))
         (speed> *Pilot (setq *Speed A)) )
      (unless (= *Climb (setq A (/ (: vz) 1.0)))
         (climb> *Pilot (setq *Climb A)) )
      (unless (= *Alt (setq A (/ (caddr Body) 1.0)))
         (alt> *Pilot (setq *Alt A)) ) ) )
