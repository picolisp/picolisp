# 24mar07abu
# (c) Software Lab. Alexander Burger

(allowed ("app/" "img/")
   "@start" "@stop" "favicon.ico" "lib.css" "@psh" )

(load "lib/http.l" "lib/xhtml.l" "lib/form.l" "lib/ps.l" "lib/adm.l")
(load "app/er.l" "app/lib.l" "app/gui.l")

(setq
   *Scl 2
   *Css "lib.css"
   *Blob "blob/app/" )

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
   (call 'mkdir "-p" "db/app/" "blob/app/")
   (pool "db/app/" *Dbs)
   (unless (seq *DB)
      (load "app/init.l") ) )

(de go ()
   (server 8080 "@start") )
