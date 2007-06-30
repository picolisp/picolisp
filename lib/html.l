# 03jun07abu
# (c) Software Lab. Alexander Burger

# *Url1 *Frame *Meta *Css

### HTML Output ###
(de html (Ttl . Prg)
   (httpHead NIL (if (car Prg) 0 (pop 'Prg)))
   (ht:Out *Chunked
      (prinl
         "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 "
         (if (num? (car Prg)) "Frameset" "Transitional")
         "//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">" )
      (if *Lang
         (prinl "<HTML lang=\"" *Lang "\">")
         (prinl "<HTML>") )
      (prinl "<HEAD>")
      (prinl "<BASE HREF=\"" (baseHRef) "\">")
      (when Ttl
         (prin "<TITLE>")
         (ht:Prin Ttl)
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
      (nond
         ((num? (car Prg))
            (prin "<BODY")
            (while (and (pair (car Prg)) (=T (caar Prg)))
               (prin " " (eval (cdr (pop 'Prg)) 1)) )
            (prinl ">")
            (prEval Prg 2)
            (prinl "</BODY>") )
         ((num? (cadr Prg))
            (prinl
               "<FRAMESET COLS=\""
               (eval (pop 'Prg) 1)
               ",*\"><FRAME NAME=\"MENU\" SRC=\""
               *SesId
               "1\"><FRAME NAME=\"MAIN\" SRC=\""
               *SesId
               (eval (pop 'Prg) 1)
               "\"></FRAMESET>" )
            (setq  *Frame
               (cons (list NIL NIL (cons 'html NIL Prg))) ) )
         (NIL
            (prinl
               "<FRAMESET ROWS=\""
               (eval (pop 'Prg) 1)
               ",*\"><FRAME SRC=\""
               *SesId
               "0\" MARGINHEIGHT=\"0\" SCROLLING=\"NO\"><FRAMESET COLS=\""
               (eval (pop 'Prg) 1)
               ",*\"><FRAME NAME=\"MENU\" SRC=\""
               *SesId
               "1\"><FRAME NAME=\"MAIN\" SRC=\""
               *SesId
               (eval (pop 'Prg) 1)
               "\"></FRAMESET></FRAMESET>" )
            (setq  *Frame
               (mapcar
                  '((L)
                     (mix L 1 2 (cons 'html NIL (cddr L))) )
                  Prg ) ) ) )
      (prinl "</HTML>") ) )

(undef 'urlN)
(de urlN (Str)
   (if (= "0" Str)
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
         (prinl "</TR></TABLE>") )
      (run (nth *Frame (format Str) 3)) ) )

(de url1 (Str)
   (setq *Url1 Str) )

# Ouput navigation links
(de navi ()
   (<href> "<<<" "javascript:history.back()" (and *Frame "MAIN"))
   (if *Url1
      (<href> "----" *Url1 (and *Frame "MAIN"))
      (prin "----") )
   (<href> ">>>" "javascript:history.forward()" (and *Frame "MAIN")) )


(de _htAlign (X)
   (cond
      ((not X))
      ((=T X) " ALIGN=\"RIGHT\"")
      ((=0 X) " ALIGN=\"CENTER\"")
      (T X) ) )

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
   (ifn N
      (<item2> S '(navi) 3)
      (prin "<H" N (_htAlign X) ">")
      (ht:Prin S)
      (prinl "</H" N ">") ) )

(de <font> (Col Siz . Prg)
   (prin "<FONT")
   (and Col (prin " COLOR=\"" Col "\""))
   (and Siz (prin " SIZE=\"" Siz "\""))
   (prin ">")
   (prEval Prg 2)
   (prinl "</FONT>") )

(de <b> @
   (prin "<b>")
   (while (args)
      (<item> (next)) )
   (prinl "</b>") )

(de <br> @
   (when (args)
      (<item> (next))
      (while (args)
         (space)
         (<item> (next)) ) )
   (prinl "<br>") )

(de <hr> ()
   (prinl '<hr>) )

(de <center> Prg
   (prin "<center>")
   (prEval Prg 2)
   (prinl "</center>") )

(de <p> (X . Prg)
   (prin "<p" (_htAlign X) ">")
   (prEval Prg 2)
   (prinl "</p>") )

(de <name> (Name . Prg)
   (prin "<a NAME=\"" Name "\">")
   (prEval Prg 2)
   (prinl "</a>") )

(de <href> (S Url Tar)
   (prin "<A HREF=\"" (sesId Url))
   (cond
      (Tar (prin "\" TARGET=\"" Tar))
      (*Frame (prin "\" TARGET=\"MAIN")) )
   (prin "\">")
   (ht:Prin S)
   (prin "</A>") )

(de <button> @
   (prin "[")
   (pass <href>)
   (prinl "]") )

(de <img> (S A Url X)
   (and Url (prin "<A HREF=\"" (sesId Url)  "\">"))
   (prin "<IMG SRC=\"" (sesId S) "\" ALT=\"" A "\"" (_htAlign X) ">")
   (and Url (prin "</A>")) )

(de <pre> Prg
   (prinl "<PRE>")
   (prEval Prg 2)
   (prinl "</PRE>") )

(de <list> @
   (prinl "<UL>")
   (while (args)
      (prin "<LI>")
      (<item> (next))
      (prinl) )
   (prinl "</UL>") )

(de <tree> ("Url" "Path" "Tree" "Able?" "Excl?" "Expand" "Print")
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
               (cons (car "Pos") ("Expand" (car "Pos")))
               (caar "Pos") ) ) )
      (setq "Pos" (car "Pos"))
      ("tree" "Tree")
      "Tree" ) )

(de "tree" ("Tree" "Lst")
   (prinl "<UL>")
   (for ("N" . "X") "Tree"
      (prin "<LI><A NAME=\"T" (inc '"A") "\"></A>")
      (cond
         ((pair "X")
            (let "L" (append "Lst" (cons "N"))
               (<href> (if (== "X" "Pos") "<+>" "[+]")
                  (pack "Url"
                     '? (ht:Fmt (cons NIL "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("Print" (car "X"))
               (and (cdr "X") ("tree" @ "L")) ) )
         (("Able?" "X")
            (let "L" (append "Lst" (cons (- "N")))
               (<href> (if (== "X" "Pos") "< >" "[ ]")
                  (pack "Url"
                     '? (ht:Fmt (cons ("Excl?" "X") "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("Print" "X") ) )
         (T ("Print" "X")) ) )
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
      (for "L" "Head"
         (prin
            "<TH ALIGN="
            (case (car "L")
               ((- ^) "\"LEFT\"")
               (+ "\"RIGHT\"")
               (T "\"CENTER\"") )
            (and (caddr "L") (pack " WIDTH=" @))
            (cadddr "L")
            ">" )
         (<item> (cadr "L"))
         (prin "</TH>") )
      (prinl "</TR>") )
   (prEval "Prg")
   (prinl "</TABLE>") )

(de <row> @
   (prinl "<TR>")
   (map
      '(("X" "H")
         (unless (memq (car "X") '(T -))
            (prinl
               "<TD ALIGN="
               (if (== '+ (caar "H")) "\"RIGHT\"" "\"LEFT\"")
               (and (== '^ (caar "H")) " VALIGN=\"TOP\"")
               (when (== '- (cadr "X"))
                  (pack
                     " COLSPAN="
                     (-
                        (length "X")
                        (length
                           (seek
                              '((L) (n== '- (car L)))
                              (cdr "X") ) ) ) ) )
               ">" )
            (<item> (car "X"))
            (prinl "</TD>") ) )
      (rest)
      "Head" )
   (prinl "</TR>") )

(de <grid> ("Head" . @)
   (<table> NIL "" "Head"
      (while (args)
         (apply <row> (next)) ) ) )

(de <th> "Prg"
   (prin "<TR")
   (while (and (pair (car "Prg")) (=0 (caar "Prg")))
      (prin " " (eval (cdr (pop '"Prg")))) )
   (prinl ">")
   (while "Prg"
      (prin "<TH")
      (while (and (pair (car "Prg")) (=T (caar "Prg")))
         (prin " " (eval (cdr (pop '"Prg")))) )
      (prin ">")
      (<item> (eval (pop '"Prg")))
      (prinl "</TH>") )
   (prinl "</TR>") )

(de <td> "Prg"
   (prin "<TR")
   (while (and (pair (car "Prg")) (=0 (caar "Prg")))
      (prin " " (eval (cdr (pop '"Prg")))) )
   (prinl ">")
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
(de <post> (S . Prg)
   (prinl
      "<FORM ENCTYPE=\"multipart/form-data\" ACTION=\""
      (sesId S)
      "\" METHOD=POST"
      (and *Frame " TARGET=\"MAIN\"")
      ">" )
   (prEval Prg 2)
   (prinl "</FORM>") )

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

(de <field> (N S "Var" Url X)
   (when S
      (if Url (<href> S Url) (ht:Prin S))
      (space) )
   (prin "<INPUT" (_htAlign X) " TYPE=TEXT ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" SIZE=" N ">") )

(de <hidden> ("Var" Val)
   (prin "<INPUT TYPE=HIDDEN ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin Val)
   (prinl "\">") )

(de <passwd> (N S "Var" X)
   (when S
      (ht:Prin S)
      (space) )
   (prin "<INPUT" (_htAlign X) " TYPE=PASSWORD ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" SIZE=" N ">") )

(de <upload> (N S "Var" Url)
   (when S
      (if Url (<href> S Url) (ht:Prin S))
      (space) )
   (prin "<INPUT TYPE=FILE ")
   (htmlVar "Var")
   (prin " VALUE=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" SIZE=" N ">") )

(de <area> (Cols Rows S "Var" Url)
   (when S
      (if Url (<href> S Url) (ht:Prin S))
      (space) )
   (prin "<TEXTAREA ")
   (htmlVar "Var")
   (prin " COLS=" Cols " ROWS=" Rows ">")
   (ht:Prin (htmlVal "Var"))
   (prinl "</TEXTAREA>") )

(de <select> (S Lst "Var")
   (when S
      (ht:Prin S)
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
   (prin " VALUE=\"T\"" (and (htmlVal "Var") " CHECKED") "> ")
   (ht:Prin S) )

(de <radio> ("Var" Val S)
   (prin "<INPUT TYPE=RADIO ")
   (htmlVar "Var")
   (prin " VALUE=\"" Val "\"" (and (= Val (htmlVal "Var")) " CHECKED") "> ")
   (ht:Prin S) )

(de <submit> (S)
   (prin "<INPUT TYPE=SUBMIT VALUE=\"")
   (ht:Prin S)
   (prinl "\">") )

(de <reset> (S)
   (prin "<INPUT TYPE=RESET VALUE=\"")
   (ht:Prin S)
   (prinl "\">") )
