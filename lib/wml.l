# 23apr01abu
# (c) Software Lab. Alexander Burger

(load "@lib/xml.l")

(de wml @
   (prinl "<?xml version=\"1.0\"?>")
   (prinl "<?xml-stylesheet href=\"wml.css\" type=\"text/css\" ?>")
   (prinl "<!DOCTYPE wml PUBLIC \"-//WAPFORUM//DTD WML 1.1//EN\" \"http://www.wapforum.org/DTD/wml_1.1.xml\">")
   (prinl "<wml>")
   (mapc xml (rest))
   (prinl "</wml>") )

(de card "Lst"
   (bind +Wml
      (quote (tag 'card T "Lst")) ) )

(de +Wml
   (tag ("Tag" "F" "Lst")
      (cons "Tag"
         (cons
            (and "F" (attr (pop '"Lst")))
            (mapcar eval "Lst") ) ) )
   (attr ("Lst")
      (make
         (while "Lst"
            (link (cons (pop '"Lst") (eval (pop '"Lst")))) ) ) )
   (p "Lst"
      (tag 'p NIL "Lst") )
   (b (S)
      (list 'b NIL S) )
   (br ()
      '(br) )
   (input "Lst"
      (tag 'input T  "Lst") )
   (anchor "Lst"
      (tag 'anchor NIL "Lst") )
   (go "Lst"
      (tag 'go T "Lst") )
   (setvar (Nm Val)
      (list 'setvar (list (cons 'name Nm) (cons 'value Val))) )
   (a (Url Str)
      (list 'a (list (cons 'href Url)) Str) )
   (obj (Obj . Lst)
      (and Obj
         (list 'a
            (list (cons 'href (wap> Obj)))
            (apply get Lst Obj) ) ) )
   (table "Lst"
      (cons 'table
         (cons (attr (car "Lst"))
            (make (run (cdr "Lst"))) ) ) )
   (row "Lst"
      (link
         (cons 'tr
            (cons NIL
               (mapcar
                  '(("L") (list 'td NIL (eval "L")))
                  "Lst" ) ) ) ) ) )
