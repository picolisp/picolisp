# 17dec04abu
# (c) Software Lab. Alexander Burger

# *Home *Allow *Gate *Agent *Host *Port *Sock *MPartLim *MPartEnd *ContLen
# *Url *Timeout *SesId *ConId *Frame *U1 *Help *Meta *Css

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
      (timeout *Timeout)
      (task *Sock
         (when (accept *Sock)
            (http @)
            (timeout *Timeout) ) ) ) )

(de baseHRef ()
   (pack
      (or *Gate "http") "://" *Host
      (if *Gate "/" ":") *Port "/" ) )

(de https @
   (pass pack "https://" *Host "/" *Port "/" *SesId) )

# Application startup page
(de app ()
   (unless *SesId
      (setq
         *SesId (pack (% (in "/dev/urandom" (rd 5)) 100000000000) "~")
         *Sock (port *HPorts '*Port) ) ) )

(de allowed Lst
   (setq *Allow (cons NIL (car Lst)))
   (mapc allow (cdr Lst)) )

(de allow (X)
   (and *Allow (idx *Allow X T))
   X )

# Handle HTTP-Transaction
(de http (S)
   (use (L @U F)
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
               (setq
                  L (split @U "?")
                  @U (car L)
                  L (mapcan
                     '((L)
                        (ifn (cdr (setq L (split L "=")))
                           (cons (_htArg (car L)))
                           (_htSet (car L) (_htArg (cadr L)))
                           NIL ) )
                     (split (cadr L) "&") ) )
               (if (setq *Url (ht:Pack @U))
                  (setq F (format *Url))
                  (setq  *Url (car *Home)  @U (cdr *Home)  F) )
               (if
                  (or
                     F
                     (not *Allow)
                     (tmp? *Url)
                     (idx *Allow *Url)
                     (unless (sub? "/../" *Url)
                        (find pre? (cdr *Allow) (circ *Url)) ) )
                  (cond
                     ((<> *ConId *SesId)
                        (and (info "void") (httpEcho "void")) )
                     ((=0 F)
                        (html NIL
                           (prinl "<TABLE WIDTH=\"100%\"><TR>")
                           (for (N . L) *Frame
                              (prin "<TD ALIGN=\"CENTER\">")
                              (when (eval (car L))
                                 (prin "<IMG SRC=\"" *SesId @ "\">") )
                              (prinl
                                 "<A HREF=\"" *SesId N "\" TARGET=\"MENU\">"
                                 (eval (cadr L))
                                 "</A></TD>" ) )
                           (prinl "</TR></TABLE>") ) )
                     (F (html NIL (prEval (nth *Frame F 3))))
                     ((member '@ @U)
                        (apply (val (intern (ht:Pack (cdr @)))) L) )
                     ((tail '("." "l") @U)
                        (load *Url) )
                     ((assoc (stem @U ".") *Mimes)
                        (apply httpEcho (cdr @) *Url) )
                     ((=T (car (info *Url)))
                        (load (pack *Url "default")) )
                     (T (httpEcho *Url "application/octet-stream" 1 T)) )
                  (unless (tail '("." "c" "l" "a" "s" "s") @U)
                     (msg *Url " not allowed")
                     (http404) ) ) ) ) )
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
                           (link L) ) ) ) ) )
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
                  (setq @N (_htArg @N))
                  @V ) ) ) )
      (unless
         (and
            (= `(char '*) (char "Var"))
            (or (not *Allow) (idx *Allow "Var")) )
         (msg "Var" " not allowed")
         (throw "http") )
      (cond
         ((not @N) (set "Var" Val))
         ((assoc @N (val "Var")) (con @ Val))
         (T (queue "Var" (cons @N Val))) ) ) )

(de _htArg (Lst)
   (case (car Lst)
      ("$" (intern (ht:Pack (cdr Lst))))
      ("+" (format (pack (cdr Lst))))
      ("." (extern (ht:Pack (cdr Lst))))
      ("_" (mapcar _htArg (split (cdr Lst) "_")))
      (T (ht:Pack Lst)) ) )

(de htmlVar ("Var")
   (prin "NAME=\"")
   (if (pair "Var")
      (prin (car "Var") "(" (ht:Fmt (cdr "Var")) ")")
      (prin "Var") )
   (prin "\"") )

(de htmlVal ("Var")
   (if (pair "Var")
      (cdr (assoc (cdr "Var") (val (car "Var"))))
      (val "Var") ) )

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

# Ouput navigation links
(de navi ()
   (<href> "<<<" "javascript:history.back()" (and *Frame "MAIN"))
   (if *U1
      (<href> "----" *U1 (and *Frame "MAIN"))
      (prin "----") )
   (<href> ">>>" "javascript:history.forward()" (and *Frame "MAIN")) )

(de url1 (Str)
   (setq *U1 Str) )

# Html Template
(de htempl ("File" . "Lst")
   (in "File"
      (while (echo "<BASE HREF" "<HTeMpL>" "<IMG SRC=\"HTeMpL.gif\" ALT=\"")
         (case @
            ("<BASE HREF"
               (till ">" T)
               (prin "<BASE HREF=\"" (baseHRef) "\"") )
            ("<HTeMpL>"
               (let S (till ">")
                  (until (tail '`(chop "</HTeMpL") S)
                     (conc S (cons (char)))
                     (if (till ">")
                        (conc S @)
                        (quit "Bad HTeMpL") ) )
                  (char)
                  (prin (eval (str (pack (head -8 S))))) ) )
            ("<IMG SRC=\"HTeMpL.gif\" ALT=\""
               (let (S (till "\"" T)  L (cddr (split (till ">") "\"")))
                  (char)
                  (apply
                     (cdr (assoc S "Lst"))
                     (mapcar pack (filter prog (cdddr L) '(NIL T .)))
                     (format (pack (car L)))
                     (format (pack (caddr L))) ) ) ) ) ) ) )

