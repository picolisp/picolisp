# 24sep03abu
# (c) Software Lab. Alexander Burger

# *Home *Allow *Gate *Agent *Host *Port *Sock *MPartLim *MPartEnd *ContLen
# *Url *SesId *ConId *InND *OutN *Frame *U1 *Help *Meta *Css

(default *HPorts 0)

(de *Mimes
   (`(chop ".css") "text/css" 86400)
   (`(chop ".gif") "image/gif" 86400)
   (`(chop ".jpg") "image/jpeg" 86400)
   (`(chop ".txt") "text/octet-stream" 1)  # 'T' MSIE problem?
   (`(chop ".wav") "audio/x-wav" 1)
   (`(chop ".mp3") "audio/x-mpeg" 86400)
   (`(chop ".pdf") "application/pdf" 1)
   (`(chop ".zip") "application/zip" 1)
   (`(chop ".jar") "application/java-archive" 86400) )


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
      (or *Sock (bye))
      (timeout `(* 15 60000))
      (task *Sock
         (http (or (listen *Sock 60000) (quit "Bad Client")))
         (timeout `(* 15 60000)) ) ) )

(de baseHRef ()
   (pack
      (or *Gate "http") "://" *Host
      (if *Gate "/" ":") *Port "/" ) )

(de https @
   (pass pack "https://" *Host "/" *Port "/" *SesId) )

# Init crypt
(de rsa (N)
   (seed (in "/dev/urandom" (rd 20)))
   (setq *InND (rsaKey N))
   (off *OutN) )

# Application startup page
(de app ()
   (unless *Sock
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
               ((quit ": Bad HTTP Request" L)) )
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
               (out S
                  (cond
                     ((<> *ConId *SesId)
                        (and (info "void") (httpEcho "void")) )
                     ((=0 F)
                        (html NIL
                           (prinl "<TABLE WIDTH=\"100%\"><TR>")
                           (let N 0
                              (mapc
                                 '((L)
                                    (prin "<TD ALIGN=\"CENTER\">")
                                    (when (car L)
                                       (prin "<IMG SRC=\"" *SesId (car L) "\">") )
                                    (prinl
                                       "<A HREF=\"" *SesId (inc 'N) "\" TARGET=\"MENU\">"
                                       (cadr L) "</A></TD>" ) )
                                 *Frame ) )
                           (prinl "</TR></TABLE>") ) )
                     (F (html NIL (prEval (nth *Frame F 3))))
                     ((member '@ @U)
                        (apply (val (intern (ht:Pack (cdr @)))) L) )
                     ((= '("." "l") (tail 2 @U))
                        (load *Url) )
                     ((= '("." "h" "t" "m" "l") (tail 5 @U))
                        (httpEcho *Url) )
                     ((assoc (tail 4 @U) *Mimes)
                        (apply httpEcho (cdr @) *Url) )
                     ((=T (car (info *Url)))
                        (load (pack *Url "default")) )
                     (T (httpEcho *Url "application/octet-stream" 1 T)) ) )
               (or
                  (= '("." "c" "l" "a" "s" "s") (tail 6 @U))
                  (msg *Url " not allowed") ) ) ) )
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
                     ((index ":" @X) (head (- @ 1) @X))
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
               (while (or (member "/" @V) (member "\\" @V))
                  (setq @V (cdr @)) )
               (let F (if (_htSet @N (pack @V)) (tmp @) "/dev/null")
                  (unless (out F (echo (pack "^M^J" *MPartLim)))
                     (call "rm" "-f" F) ) )
               (let C (char)
                  (and (= "^M" C) (setq C (char)))
                  (setq L (if (= "^J" C) *MPartLim *MPartEnd)) ) ) ) ) ) )

(de _htSet ("Var" Val)
   (use (@V @N)
      (off @N)
      (setq "Var"
         (intern
            (pack
               (cond
                  ((or (match '("*" @V "(" @N ")") "Var") (match '("%" "2" "A" @V "(" @N ")") "Var"))
                     (setq @N (_htArg @N))
                     (cons "*" @V) )
                  ((match '("%" "2" "A" . @V) "Var")
                     (cons "*" @V) )
                  ((= "*" (car "Var"))
                     "Var" )
                  (T (throw "http")) ) ) ) )
      (or
         (not *Allow)
         (idx *Allow "Var")
         (msg *Url " not allowed")
         (throw "http") )
      (cond
         ((not @N) (set "Var" Val))
         ((assoc @N (val "Var")) (con @ Val))
         (T (queue "Var" (cons @N Val))) ) ) )

(de _htArg (Lst)
   (use @L
      (cond
         ((= "$" (car Lst))
            (format (pack (cdr Lst))) )
         ((match '("[" @L "]") Lst)
            (intern (ht:Pack @L)) )
         ((match '("{" @L "}") Lst)
            (extern (pack @L)) )
         ((match '("(" @L ")") Lst)
            (mapcar _htArg (split @L "_")) )
         (T (ht:Pack Lst)) ) ) )

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
   (_http Typ Upd)
   (let (I (info File)  D (date (cadr I)))
      (prinl "Content-Length: " (car I) "^M")
      (prinl "Last-Modified: "
         (day (cadr I) *Day) ", "
         (pad 2 (caddr D)) " "
         (get *Mon (cadr D)) " "
         (car D) " "
         (tim$ (cddr I)) " GMT^M" ) )
   (when Att
      (let F (chop File)
         (while (member "/" F)
            (setq F (cdr @)) )
         (prinl "Content-Disposition: attachment; filename=\"" F "\"^M") ) )
   (prinl "^M")
   (in File (echo)) )

# Ouput navigation links
(de navi ()
   (<href> "<<<" "javascript:history.back()" (and *Frame "MAIN"))
   (if *U1
      (<href> "---" *U1 (and *Frame "MAIN"))
      (prin "---") )
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
                  (until (= (tail 8 S) '`(chop "</HTeMpL"))
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
   (mapc
      '((L)
         (prin "<META")
         (while L
            (prin " " (caar L) "=\"" (cdr (pop 'L)) "\"") )
         (prinl ">") )
      *Meta )
   (when *Css
      (prinl
         "<link rel=\"stylesheet\" type=\"text/css\" href=\""
         *SesId *Css "\">" ) )
   (prinl "</HEAD>")
   (cond
      ((not (num? (car "Prg")))
         (prin "<BODY MARGINHEIGHT=\"0\"")
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
         (prin " ")
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

(de <list> @
   (prinl "<UL>")
   (while (args)
      (prin "<LI>")
      (<item> (next))
      (prinl) )
   (prinl "</UL>") )

(de <pre> "Prg"
   (prinl "<PRE>")
   (prEval "Prg")
   (prinl "</PRE>") )


# Tables
(de <table> ("Body" "Ttl" "Head" . "Prg")
   (prin "<TABLE")
   (cond
      ((=T "Body") (prin " BORDER=\"1\""))
      ("Body" (prin " " "Body")) )
   (prinl ">")
   (when "Ttl"
      (prin "<CAPTION>")
      (ht:Prin "Ttl")
      (prinl "</CAPTION>") )
   (when "Head"
      (prin "<TR>")
      (mapc
         '((L)
            (prin
               "<TH ALIGN="
               (case (car L)
                  ((- ^) "LEFT")
                  (+ "RIGHT")
                  (T "CENTER") )
               (and (caddr L) (pack " WIDTH=" @))
               (cadddr L)
               ">" )
            (ht:Prin (cadr L))
            (prin "</TH>") )
         "Head" )
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
               (if (== '+ (caar H)) "RIGHT" "LEFT")
               (and (== '^ (caar H)) " VALIGN=TOP")
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
   (mapc
      '((X)
         (prin
            (if (= X (htmlVal "Var")) "<OPTION SELECTED>" "<OPTION>")
            X ) )
      Lst )
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
