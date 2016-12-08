# 24nov16abu
# 21jan09 Tomas Hlavaty <kvietaag@seznam.cz>

# Check or write header
(de xml? (Flg)
   (if Flg
      (prinl "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
      (skip)
      (prog1
         (head '("<" "?" "x" "m" "l") (till ">"))
         (char) ) ) )

# Generate/Parse XML data
# expects well formed XML
# encoding by picolisp (utf8 "only", no utf16 etc.)
# trim whitespace except in cdata
# ignore <? <!-- <!DOCTYPE
# non-builtin entities as normal text: &ent; => ent
(de xml (Lst N)
   (if Lst
      (let (Nn NIL Nl NIL Pre NIL)
         (when N
            (do (abs N)
               (push 'Nn (if (lt0 N) "^I" " ")) ) )
         (_xml_ Lst) )
      (_xml) ) )

(de _xml_ (Lst)
   (let Tag (++ Lst)
      (when Nl
         (prinl)
         (when Pre
            (prin Pre) ) )
      (prin "<" Tag)
      (for X (++ Lst)
         (prin " " (car X) "=\"")
         (escXml (cdr X))
         (prin "\"") )
      (ifn Lst
         (prin "/>")
         (prin ">")
         (use Nlx
            (let (Nl N
                  Pre (cons Pre Nn) )
               (for X Lst
                  (if (pair X)
                     (_xml_ X)
                     (off Nl)
                     (escXml X) ) )
               (setq Nlx Nl) )
            (when Nlx
               (prinl)
               (when Pre
                  (prin Pre) ) ) )
         (prin "</" Tag ">") ) ) )

(de _xml (In Char)
   (unless Char
      (skip)
      (unless (= "<" (char))
         (quit "Bad XML") ) )
   (case (peek)
      ("?"
         (from "?>")
         (unless In (_xml In)) )
      ("!"
         (char)
         (case (peek)
            ("-"
               (ifn (= "-" (char) (char))
                  (quit "XML comment expected")
                  (from "-->")
                  (unless In (_xml In)) ) )
            ("D"
               (if (find '((C) (<> C (char))) '`(chop "DOCTYPE"))
                  (quit "XML DOCTYPE expected")
                  (when (= "[" (from "[" ">"))
                     (use X
                        (loop
                           (T (= "]" (setq X (from "]" "\"" "'" "<!--"))))
                           (case X
                              ("\"" (from "\""))
                              ("'" (from "'"))
                              ("<!--" (from "-->"))
                              (NIL (quit "Unbalanced XML DOCTYPE")) ) ) )
                     (from ">") )
                  (unless In (_xml In)) ) )
            ("["
               (if (find '((C) (<> C (char))) '`(chop "[CDATA["))
                  (quit "XML CDATA expected")
                  (pack
                     (head -3
                        (make
                           (loop
                              (NIL (link (char)) (quit "Unbalanced XML CDATA"))
                              (T (= '`(chop "]]>") (tail 3 (made)))) ) ) ) ) ) )
            (T (quit "Unhandled XML tag")) ) )
      (T
         (let Tok (till " ^I^M^J/>" T)
            (use X
               (make
                  (link (intern (pack Tok)))
                  (let L
                     (make
                        (loop
                           (NIL (skip) (quit "Unexpected end of XML" Tok))
                           (T (member @ '("/" ">")))
                           (NIL (setq X (intern (pack (trim (till "="))))))
                           (char)
                           (skip)
                           (let C (char)
                              (unless (member C '("\"" "'"))
                                 (quit "XML attribute quote expected" X) )
                              (link (cons X (pack (xmlEsc (till C))))) )
                           (char) ) )
                     (if (= "/" (char))
                        (prog (char) (and L (link L)))
                        (link L)
                        (loop
                           (NIL (if *XmlKeepBlanks (peek) (skip))
                              (quit "Unexpected end of XML" Tok) )
                           (T (and (= "<" (setq X (char))) (= "/" (peek)))
                              (char)
                              (unless (= Tok (till " ^I^M^J/>" T))
                                 (quit "Unbalanced XML" Tok) )
                              (skip)
                              (char) )
                           (if (= "<" X)
                              (when (_xml T "<")
                                 (link @) )
                              (link
                                 (pack
                                    (xmlEsc
                                       ((if *XmlKeepBlanks prog trim)
                                          (cons X (till "<")) ) ) ) ) ) ) ) ) ) ) ) ) ) )

(de xmlEsc (L)
   (use (@X @Z)
      (make
         (while L
            (ifn (match '("&" @X ";" @Z) L)
               (link (++ L))
               (link
                  (cond
                     ((= @X '`(chop "quot")) "\"")
                     ((= @X '`(chop "amp")) "&")
                     ((= @X '`(chop "lt")) "<")
                     ((= @X '`(chop "gt")) ">")
                     ((= @X '`(chop "apos")) "'")
                     ((= "#" (car @X))
                        (char
                           (if (= "x" (cadr @X))
                              (hex (cddr @X))
                              (format (cdr @X)) ) ) )
                     (T @X) ) )
               (setq L @Z) ) ) ) ) )

(de escXml (X)
   (for C (chop X)
      (prin (case C
               ("\"" "&quot;")
               ("&" "&amp;")
               ("<" "&lt;")
               (">" "&gt;")
               (T C) ) ) ) )


# Simple XML string
(de xml$ (Lst)
   (pack
      (make
         (recur (Lst)
            (let Tag (++ Lst)
               (link "<" Tag)
               (for X (++ Lst)
                  (link " " (car X) "=\"" (cdr X) "\"") )
               (ifn Lst
                  (link "/>")
                  (link ">")
                  (for X Lst
                     (if (pair X)
                        (recurse X (+ 3 N))
                        (link X) ) )
                  (link "</" Tag ">") ) ) ) ) ) )


# Access functions
(de body (Lst . @)
   (while (and (setq Lst (cddr Lst)) (args))
      (setq Lst (asoq (next) Lst)) )
   Lst )

(de attr (Lst Key . @)
   (while (args)
      (setq
         Lst (asoq Key (cddr Lst))
         Key (next) ) )
   (cdr (asoq Key (cadr Lst))) )

# <xml> output
(de "xmlL" Lst
   (push '"Xml"
      (make
         (link (++ Lst))
         (let Att
            (make
               (while (and Lst (car Lst) (atom (car Lst)))
                  (let K (++ Lst)
                     (if (=T K)
                        (for X (eval (++ Lst) 1)
                           (if (=T (car X))
                              (link (cons (cdr X) NIL))
                              (when (cdr X)
                                 (link X) ) ) )
                        (when (eval (++ Lst) 1)
                           (link (cons K @)) ) ) ) ) )
            (let "Xml" NIL
               (xrun Lst)
               (ifn "Xml"
                  (when Att
                     (link Att) )
                  (link Att)
                  (chain (flip "Xml")) ) ) ) ) ) )

(de "xmlO" Lst
   (let Tag (++ Lst)
      (when "Nl"
         (prinl)
         (when "Pre"
            (prin "Pre") ) )
      (prin "<" Tag)
      (while (and Lst (car Lst) (atom (car Lst)))
         (let K (++ Lst)
            (if (=T K)
               (for X (eval (++ Lst) 1)
                  (if (=T (car X))
                     (prin " " (cdr X) "=\"\"")
                     (when (cdr X)
                        (prin " " (car X) "=\"")
                        (escXml (cdr X))
                        (prin "\"") ) ) )
               (when (eval (++ Lst) 1)
                  (prin " " K "=\"")
                  (escXml @)
                  (prin "\"") ) ) ) )
      (ifn Lst
         (prin "/>")
         (prin ">")
         (use Nl
            (let ("Nl" "N"
                  "Pre" (cons "Pre" "Nn") )
               (xrun Lst)
               (setq Nl "Nl") )
            (when Nl
               (prinl)
               (when "Pre"
                  (prin "Pre") ) ) )
         (prin "</" Tag ">") ) ) )

(de <xml> ("N" . Lst)
   (if (=T "N")
      (let (<xml> "xmlL"
            xprin '(@ (push '"Xml" (pass pack)))
            xrun '((Lst Ofs)
                   (default Ofs 2)
                   (for X Lst
                      (if (pair X)
                         (eval X Ofs '("Xml"))
                         (when (eval X Ofs '("Xml"))
                            (xprin @) ) ) ) )
            "Xml" NIL )
         (run Lst 1 '(<xml> xprin xrun "Xml"))
         (car (flip "Xml")) )
      (let (<xml> "xmlO"
            xprin '(@ (off "Nl") (mapc escXml (rest)))
            xrun '((Lst Ofs)
                   (default Ofs 2)
                   (for X Lst
                      (if (pair X)
                         (eval X Ofs '("Nl" "Pre"))
                         (when (eval X Ofs '("Nl" "Pre"))
                            (xprin @) ) ) ) )
            "Nn" NIL
            "Nl" NIL
            "Pre" NIL )
         (when "N"
            (do (abs "N")
               (push '"Nn" (if (lt0 "N") "^I" " ")) ) )
         (run Lst 1 '(<xml> xprin xrun "N" "Nn" "Nl" "Pre")) ) ) )

# vi:et:ts=3:sw=3
