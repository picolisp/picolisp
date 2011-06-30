# 26may06abu
# (c) Software Lab. Alexander Burger

(de zahlwort (N)
   (cond
      ((not N))
      ((=0 N) "null")
      ((lt0 N) (pack "minus " (zahlw (- N))))
      (T (zahlw N)) ) )

(de zahlw (N Flg)
   (cond
      ((=0 N))
      ((= 1 N) (if Flg "ein" "eins"))
      ((= 2 N) "zwei")
      ((= 3 N) "drei")
      ((= 4 N) "vier")
      ((= 5 N) "fünf")
      ((= 6 N) "sechs")
      ((= 7 N) "sieben")
      ((= 8 N) "acht")
      ((= 9 N) "neun")
      ((= 10 N) "zehn")
      ((= 11 N) "elf")
      ((= 12 N) "zwölf")
      ((= 17 N) "siebzehn")
      ((> 20 N)
         (pack (zahlw (% N 10) T) "zehn") )
      ((> 100 N)
         (pack
            (unless (=0 (% N 10))
               (pack (zahlw (% N 10) T) "und") )
            (get
               (quote
                  "zehn" "zwanzig" "dreissig" "vierzig" "fünfzig"
                  "sechzig" "siebzig" "achtzig" "neunzig" )
               (/ N 10) ) ) )
      ((> 1000 N)
         (pack
            (zahlw (/ N 100) T)
            "hundert"
            (zahlw (% N 100)) ) )
      ((> 1000000 N)
         (pack
            (zahlw (/ N 1000) T)
            "tausend"
            (zahlw (% N 1000)) ) )
      ((> 2000000 N)
         (pack "einemillion" (zahlw (% N 1000000))) )
      ((> 1000000000000 N)
         (pack
            (zahlw (/ N 1000000) T)
            "millionen"
            (zahlw (% N 1000000)) ) )
      (T "RIESIG") ) )
