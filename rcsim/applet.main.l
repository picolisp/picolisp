# 27feb07abu
# (c) Software Lab. Alexander Burger

# *Panel *Rate *Sound *Tone

(allowed ("loc/help/")
   *PW "@rcsim" "favicon.ico" "lib/clrlog.l" "@psh" )

(load "lib/http.l" "lib/html.l")
(load "simul/gui.l")
(load "rcsim/lib.l")
(load "lib/heartbeat.l")


(de main ()
   (setq
      *Pilot (new '(+Pilot))
      *Model (new '(+Model))
      *Rate (list 0 0) )
   (push '*Bye
      '(unless (=0 (cadr *Rate))
         (prin (format (*/ (cadr *Rate) (car *Rate)) 2) " s  ") ) ) )

(de go ()
   (server 8080 "@rcsim") )

(de rcsim ()
   (and (app) (heartbeat "rcsim"))
   (html "RC-Sim"
      (<center>
         (setq *Scene (form '(+RcField) 600 400))
         "<br>"
         (setq
            *Panel (form '(+Form) 600 150
               (quote
                  (gui 'msg '(+Skip +Lock +Mono +TextField) "" -72 -5)
                  (----)
                  (row
                     (gui 'thr '(+Skip +Lock +NumField) "Throttle [%]" 5)
                     (gui 'speed '(+Skip +Lock +NumField) "Speed [km/h]" 5)
                     (gui 'frm '(+Skip +Lock +FixField) 2 "Rate [s]" 5) )
                  (row
                     (gui '(+Var +Checkbox) '*Sound "Sound")
                     (gui 'climb '(+Skip +Lock +NumField) "Climb [m/s]" 5)
                     (gui 'alt '(+Skip +Lock +NumField) "Altitude [m]" 5) ) ) ) )
         "<br>"
         (<href> "(c) Software Lab." "http://www.software-lab.de") ) ) )

# Pilot
(class +Pilot)

(dm thr> (N)
   (set> (get *Panel 'thr) N) )

(dm speed> (N)
   (set> (get *Panel 'speed) N) )

(dm climb> (N)
   (set> (get *Panel 'climb) N) )

(dm alt> (N)
   (set> (get *Panel 'alt) N) )

(dm rate> (N)
   (inc *Rate)
   (inc (cdr *Rate) N)
   (set> (get *Panel 'frm) N) )


# Scene
(class +RcField +Z3dField)
# env

(dm T (DX DY)
   (load "rcsim/env.l")
   (super DX DY 8000.0 NIL  0 0 *Tower  LightBlue DarkGreen ) )

(dm start> ()
   (super)
   (wait NIL (get *Panel 'msg))
   (start)
   (nxt> This) )

(dm stop> ()
   (stop)
   (super) )

(dm foc> ()
   (when (get *Panel 'msg)
      (set> @
         "HOME:      Full throttle                DOWN:  Elevator up^J\
          PAGE DOWN: Decrease throttle            UP:    Elevator down^J\
          PAGE UP:   Increase throttle            LEFT:  Aileron/rudder left^J\
          END:       Engine off                   RIGHT: Aileron/rudder right^J\
          INS:       Zoom in                      DEL:   Zoom out" ) ) )

(dm nxt> ()
   (when (get *Panel 'msg)
      (set> @
         "^J   Click on the picture for keybard focus" ) ) )

(dm sim> ())

(dm draw> ()
   (dir> This (dir> *Model))
   (super
      (z3d:Draw (get *Model 'body))
      (mapc z3d:Draw (: env)) ) )

(dm ok> ()
   (draw) )

(dm tone> (A F)
   (unless (= *Tone (setq F (if *Sound (>> 1 F) 0)))
      (super A (setq *Tone F)) ) )

# Key Controls
(dm INS> ()
   (when (> 32000.0 (: foc))
      (=: foc (>> -1 (: foc))) ) )

(dm DEL> ()
   (when (> (: foc) 2000.0)
      (=: foc (>> 1 (: foc))) ) )

(dm UP> ()
   (down> *Model) )

(dm DN> ()
   (up> *Model) )

(dm LE> ()
   (left> *Model) )

(dm RI> ()
   (right> *Model) )

(dm BEG> ()
   (throt> *Model T) )

(dm PGDN> ()
   (throt> *Model -1) )

(dm PGUP> ()
   (throt> *Model +1) )

(dm END> ()
   (throt> *Model) )
