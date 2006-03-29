# 04feb06abu
# (c) Software Lab. Alexander Burger
# ./p dbg.l misc/uhr.l -go

(load "lib/http.l" "lib/html.l" "lib/gui2.l")

(de uhr ()
   (app)
   (html "Uhr"
      (<head> "Uhr")
      (setq *Uhr
         (form '(+Form) 240 80
            (quote
               (gui 'uhr '(+Mono +Label) "Zeit:" (stamp))
               (row
                  (gui '(+Button) "" "Start"
                     '(task -1000 1000
                        (set> (get *Uhr 'uhr) (stamp)) ) )
                  (gui '(+Button) "" "Stop" '(task -1000)) ) ) ) ) ) )

(de go ()
   (server 8080 "@uhr") )
