# 18jun05abu
# (c) Software Lab. Alexander Burger

# *Home *Gate *Agent *Host *Port *Port1 *Sock *MPartLim *MPartEnd *ContLen
# *Url *Timeout *SesId *ConId

(default
   *HPorts 0
   *Timeout (* 15 60 1000) )

(de *Mimes
   (`(chop "html"))
   (`(chop "au") "audio/basic" 86400)
   (`(chop "wav") "audio/x-wav" 86400)
   (`(chop "mp3") "audio/x-mpeg" 86400)
   (`(chop "css") "text/css" 86400)
   (`(chop "gif") "image/gif" 86400)
   (`(chop "jpg") "image/jpeg" 86400)
   (`(chop "txt") "text/octet-stream" 1 T)
   (`(chop "ps") "application/postscript" 1)
   (`(chop "pdf") "application/pdf" 1)
   (`(chop "zip") "application/zip" 1)
   (`(chop "jar") "application/java-archive" 86400) )

(de mime (S . @)
   (let L (chop S)
      (if (assoc L *Mimes)
         (con @ (rest))
         (push '*Mimes (cons L (rest))) ) ) )


### HTTP-Client ###
(de client ("Host" "Port" "Name" . "Prg")
   (when (connect "Host" "Port")
      (let "H" @
         (prog1
            (out "H"
               (prinl "GET /" "Name" " HTTP/1.1^M")
               (prinl "Connection: close^M")
               (prinl "User-Agent: PicoLisp^M")
               (prinl "Host: " "Host" "^M")
               (prinl "Accept-Charset: utf-8^M")
               (prinl "^M")
               (flush)
               (in "H" (run "Prg")) )
            (close "H") ) ) ) )

# Local Password
(de pw ()
   (in ".pw" (line T)) )

# Pico Shell
(de psh (Pw Tty)
   (when
      (and
         (= Pw (pw))
         (in (list "ps" (pack "t" Tty)) (from "/psh "))
         (ctty Tty) )
      (prinl *Pid)
      (load "dbg.l")
      (quit) ) )


### HTTP-Server ###
(de server (P H)
   (setq
      *Port P
      *Port1 P
      *Home (cons H (chop H))
      P (port P) )
   (gc)
   (use S
      (loop
         (setq S (listen P))
         (NIL (fork) (close P))
         (close S) )
      (http S)
      (or *SesId (bye))
      (task *Sock
         (when (accept *Sock)
            (http @) ) ) ) )

(de baseHRef (Port)
   (pack
      (or *Gate "http") "://" *Host
      (if *Gate "/" ":") (or Port *Port) "/" ) )

(de https @
   (pass pack "https://" *Host "/" *Port "/" *SesId) )

(de ext.html (Sym)
   (pack (ht:Fmt Sym) ".html") )

# Application startup
(de app ()
   (unless *SesId
      (setq
         *SesId (pack (% (in "/dev/urandom" (rd 5)) 100000000000) "~")
         *Sock (port *HPorts '*Port) )
      (timeout *Timeout) ) )

# Handle HTTP-Transaction
(de http (S)
   (use (L @U @X)
      (catch "http"
         (in S
            (cond
               ((=T (setq L (line))) (throw "http"))
               ((match '("G" "E" "T" " " "/" @U " " "H" "T" "T" "P" . @) L)
                  (_htHead) )
               ((match '("P" "O" "S" "T" " " "/" @U " " "H" "T" "T" "P" . @) L)
                  (off *MPartLim *MPartEnd)
                  (_htHead)
                  (and *MPartLim *MPartEnd (_htMultipart)) )
               ((and
                     (match '(@U " " @ " " "H" "T" "T" "P" . @) L)
                     (member @U
                        (quote
                           ("O" "P" "T" "I" "O" "N" "S")
                           ("H" "E" "A" "D")
                           ("P" "U" "T")
                           ("D" "E" "L" "E" "T" "E")
                           ("T" "R" "A" "C" "E")
                           ("C" "O" "N" "N" "E" "C" "T") ) ) )
                  (out S
                     (httpStat 501 "Method Not Implemented"
                        "Allow: GET, POST" ) )
                  (throw "http") )
               (T (out S (httpStat 400 "Bad Request")) (throw "http")) )
            (out S
               (cond
                  ((<> *ConId *SesId)
                     (and (info "void") (httpEcho "void")) )
                  ((match '("-" @X "." "h" "t" "m" "l") @U)
                     (try 'html> (extern (ht:Pack @X))) )
                  ((>= '("9") @U '("0"))
                     (urlN (car @U)) )
                  (T
                     (setq
                        L (split @U "?")
                        @U (car L)
                        L (mapcan
                           '((L)
                              (ifn (cdr (setq L (split L "=")))
                                 (cons (htArg (car L)))
                                 (_htSet (car L) (htArg (cadr L)))
                                 NIL ) )
                           (split (cadr L) "&") ) )
                     (unless (setq *Url (ht:Pack @U))
                        (setq  *Url (car *Home)  @U (cdr *Home)) )
                     (cond
                        ((= '@ (car @U))
                           (if (and *Allow (not (idx *Allow *Url)))
                              (prog (msg *Url " not allowed") (http404))
                              (and *SesId (timeout *Timeout))
                              (apply (val (intern (ht:Pack (cdr @U)))) L) ) )
                        ((and *Allow
                              (not (idx *Allow *Url))
                              (or
                                 (sub? ".." *Url)
                                 (nor
                                    (and *Tmp (pre? *Tmp *Url))
                                    (find pre? (cdr *Allow) (circ *Url)) ) ) )
                           (msg *Url " not allowed")
                           (http404) )
                        ((tail '("." "l") @U)
                           (and *SesId (timeout *Timeout))
                           (load *Url) )
                        ((assoc (stem @U ".") *Mimes)
                           (apply httpEcho (cdr @) *Url) )
                        ((=T (car (info *Url)))
                           (load (pack *Url "default")) )
                        (T (httpEcho *Url "application/octet-stream" 1 T)) ) ) ) ) ) )
      (close S) ) )

(de _htHead ()
   (use (L @X @Y)
      (if (index "~" @U)
         (setq *ConId (pack (head @ @U))  @U (cdr (nth @U @)))
         (off *ConId) )
      (off *Gate)
      (while (setq L (line))
         (cond
            ((=T L) (throw "http"))
            ((match '(~(chop "Gate: ") @X " " . @Y) L)
               (setq *Gate (pack @X)  *Adr (pack @Y)) )
            ((match '(~(chop "User-@gent: ") . @X) L)
               (setq *Agent @X) )
            ((match '(~(chop "Host: ") . @X) L)
               (setq *Host
                  (cond
                     (*Gate @X)
                     ((index ":" @X) (head (dec @) @X))
                     (T @X) ) ) )
            ((match '(~(chop "Content-@ype: multipart/form-data; boundary=") . @X) L)
               (setq
                  *MPartLim (append '(- -) @X)
                  *MPartEnd (append *MPartLim '(- -)) ) )
            ((match '(~(chop "Content-@ength: ") . @X) L)
               (setq *ContLen (format (pack @X))) ) ) ) ) )

# rfc1867 multipart/form-data
(de _htMultipart ()
   (use (L @X @N @V)
      (setq L (line))
      (while (= *MPartLim L)
         (unless (match '(~(chop "Content-Disposition: form-data; name=") . @X) (line))
            (throw "http") )
         (while (line)
            (when (=T @)
               (throw "http") ) )
         (cond
            ((not (member ";" @X))
               (match '("\"" @X "\"") @X)
               (_htSet @X
                  (pack
                     (make
                        (until
                           (or
                              (= *MPartLim (setq L (line)))
                              (= *MPartEnd L) )
                           (when (made)
                              (link "^J") )
                           (link (trim L)) ) ) ) ) )
            ((match '(@N ~(chop "; filename=") . @V) @X)
               (match '("\"" @N "\"") @N)
               (match '("\"" @V "\"") @V)
               (if (_htSet @N (pack (stem @V '/ '\)))
                  (let F (tmp @)
                     (unless (out F (echo (pack "^M^J" *MPartLim)))
                        (call 'rm "-f" F) ) )
                  (out "/dev/null" (echo (pack "^M^J" *MPartLim))) )
               (let C (char)
                  (and (= "^M" C) (setq C (char)))
                  (setq L (if (= "^J" C) *MPartLim *MPartEnd)) ) ) ) ) ) )

(de _htSet ("Var" Val)
   (use (@N @V)
      (off @N)
      (setq "Var"
         (intern
            (ht:Pack
               (ifn (match '(@V "(" @N ")") "Var")
                  "Var"
                  (setq @N (htArg @N))
                  @V ) ) ) )
      (cond
         ((nand (= `(char '*) (char "Var")) (or (not *Allow) (idx *Allow "Var")))
            (msg "Var" " not allowed")
            (throw "http") )
         ((not @N) (set "Var" Val))
         ((assoc @N (val "Var")) (con @ Val))
         (T (queue "Var" (cons @N Val))) ) ) )

(de htArg (Lst)
   (case (car Lst)
      ("$" (intern (ht:Pack (cdr Lst))))
      ("+" (format (pack (cdr Lst))))
      ("-" (extern (ht:Pack (cdr Lst))))
      ("_" (mapcar htArg (split (cdr Lst) "_")))
      (T (ht:Pack Lst)) ) )

# Http Transfer Header
(de _http (Typ Upd)
   (prinl "HTTP/1.1 200 OK^M")
   (prinl "Server: PicoLisp^M")
   (prinl "Connection: close^M")
   (when Upd
      (prinl "Cache-Control: max-age=" Upd "^M")
      (when (=0 Upd)
         (prinl "Cache-Control: no-cache^M") ) )
   (prinl "Content-Type: " (or Typ "text/html; charset=utf-8") "^M") )

(de httpHead (Typ Upd)
   (_http Typ Upd)
   (prinl "^M") )

# Http Echo
(de httpEcho (File Typ Upd Att)
   (ifn (info File)
      (http404)
      (_http Typ Upd)
      (let D (date (cadr @))
         (prinl "Content-Length: " (car @) "^M")
         (prinl "Last-Modified: "
            (day (cadr @) *Day) ", "
            (pad 2 (caddr D)) " "
            (get *Mon (cadr D)) " "
            (car D) " "
            (tim$ (cddr @) T) " GMT^M" ) )
      (when Att
         (prinl
            "Content-Disposition: attachment; filename=\""
            (stem (chop File) "/")
            "\"^M" ) )
      (prinl "^M")
      (in File (echo)) ) )

(de sesId (Url)
   (if
      (or
         (pre? "http:" Url)
         (pre? "https:" Url)
         (pre? "mailto:" Url)
         (pre? "javascript:" Url) )
      Url
      (pack *SesId Url) ) )

(de redirect (Url)
   (httpHead)
   (prinl "<HTML>")
   (prinl "<FRAMESET ROWS=\"100%,*\">")
   (prinl "<FRAME SRC=\"" Url "\">")
   (prinl "</FRAMESET>")
   (prinl "</HTML>") )

(de httpStat (N Str . @)
   (prinl "HTTP/1.1 " N " " Str "^M")
   (prinl "Server: PicoLisp^M")
   (while (args)
      (prinl (next) "^M") )
   (prinl "Connection: close^M")
   (prinl "Content-Type: text/html^M")
   (prinl "^M")
   (prinl "<HTML>")
   (prinl "<HEAD><TITLE>" N " " Str "</TITLE></HEAD>")
   (prinl "<BODY><H1>" Str "</H1></BODY>")
   (prinl "</HTML>") )

(de http404 ()
   (httpStat 404 "Not Found") )

(de urlN . `http404)
