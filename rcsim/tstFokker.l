# 05jul04abu
# (c) Software Lab. Alexander Burger

# *Model *Foc *Yaw *Pitch *X *Y *Z *Snap *SX *SY

(load "simul/lib.l" "lib/xterm.l")

(setq *Foc 750.0  *Yaw -2.25  *Pitch 0  *X 7.0  *Y 9.0  *Z 2.0)
(off *Snap *SX *SY)

# Move
(fkey *XtUp
   (inc '*X (*/ (ext:Cos *Yaw 1.0) *Foc 1000.0))
   (inc '*Y (*/ (ext:Sin *Yaw 1.0) *Foc 1000.0))
   (draw) )

(fkey *XtDown
   (dec '*X (*/ (ext:Cos *Yaw 1.0) *Foc 1000.0))
   (dec '*Y (*/ (ext:Sin *Yaw 1.0) *Foc 1000.0))
   (draw) )

(fkey *XtHome
   (inc '*Z 1.0)
   (draw) )

(fkey *XtEnd
   (dec '*Z 1.0)
   (draw) )


# Turn
(fkey *XtRight
   (inc '*Yaw 0.1)
   (draw) )

(fkey *XtLeft
   (dec '*Yaw 0.1)
   (draw) )

(fkey *XtPgUp
   (inc '*Pitch 0.05)
   (draw) )

(fkey *XtPgDn
   (dec '*Pitch 0.05)
   (draw) )


(de blade ()
   (with *Model
      (set (: propeller) (val (: blade))) ) )

(de disk ()
   (with *Model
      (set (: propeller) (val (: disk))) ) )


(de main ()
   (with (setq *Model (new))
      (load "rcsim/fokker.l")
      (z3d:Yrot 0.26 (: body))
      (z3d:dz -0.30 (: body)) )
   (blade) )

(de go ()
   (out (setq *Sock (listen (port 8080) 120000))
      (pr 400 300) )
   (draw)
   (task *Sock
      (in *Sock
         (case (rd)
            (`(char "o")  # ok
               )
            (`(char "c")  # clk
               (setq *SX (rd)  *SY (rd))
               (draw) ) ) ) ) )


(de draw ()
   (out *Sock
      (z3d:Draw *Foc *Yaw *Pitch *X *Y *Z LightBlue DarkGreen *SX *SY)
      (z3d:Draw (get *Model 'body))
      (setq *Snap (z3d:Draw)) ) )

(de tst (Flg)
   (if Flg
      (task -100 0
         (z3d:Xrot 0.1 (get *Model 'propeller))
         (draw) )
      (task -100) )
   Flg )
