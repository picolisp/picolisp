# 29aug16abu
# (c) Software Lab. Alexander Burger

(allowed ("app/")
   "!work" "!stop" "@lib.css" "!psh" )

(scl 2)
(load
   "@lib/http.l" "@lib/xhtml.l" "@lib/form.l" "@lib/svg.l"
   "@lib/adm.l" )  # "@lib/boss.l"

(setq
   *Css '("@lib.css" "app/menu.css")
   *Pool "db/app/"
   *Blob "db/app/blob/"
   *Salt (16 . "$6$@1$") )

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
   ("Deutsch (DE)" "DE" . "de")
   ("Deutsch (CH)" "CH" . "ch")
   ("Español (AR)" "AR" . "ar")
   ("Español (ES)" "ES" . "es")
   ("λληνικά (GR)" "GR" . "gr")
   ("Norsk" "NO" . "no")
   ("Русский" "RU" . "ru")
   ("Svenska" "SE" . "sv")
   ("日本語" "JP" . "jp") )

# Entry point
(de main ()
   (call "mkdir" "-p" "db/app/" *Blob)
   (pool *Pool *Dbs)
   (unless (seq *DB)
      (load "app/init.l") ) )

(de go (Rpc)
   (when Rpc
      (task (port @)  # Set up query server in the background
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
      (forked) )
   (rollback)
   (retire 20)
   (server (or (format (sys "PORT")) 8080) "!work") )

# vi:et:ts=3:sw=3
