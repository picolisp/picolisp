# 20dec02abu
# (c) Software Lab. Alexander Burger

# *Home *Allow *Gate *Host *Port *Sock *MPartLim *MPartEnd *ContLen
# *AppGate *AppPort *App *Apps *AppId *SesId *ConId *Top *Bar *Menu
# *InND *OutN
# *Frame *U1

(default *HPorts 0  *APorts 0)

(de *Events
   (act> . 1) (cmd> . 1) (key> . 1) (nxt> . 1) (rsa> . 1)
   (scr> . 2) (adv> . 2)
   (chg> . 3) (log> . 3)
   (clk> . 4) (drg> . 4) )

(de *Mimes
   (`(chop ".gif") "image/gif")
   (`(chop ".jpg") "image/jpeg")
   (`(chop ".txt") "text/octet-stream")  #? 'T' -> Bug in MSIE 5.x
   (`(chop ".pdf") "application/pdf")    #? ..
   (`(chop ".jar") "application/java-archive") )


### HTTP-Client ###
(de client ("Host" "Port" "Name" . "Prg")
   (when (setq "Host" (connect "Host" (default "Port" 80)))
      (out "Host"
         (prinl "GET /" "Name" " HTTP/1.1")
         (prinl "Connection: close")
         (prinl "User-Agent: Pico")
         (prinl "Host: " "Host" ":" "Port")
         (prinl "Accept:  text/html, text/plain")
         (prinl "Accept-Language: en")
         (prinl "Accept-Charset: utf-8")
         (prinl)
         (flush)
         (prog1
            (in "Host" (run "Prg"))
            (close "Host") ) ) ) )

# Local Password
(de pw ()
   (in ".pw" (read)) )

# Pico Shell
(de psh (Pw Tty)
   (when (and (= Pw (pw)) (in (list "ps" (pack "t" Tty)) (from "/psh ")))
      (ctty Tty)
      (out NIL (load "dbg.l" NIL))
      (bye) ) )

### HTTP-Server ###
(de server (P H)
   (setq
      *Port P
      *Home (cons H (chop H))
      P (port P) )
   (use S
      (do NIL
         (setq S (listen P))
         (NIL (fork) (close P))
         (close S) )
      (http S)
      (task (or *Sock (bye))
         (http (or (listen *Sock 60000) (quit "Bad Client"))) ) ) )

(de baseHRef ()
   (pack
      (or *Gate "http") "://" *Host
      (if *Gate "/" ":") *Port "/" ) )

(de https @
   (pass pack "https://" *Host "/" *Port "/" *SesId) )

(de sesId @
   (pass pack *SesId) )

(de software-lab ()
   (<right> "<A HREF=\"http://www.software-lab.de\">(c) Software Lab.</A>") )

# Init crypt
(de rsa (N)
   (seed (in "/dev/urandom" (rd 20)))
   (setq *InND (rsaKey N))
   (off *OutN) )

# Application startup page
(de app ()
   (unless *Sock
      (setq
         *SesId (pack (fmt64 (in "/dev/urandom" (rd 6))) "~")
         *Sock (port *HPorts '*Port) ) ) )

(de allow (F)
   (if *Allow
      (?push '*Allow F)
      F ) )

# Handle HTTP-Transaction
(de http (S)
   (use (L @U X)
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
               (T (quit ": Bad HTTP Request" L)) )
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
            (timeout `(* 20 60000))
            (unless (setq X (htDecode @U))
               (setq  X (car *Home)  @U (cdr *Home)) )
            (when
               (or
                  (format X)
                  (tmp? X)
                  (not *Allow)
                  (find '((P) (pre? P X)) *Allow) )
               (or (= *ConId *SesId) (throw "http"))
               (out S
                  (cond
                     ((= X "0")
                        (html NIL
                           (prinl "<TABLE WIDTH=\"100%\"><TR>")
                           (let N 0
                              (mapc
                                 '((L)
                                    (prin
                                       "<TD ALIGN=\"CENTER\"><A HREF=\""
                                       *SesId
                                       (inc 'N)
                                       "\" TARGET=\"MENU\">"
                                       (cadr L) )
                                    (when (car L)
                                       (prin "<IMG SRC=\"" *SesId (car L) "\">") )
                                    (prinl "</A></TD>") )
                                 *Frame ) )
                           (prinl "</TR></TABLE>") ) )
                     ((<= "1" X "9")
                        (html NIL
                           (prEval (nth *Frame (format X) 3)) ) )
                     ((member '@ @U)
                        (apply (val (intern (htDecode (cdr @)))) L) )
                     ((= '("." "l") (tail 2 @U))
                        (load X) )
                     ((= '("." "h" "t" "m" "l") (tail 5 @U))
                        (httpEcho X) )
                     ((assoc (tail 4 @U) *Mimes)
                        (apply httpEcho (cdr @) X) )
                     ((call "test" "-d" X)
                        (load (pack X "default")) )
                     (T (httpEcho X "application/octet-stream" T T)) ) ) ) ) )
      (close S) ) )

(de _htHead ()
   (use (L @X)
      (if (index "~" @U)
         (setq *ConId (pack (head @ @U))  @U (cdr (nth @U @)))
         (off *ConId) )
      (off *Gate)
      (while (setq L (line))
         (cond
            ((=T L) (throw "http"))
            ((match '(~(chop "Gate: ") . @X) L)
               (setq *Gate (pack @X)) )
            ((match '(~(chop "Host: ") . @X) L)
               (setq *Host
                  (pack
                     (cond
                        (*Gate @X)
                        ((index ":" @X) (head (- @ 1) @X))
                        (T @X) ) ) ) )
            ((match '(~(chop "Content-@ype: multipart/form-data; boundary=") . @X) L)
               (setq
                  *MPartLim (append '(- -) @X)
                  *MPartEnd (append *MPartLim '(- -)) ) )
            ((match '(~(chop "Content-@ength: ") . @X) L)
               (setq *ContLen (format (pack @X))) ) ) ) ) )

# rfc1867 multipart/form-data
(de _htMultipart ()
   (use (L @N @V @X)
      (setq L (line))
      (while (= *MPartLim L)
         (when
            (match
               '(~(chop "Content-Disposition: form-data; name=\"") @N "\"" . @X)
               (line) )
            (while (line)
               (when (=T @)
                  (throw "http") ) )
            (cond
               ((not @X)
                  (_htSet @N
                     (pack
                        (make
                           (until
                              (or
                                 (= *MPartLim (setq L (line)))
                                 (= *MPartEnd L) )
                              (when (made)
                                 (link "^J") )
                              (link L) ) ) ) ) )
               ((match '(~(chop "; filename=\"") @V "\"") @X)
                  (when @V
                     (while (or (member "/" @V) (member "\\" @V))
                        (setq @V (cdr @)) )
                     (let F (tmp (_htSet @N (pack @V)))
                        (unless (out F (echo (pack "^M^J" *MPartLim)))
                           (call "rm" "-f" F) ) ) )
                  (let C (char)
                     (and (= "^M" C) (setq C (char)))
                     (setq L (if (= "^J" C) *MPartLim *MPartEnd)) ) ) ) ) ) ) )

(de _htSet ("Var" Val)
   (use (@V @N)
      (setq "Var"
         (intern
            (pack
               (if (match '("*" @V "(" @N ")") "Var")
                  (setq @N (_htArg @N)  @V (cons "*" @V))
                  (off @N)
                  "Var" ) ) ) )
      (or
         (not *Allow)
         (memq "Var" *Allow)
         (throw "http") )
      (cond
         ((not @N) (set "Var" Val))
         ((assoc @N (val "Var")) (con @ Val))
         (T (queue "Var" (cons @N Val))) ) ) )

(de _htArg (Lst)
   (cond
      ((format (pack Lst)) @)
      ((and (= "[" (car Lst)) (= "]" (last Lst)))
         (intern (htDecode (cdr (head -1 Lst)))) )
      ((and (= "{" (car Lst)) (= "}" (last Lst)))
         (extern (pack (cdr (head -1 Lst)))) )
      ((and (= "(" (car Lst)) (= ")" (last Lst)))
         (mapcar _htArg (split (cdr (head -1 Lst)) "_")) )
      (T (htDecode Lst)) ) )

(de _htFmt (X)
   (cond
      ((or (num? X) (ext? X))
         X )
      ((str? X)
         (pack (htEncode X)) )
      ((pair X)
         (pack "("
            (maplist
               '((L)
                  (cons
                     (_htFmt (car L))
                     (and (cdr L) "_") ) )
               X )
            ")" ) )
      (T (pack "[" (htEncode X) "]")) ) )

(de htEncode (X)
   (mapcar
      '((C)
         (if (sub? C " \"%&()=?[]_{}")
            (pack "%" (hex (char C)))
            C ) )
      (chop X) ) )

(de htDecode (Lst)
   (pack
      (make
         (while Lst
            (link
               (case (pop 'Lst)
                  ("%"
                     (let N (hex (cut 2 'Lst))
                        (char
                           (cond
                              ((< N 128) N)
                              ((< N 224)
                                 (|
                                    (>> -6 (& 31 N))
                                    (_utf6bit) ) )
                              (T
                                 (|
                                    (>> -12 (& 15 N))
                                    (>> -6 (_utf6bit))
                                    (_utf6bit) ) ) ) ) ) )
                  (T @) ) ) ) ) ) )

(de _utf6bit ()
   (pop 'Lst)
   (& 63 (hex (cut 2 'Lst))) )

(de htFmt @
   (pack
      (make
         (while (args)
            (link (_htFmt (next)))
            (and (args) (link "&")) ) ) ) )

(de htmlVar ("Var")
   (prin "NAME=\"")
   (if (pair "Var")
      (prin (car "Var") "(" (_htFmt (cdr "Var")) ")")
      (prin "Var") )
   (prin "\"") )

(de htmlVal ("Var")
   (if (pair "Var")
      (cdr (assoc (cdr "Var") (val (car "Var"))))
      (val "Var") ) )

# Http Transfer Header
(de _http (Typ Upd)
   (prinl "HTTP/1.1 200 OK")
   (prinl "Server: Pico")
   (prinl "Connection: close")
   (when Upd
      (prinl "Cache-Control: no-cache") )
   (prinl "Content-Type: " (or Typ "text/html; charset=utf-8")) )

(de httpHead (Typ)
   (_http Typ T)
   (prinl) )

# Http Echo
(de httpEcho (File Typ Upd Att)
   (_http Typ Upd)
   (prinl "Content-Length: " (car (info File)))
   (when Att
      (let F (chop File)
         (while (member "/" F)
            (setq F (cdr @)) )
         (prinl "Content-Disposition: attachment; filename=\"" F "\"") ) )
   (prinl)
   (in File (echo)) )

# Ouput navigation links
(de navi ()
   (<href> "<<<" "javascript:history.back()" (and *Frame "MAIN"))
   (if *U1
      (<href> "---" (sesId *U1) (and *Frame "MAIN"))
      (prin "---") )
   (<href> ">>>" "javascript:history.forward()" (and *Frame "MAIN")) )

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
   (httpHead)
   (prinl
      "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 "
      (if (num? (car "Prg")) "Frameset" "Transitional")
      "//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">" )
   (prinl "<HTML>")
   (prinl "<HEAD>")
   (prinl "<BASE HREF=\"" (baseHRef) "\">")
   (and "Ttl" (prinl "<TITLE>" "Ttl" "</TITLE>"))
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

(de refresh (Url)
   (setq Url (pack (baseHRef) *SesId Url))
   (httpHead)
   (prinl "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">")
   (prinl "<HTML>")
   (prinl "<HEAD>")
   (prinl "<META http-equiv=\"refresh\" content=\"0; URL=" Url "\">")
   (prinl "</HEAD>")
   (prin "<BODY>")
   (<href> Url Url)
   (prinl "</BODY>")
   (prinl "</HTML>") )

(de <head> (S N)
   (if N
      (prinl "<H" N ">" S "</H" N ">")
      (prin
         "<TABLE WIDTH=\"100%\"><TR><TD ALIGN=\"LEFT\"><H3>"
         S
         "</H3></TD><TD ALIGN=\"RIGHT\">" )
      (navi)
      (prinl "</TD></TR></TABLE>") ) )

(de <item> ("X")
   (cond
      ((atom "X") (prinl "X"))
      ((=T (car "X")) (apply <href> (cdr "X")))
      (T (eval "X")) ) )

(de <br> @
   (when (args)
      (<item> (next))
      (while (args)
         (prin " ")
         (<item> (next)) ) )
   (prinl "<br>") )

(de <center> (S N)
   (default N 3)
   (prinl "<H" N " ALIGN=\"CENTER\">" S "</H" N ">") )

(de <right> (S)
   (prinl "<P ALIGN=\"RIGHT\">" S) )

(de <bold> (S)
   (prinl "<B>" S "</B>") )

(de <href> (S Url Tar)
   (prin "<A HREF=\"" Url)
   (cond
      (Tar (prin "\" TARGET=\"" Tar))
      (*Frame (prin "\" TARGET=\"MAIN\"")) )
   (prin "\">" S "</A>") )

(de <img> (S A Url)
   (and Url (prin "<A HREF=\"" Url  "\">"))
   (prin "<IMG SRC=\"" *SesId S "\" ALT=\"" A "\">")
   (and Url (prin "</A>")) )

(de <list> @
   (prinl "<UL>")
   (while (args)
      (prin "<LI>")
      (<item> (next)) )
   (prinl "</UL>") )

(de <pre> "Prg"
   (prinl "<PRE>")
   (prEval "Prg")
   (prinl "</PRE>") )


### Tables ###
(de <table> ("Bord" "Ttl" "Head" . "Prg")
   (prinl "<TABLE" (and "Bord" " BORDER=\"1\"") ">")
   (when "Ttl"
      (prinl "<CAPTION>" "Ttl" "</CAPTION>") )
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
               ">"
               (cadr L) )
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


### HTML Form ###
(de <post> ("S" . "Prg")
   (prinl
      "<FORM ENCTYPE=\"multipart/form-data\" ACTION=\""
      (baseHRef) *SesId "S"
      "\" METHOD=POST>" )
   (prEval "Prg")
   (prinl "</FORM>") )

(de <get> ("S" . "Prg")
   (prinl "<FORM ACTION=\""
      (baseHRef) *SesId "S"
      "\" METHOD=GET>" )
   (prEval "Prg")
   (prinl "</FORM>") )

(de <field> (N S "Var" Url)
   (when S
      (if Url (<href> S Url) (prin S))
      (space) )
   (prin "<INPUT TYPE=TEXT ")
   (htmlVar "Var")
   (prinl " VALUE=\"" (htmlVal "Var") "\" SIZE=" N ">") )

(de <hidden> ("Var" "Val")
   (prin "<INPUT TYPE=HIDDEN ")
   (htmlVar "Var")
   (prinl " VALUE=\"" "Val" "\">") )

(de <upload> (N S "Var" Url)
   (when S
      (if Url (<href> S Url) (prin S))
      (space) )
   (prin "<INPUT TYPE=FILE ")
   (htmlVar "Var")
   (prinl " VALUE=\"" (htmlVal "Var") "\" SIZE=" N ">") )

(de <area> (Cols Rows S "Var" Url)
   (when S
      (if Url (<href> S Url) (prin S))
      (space) )
   (prin "<TEXTAREA ")
   (htmlVar "Var")
   (prin " COLS=" Cols " ROWS=" Rows ">" (htmlVal "Var"))
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
   (prinl " VALUE=\"T\"" (and (htmlVal "Var") " CHECKED") ">" S) )

(de <radio> ("Var" Val S)
   (prin "<INPUT TYPE=RADIO ")
   (htmlVar "Var")
   (prin " VALUE=\"" Val "\"" (and (= Val (htmlVal "Var")) " CHECKED") ">" S) )

(de <submit> (S)
   (prinl "<INPUT TYPE=SUBMIT VALUE=\"" S "\">") )

(de <reset> (S)
   (prinl "<INPUT TYPE=RESET VALUE=\"" S "\">") )


### Applets ###
(de dispatch ()
   (timeout `(* 20 60000))
   (in *App
      (let S (rd)
         (cond
            ((not S) (bye))
            ((num? S))
            ((pair S))
            ((=T S) (push '*AppId (rd)))
            ((<> meth (val S))
               (out NIL (prinl ">> " S " <<")) )
            ((get *Apps (rd))
               (send S (setq *Top @)) )
            ((assoc S *Events)
               (do (cdr @) (rd)) ) ) ) ) )

(de url (Str Tar . @)
   (when Str
      (out *App
         (pr
            (get *Top 'id)
            "url"
            (pack
               (baseHRef)
               *SesId
               Str
               (and (args) (pack "?" (pass htFmt))) )
            (or Tar (if *Frame "MAIN" "_self")) ) ) ) )

(de url1 (Str)
   (setq *U1 (chop Str))
   Str )

(de bar (Ttl X Y Prg)
   (prinl Ttl "<hr>")
   (setq *Bar (new '(+Form) X Y Prg))
   (navi) )

(de initAppId ()
   (if *AppId
      (set (nth *Apps (=: id (pop '*AppId))) This)
      (=: id (+ 1 (length *Apps)))
      (queue '*Apps This) ) )


(class +Applet)
# id run

(dm T (A J DX DY . @)
   (unless *AppPort
      (task (setq "Sok1" (port *APorts '*AppPort))
         (task "Sok1")  # Only once
         (task -40000 40000
            (out *App (pr 0)) )
         (task (setq *App (or (listen "Sok1" 60000) (quit "Bad Applet")))
            (dispatch) ) ) )
   (initAppId)
   (prinl "<APPLET CODE=\"" A ".class\" ARCHIVE=\"" *SesId J
      "\" WIDTH=" DX " HEIGHT=" DY ">" )
   (prinl "<PARAM NAME=\"ID\" VALUE=\"" (: id) "\">")
   (prinl "<PARAM NAME=\"port\" VALUE=\"" *AppPort "\">")
   (when *AppGate
      (prinl "<PARAM NAME=\"gate\" VALUE=\"" *AppGate "\">") )
   (while (args)
      (prinl "<PARAM NAME=\"" (next) "\" VALUE=\"" (next) "\">") )
   (prinl "</APPLET>") )

(dm close> ()
   (set (nth *Apps (: id)))
   (out *App
      (pr (- (: id))) ) )

(dm init> ())

(dm start> ()
   (=: run T) )

(dm upd> ())

(dm paint> ())

(dm stop> ()
   (=: run) )

(dm esc> ()
   (beep> This) )

(dm rsa> ()
   (setq *OutN (rd)) )

(dm cmd> ()
   (eval (nth *Menu (rd) 3)) )

(dm beep> ()
   (out *App
      (pr (: id) "beep") ) )

(dm play> (X)
   (out *App
      (pr (: id) "play" X) ) )

(dm menu> (Ttl Lst)
   (out *App
      (pr (: id) "menu" Ttl (length Lst))
      (mapc
         '((L) (pr (car L) (eval (cadr L))))
         (setq *Menu Lst) ) ) )


### Applet Form ###
# *Lay

(class +Form +Applet)
# init fields arrays focus focus2 hot able lock rv

(de gui @
   (pr *Lay)
   (cond
      ((pair (next)) (pass new (arg)))
      ((and (not (: fields)) (get *Top (arg)))
         (quit "Conflict" (arg)) )
      (T (put *Top (arg) (pass new (next)))) )
   (setq *Lay '+) )

(de txt @
   (pr *Lay)
   (pr (next) -1)  # Label WEST
   (while (args)
      (pr '- (next) 0) )  # SOUTH
   (setq *Lay '+) )

(de row "Prg"
   (_row) )

(de flow "Prg"
   (pr "[")
   (_row)
   (pr "]") )

(de _row ()
   (eval (pop '"Prg"))
   (while "Prg"
      (setq *Lay '-)
      (eval (pop '"Prg")) ) )

(de ---- (Flg)
   (setq *Lay (if Flg '/ '*)) )

(de -|- (Flg)
   (setq *Lay (if Flg ': '=)) )


(dm T (DX DY Prg)
   (super "Front" "pico.jar" DX DY)
   (=: init Prg) )

(dm init> ()
   (super)
   (out *App
      (pr (: id) "make")
      (let *Lay '*
         (=: fields (make (run (: init)))) )
      (pr NIL) )
   (let I 0
      (mapc
         '((F)
            (put F 'ix (inc 'I))
            (init> F) )
         (: fields) ) )
   (mapc 'init> (: arrays)) )

(dm start> ()
   (super)
   (mapc 'start> (: fields))
   (mapc 'start> (: arrays))
   (upd> This)
   (focus1> This) )

(dm focus1> ()
   (find
      '((F)
         (and
            (isa '+TextField F)
            (able?> F)
            (t (focus> F)) ) )
      (: fields) ) )

(dm upd> ()
   (super)
   (mapc
      '((F) (or (get F 'touch) (upd> F)))
      (: fields) )
   (mapc
      '((A) (or (get A 'touch) (upd> A)))
      (: arrays) )
   (able> This) )

(dm stop> ()
   (fieldEnd)
   (mapc 'stop> (: fields))
   (mapc 'stop> (: arrays))
   (super) )

(dm able> ()
   (unless (: lock)
      (mapc 'able> (: able)) ) )

(dm lock> (Flg)
   (out *App
      (pr (: id) "lock" (bool (=: lock Flg))) )
   (upd> This) )

(dm focus> (F)
   (=: focus F)
   (out *App
      (pr (: id) "focus" (get F 'ix)) ) )

(dm next> ()
   (out *App
      (pr (: id) "next") ) )

(dm menu> (F Ttl Lst)
   (out *App
      (pr (: id) "menu" (get F 'ix) Ttl (length Lst))
      (mapc
         '((L) (pr (car L) (eval (cadr L))))
         (setq *Menu Lst) ) ) )

# Events
# ix
(dm clk> ()
   (clk> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm drg> ()
   (drg> (get (: fields) (rd)) (rd) (rd) (rd)) )

(dm adv> ()
   (put (: fields) (rd) 'adv (rd)) )

(dm act> ()
   (let F (get (: fields) (rd))
      (and (fieldEnd) (= F (: focus)) (act> F))
      (when (get *Apps (: id))
         (out *App (pr (: id) "ack")) ) ) )

# sym
(dm key> ()
   (let X (rd)
      (when (: focus)
         (ifn (key> (: focus) X)
            (beep> This)
            (type> (: focus) @)
            (=: focus touch T)
            (and (: focus arr) (=: focus arr touch T)) ) ) ) )

(dm ret> ()
   (use (B L)
      (ifn
         (and
            (setq B (: focus arr))
            (isa '+Chart B)
            (setq L
               (seek
                  '((L) (memq (: focus) (car L)))
                  (get B 'fields) ) )
            (not
               (find 'able?> (cdr (memq (: focus) (car L)))) )
            (not
               (find '((L) (find 'able?> L)) (cdr L)) ) )
         (next> This)
         (focus> (car (last (get B 'fields))))
         (send 'DN> B) ) ) )

(de _boxSend X
   (ifn
      (mini
         '((F)
            (or
               (not (get F 'arr))
               (abs (- (: focus ix) (get F 'ix))) ) )
         (: fields) )
      (beep> This)
      (let A (get @ 'arr)
         (when (fieldEnd)
            (send (car X) A) ) ) ) )

(dm PGUP> ()
   (_boxSend PGUP>) )

(dm PGDN> ()
   (_boxSend PGDN>) )

(dm END> ()
   (_boxSend END>) )

(dm BEG> ()
   (_boxSend BEG>) )

(dm UP> ()
   (_boxSend UP>) )

(dm DN> ()
   (_boxSend DN>) )

(dm DEL> ()
   (_boxSend DEL>) )

(dm INS> ()
   (_boxSend INS>) )


# Help
(dm F1> ()
   (if help
      (help This)
      (url "lib/help.l") ) )

# Choice
(dm F2> ()
   (if (and (not (: lock)) (: focus) (cho> (: focus)))
      (menu> This (: focus) `(_ "F2-Choice") @)
      (beep> This) ) )

# Field Hot-Action
(dm F3> ()
   (ifn (: focus)
      (beep> This)
      (when (fieldEnd)
         (act> (: focus)) ) ) )

# Form Hot-Action
(dm F4> ()
   (ifn (: hot)
      (beep> This)
      (when (fieldEnd)
         (act> (: hot)) ) ) )

# Undo
(dm F5> ()
   (if (: focus undo)
      (undo> (: focus))
      (beep> This) ) )

# Redo
(dm F6> ()
   (if (: focus redo)
      (redo> (: focus))
      (beep> This) ) )

(dm F7> ()
   (beep> This) )

(dm F8> ()
   (beep> This) )

(dm F9> ()
   (beep> This) )

(dm F10> ()
   (beep> This) )

(dm F11> ()
   (beep> This) )

(dm F12> ()
   (beep> This) )

# ix sym|flg sel
(dm chg> ()  # Change string
   (=: "last")
   (chg> (get (: fields) (rd))) )

# ix sym|flg sel
(dm log> ()  # Change string and log state
   (=: "last")
   (log> (get (: fields) (rd))) )

# ix
(dm nxt> ()
   (let F (get (: fields) (rd))
      (when (fieldEnd)
         (when (isa '+TextField F)
            (=: focus2 F) )
         (beg> (=: focus F)) ) ) )

# ix val
(dm scr> ()
   (let (N (rd)  P (rd))
      (when (fieldEnd)
         (scr> (get (: fields) N) P) ) ) )


# Clear undo/redo
(de zapUndo ()
   (mapc
      '((L) (mapc 'zapUndo> L))
      (: fields) ) )

# Enter value into current focus field
(de setFocus (Val)
   (set> (: focus) Val)
   (able> This)
   (next> This) )

# Field end processing
(de fieldEnd ()
   (cond
      ((not (: run)))
      ((not (: focus)) T)
      ((: focus ign) T)
      ((or (chk> (: focus)) (and (: focus arr) (chk> (: focus arr))))
         (let Err @
            (or
               (== (: "last") (: focus))
               (and (: top) (not (: on)))
               (nil
                  (=: "last" (: focus))
                  (beep> This)
                  (focus> (: "last"))
                  (alert "Check"
                     (if (: "last" lbl)
                        (cons
                           (pack "*** " @ " ***")
                           (if (pair Err) Err (cons Err)) )
                        Err ) )
                  (when (: "last" undo)
                     (undo> (: "last")) ) ) ) ) )
      (T
         (end> (: focus))
         (and (: focus arr) (end> @))
         (=: focus touch NIL)
         (and (: focus arr) (=: focus arr touch NIL))
         T ) ) )


### Form Prefix Classes ###
(class +View)
# "view"

(dm T (Flg . @)
   (=: "view" Flg)
   (pass extra) )

(dm init> ()
   (extra)
   (lock> This (: "view")) )


### Dialogs ###
(class +Dialog +Form)
# top on args

(dm T ("Ttl" "Lst" "Args")
   (initAppId)
   (out *App
      (pr (get (=: top *Top) 'id) "dialog" "Ttl" (: id)) )
   (=: init "Lst")
   (=: args "Args")
   (wait NIL (: on)) )

(dm init> ()
   (=: on T)
   (super)
   (mapc
      '((V F) (and V (set> F V)))
      (if (lst? (: args))
         (: args)
         (car (val (: args))) )
      (: fields) )
   (unless (lst? (: args))
      (mapc
         '((L B)
            (while L
               (put B (caar L) (cdr (pop 'L))) ) )
         (cdr (val (: args)))
         (: arrays) ) )
   (start> This) )

(dm stop> ()
   (unless (lst? (: args))
      (set (: args)
         (cons
            (mapcar 'val> (: fields))
            (mapcar 'stat> (: arrays)) ) ) )
   (=: on)
   (super)
   (close> This)
   (setq *Top (: top)) )


(de alert (Ttl @X)
   (with
      (new '(+Dialog) Ttl
         (cons
            (fill
               (if (pair @X)
                  '(mapc txt '@X)
                  '(txt @X) ) )
            '((okButton)) ) )
      (wait NIL (not (: on))) ) )

(de ask (Ttl @X)
   (with
      (new '(+Dialog) Ttl
         (cons
            (fill
               (if (pair @X)
                  '(mapc txt '@X)
                  '(txt @X) ) )
            '((----)
               (row (okButton NIL `(_ "Yes")) (quitButton `(_ "No"))) ) ) )
      (wait NIL (not (: on)))
      (: rv) ) )

(de confirm ("Ttl" "@X" "Exe")
   (with
      (new '(+Dialog) "Ttl"
         (cons
            (fill
               (if (pair "@X")
                  '(mapc txt '"@X")
                  '(txt "@X") ) )
            (quote
               (----)
               (row
                  (okButton NIL `(_ "Yes"))
                  (gui '(+Button) "" `(_ "No")
                     '(prog (=: home rv 0) (stop> (: home))) )
                  (quitButton) ) ) ) )
      (wait NIL (not (: on)))
      (when (=T (: rv))
         (eval "Exe") )
      (: rv) ) )

(de dialog ("Ttl" "Args" "Lst")
   (with (new '(+Dialog) "Ttl" "Lst" "Args")
      (wait NIL (not (: on)))
      (: rv) ) )

# Dialog Buttons
(de okButton (@Exe S)
   (gui '(+Button) "" (or S "Ok")
      (cons 'prog
         (ifn @Exe
            '((=: home rv T) (stop> (: home)))
            (list
               (fill '(=: home rv @Exe))
               '(stop> (: home)) ) ) ) ) )

(de quitButton (S)
   (gui '(+Rid +Button) "" (or S `(_ "Cancel"))
      '(stop> (: home)) ) )


### Busy/Progress indicator ###
(====)
(off "Busy")

(class +BusyDialog +Dialog)
# prg work ind

(dm T (Ttl Cnt Prg Lst)
   (=: work Cnt)
   (=: prg Prg)
   (setq "Busy" This)
   (super Ttl Lst) )

(dm paint> ()
   (super)
   (run (: prg))
   (stop> This) )

(dm stop> ()
   (super)
   (off "Busy") )


# Busy/Progress utilities
(de busy ("Cnt" "Msg" . "Prg")
   (ifn *Top
      (run "Prg")
      (catch "busy"
         (new '(+BusyDialog) `(_ "Please wait") "Cnt" "Prg"
            (quote
               (mapc txt "Msg")
               (----)
               (row
                  (quitButton)
                  (gui 'ind '(+Mono +Label) "->" (pack "Cnt" "        ")) ) ) )
         (wait NIL (not "Busy")) ) ) )

(de work ()
   (when *Top
      (if "Busy"
         (with @
            (set> (: ind)
               (format (abs (dec (:: work)))) ) )
         (throw "busy") ) ) )
(====)


### Field Prefix Classes ###
(class +Map +Sync)
# map

(dm T (Lst . @)
   (=: map Lst)
   (pass super) )

(dm key> (C)
   (let H
      (pack
         (head (: sel) (chop (: str)))
         (setq C (extra C)) )
      (if
         (find
            '((X) (pre? H (car X)))
            (: map) )
         (pack (nth (chop (car @)) (+ 1 (: sel))))
         C ) ) )

(dm set> (Val)
   (extra
      (if
         (seek
            '((X) (= Val (cdar X)))
            (: map) )
         (caar @)
         Val ) ) )

(dm val> ()
   (let V (extra)
      (if (assoc V (: map))
         (cdr @)
         V ) ) )

(dm cho> ()
   (let H (pack (head (: sel) (chop (: str))))
      (mapcan
         '((X)
            (when (pre? H (car X))
               (cons (mkCho (car X) (cdr X))) ) )
         (: map) ) ) )


(class +Mac)
# mac

(dm T (Lst . @)
   (mac> This Lst)
   (pass extra) )

(dm mac> (Lst)
   (let N 0
      (=: mac
         (mapcar
            '((X)
               (cond
                  ((num? X) (setq X (chop (format X))))
                  ((sym? X) (setq X (chop X))) )
               (when (> (length X) N)
                  (setq N (length X)) )
               X )
            Lst ) )
      (=: mac (cons N (: mac))) ) )

(dm cho> ()
   (if (=0 (: sel))
      (mapcar
         '((X) (mkCho (pack X)))
         (cdr (: mac)) )
      (let H
         (tail
            (car (: mac))
            (head (: sel) (chop (: str))) )
         (mapcan
            '((M)
               (when
                  (seek
                     '((S) (not (find <> S M)))
                     H )
                  (cons
                     (list
                        (pack M)
                        T
                        'type>
                        '(: focus)
                        (lit (nth M (+ 1 (length @)))) ) ) ) )
            (cdr (: mac)) ) ) ) )

(class +Macro +Sync +Mac)

(dm key> (C)
   (when (setq C (extra C))
      (let H
         (append
            (tail
               (car (: mac))
               (head (: sel) (chop (: str))) )
            (cons C) )
         (use M
            (if
               (seek
                  '((S)
                     (setq M
                        (find
                           '((M) (not (find <> S M)))
                           (cdr (: mac)) ) ) )
                  H )
               (pack (nth M (length @)))
               C ) ) ) ) )


# F2-Choice
(class +Cho)
# cho

(dm T (Foo . @)
   (=: cho Foo)
   (pass extra) )

(dm cho> ()
   (mapcar
      '((L)  # ("key" T  setFocus (quote . Obj))
         (cons
            ((: cho) (car L) (eval (cadddr L)))
            (cdr L) ) )
      (extra) ) )


(class +Uppc)

(dm key> (C)
   (uppc (extra C)) )


# Field enable/disable
(class +Able)

(dm T (Exe . @)
   (=: able Exe)
   (put *Top 'able
      (cons This (get *Top 'able)) )
   (pass extra)
   (pr "able") )

(dm cho> ()
   (when (eval (: able))
      (extra) ) )


(class +Lock +Able)

(dm T @
   (pass super NIL) )


# Able prefix
(class +Skip)

(dm beg> ()
   (if (eval (: able))
      (extra)
      (next> (: home)) ) )


# Escape from Form lock
(class +Rid)

(dm T @
   (pass extra)
   (pr "rid") )

(dm upd> ()
   (extra)
   (and
      (: home lock)
      (memq This (: home able))
      (able> This) ) )


# Field display
(class +Font)

# "Helvetica" "SansSerif" "serif" "Monospaced"
(dm T (Name Size . @)
   (pass extra)
   (pr Name Size) )

(class +Mono +Font)

(dm T @
   (pass super "Monospaced" 12) )


(class +Align +Mono)

(dm set> (Val)
   (extra (and Val (align (: dx) Val))) )


(class +Sync)

(dm T @
   (pass extra)
   (pr "sync") )


(class +Limit +Sync)
# lim

(dm T (N . @)
   (=: lim N)
   (pass super) )

(dm key> (C)
   (when (> (: lim) (length (: str)))
      (extra C) ) )

(dm chk> ()
   (or
      (and (> (length (: str)) (: lim)) `(_ "Text too long"))
      (extra) ) )


(class +Color)

(dm T (B F . @)
   (pass extra)
   (and B (pr "bCol" B))
   (and F (pr "fCol" F)) )


(class +Radio)
# radio

(dm T (Lst . @)
   (=: radio Lst)
   (pass extra) )

(dm set> (Val)
   (extra Val)
   (when Val
      (mapc
         '(("X")
            (clr> (field "X")) )
         (: radio) ) ) )



(class +Relay)
# relay

(dm T (Lst . @)
   (=: relay Lst)
   (pass extra) )

(dm relay> (Val)
   (mapc
      '(("X")
         (if (atom "X")
            (set> (field "X") Val)
            (set> (field (car "X"))
               (if (or (atom (cdr "X")) (lst? (cadr "X")))
                  ((cdr "X") Val)
                  (with Val (eval (cdr "X"))) ) ) ) )
      (: relay) ) )

(dm upd> ()
   (extra)
   (relay> This (val> This)) )

(dm set> (Val)
   (let Old (val> This)
      (extra Val)
      (let Val (val> This)
         (unless (= Old Val)
            (relay> This Val) ) ) ) )

(dm end> ()
   (extra)
   (relay> This (val> This)) )


(class +Hot)
# hot

(dm T (Exe . @)
   (=: hot Exe)
   (pass extra)
   (hotField) )

(dm act> ()
   (eval (: hot)) )


(class +Init)
# init

(dm T (Exe . @)
   (=: init Exe)
   (pass extra) )

(dm init> ()
   (eval (: init))
   (extra) )


(class +Start)
# start

(dm T (Exe . @)
   (=: start Exe)
   (pass extra) )

(dm start> ()
   (eval (: start))
   (extra) )


(class +Set)
# set

(dm T (Foo . @)
   (=: set Foo)
   (pass extra) )

(dm set> (Val)
   ((: set) Val) )


(class +Clr)
# clr

(dm T (Exe . @)
   (=: clr Exe)
   (pass extra) )

(dm clr> ()
   (eval (: clr)) )


(class +Fmt)
# set val

(dm T (Foo1 Foo2 . @)
   (=: set Foo1)
   (=: val Foo2)
   (pass extra) )

(dm set> (Val)
   (extra ((: set) Val)) )

(dm val> ()
   ((: val) (extra)) )


(class +Upd)
# upd

(dm T (Exe . @)
   (=: upd Exe)
   (pass extra) )

(dm upd> ()
   (eval (: upd)) )


(class +Var)
# var

(dm T (Var . @)
   (=: var Var)
   (pass extra) )

(dm set> (Val)
   (extra (set (: var) Val)) )

(dm upd> ()
   (extra)
   (set> This (val (: var))) )


(class +Beg)
# beg

(dm T (Exe . @)
   (=: beg Exe)
   (pass extra) )

(dm beg> ()
   (eval (: beg))
   (extra) )


(class +Chg)
# chg

(dm T (Exe . @)
   (=: chg Exe)
   (pass extra) )

(dm chg> ()
   (extra)
   (eval (: chg)) )


(class +Chk)
# chk

(dm T (Exe . @)
   (=: chk Exe)
   (pass extra) )

(dm chk> ()
   (eval (: chk)) )


(class +End)
# end

(dm T (Exe . @)
   (=: end Exe)
   (pass extra) )

(dm end> ()
   (eval (: end)) )


### Form Field Classes ###
(class +field)
# home ix lbl str sel ign arr able undo redo adv

(dm T ()
   (=: home *Top)
   (=: sel 0)
   (link This) )

(dm init> ())

(dm start> ())

(dm upd> ())

(dm stop> ())

(dm beg> ())

(dm chg> ()
   (=: str (rd))
   (=: sel (rd)) )

(dm chk> ())
(dm end> ())
(dm cho> ())

(dm log> ()
   (do> This
      (chg> This) ) )

(dm text> (S)
   (out *App
      (pr (: home id) "text" (: ix) S) ) )

(dm type> (S)
   (out *App
      (pr (: home id) "type" (: ix) S) ) )

(dm str> (Str)
   (unless (= Str (: str))
      (=: sel 0)
      (text> This (=: str Str)) ) )

(dm set> (Val)
   (text> This Val) )

(dm clr> ()
   (set> This) )

(dm val> ())

(dm act> ()
   (beep> (: home)) )

(dm key> (C))

(dm do> "Prg"
   (let "S" (: str)
      (run "Prg")
      (unless (= "S" (: str))
         (=: undo (cons "S" (: undo)))
         (=: redo) ) ) )

(dm undo> ()
   (=: redo (cons (: str) (: redo)))
   (str> This (car (: undo)))
   (unless (=: undo (cdr (: undo)))
      (=: touch)
      (and (: arr) (=: arr touch NIL)) ) )

(dm redo> ()
   (=: undo (cons (: str) (: undo)))
   (str> This (car (: redo)))
   (=: redo (cdr (: redo)))
   (=: touch T)
   (and (: arr) (=: arr touch T)) ) )

(dm focus> ()
   (focus> (: home) This)
   (beg> This) )

(dm able> ()
   (out *App
      (pr (: home id) "able" (: ix) (bool (eval (: able)))) ) )

(dm able?> ()
   (or
      (not (memq This (: home able)))
      (eval (: able)) ) )

(dm scr> (N)
   (scr> (: arr) N) )

(dm zapUndo> ()
   (=: touch)
   (=: undo)
   (=: redo) )


# Mark hot link field (blue foreground)
(de hotField ()
   (pr "fCol" `(hex "0000FF")) )

# Get field
(de field (X)
   (if (sym? X)
      (get (: home) X)
      (get (: home fields) (+ X (: ix))) ) )

# Get current chart data row
(de curr ()
   (pick
      '((F D) (and (memq This F) D))
      (: arr fields)
      (nth (: arr data) (: arr ofs)) ) )


(class +Button +field)
# exe

(dm T (Ttl Lbl Exe . @)
   (pr Ttl `(char "B") (=: lbl Lbl))
   (=: exe Exe)
   (=: ign T)
   (pass super) )

(dm act> ()
   (eval (: exe)) )

(dm set> (Val)
   (=: lbl Val)
   (super Val) )

(dm val> ()
   (: lbl) )


(class +SetButton +Button)

(dm act> ()
   (when (super)
      (let (Val @  Fld (get (: home fields) (+ 1 (: ix))))
         (focus> Fld)
         (do> Fld
            (if (=T Val)
               (clr> This)
               (set> This Val) ) ) )
      (next> (: home)) ) )


(class +ChgButton +Button)
# chg

(dm T (Ttl Lbl Foo . @)
   (=: chg Foo)
   (pass super Ttl Lbl
      '(let
         (Fld (get (: home fields) (+ 1 (: ix)))
            Val ((: chg) (val> Fld)) )
         (when Val
            (focus> Fld)
            (do> Fld
               (if (=T Val)
                  (clr> This)
                  (set> This Val) ) ) )
         (next> (: home)) ) ) )


(class +ClrButton +Button)
# clr

(dm T (Ttl Lbl Lst . @)
   (=: clr Lst)
   (pass super Ttl Lbl
      '(prog
         (mapc
            '((X)
               (if (atom X)
                  (clr> (get (: home) X))
                  (set> (get (: home) (car X)) (eval (cdr X))) ) )
            (: clr) )
         (able> (: home))
         (focus1> (: home)) ) ) )


(class +Checkbox +field)

(dm T (Ttl . @)
   (pr (=: lbl Ttl) `(char "c"))
   (pass super) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Val)
   (super (=: str (bool Val))) )

(dm val> ()
   (bool (: str)) )


(class +Label +field)

(dm T (Ttl Txt . @)
   (pr (=: lbl Ttl) `(char "L") Txt)
   (=: ign T)
   (pass super) )


(class +DrawField +field)
# dx dy sx sy lst tmp

# (ttl dx dy sx sy)
(dm T (Ttl DX DY . @)
   (pr
      (=: lbl Ttl)
      `(char "D")
      (=: dx DX)
      (=: dy DY) )
   (pass super) )

(dm siz> (SX SY)
   (out *App
      (pr (: home id) "siz" (: ix) (=: sx SX) (=: sy SY)) ) )

(dm set> (Lst)
   (out *App
      (pr (: home id) "set" (: ix)
         (sum 'len> (=: lst Lst)) )
      (mapc 'pr> Lst) ) )

(dm tmp> (Lst)
   (out *App
      (pr (: home id) "tmp" (: ix)
         (sum 'len> (=: tmp Lst)) )
      (mapc 'pr> Lst) ) )

(dm clk> (M X Y))
(dm drg> (M X Y))

(dm new> (Typ . @)
   (prog1
      (pass new Typ This)
      (set> This (cons @ (: lst))) ) )


(class +PictField +field)
# dx dy img

# (ttl dx dy)
(dm T (Ttl DX DY . @)
   (pr
      (=: lbl Ttl)
      `(char "P")
      (=: dx DX)
      (=: dy DY) )
   (pass super) )

(dm set> (Img)
   (out *App
      (ifn (=: img Img)
         (pr (: home id) "img" (: ix) 0)
         (pr (: home id) "img" (: ix) (car (info Img)))
         (in Img (echo)) ) ) )

(dm val> ()
   (: img) )

(dm clk> (M X Y))
(dm drg> (M X Y))


(class +TextField +field)
# dx dy

# (ttl dx [dy])
# (ttl lst)
(dm T (Ttl . @)
   (pr (=: lbl Ttl))
   (if (num? (next))
      (pr `(char "T")                     # TextField or TextArea
         (=: dx (arg))
         (or (=: dy (next)) 0) )
      (pr `(char "C") (length (arg)))     # Choice
      (=: dx (apply max (mapcar length (arg))))
      (mapc pr (arg))
      (=: str (car (arg))) )
   (pass super) )

(dm feed> (N S)  # TextArea only
   (out *App
      (pr (: home id) "feed" (: ix) N S) ) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Val)
   (str> This Val) )

(dm val> ()
   (: str) )

(dm key> (C)
   C )

(de mkCho (Key Val)
   (cons Key
      (cons T
         (list 'setFocus (lit (or Val Key))) ) ) )


# Matchcode Field
(class +McField +Uppc +TextField)

(dm key> (C)
   (and
      (setq C (super C))
      (or (<= "0" C "9") (<= "A" C "Z") (sub? C "#$-@"))
      C ) )


# Secure Transmission Field Prefix
(class +Rsa)

(de outN ()
   (unless *OutN
      (or *InND (quit "No keys"))
      (out *App
         (pr (: home id) "rsa" (car *InND)) ) ) )

(dm T @
   (pass extra)
   (pr "crypt") )

(dm beg> ()
   (outN)
   (extra) )

(dm chg> ()
   (=: str (pack (decrypt *InND (rd))))
   (=: sel (rd)) )

(dm text> (S)
   (outN)
   (wait NIL *OutN)
   (extra (encrypt *OutN (chop S))) )

(dm feed> (N S)  # TextArea only
   (outN)
   (wait NIL *OutN)
   (extra N (encrypt *OutN (chop S))) )

(dm key> (Lst)
   (outN)
   (wait NIL *OutN)
   (encrypt *OutN (chop (extra (car (decrypt *InND Lst))))) )


# Password Field
(class +PwField +Rsa +TextField)

(dm T @
   (pass super)
   (pr "pw") )


# Symbol Fields
(class +SymField +TextField)

(dm val> ()
   (let S (super)
      (and (<> "-" S) (intern S)) ) )


# Class Fields
(class +ClsField +Map +TextField)
# cls

(dm T (Exe Ttl Lst)
   (=: cls Exe)
   (super Lst Ttl (mapcar car Lst)) )

(dm upd> ()
   (set> This (val (eval (: cls)))) )

(dm set> (Val)
   (when (eval (: cls))
      (set @ Val) )
   (super Val) )


# Numeric Fields
(class +DigField +Align +TextField)

(dm key> (C)
   (and (<= "0" C "9") C) )


(class +NumField +DigField)

(dm set> (Val)
   (super (format Val)) )

(dm val> ()
   (format (super)) )


(class +IntField +NumField)

(dm key> (C)
   (and
      (sub? C "+-0123456789")
      C ) )


(class +FixField  +Align +TextField)
# scl

(dm T (N . @)
   (=: scl N)
   (pass super) )

(dm key> (C)
   (and
      (sub? C "+-0,123.456789")
      C ) )

(dm set> (Val)
   (super (format Val (: scl) *Sep0 *Sep3)) )

(dm val> ()
   (let (S (super)  L (chop S))
      (unless (member *Sep0 L)
         (setq S (pack S *Sep0)) )
      (format S (: scl) *Sep0 *Sep3) ) )

# Numeric Field Prefix
(class +NegRed)

(dm set> (Val)
   (out *App
      (pr (: home id) "fCol" (: ix)
         (if (lt0 Val) `(hex "CC0000") 0) ) )
   (extra Val) )


(class +DateField +Limit +TextField)

(dm T @
   (pass super 12) )

(dm key> (C)
   (and
      (setq C (super C))
      (or (= C (cadr *DateFmt)) (sub? C "0123456789"))
      C ) )

(dm cho> ()
   (let (D (or (val> This) (date))  I (- D 8))
      (make
         (do 15
            (link
               (mkCho
                  (pack
                     (datStr (inc 'I))
                     " ("
                     (day I)
                     ")"
                     (and (= D I) " <--") )
                  I ) ) ) ) ) )

(dm act> ()
   (if (val> This)
      (beep> (: home))
      (do> This
         (set> This (date)) ) ) )

(dm set> (Val)
   (super (datStr Val)) )

(dm val> ()
   (expDat (super)) )

(dm chk> ()
   (and
      (: str)
      (not (val> This))
      `(_ "Bad date format") ) )


(class +TimeField +Limit +TextField)

(dm T @
   (pass super 10) )

(dm key> (C)
   (and
      (setq C (super C))
      (sub? C ":0123456789")
      C ) )

(dm cho> ()
   (let Tim (time)
      (list (mkCho (tim$ Tim (> (: dx) 6)) Tim)) ) )

(dm set> (Val)
   (super (tim$ Val (> (: dx) 6))) )

(dm val> ()
   ($tim (super)) )

(dm chk> ()
   (and
      (: str)
      (not (val> This))
      `(_ "Bad time format") ) )


(class +FileField +TextField)
# file org

(dm T (Exe . @)
   (=: file Exe)
   (pass super) )

(dm upd> ()
   (set> This
      (=: org
         (let F (eval (: file))
            (and F
               (call "test" "-f" F)
               (in F (till NIL T)) ) ) ) ) )

(dm set> (Val)
   (and
      (<> Val (: org))
      (eval (: file))
      (out @ (prin Val)) )
   (super Val) )


(class +HttpField +TextField)

(dm T @
   (pass super)
   (hotField) )

(dm act> ()
   (when (val> This)
      (let Val @
         (out *App
            (pr
               (: home id) "url"
               (if (sub? ":/" Val) Val (pack "http://" Val))
               "HTTP" ) ) ) ) )


(class +MailField +TextField)

(dm T @
   (pass super)
   (hotField) )

(dm act> ()
   (when (val> This)
      (out *App
         (pr (: home id) "url" (pack "mailto:" @) "MAIL") ) ) )


### Field Arrays ###
(class +array)
# home fields

(dm T ()
   (=: home *Top)
   (put *Top 'arrays
      (conc (get *Top 'arrays) (cons This)) ) )

(dm init> ())

(dm start> ())

(dm upd> ())

(dm stop> ())

(dm chk> ())
(dm end> ())

(dm set> ())
(dm val> ())
(dm stat> ())

(dm clr> ()
   (set> This) )

(dm PGUP> ()
   (beep> (: home)) )

(dm PGDN> ()
   (beep> (: home)) )

(dm BEG> ()
   (beep> (: home)) )

(dm END> ()
   (beep> (: home)) )

(dm UP> ()
   (beep> (: home)) )

(dm DN> ()
   (beep> (: home)) )

(dm DEL> ()
   (beep> (: home)) )

(dm INS> ()
   (beep> (: home)) )


(class +Array +array)
# put get

# (.. ttl cols foo lst [put [get]])
(dm T ("Ttl" "N" "foo" "Lst" "Put" "Get")
   (super)
   (pr "Ttl" 0)
   (=: put (or "Put" prog1))
   (=: get (or "Get" prog1))
   (mapc
      '((F)
         (link F)
         (put F 'arr This) )
      (=: fields
         (make
            (while "Lst"
               (let *Lay '+
                  (do "N"
                     ("foo" (pop '"Lst"))
                     (NIL "Lst")
                     (setq *Lay '-) ) ) ) ) ) ) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Lst)
   (mapc 'set> (: fields) ((: put) Lst)) )

(dm val> ()
   ((: get)
      (mapcar 'val> (: fields)) ) )


(class +chart +array)
# rows cols put get ofs lock

(de scrl (N)
   (zapUndo)
   (get> This)
   (=: ofs N)
   (put> This)
   (setScroll) )

(de setScroll ()
   (out *App
      (pr (: home id) "scrl"
         (get (caar (: fields)) 'ix)
         (: ofs)  # val
         (: rows) # vis
         (size> This) ) ) )  # max

# (.. rows lst prg [put [get]])
(dm T (N Lst Prg Put Get)
   (super)
   (=: rows N)
   (pr (car Lst) 0)
   (mapc
      '((S) (pr '- S 0))
      (cdr Lst) )
   (=: cols (length (setq Lst Prg)))
   (=: ofs 1)
   (=: put (or Put prog1))
   (=: get (or Get prog1))
   (mapc
      '((L)
         (mapc
            '((F)
               (link F)
               (put F 'arr This) )
            L ) )
      (=: fields
         (make
            (do N
               (let *Lay '+
                  (link
                     (make
                        (mapc
                           '((L)
                              (eval L)
                              (setq *Lay '-) )
                           Lst ) ) ) ) ) ) ) )
   (=: lock
      (not
         (find
            '((F) (not (isa '+Lock F)))
            (: fields 1) ) ) ) )

(dm init> ()
   (setScroll) )

(dm row> (Fld)
   (default Fld (: home focus))
   (when
      (find
         '((L) (memq Fld L))
         (: fields) )
      (+ -1 (: ofs) (index @ (: fields))) ) )

(dm row2> ()
   (when
      (find
         '((L) (memq (: home focus2) L))
         (: fields) )
      (+ -1 (: ofs) (index @ (: fields))) ) )

(dm scr> (N)
   (scrl N) )

(dm PGUP> ()
   (scrl (max 1 (- (: ofs) (: rows)))) )

(dm PGDN> ()
   (scrl (+ (: ofs) (: rows))) )

(dm BEG> ()
   (scrl 1) )

(dm END> ()
   (scrl
      (max 1
         (- (size> This) (length (: fields)) -2) ) ) )

(dm UP> ()
   (scrl (max 1 (- (: ofs) 1))) )

(dm DN> ()
   (scrl (+ 1 (: ofs))) )


(class +Chart +chart)
# data clip

(dm put> ()
   (mapc
      '((F D)
         (mapc 'set> F ((: put) D)) )
      (: fields)
      (nth (: data) (: ofs)) )  )

(dm get> ()
   (unless (: lock)
      (map
         '((F D)
            (set D
               (trim
                  ((: get)
                     (mapcar '((F) (val> F)) (car F))
                     (car D) ) ) ) )
         (: fields)
         (nth
            (=: data
               (need
                  (- 1 (: ofs) (: rows))
                  (: data) ) )
            (: ofs) ) )
      (=: data (trim (: data))) ) )

(dm size> ()
   (length (: data)) )

(dm end> ()
   (set> This (val> This)) )

(dm set> (Lst)
   (unless (= Lst (: data))
      (let N (- (length Lst) (: rows) -1)
         (when (> (: ofs) N)
            (=: ofs (max 1 N)) ) )
      (=: data (copy Lst)) )
   (put> This)
   (setScroll) )

(dm val> ()
   (get> This)
   (: data) )

(dm stat> ()
   (list
      (cons 'ofs (: ofs))
      (cons 'data (: data)) ) )

(dm DEL> ()
   (zapUndo)
   (get> This)
   (ifn (row> This)
      (beep> (: home))
      (=: clip (get (: data) @))
      (=: data
         (conc
            (head (- @ 1) (: data))
            (nth (: data) (+ @ 1)) ) )
      (put> This)
      (setScroll) ) )

(dm INS> ()
   (zapUndo)
   (get> This)
   (ifn (row> This)
      (beep> (: home))
      (=: data
         (conc
            (head (- @ 1) (: data))
            (list (: clip))
            (nth (: data) @) ) )
      (put> This)
      (setScroll) ) )


(class +ListChart +Chart)

(dm set> (Lst)
   (super (mapcar list Lst)) )

(dm val> ()
   (mapcar car (super)) )


# Chart Prefix
(class +Del)
# del

(dm T (Exe . @)
   (=: del Exe)
   (pass extra) )

(dm INS> ()
   (if (eval (: del))
      (extra)
      (beep> (: home)) ) )

(dm DEL> ()
   (if (eval (: del))
      (extra)
      (beep> (: home)) ) )
