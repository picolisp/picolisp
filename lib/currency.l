# 02jul02abu
# (c) Software Lab. Alexander Burger

(de oanda (Key)
   (client "www.oanda.com" 80
      (pack "convert/classic?value=1&expr=EUR&exch=" Key)
      (and
         (from "1 Euro (EUR) = ")
         (till " " T)
         (format @ 6) ) ) )

(de autoCurr ()
   (iter (tree 'key '+Currency)
      '((C)
         (when (and (get C 'auto) (oanda (get C 'key)))
            (dbSync)
            (put> C 'rate @)
            (put> C 'dat (date))
            (commit 'upd) ) ) ) )
