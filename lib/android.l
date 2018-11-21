# 21nov18abu
# (c) Software Lab. Alexander Burger

(ifn (info "UUID")
   (off *Uuid)
   (setq *Uuid (in "UUID" (line T)))
   (for F '("JAVA" "LISP" "BOSS")
      (native "@" "unlink" 'I F)
      (native "@" "mkfifo" 'I F `(oct "600")) )
   (hear (open "BOSS")) )

(symbols 'android 'pico)

# SSL
(sys "LD_LIBRARY_PATH" "lib")
(sys "SSL_CERT_FILE" "tls/cert.pem")

# (boss 'sym ['any ..])
(local) boss
(de boss @
   (out "BOSS" (pr (rest))) )

# Android Context
(local) CONTEXT
(de CONTEXT . {OOOO40000000000})

# Java I/O
# (java "cls" 'T ['any ..]) -> obj         New object
# (java 'obj ['n] 'msg ['any ..]) -> any   Send message to object
# (java 'obj "fld" ["fld" ..]) -> any      Value of object field
# (java "cls" ['n] 'msg ['any ..]) -> any  Call method in class
# (java "cls" "fld" ["fld" ..]) -> any     Value of class field
# (java T "cls" ["cls" ..]) -> obj         Define interface
# (java 'obj) -> [lst ..]                  Reflect object
# (java "cls") -> cls                      Get class
(local) [java1 java *Java *Lisp null]
(de java1 ()
   (unless *Java
      (setq *Java (open "JAVA")  *Lisp (open "LISP"))
      (task *Lisp
         (ext 65535
            (in *Lisp
               (prog1
                  (if (get (rd) (rd))
                     (apply @ (rd))
                     (rd)
                     NIL )
                  (out *Java (pr T @)) ) ) ) )
      (forked)
      (queue '*Ext (cons 65535 java)) ) )

(de java @
   (ext 65535
      (out *Java (pr NIL (rest)))
      (in *Lisp
         (for (X (rd) X (rd))
            (and (=0 X) (quit (rd)))  # 0: Exception
            (prog1                    # Callback
               (if (get X (rd))
                  (apply @ (rd))
                  (rd)
                  NIL )
               (out *Java (pr T @)) ) )
         (rd) ) ) )

# Android device ID
(local) [dev getString getContentResolver]
(de dev ()
   (java "android.provider.Settings$Secure" 'getString
      (java CONTEXT 'getContentResolver)
      "android_id" ) )

# Push-Load
(local) [loadTxt loadData loadUrl]
(de loadTxt @
   (java (; CONTEXT GUI) 'runOnUiThread
      (java (; CONTEXT GUI PilView) 0 'loadData
         (pack "<html><body>" (pass pack) "</body></html>")
         "text/html; charset=utf-8"
         'null ) ) )

(de loadUrl @
   (java (; CONTEXT GUI) 'runOnUiThread
      (java (; CONTEXT GUI PilView) 0 'loadUrl (pass pack)) ) )

# Clear WebView history and cache
(local) [clearHistory clearCache]
(de clearHistory ()
   (java CONTEXT 'clearHistory) )

(de clearCache ()
   (java (; CONTEXT GUI) 'runOnUiThread
      (java (; CONTEXT GUI PilView) 0 'clearCache T) ) )

# Wake lock
(local) [wake *Wake getSystemService newWakeLock acquire release]
(de wake @
   (default *Wake
      (java
         (java CONTEXT 'getSystemService "power")  # PowerManager
         'newWakeLock 1 "PilWake" ) )              # PowerManager.WakeLock
   (when (args)  # (wake 'flg)
      (java *Wake (if (next) 'acquire 'release)) ) )

# Check if WIFI is active
(local) [getActiveNetworkInfo getType]
(de wifi? ()
   (and
      (java
         (java CONTEXT 'getSystemService "connectivity")  # ConnectivityManager
         'getActiveNetworkInfo )  # NetworkInfo
      (=1 (java @ 'getType)) ) )  # onnectivityManager.TYPE_WIFI

# Generate file content URI
(local) [fileUri getUriForFile getPackageName]
(de fileUri (File)
   (java "android.support.v4.content.FileProvider" 'getUriForFile
      CONTEXT
      (pack (java CONTEXT 'getPackageName) ".fileprovider")
      (java "java.io.File" T File) ) )

# Update APK
(local) [update? getInt]
(de update? ()
   (gt0  # (java (java CONTEXT 'getPackageManager) 'canRequestPackageInstalls)
      (java "android.provider.Settings$Secure" 'getInt
         (java CONTEXT 'getContentResolver) "install_non_market_apps" ) ) )

(local) [update startActivity setFlags setData fromFile]
(de update (File)
   (java (; CONTEXT GUI) 'startActivity
      (prog1
         (java "android.content.Intent" T "android.intent.action.INSTALL_PACKAGE")
         (java @ 'setFlags 1)  # Intent.FLAG_GRANT_READ_URI_PERMISSION
         (java @ 'setData (fileUri File)) ) ) )

# Toast
(local) toast
(de toast (X . @)
   (java CONTEXT 'toast (pass pack X))
   X )

# Notification
(local) [
   notify cancel setSmallIcon setContentTitle setContentText setAutoCancel
   setLights setAction putExtra setContentIntent getActivity build ]
(de notify (Id Ttl Msg File)
   (let N (java CONTEXT 'getSystemService "notification")  # NotificationManager
      (ifn Ttl
         (java N 'cancel Id)
         (let B (java "android.support.v4.app.NotificationCompat$Builder" T CONTEXT)
            (java B 'setSmallIcon (java "de.software_lab.pilbox.R$drawable" "notify"))
            (java B 'setContentTitle Ttl)
            (java B 'setContentText Msg)
            (java B 'setAutoCancel T)
            (java B 'setLights `(hex "FFFFFF") 500 500)
            (let Intent (java "android.content.Intent" T CONTEXT (java "de.software_lab.pilbox.PilBoxActivity"))  # Activity class
               (java Intent 'setFlags `(hex "24000000"))  # FLAG_ACTIVITY_SINGLE_TOP | FLAG_ACTIVITY_NEW_TASK
               (when File
                  (java Intent 'setAction "RPC")
                  (java Intent 'putExtra "LOAD" File) )
               (java B 'setContentIntent
                  (java "android.app.PendingIntent" 'getActivity
                     CONTEXT 0 Intent `(hex "18000000") ) ) )  # FLAG_ACTIVITY_NEW_TASK | FLAG_UPDATE_CURRENT
            (prog1
               (java B 'build)  # Notification
               (java N 'notify Id @) ) ) ) ) )

# Service foreground state
(local) [startForeground stopForeground]
(de startForeground (Ttl Msg)
   (java CONTEXT 'startForeground 1
      (notify 1 Ttl Msg) ) )

(de stopForeground ()
   (java CONTEXT 'stopForeground T) )

# Start Activity for a result
(local) [
   startActivityForResult *ResultProxy *ProxyResults resolveActivity
   getPackageManager setResultProxy good bad ]
(de startActivityForResult (Fun Action . @)
   (let Intent (java "android.content.Intent" T Action)
      (when (java Intent 'resolveActivity (java CONTEXT 'getPackageManager))
         (while (args)
            (let S (next)
               (if (str? S)
                  (java Intent 'putExtra S (next))
                  (java Intent S (next) (next)) ) ) )
         (unless *ResultProxy
            (setq *ResultProxy (java T "de.software_lab.pilbox.ResultProxy"))
            (def 'good *ResultProxy
               '((Req Intent)
                  (when (asoq Req *ProxyResults)
                     (del @ '*ProxyResults)
                     ((cdr @) Intent) ) ) )
            (def 'bad *ResultProxy
               '((Req Res)
                  (del (asoq Req *ProxyResults) '*ProxyResults) ) ) )
         (let Req (inc (0))
            (push '*ProxyResults (cons Req Fun))
            (java CONTEXT 'setResultProxy *ResultProxy)
            (java (; CONTEXT GUI) 'startActivityForResult Intent Req) ) ) ) )

# GPS access
(local) checkSelfPermission
(de location? ()
   (=0
      (java "android.support.v4.content.ContextCompat"
         'checkSelfPermission CONTEXT "android.permission.ACCESS_FINE_LOCATION" ) ) )

(local) [
   gps *LocMan *LocLsn onLocationChanged onProviderDisabled onProviderEnabled
   onStatusChanged requestLocationUpdates isProviderEnabled getLastKnownLocation
   getLatitude getLongitude ]
(de gps ()
   (unless *LocMan
      (setq
         *LocMan (java CONTEXT 'getSystemService "location")
         *LocLsn (java T "android.location.LocationListener") )
      ## (def 'onLocationChanged *LocLsn
      ##    '((Loc)) )
      ## (def 'onProviderDisabled *LocLsn
      ##    '((Prov)) )
      ## (def 'onProviderEnabled *LocLsn
      ##    '((Prov)) )
      ## (def 'onStatusChanged *LocLsn
      ##    '((Prov Stat Extras)) )
      (java *LocMan 'requestLocationUpdates "network" '(L . 10000) (-3 . 100) *LocLsn)
      (java *LocMan 'requestLocationUpdates "gps" '(L . 20000) (-3 . 100) *LocLsn) )
   (and
      (or
         (and
            (java *LocMan 'isProviderEnabled "gps")
            (java *LocMan 'getLastKnownLocation "gps") )
         (and
            (java *LocMan 'isProviderEnabled "network")
            (java *LocMan 'getLastKnownLocation "network") ) )
      (cons
         (+ (java @ 'getLatitude) 90000000)
         (+ (java @ 'getLongitude) 180000000) ) ) )

# Camera access
(local) [camera? hasSystemFeature]
(de camera? ()
   (java (java CONTEXT 'getPackageManager)
      'hasSystemFeature "android.hardware.camera" ) )

## '((Intent)
##    (setq *Picture (tmp "img"))
##    (loadUrl (baseHRef) *SesId "app/camera.l") )
(local) takePicture
(de takePicture (Dst Fun)
   (out Dst)
   (startActivityForResult Fun
      "android.media.action.IMAGE_CAPTURE"
      "output" (fileUri Dst) ) )

# ZXing QR-Codes
(local) [zxing? queryIntentActivities]
(de zxing? ()
   (with
      (java (java CONTEXT 'getPackageManager) 'queryIntentActivities
         (java "android.content.Intent" T "com.google.zxing.client.android.SCAN")
         65536 )  # MATCH_DEFAULT_ONLY
      (gt0 (: size)) ) )

## '((Intent)
##    (java Intent 'getStringExtra "SCAN_RESULT")
##    (java Intent 'getStringExtra "SCAN_RESULT_FORMAT") )
(local) [scanQR getStringExtra]
(de scanQR (Fun)
   (startActivityForResult Fun
      "com.google.zxing.client.android.SCAN"
      "SCAN_MODE" "QR_CODE_MODE" ) )

# Alarm
(local) [alarm elapsedRealtime getInstance getTimeInMillis getBroadcast]
(de alarm (N When File)
   (let
      (Intent (java "android.content.Intent" T CONTEXT (java "de.software_lab.pilbox.Receiver"))
         Alarm (java CONTEXT 'getSystemService "alarm") )  # AlarmManager
      (ifn When
         (java Alarm 'cancel
            (java "android.app.PendingIntent" 'getBroadcast CONTEXT N Intent 0) )
         (java Intent 'putExtra "LOAD" File)
         (java Alarm 'set
            (if (atom When) 2 0)  # ELAPSED_REALTIME_WAKEUP RTC_WAKEUP
            (cons 'L
               (if (atom When)
                  (+
                     (* 1000 When)
                     (java "android.os.SystemClock" 'elapsedRealtime) )
                  (let
                     (Dat (date (car When))
                        Tim (time (cdr When))
                        C (java "android.icu.util.Calendar" 'getInstance) )
                     (java C 'set
                        (car Dat) (dec (cadr Dat)) (caddr Dat)
                        (car Tim) (cadr Tim) (caddr Tim) )
                     (java C 'getTimeInMillis) ) ) )
            (java "android.app.PendingIntent" 'getBroadcast
               CONTEXT N Intent 0 ) ) ) ) )

# Terminate PilBox
(local) [terminate finishAndRemoveTask]
(de terminate ()
   (java (; CONTEXT GUI) 'finishAndRemoveTask) )

# vi:et:ts=3:sw=3
