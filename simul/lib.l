# 25jun02abu
# (c) Software Lab. Alexander Burger

(setq *Scl 6)  # Keep in sync with `SCL' in "src/z3d.c"

(load "lib/simul.l")
(load "simul/rgb.l")

# Unity Matrix
(setq
   *UMat (1.0 0.0 0.0  0.0 1.0 0.0  0.0 0.0 1.0)
   PI    3.1415927
   PI/2  1.5707963 )

# Mirror in y-direction
(de y-mirror (Lst)
   (make
      (while (sym? (car Lst))
         (link (pop 'Lst)) )
      (link
         (pop 'Lst)     # pos-x
         (- (pop 'Lst)) # pos-y
         (pop 'Lst) )   # pos-z
      (mapc
         '((L)
            (link
               (if (sym? (car L))
                  (y-mirror L)
                  (make
                     (link (cadr L) (car L))
                     (when (sym? (car (setq L (cddr L))))
                        (link (pop 'L)) )
                     (while L
                        (link (pop 'L) (- (pop 'L)) (pop 'L)) ) ) ) ) )
         Lst ) ) )

# Create model
(de model (Lst)
   (let Obj This
      (while (sym? (cadr Lst))
         (setq Obj (get Obj (pop 'Lst))) )
      (unless Obj
         (quit "Can't attach (sub)model" (car Lst)) )
      (prog1
         (put Obj (pop 'Lst) (new T))
         (set @
            (make
               (link (pop 'Lst) (pop 'Lst) (pop 'Lst))
               (mapc link *UMat)
               (while Lst
                  (link
                     (if (and (caar Lst) (sym? (caar Lst)))
                        (model (pop 'Lst))
                        (pop 'Lst) ) ) ) ) ) ) ) )

# Duplicate position and orientation
(de placement (Sym)
   (prog1
      (new T)
      (set @
         (conc
            (head 12 (val Sym))
            (mapcan
               '((X)
                  (and
                     (sym? X)
                     (list (placement X)) ) )
               (nth (val Sym) 13) ) ) ) ) )

# Reset orientation
(de straight (Sym)
   (mapc
      '((V S) (set S V))
      *UMat
      (cdddr (val Sym)) ) )

# Movements
(de z3d:dx (X M)
   (touch M)
   (set (val M)
      (+ X (car (val M))) ) )

(de z3d:dy (Y M)
   (touch M)
   (set (cdr (val M))
      (+ Y (cadr (val M))) ) )

(de z3d:dz (Z M)
   (touch M)
   (set (cddr (val M))
      (+ Z (caddr (val M))) ) )


### 3D-Applet ###
(off *Z3dFields)

(class +Z3dField +Applet)
# foc yaw pitch x y z sky gnd snx sny snap

(dm T (DX DY F Dir X Y Z Sky Gnd)
   (super "Z3dField" "gl.jar" DX DY)
   (=: foc F)
   (=: yaw (car Dir))
   (=: pitch (cdr Dir))
   (=: x X)
   (=: y Y)
   (=: z Z)
   (=: sky Sky)
   (=: gnd Gnd) )

(dm start> ()
   (super)
   (task -200 0
      (mapc 'do> *Z3dFields) )
   (draw> (push '*Z3dFields This)) )

(dm draw> "Prg"
   (out *App
      (pr (: id) "draw")
      (z3d:Draw (: foc)
         (: yaw) (: pitch)
         (: x) (: y) (: z)
         (: sky) (: gnd)
         (: snx) (: sny) )
      (run "Prg")
      (=: snap (z3d:Draw)) ) )

(dm do> ())

(dm clk> ()
   (rd)     # m
   (rd)     # x
   (rd) )   # y

(dm mov> ()
   (if (bit? 2 (rd))  # ctrl
      (prog
         (=: snx (rd))
         (=: sny (rd))
         (draw> This) )
      (rd)
      (rd)
      (when (: snx)
         (=: snx (=: sny))
         (draw> This) ) ) )

# Key Navigation
(dm LE> ()
   (dec (:: yaw) 0.1)
   (draw> This) )

(dm UP> ()
   (inc (:: x) (*/ (ext:Cos (: yaw) 1.0) (: foc) 1000.0))
   (inc (:: y) (*/ (ext:Sin (: yaw) 1.0) (: foc) 1000.0))
   (draw> This) )

(dm RI> ()
   (inc (:: yaw) 0.1)
   (draw> This) )

(dm DN> ()
   (dec (:: x) (*/ (ext:Cos (: yaw) 1.0) (: foc) 1000.0))
   (dec (:: y) (*/ (ext:Sin (: yaw) 1.0) (: foc) 1000.0))
   (draw> This) )

# Pitch Control
(dm PGUP> ()
   (inc (:: pitch) 0.1)
   (draw> This) )

(dm PGDN> ()
   (dec (:: pitch) 0.1)
   (draw> This) )

# Defaults
(dm END> ()
   (beep> This) )

(dm BEG> ()
   (beep> This) )

(dm DEL> ()
   (beep> This) )

(dm INS> ()
   (beep> This) )


(dm stop> ()
   (super)
   (setq *Z3dFields (delq This *Z3dFields)) )

(dm text> (Lst)
   (out *App
      (pr (: id) "text" (length Lst))
      (mapc
         '((L) (pr (car L) (cadr L) (cddr L)))  # (x y . str)
         Lst ) ) )


### Animation Primitives ###
(de pause (N)
   (link (or N 1)) )

(de dx (X M)
   (link (list 'z3d:dx X (lit M))) )

(de dy (Y M)
   (link (list 'z3d:dy Y (lit M))) )

(de dz (Z M)
   (link (list 'z3d:dz Z (lit M))) )

(de xRot (A M)
   (link (list 'z3d:Xrot A (lit M))) )

(de yRot (A M)
   (link (list 'z3d:Yrot A (lit M))) )

(de zRot (A M)
   (link (list 'z3d:Zrot A (lit M))) )

(de aRot (A M)
   (link (list 'z3d:Arot A (lit M))) )

(de approach (M1 M2)
   (link
      (list
         'z3d:Approach
         '(car *Pet)
         (lit M1)
         (lit M2) ) ) )

# Modify A absolute
(de absA (N A . Prg)
   (setq A (/ A N))
   (link N (make (run Prg))) )

# Modify A relative
(de relA (N A . Prg)
   (setq A (dir> This (/ A N)))
   (link N (make (run Prg))) )


### Direction Prefix Classes ###
(class +Right)

(dm pol> (Lst)
   Lst )

(dm dir> (N)
   N )


(class +Left)

(dm pol> (Lst)
   (y-mirror Lst) )

(dm dir> (N)
   (- N) )


### Model Base Class ###
(class +Model +Entity)
# pet

(rel id     (+Key +Symbol))                     # Identifier
(rel x      (+Ref +Number))                     # Coordinates
(rel y      (+Ref +Number))
(rel z      (+Ref +Number))
(rel mdl    (+Symbol))                          # Model
(rel rst    (+Symbol))                          # Reset

(dm init> ())

(dm straight> ()
   (touch This)
   (straight (: mdl)) )

(dm reset> (N)
   (link N
      (make (approach (: mdl) (: rst))) ) )

(dm pet> (Prg)
   (=: pet (pet Prg (: pet))) )

(de pet? (M)
   (get M 'pet) )

(dm step> ()
   (=: pet (pex (: pet))) )
