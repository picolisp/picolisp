# 14sep04abu
# (c) Software Lab. Alexander Burger

(allow "java/gl.jar")

(load "lib/gui.l")

### 3D-Applet ###
(class +Z3dField +Applet)
# foc yaw pitch x y z sky gnd snx sny snap

(dm T (DX DY F Dir X Y Z Sky Gnd)
   (super "Z3dField" '("java/gl.jar" "java/pico.jar") DX DY)
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
   (draw> This) )

(dm foc> ())

(dm nxt> ())

(dm dir> (Dir)
   (=: yaw (car Dir))
   (=: pitch (cdr Dir)) )

(dm spot> (X Y Z)
   (dir> This (z3d:Spot X Y Z (: x) (: y) (: z))) )

(dm draw> "Prg"
   (when (: app)
      (out @
         (pr "draw")
         (z3d:Draw (: foc)
            (: yaw) (: pitch)
            (: x) (: y) (: z)
            (: sky) (: gnd)
            (: snx) (: sny) )
         (run "Prg")
         (=: snap (z3d:Draw)) ) ) )

(dm ok> ())

(dm clk> ()
   (rd)     # m
   (rd)     # x
   (rd) )   # y

(dm mov> ()
   (if (bit? 2 (rd))  # ctrl
      (prog
         (=: snx (rd))
         (=: sny (rd)) )
      (rd)
      (rd)
      (when (: snx)
         (=: snx (=: sny)) ) ) )

# Key Navigation
(dm LE> ()
   (dec (:: yaw) 0.1) )

(dm UP> ()
   (inc (:: x) (*/ (ext:Cos (: yaw) 1.0) (: foc) 1000.0))
   (inc (:: y) (*/ (ext:Sin (: yaw) 1.0) (: foc) 1000.0)) )

(dm RI> ()
   (inc (:: yaw) 0.1) )

(dm DN> ()
   (dec (:: x) (*/ (ext:Cos (: yaw) 1.0) (: foc) 1000.0))
   (dec (:: y) (*/ (ext:Sin (: yaw) 1.0) (: foc) 1000.0)) )

# Pitch Control
(dm PGUP> ()
   (inc (:: pitch) 0.1) )

(dm PGDN> ()
   (dec (:: pitch) 0.1) )

# Defaults
(dm END> ()
   (beep> This) )

(dm BEG> ()
   (beep> This) )

(dm DEL> ()
   (beep> This) )

(dm INS> ()
   (beep> This) )


(dm tone> (A F)
   (when (: app)
      (out @ (pr "tone" A F)) ) )

(dm text> (Lst)
   (when (: app)
      (out @
         (pr "text" (length Lst))
         (for L Lst
            (pr (car L) (cadr L) (cddr L)) ) ) ) )  # (x y . str)
