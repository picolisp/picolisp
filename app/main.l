# 15nov10abu
# (c) Software Lab. Alexander Burger

(allowed ("app/" "img/")
   "@start" "@stop" "favicon.ico" "lib.css" "@psh" )

(load "lib/http.l" "lib/xhtml.l" "lib/form.l" "lib/ps.l" "lib/adm.l")

(setq
   *Scl 2
   *Css "lib.css"
   *Blob "blob/app/" )

(load "app/er.l" "app/lib.l" "app/gui.l")

(permission
   Customer    ,"Customer"
   Item        ,"Item"
   Order       ,"Order"
   Report      ,"Report"
   RoleAdmin   ,"Role Administration"
   UserAdmin   ,"User Administration"
   Password    ,"Password"
   Delete      ,"Delete" )

(de *Locales
   ("English" NIL)
   ("English (US)" "US")
   ("English (UK)" "UK")
   ("Español (AR)" "AR" . "ar")
   ("Español (ES)" "ES" . "es")
   ("Deutsch (DE)" "DE" . "de")
   ("Deutsch (CH)" "CH" . "ch")
   ("Norsk" "NO" . "no")
   ("Русский" "RU" . "ru")
   ("日本語" "JP" . "jp") )

# Entry point
(de main ()
   (call 'mkdir "-p" "db/app/" *Blob)
   (pool "db/app/" *Dbs)
   (unless (seq *DB)
      (load "app/init.l") ) )

(de go ()
   (pw 12)
   (task (port 4040)  # Set up query server in the background
      (let? Sock (accept @)
         (unless (fork)  # Child process
            (in Sock
               (while (rd)
                  (sync)
                  (tell)
                  (out Sock
                     (pr (eval @)) ) ) )
            (bye) )
         (close Sock) ) )
   (forked)
   (rollback)
   (server 8080 "@start") )

# vi:et:ts=3:sw=3
