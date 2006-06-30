# 30jun06abu
# (c) Software Lab. Alexander Burger

# *Init *Accu *Stack

(load "lib/http.l" "lib/xhtml.l" "lib/form.l")

# Calculator logic
(de digit (N)
   (when *Init (zero *Accu) (off *Init))
   (setq *Accu (+ N (* 10 *Accu))) )

(de calc ()
   (let (Foo (caar *Stack)  Val (cddr (pop '*Stack)))
      (setq *Accu
         (if (and (== '/ Foo) (=0 *Accu))
            (alert "Div / 0")
            (Foo Val *Accu) ) ) ) )

(de operand (Foo Prio)
   (when (>= (cadar *Stack) Prio) (calc))
   (push '*Stack (cons Foo (cons Prio *Accu)))
   (on *Init) )

(de finish ()
   (while *Stack (calc))
   (on *Init) )

# Calculator GUI
(de calculator ()
   (app)
   (action
      (html 0 "Bignum Calculator" "lib.css" NIL
         (<h2> NIL "Bignum Calculator")
         (form NIL
            (<br> (gui '(+Var +NumField) '*Accu 60))
            (<grid> 4
               (gui '(+Button) "±" '(setq *Accu (- *Accu)))
               (gui '(+Able +Button) '(ge0 *Accu) (char 8730) " "
                  '(setq *Accu (sqrt *Accu)) )
               (gui '(+Button) "\^" '(operand '** 3))
               (gui '(+Button) "/" '(operand '/ 2))

               (gui '(+Button) "7" '(digit 7))
               (gui '(+Button) "8" '(digit 8))
               (gui '(+Button) "9" '(digit 9))
               (gui '(+Button) "*" '(operand '* 2))

               (gui '(+Button) "4" '(digit 4))
               (gui '(+Button) "5" '(digit 5))
               (gui '(+Button) "6" '(digit 6))
               (gui '(+Button) "-" '(operand '- 1))

               (gui '(+Button) "1" '(digit 1))
               (gui '(+Button) "2" '(digit 2))
               (gui '(+Button) "3" '(digit 3))
               (gui '(+Button) "+" '(operand '+ 1))

               (gui '(+Button) "0" '(digit 0))
               (gui '(+Button) "C" '(zero *Accu))
               (gui '(+Button) "A" '(main))
               (gui '(+Button) "=" '(finish)) ) ) ) ) )

# Initialize
(de main ()
   (on *Init)
   (zero *Accu)
   (off *Stack) )

# Start server
(de go ()
   (server 8080 "@calculator") )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
