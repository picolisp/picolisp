# 29jan03abu
# (c) Software Lab. Alexander Burger

(load "lib/xterm.l" "simul/lib.l")

(setq *Foc 750.0  *Yaw -2.25  *Pitch 0  *X 7.0  *Y 9.0  *Z  2.0)
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
(fkey *XtLeft
   (dec '*Yaw 0.1)
   (draw) )

(fkey *XtRight
   (inc '*Yaw 0.1)
   (draw) )

(fkey *XtPgDn
   (dec '*Pitch 0.05)
   (draw) )

(fkey *XtPgUp
   (inc '*Pitch 0.05)
   (draw) )


(de main ()
   (pool "db/fokker")
   (unless (get *DB 'mdl)
      (with *DB
         (=: mdl (model (load "simul/fokker.l"))) )
      (commit) ) )

(de go ()
   (rollback)
   (out (setq *Sock (listen (port 8080) 120000))
      (pr 400 300) )
   (draw)
   (task *Sock
      (in *Sock (setq *SX (rd)  *SY (rd)))
      (draw) ) )


(de draw ()
   (out *Sock
      (with *DB
         (z3d:Draw *Foc *Yaw *Pitch *X *Y *Z LightBlue DarkGreen *SX *SY)
         (z3d:Draw (: mdl))
         (setq *Snap (z3d:Draw)) ) ) )

(de tst (Flg)
   (if Flg
      (task -50 0
         (z3d:Xrot 0.1 (get *DB 'propeller))
         (draw) )
      (task -50) )
   Flg )
