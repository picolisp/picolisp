# 24nov16abu
# (c) Software Lab. Alexander Burger

# *Init *Accu *Stack

(allowed NIL "!calculator" "@lib.css")
(load "@lib/http.l" "@lib/xhtml.l" "@lib/form.l")

# Calculator logic
(de digit (N)
   (when *Init (zero *Accu) (off *Init))
   (setq *Accu (+ N (* 10 *Accu))) )

(de calc ()
   (let (Fun (caar *Stack)  Val (cddr (++ *Stack)))
      (setq *Accu
         (if (and (== '/ Fun) (=0 *Accu))
            (note "Div / 0")
            (Fun Val *Accu) ) ) ) )

(de operand (Fun Prio)
   (when (>= (cadar *Stack) Prio) (calc))
   (push '*Stack (cons Fun Prio *Accu))
   (on *Init) )

(de finish ()
   (while *Stack (calc))
   (on *Init) )

# Calculator GUI
(de calculator ()
   (app)
   (action
      (html 0 "Bignum Calculator" "@lib.css" NIL
         (<h2> NIL "Bignum Calculator")
         (form NIL
            (<br> (gui '(+Var +NumField) '*Accu 60))
            (<grid> 4
               (gui '(+JS +Button) "±" '(setq *Accu (- *Accu)))
               (gui '(+Able +JS +Button) '(ge0 *Accu) (char 8730)
                  '(setq *Accu (sqrt *Accu)) )
               (gui '(+JS +Button) "\^" '(operand '** 3))
               (gui '(+JS +Button) "/" '(operand '/ 2))

               (gui '(+JS +Button) "7" '(digit 7))
               (gui '(+JS +Button) "8" '(digit 8))
               (gui '(+JS +Button) "9" '(digit 9))
               (gui '(+JS +Button) "*" '(operand '* 2))

               (gui '(+JS +Button) "4" '(digit 4))
               (gui '(+JS +Button) "5" '(digit 5))
               (gui '(+JS +Button) "6" '(digit 6))
               (gui '(+JS +Button) "-" '(operand '- 1))

               (gui '(+JS +Button) "1" '(digit 1))
               (gui '(+JS +Button) "2" '(digit 2))
               (gui '(+JS +Button) "3" '(digit 3))
               (gui '(+JS +Button) "+" '(operand '+ 1))

               (gui '(+JS +Button) "0" '(digit 0))
               (gui '(+JS +Button) "C" '(zero *Accu))
               (gui '(+JS +Button) "A" '(main))
               (gui '(+JS +Button) "=" '(finish)) ) ) ) ) )

# Initialize
(de main ()
   (on *Init)
   (zero *Accu)
   (off *Stack) )

# Start server
(de go ()
   (server 8080 "!calculator") )
