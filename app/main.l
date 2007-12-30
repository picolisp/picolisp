# 24oct07abu
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

# Entry point
(de main ()
   (call 'mkdir "-p" "db/app/" *Blob)
   (pool "db/app/" *Dbs)
   (unless (seq *DB)
      (load "app/init.l") ) )

(de go ()
   (pw 12)
   (rollback)
   (server 8080 "@start") )

# vi:et:ts=3:sw=3
