# 09aug08abu
# 09aug08 Tomas Hlavaty <kvietaag@seznam.cz>

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
      (let Tag (pop 'Lst)
         (space (default N 0))
         (prin "<" Tag)
         (for X (pop 'Lst)
            (prin " " (car X) "=\"")
            (escXml (cdr X))
            (prin "\"") )
         (nond
            (Lst (prinl "/>"))
            ((or (cdr Lst) (pair (car Lst)))
               (prin ">")
               (escXml (car Lst))
               (prinl "</" Tag ">") )
            (NIL
               (prinl ">")
               (for X Lst
                  (if (pair X)
                     (xml X (+ 3 N))
                     (space (+ 3 N))
                     (escXml X)
                     (prinl) ) )
               (space N)
               (prinl "</" Tag ">") ) ) )
      (_xml) ) )

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
                           (NIL (skip) (quit "Unexpected end of XML" Tok))
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
                                 (pack (xmlEsc (trim (cons X (till "^M^J<"))))) ) ) ) ) ) ) ) ) ) ) )

(de xmlEsc (L)
   (use (@A @X @Z)
      (make
         (while L
            (ifn (match '("&" @X ";" @Z) L)
               (link (pop 'L))
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
                              (format (pack (cdr @X))) ) ) )
                     (T @X) ) )
               (setq L @Z) ) ) ) ) )

(de escXml (X)
   (for C (chop X)
      (if (member C '`(chop "\"&<"))
         (prin "&#" (char C) ";")
         (prin C) ) ) )


# Simple XML string
(de xml$ (Lst)
   (pack
      (make
         (recur (Lst)
            (let Tag (pop 'Lst)
               (link "<" Tag)
               (for X (pop 'Lst)
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
      (setq Lst (assoc (next) Lst)) )
   Lst )

(de attr (Lst Key . @)
   (while (args)
      (setq
         Lst (assoc Key (cddr Lst))
         Key (next) ) )
   (cdr (assoc Key (cadr Lst))) )
