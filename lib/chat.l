# 25jun02abu
# (c) Software Lab. Alexander Burger

# *Cts

(de enter (Usr)
   (and (get *Cts 'cts) (add> @ Usr)) )

(de leave (Usr)
   (and (get *Cts 'cts) (del> @ Usr)) )

(de hello (Usr)
   (and Usr (enter Usr))
   (tell 'enter (lit *Login)) )

(de speak (Str)
   (feed> (get *Cts 'log 'log) 400 (pack "(" Str ")"))
   (tell 'spoke (lit *Login) Str) )

(de spoke (Usr Str)
   (when *Cts
      (feed> (get *Cts 'log 'log) 400
         (pack
            (with Usr (or (: name) (: nm)))
            "> "
            Str ) ) ) )


(class +MsgForm +Form)

(dm start> ()
   (super)
   (wait NIL (get *Cts 'cts))
   (tell 'hello (lit *Login)) )

(dm stop> ()
   (tell 'leave (lit *Login))
   (super) )

(dm ret> ()
   (when (val> (: msg))
      (speak @) )
   (clr> (: msg)) )


(class +CtsField +Skip +Lock +TextField)
# lst

(dm set> (Lst)
   (super
      (pack
         (maplist
            '((L)
               (let (Usr (car L)  Nm (with Usr (or (: name) (: nm))))
                  (pack
                     (and (== Usr *Login) "(")
                     Nm
                     (and (== Usr *Login) ")")
                     (and (cdr L) "^J") ) ) )
            (=: lst Lst) ) ) ) )

(dm add> (Usr)
   (unless (memq Usr (: lst))
      (set> This (cons Usr (: lst))) ) )

(dm del> (Usr)
   (set> This (delq Usr (: lst))) )
