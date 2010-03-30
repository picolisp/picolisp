# 18mar10abu
# (c) Software Lab. Alexander Burger

(scl 6)  # Keep in sync with `SCL' in "src/z3d.c"

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
      (for L Lst
         (link
            (if (sym? (car L))
               (y-mirror L)
               (make
                  (link (cadr L) (car L))
                  (when (sym? (car (setq L (cddr L))))
                     (link (pop 'L)) )
                  (while L
                     (link (pop 'L) (- (pop 'L)) (pop 'L)) ) ) ) ) ) ) )

# Create model
(de model (Obj Lst)
   (let X Obj
      (while (sym? (cadr Lst))
         (setq X (get X (pop 'Lst))) )
      (unless X
         (quit "Can't attach (sub)model" (car Lst)) )
      (prog1
         (put X (pop 'Lst) (new (ext? Obj)))
         (set @
            (make
               (link (pop 'Lst) (pop 'Lst) (pop 'Lst))
               (mapc link *UMat)
               (for M Lst
                  (link
                     (if (and (car M) (sym? (car M)))
                        (model Obj M)
                        M ) ) ) ) ) ) ) )

# Duplicate position and orientation
(de placement (Sym)
   (prog1
      (new (ext? Sym))
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
(de straight (M)
   (touch M)
   (map
      '((V L) (set L (car V)))
      *UMat
      (cdddr (val M)) ) )

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
