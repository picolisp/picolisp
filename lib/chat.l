# 10jul04abu
# (c) Software Lab. Alexander Burger

# *Cts *Room

(de enter (Usr)
   (and (get *Cts 'cts) (add> @ Usr)) )

(de leave (Usr)
   (and (get *Cts 'cts) (del> @ Usr)) )

(de hello (Usr)
   (and Usr (enter Usr))
   (when (get *Cts 'cts)
      (tell 'enter (lit *Login)) ) )

(de speak (Room Str)
   (feed> (get *Cts 'log 'log) 400 (pack "(" Str ")"))
   (tell 'spoke (lit *Login) Room Str) )

(de spoke (Usr Room Str)
   (and
      *Cts
      (== Room *Room)
      (feed> (get *Cts 'log 'log) 400
         (pack
            (with Usr (or (: name) (: nm)))
            "> "
            Str ) ) ) )


(class +MsgForm +Form)

(dm start> ()
   (super)
   (add> (wait NIL (get *Cts 'cts)) *Login)
   (tell 'hello (lit *Login)) )

(dm stop> ()
   (tell 'leave (lit *Login))
   (super) )

(dm ret> ()
   (when (val> (: msg))
      (speak *Room @) )
   (clr> (: msg)) )


(class +CtsField +Skip +Lock +TextField)
# lst

(dm set> (Lst)
   (super
      (pack
         (maplist
            '((L)
               (with (car L)
                  (pack
                     (and (== This *Login) "(")
                     (or (: name) (: nm))
                     (and (== This *Login) ")")
                     (and (cdr L) "^J") ) ) )
            (=: lst Lst) ) ) ) )

(dm add> (Usr)
   (unless (memq Usr (: lst))
      (set> This (cons Usr (: lst))) ) )

(dm del> (Usr)
   (set> This (delq Usr (: lst))) )
