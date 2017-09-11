# 11sep17abu
# (c) Software Lab. Alexander Burger

(ifn (info "UUID")
   (off *Uuid)
   (setq *Uuid (in "UUID" (line T)))
   (for F '("JAVA" "LISP" "RQST" "RPLY" "BOSS")
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
# (java "cls" 'T ['any ..]) -> obj       New object
# (java 'obj 'msg ['any ..]) -> any      Send message to object
# (java 'obj "fld" ["fld" ..]) -> any    Value of object field
# (java "cls" 'msg ['any ..]) -> any     Call method in class
# (java "cls" "fld" ["fld" ..]) -> any   Value of class field
# (java T "cls" ["cls" ..]) -> obj       Define interface
# (java 'obj) -> [lst ..]                Reflect object
# (java "cls") -> [lst lst ..]           Reflect class
(local) [java *Java *Lisp]
(de java @
   (unless *Java
      (setq *Java (open "JAVA")  *Lisp (open "LISP"))
      (task (open "RQST")  R (open "RPLY")
         (in @
            (out R
               (ext 65535
                  (pr
                     (with (rd)  # Obj
                        (if (get (rd) This)
                           (apply @ (rd))
                           (rd)
                           NIL ) ) ) ) ) ) )
      (forked)
      (queue '*Ext (cons 65535 java))
      (con java (cddr java)) )
   (ext 65535
      (out *Java (pr (rest)))
      (let? Val (in *Lisp (rd))
         (if (== 'err (car (pair Val)))
            (nil (msg (cdr Val)))
            Val ) ) ) )

# Android device ID
(local) [dev getString getContentResolver]
(de dev ()
   (java "android.provider.Settings$Secure" 'getString
      (java CONTEXT 'getContentResolver)
      "android_id" ) )

# Push-Load
(local) loadUrl
(de loadUrl @
   (java CONTEXT 'loadUrl (pass pack)) )

# Clear WebView history and cache
(local) [clearHistory clearCache]
(de clearHistory ()
   (java CONTEXT 'clearHistory) )

(de clearCache ()
   (java CONTEXT 'clearCache) )

# Wake lock
(local) [wake *Wake getSystemService newWakeLock acquire release)]
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
(de toast (Str)
   (java CONTEXT 'toast Str)
   Str )

# Notification
(local) [
   notify setSmallIcon setContentTitle setContentText setAutoCancel setLights
   setContentIntent getActivity build ]
(de notify (Ttl Msg Id)
   (let B (java "android.support.v4.app.NotificationCompat$Builder" T CONTEXT)
      (java B 'setSmallIcon (java "de.software_lab.pilbox.R$drawable" "notify"))
      (java B 'setContentTitle Ttl)
      (java B 'setContentText Msg)
      (java B 'setAutoCancel T)
      (java B 'setLights `(hex "FFFFFF") 500 500)
      (let Intent (java "android.content.Intent" T CONTEXT (; CONTEXT GUI 0 1))  # Activity class
         (java Intent 'setFlags `(hex "24000000"))  # FLAG_ACTIVITY_SINGLE_TOP | FLAG_ACTIVITY_NEW_TASK
         (java B 'setContentIntent
            (java "android.app.PendingIntent" 'getActivity CONTEXT 0 Intent `(hex "10000000")) ) )  # FLAG_ACTIVITY_NEW_TASK
      (prog1 (java B 'build)  # Notification
         (java (java CONTEXT 'getSystemService "notification")  # NotificationManager
            'notify Id @ ) ) ) )

# Service foreground state
(local) [startForeground stopForeground]
(de startForeground (Ttl Msg)
   (java CONTEXT 'startForeground 1
      (notify Ttl Msg 1) ) )

(de stopForeground ()
   (java CONTEXT 'stopForeground T) )

# Start Activity for a result
(local) [
   startActivityForResult *ResultProxy *ProxyResults resolveActivity
   getPackageManager putExtra setResultProxy good bad ]
(de startActivityForResult (Fun Action . @)
   (let Intent (java "android.content.Intent" T Action)
      (when (java Intent 'resolveActivity (java CONTEXT 'getPackageManager))
         (while (args)
            (let S (next)
               (if (str? S)
                  (java Intent 'putExtra S (next))
                  (java Intent S (next) (next)) ) ) )
         (unless *ResultProxy
            (java CONTEXT 'setResultProxy
               (setq *ResultProxy (java T "de.software_lab.pilbox.ResultProxy")) ) )
         (def 'good *ResultProxy
            '((Req Intent)
               (when (asoq Req *ProxyResults)
                  (del @ '*ProxyResults)
                  ((cdr @) Intent) ) ) )
         (def 'bad *ResultProxy
            '((Req Res)
               (del (asoq Req *ProxyResults) '*ProxyResults) ) )
         (let Req (inc (0))
            (push '*ProxyResults (cons Req Fun))
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
      (def 'onLocationChanged *LocLsn
         '((Loc)
            (msg Loc " onLocationChanged")
            NIL ) )
      (def 'onProviderDisabled *LocLsn
         '((Prov)) )
      (def 'onProviderEnabled *LocLsn
         '((Prov)) )
      (def 'onStatusChanged *LocLsn
         '((Prov Stat Extras)) )
      (java *LocMan 'requestLocationUpdates "gps" '(L . 20000) (-3 . 100) *LocLsn) )
   (when (java *LocMan 'isProviderEnabled "gps")
      (let? Loc (java *LocMan 'getLastKnownLocation "gps")
         (cons
            (+ (java Loc 'getLatitude) 90000000)
            (+ (java Loc 'getLongitude) 180000000) ) ) ) )

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
(local) scanQR
(de scanQR (Fun)
   (startActivityForResult Fun
      "com.google.zxing.client.android.SCAN"
      "SCAN_MODE" "QR_CODE_MODE" ) )

# Terminate PilBox
(local) [terminate finishAndRemoveTask]
(de terminate ()
   (java (; CONTEXT GUI) 'finishAndRemoveTask) )

# vi:et:ts=3:sw=3
