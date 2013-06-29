# 30may13abu
# (c) Software Lab. Alexander Burger

# *Salt *Login *Users *Perms

# crypt(3) algorithm, e.g. (setq *Salt (16 . "$6$@1$"))
(de passwd (Str Salt)
   (if *Salt
      `(if (== 64 64)
         '(native "libcrypt.so" "crypt" 'S Str (or Salt (salt)))
         '(ext:Crypt Str (or Salt (salt))) )
      Str ) )

(de salt ()
   (text (cdr *Salt) (randpw (car *Salt))) )

(de randpw (Len)
   (make
      (in "/dev/urandom"
         (do Len
            (link
               (get
                  '`(mapcar char
                     (conc
                        (range 46 57)
                        (range 65 90)
                        (range 97 122) ) )
                  (inc (& 63 (rd 1))) ) ) ) ) ) )

(de auth (Nm Pw)
   (with (db 'nm '+User Nm)
      (and
         (: pw 0)
         (= @ (passwd Pw @))
         This ) ) )

### Login ###
(de login (Nm Pw)
   (ifn (setq *Login (auth Nm Pw))
      (msg *Pid " ? " Nm)
      (msg *Pid " * " (stamp) " " Nm)
      (tell 'hi *Pid Nm *Adr)
      (push1 '*Bye '(logout))
      (push1 '*Fork '(del '(logout) '*Bye))
      (timeout (setq *Timeout `(* 3600 1000))) )
   *Login )

(de logout ()
   (when *Login
      (rollback)
      (off *Login)
      (tell 'hi *Pid)
      (msg *Pid " / " (stamp))
      (timeout (setq *Timeout `(* 300 1000))) ) )

(de hi (Pid Nm Adr)
   (if (and (= Nm (get *Login 'nm)) (= Adr *Adr))
      (bye)
      (hi2 Pid Nm)
      (tell 'hi2 *Pid (get *Login 'nm)) ) )

(de hi2 (Pid Nm)
   (if2 Nm (lup *Users Pid)
      (con @ Nm)
      (idx '*Users (cons Pid Nm) T)
      (idx '*Users @ NIL) ) )


### Role ###
(class +Role +Entity)

(rel nm (+Need +Key +String))          # Role name
(rel perm (+List +Symbol))             # Permission list
(rel usr (+List +Joint) role (+User))  # Associated users


### User ###
(class +User +Entity)

(rel nm (+Need +Key +String))          # User name
(rel pw (+Swap +String))               # Password
(rel role (+Joint) usr (+Role))        # User role


### Permission management ###
(de permission Lst
   (while Lst
      (queue '*Perms (car Lst))
      (def (pop 'Lst) (pop 'Lst)) ) )

(de may Args
   (mmeq Args (get *Login 'role 'perm)) )

(de must Args
   (unless
      (if (cdr Args)
         (mmeq @ (get *Login 'role 'perm))
         *Login )
      (msg *Pid " No permission: " (car Args))
      (forbidden) ) )

### GUI ###
(de loginForm "Opt"
   (form NIL
      (htPrin "Opt")
      (<grid> 2
         ,"Name" (gui 'nm '(+Focus +Able +TextField) '(not *Login) 20)
         ,"Password" (gui 'pw '(+Able +PwField) '(not *Login) 20) )
      (--)
      (gui '(+Button) '(if *Login ,"logout" ,"login")
         '(cond
            (*Login (logout))
            ((login (val> (: home nm)) (val> (: home pw)))
               (clr> (: home pw)) )
            (T (error ,"Permission denied")) ) )
      (when *Login
         (<nbsp> 4)
         (<span> "bold green"
            (<big> (ht:Prin "'" (; *Login nm) ,"' logged in")) ) ) ) )

# vi:et:ts=3:sw=3
