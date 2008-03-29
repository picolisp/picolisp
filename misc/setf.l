# 31jan08abu
# (c) Software Lab. Alexander Burger

# 'setf' is the most perverse concept ever introduced into Lisp
(de setf "Args"
   (let "P" (car "Args")
      (set
         (if (atom "P")
            "P"
            (let (: ::  get prop  car prog  cadr cdr  caddr cadr  cadddr caddr)
               (eval "P") ) )
         (eval (cadr "Args")) ) ) )

### Test ###
(test 7
   (use A
      (setf A 7)
      A ) )

(test (7 2 3)
   (let L (1 2 3)
      (setf (car L) 7)
      L ) )

(test (1 7 3)
   (let L (1 2 3)
      (setf (cadr L) 7)
      L ) )

(test 7
   (put 'A 'a 1)
   (setf (get 'A 'a) 7)
   (get 'A 'a) )

(test 7
   (put 'A 'a 1)
   (with 'A
      (setf (: a) 7)
      (: a) ) )

# But also:
(undef 'foo)
(de foo (X)
   (cadr X) )

(test (1 7 3)
   (let L (1 2 3) (setf (foo L) 7) L) )

# vi:et:ts=3:sw=3