### Html Output ###
(de html ("Ttl" . "Prg")
   (httpHead NIL (if (car "Prg") 0 (pop '"Prg")))
   (prinl
      "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 "
      (if (num? (car "Prg")) "Frameset" "Transitional")
      "//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">" )
   (if *Lang
      (prinl "<HTML lang=\"" *Lang "\">")
      (prinl "<HTML>") )
   (prinl "<HEAD>")
   (prinl "<BASE HREF=\"" (baseHRef) "\">")
   (when "Ttl"
      (prin "<TITLE>")
      (ht:Prin "Ttl")
      (prinl "</TITLE>") )
   (for L *Meta
      (prin "<META")
      (while L
         (prin " " (caar L) "=\"" (cdr (pop 'L)) "\"") )
      (prinl ">") )
   (when *Css
      (prinl
         "<link rel=\"stylesheet\" type=\"text/css\" href=\""
         *SesId *Css "\">" ) )
   (prinl "</HEAD>")
   (cond
      ((not (num? (car "Prg")))
         (prin "<BODY")
         (while (and (pair (car "Prg")) (=T (caar "Prg")))
            (prin " " (eval (cdr (pop '"Prg")))) )
         (prinl ">")
         (prEval "Prg")
         (prinl "</BODY>") )
      ((= 3 (length "Prg"))
         (prinl
            "<FRAMESET COLS=\""
            (eval (car "Prg"))
            ",*\"><FRAME NAME=\"MENU\" SRC=\""
            *SesId
            "1\"><FRAME NAME=\"MAIN\" SRC=\""
            *SesId
            (eval (cadr "Prg"))
            "\"></FRAMESET>" )
         (setq  *Frame (cons "Prg")) )
      (T
         (prinl
            "<FRAMESET ROWS=\""
            (eval (car "Prg"))
            ",*\"><FRAME SRC=\""
            *SesId
            "0\" MARGINHEIGHT=\"0\" SCROLLING=\"NO\"><FRAMESET COLS=\""
            (eval (cadr "Prg"))
            ",*\"><FRAME NAME=\"MENU\" SRC=\""
            *SesId
            "1\"><FRAME NAME=\"MAIN\" SRC=\""
            *SesId
            (eval (caddr "Prg"))
            "\"></FRAMESET></FRAMESET>" )
         (setq  *Frame (cdddr "Prg")) ) )
   (prinl "</HTML>") )

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


### HTML Generators ###
(de _htAlign (X)
   (cond
      ((not X))
      ((=T X) " ALIGN=\"RIGHT\"")
      ((=0 X) " ALIGN=\"CENTER\"")
      (T X) ) )

(de _sesId (Url)
   (if
      (or
         (pre? "http:" Url)
         (pre? "https:" Url)
         (pre? "mailto:" Url)
         (pre? "javascript:" Url) )
      Url
      (pack *SesId Url) ) )

(de <item> ("X")
   (cond
      ((atom "X") (ht:Prin "X"))
      ((=T (car "X")) (apply <href> (cdr "X")))
      (T (eval "X")) ) )

(de <item2> ("L" "R" "N")
   (prin "<TABLE WIDTH=\"100%\"><TR><TD ALIGN=\"LEFT\">")
   (and "N" (prin "<H" "N" ">"))
   (<item> "L")
   (and "N" (prin "</H" "N" ">"))
   (prin "</TD><TD ALIGN=\"RIGHT\">")
   (<item> "R")
   (prinl "</TD></TR></TABLE>") )

(de <head> (S N X)
   (if N
      (prinl "<H" N (_htAlign X) ">" S "</H" N ">")
      (<item2> S '(navi) 3) ) )

(de <font> ("Col" "Siz" . "Prg")
   (prin "<FONT")
   (and "Col" (prin " COLOR=\"" "Col" "\""))
   (and "Siz" (prin " SIZE=\"" "Siz" "\""))
   (prin ">")
   (prEval "Prg")
   (prinl "</FONT>") )

(de <b> "Prg"
   (prin "<b>")
   (prEval "Prg")
   (prinl "</b>") )

(de <br> @
   (when (args)
      (<item> (next))
      (while (args)
         (space)
         (<item> (next)) ) )
   (prinl "<br>") )

(de <center> "Prg"
   (prin "<center>")
   (prEval "Prg")
   (prinl "</center>") )

(de <p> ("X" . "Prg")
   (prin "<p" (_htAlign "X") ">")
   (prEval "Prg")
   (prinl "</p>") )

(de <name> ("Name" . "Prg")
   (prin "<a NAME=\"" "Name" "\">")
   (prEval "Prg")
   (prinl "</a>") )

(de <href> (S Url Tar)
   (prin "<A HREF=\"" (_sesId Url))
   (cond
      (Tar (prin "\" TARGET=\"" Tar))
      (*Frame (prin "\" TARGET=\"MAIN\"")) )
   (prin "\">")
   (ht:Prin S)
   (prin "</A>") )

(de <button> @
   (prin "[")
   (pass <href>)
   (prinl "]") )

(de <img> (S A Url X)
   (and Url (prin "<A HREF=\"" (_sesId Url)  "\">"))
   (prin "<IMG SRC=\"" (_sesId S) "\" ALT=\"" A "\"" (_htAlign X) ">")
   (and Url (prin "</A>")) )

(de <pre> "Prg"
   (prinl "<PRE>")
   (prEval "Prg")
   (prinl "</PRE>") )

(de <list> @
   (prinl "<UL>")
   (while (args)
      (prin "<LI>")
      (<item> (next))
      (prinl) )
   (prinl "</UL>") )

(de <tree> ("Url" "Path" "Tree" "able?" "excl?" "expand" "format")
   (let ("Pos" "Tree"  "F" (pop '"Path")  "A" 0)
      (when "Path"
         (loop
            (and "F"
               (not (cdr "Path"))
               (map
                  '((L)
                     (when (pair (car L)) (set L (caar L))) )
                  "Pos" ) )
            (T (atom (car (setq "Pos" (nth "Pos" (abs (pop '"Path")))))))
            (NIL "Path")
            (setq "Pos" (cdar "Pos")) )
         (set "Pos"
            (if (atom (car "Pos"))
               (cons (car "Pos") ("expand" (car "Pos")))
               (caar "Pos") ) ) )
      (setq "Pos" (car "Pos"))
      (<_tree> "Tree")
      "Tree" ) )

(de <_tree> ("Tree" "Lst")
   (prinl "<UL>")
   (for ("N" . "X") "Tree"
      (prin "<LI><A NAME=\"T" (inc '"A") "\"></A>")
      (cond
         ((pair "X")
            (let "L" (append "Lst" (cons "N"))
               (<href> (if (== "X" "Pos") "<+>" "[+]")
                  (pack "Url"
                     "?" (ht:Fmt (cons NIL "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("format" (car "X"))
               (and (cdr "X") (<_tree> @ "L")) ) )
         (("able?" "X")
            (let "L" (append "Lst" (cons (- "N")))
               (<href> (if (== "X" "Pos") "< >" "[ ]")
                  (pack "Url"
                     "?" (ht:Fmt (cons ("excl?" "X") "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("format" "X") ) )
         (T ("format" "X")) ) )
   (prinl "</UL>") )


# Tables
(de <table> ("Body" "Ttl" "Head" . "Prg")
   (prin "<TABLE")
   (cond
      ((=T "Body") (prin " BORDER=\"1\""))
      ("Body" (prin " " "Body")) )
   (prinl ">")
   (when "Ttl"
      (prin "<CAPTION>")
      (<item> "Ttl")
      (prinl "</CAPTION>") )
   (when "Head"
      (prin "<TR>")
      (for L "Head"
         (prin
            "<TH ALIGN="
            (case (car L)
               ((- ^) "\"LEFT\"")
               (+ "\"RIGHT\"")
               (T "\"CENTER\"") )
            (and (caddr L) (pack " WIDTH=" @))
            (cadddr L)
            ">" )
         (<item> (cadr L))
         (prin "</TH>") )
      (prinl "</TR>") )
   (prEval "Prg")
   (prinl "</TABLE>") )

(de <row> @
   (prinl "<TR>")
   (map
      '((X H)
         (unless (memq (car X) '(T -))
            (prinl
               "<TD ALIGN="
               (if (== '+ (caar H)) "\"RIGHT\"" "\"LEFT\"")
               (and (== '^ (caar H)) " VALIGN=\"TOP\"")
               (when (== '- (cadr X))
                  (pack
                     " COLSPAN="
                     (-
                        (length X)
                        (length
                           (seek
                              '((L) (n== '- (car L)))
                              (cdr X) ) ) ) ) )
               ">" )
            (<item> (car X))
            (prinl "</TD>") ) )
      (rest)
      "Head" )
   (prinl "</TR>") )

(de <grid> ("Head" . @)
   (<table> NIL "" "Head"
      (while (args)
         (apply <row> (next)) ) ) )

(de <th> "Prg"
   (prinl "<TR>")
   (while "Prg"
      (prin "<TH")
      (while (and (pair (car "Prg")) (=T (caar "Prg")))
         (prin " " (eval (cdr (pop '"Prg")))) )
      (prin ">")
      (<item> (eval (pop '"Prg")))
      (prinl "</TH>") )
   (prinl "</TR>") )

(de <td> "Prg"
   (prinl "<TR>")
   (while "Prg"
      (prin "<TD")
      (while (and (pair (car "Prg")) (=T (caar "Prg")))
         (prin " " (eval (cdr (pop '"Prg")))) )
      (prin ">")
      (<item> (eval (pop '"Prg")))
      (prinl "</TD>") )
   (prinl "</TR>") )


### Reporting ###
(de report (Nm Ttl . @)
   (out (list "bin/lat1" (setq "*Rep" (tmp Nm ".txt")))
      (prinl (or Ttl Nm) "^M") )
   (<head> (or Ttl Nm))
   (<href> "Download" "*Rep")
   (while (args)
      (prin " | ")
      (<href> (next) (pack '@ (next)) (next)) )
   (<br>)
   (setq "*Rep" (list "bin/lat1" (pack "+" "*Rep"))) )

(de record @
   (pass <row>)
   (out "*Rep"
      (map
         '((L)
            (prin
               (cond
                  ((== '- (car L)))
                  ((atom (car L)) (car L))
                  ((=T (caar L)) (cadar L)) ) )
            (when
               (seek
                  '((L) (n== '- (car L)))
                  (cdr L) )
               (prin "^I") ) )
         (filter nT (rest)) )
      (prinl "^M") ) )

(de record1 @
   (pass <br>)
   (out "*Rep"
      (when (args)
         (prin
            (cond
               ((atom (next)) (arg))
               ((=T (car (arg))) (cadr (arg))) ) )
         (while (args)
            (prin " "
               (cond
                  ((atom (next)) (arg))
                  ((=T (car (arg))) (cadr (arg))) ) ) ) )
      (prinl "^M") ) )

(de href (Obj Val)
   (cond
      ((= Obj "HTTP")
         (list T Val (if (sub? ":/" Val) Val (pack "http://" Val)) "HTTP") )
      ((= Obj "MAIL")
         (list T Val (pack "mailto:" Val) "MAIL") )
      ((and Obj (url> Obj))
         (list T Val @) )
      (T Val) ) )


### HTML Form ###
(de <post> ("S" . "Prg")
   (prinl
      "<FORM ENCTYPE=\"multipart/form-data\" ACTION=\""
      (_sesId "S")
      "\" METHOD=POST"
      (and *Frame " TARGET=\"MAIN\"")
      ">" )
   (prEval "Prg")
   (prinl "</FORM>") )

(de <field> (N S "Var" Url X)
   (when S
      (if Url (<href> S Url) (prin S))
      (space) )
   (prin "<INPUT" (_htAlign X) " TYPE=TEXT ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" SIZE=" N ">") )

(de <hidden> ("Var" "Val")
   (prin "<INPUT TYPE=HIDDEN ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin "Val")
   (prinl "\">") )

(de <passwd> (N S "Var" X)
   (when S
      (prin S)
      (space) )
   (prin "<INPUT" (_htAlign X) " TYPE=PASSWORD ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" SIZE=" N ">") )

(de <upload> (N S "Var" Url)
   (when S
      (if Url (<href> S Url) (prin S))
      (space) )
   (prin "<INPUT TYPE=FILE ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" SIZE=" N ">") )

(de <area> (Cols Rows S "Var" Url)
   (when S
      (if Url (<href> S Url) (prin S))
      (space) )
   (prin "<TEXTAREA ")
   (htmlVar "Var")
   (prin " COLS=" Cols " ROWS=" Rows ">")
   (ht:Prin (htmlVal "Var"))
   (prinl "</TEXTAREA>") )

(de <select> (S Lst "Var")
   (when S
      (prin S)
      (space) )
   (prin "<SELECT ")
   (htmlVar "Var")
   (prin ">")
   (for X Lst
      (prin
         (if (= X (htmlVal "Var")) "<OPTION SELECTED>" "<OPTION>")
         X ) )
   (prinl "</SELECT>") )

(de <check> ("Var" S)
   (prin "<INPUT TYPE=HIDDEN ")
   (htmlVar "Var")
   (prinl " VALUE=\"\">")
   (prin "<INPUT TYPE=CHECKBOX ")
   (htmlVar "Var")
   (prinl " VALUE=\"T\"" (and (htmlVal "Var") " CHECKED") "> " S) )

(de <radio> ("Var" Val S)
   (prin "<INPUT TYPE=RADIO ")
   (htmlVar "Var")
   (prin " VALUE=\"" Val "\"" (and (= Val (htmlVal "Var")) " CHECKED") "> " S) )

(de <submit> (S)
   (prin "<INPUT TYPE=SUBMIT VALUE=\"")
   (ht:Prin S)
   (prinl "\">") )

(de <reset> (S)
   (prin "<INPUT TYPE=RESET VALUE=\"")
   (ht:Prin S)
   (prinl "\">") )
