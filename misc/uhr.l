# 07feb02abu
# (c) Software Lab. Alexander Burger

(app)

(html "Uhr"
   (<head> "Uhr")
   (setq *Uhr
      (new '(+Form) 240 80
         (quote
            (gui 'uhr '(+Mono +Label) "Zeit:" (stamp))
            (row
               (gui '(+Button) "" "Start"
                  '(task -1000 1000
                     (set> (get *Uhr 'uhr) (stamp)) ) )
               (gui '(+Button) "" "Stop" '(task -1000)) ) ) ) ) )
