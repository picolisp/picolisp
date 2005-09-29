# 08sep05abu
# (c) Software Lab. Alexander Burger

# *Frame

(de htPrin (Ofs Prg)
   (for X Prg
      (if (atom X)
         (ht:Prin (eval X Ofs))
         (eval X Ofs) ) ) )

(de tag (Nm Attr Ofs Prg)
   (prin '< Nm)
   (when Attr
      (cond
         ((atom Attr)
            (prin " class=\"" Attr "\"") )
         ((atom (car Attr))
            (prin " " (car Attr) "=\"" (cdr Attr) "\"") )
         (T
            (for Y Attr
               (prin " " (car Y) "=\"" (cdr Y) "\"") ) ) ) )
   (prin '>)
   (if (atom Prg)
      (ht:Prin (eval Prg Ofs))
      (for X Prg
         (if (atom X)
            (ht:Prin (eval X Ofs))
            (eval X Ofs) ) ) )
   (prinl "</" Nm '>) )

(de <tag> (Nm Attr . Prg)
   (tag Nm Attr 2 Prg) )


### XHTML Output ###
(de html ("Upd" "Ttl" "Css" "Attr". "Prg")
   (xhtml "Upd" "Ttl" "Css" "Attr" "Prg") )

(de xhtml (Upd Ttl Css Attr Prg)
   (httpHead NIL Upd)
   ## (prinl "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
   (prinl
      (if (num? (car Prg))
         "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Frameset//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">"
         "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">" ) )
   (prinl
      "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\""
      (or *Lang "en")
      "\" lang=\""
      (or *Lang "en")
      "\">" )
   (prinl "<head>")
   (and Ttl (<tag> 'title NIL Ttl))
   (and *Host *Port (prinl "<base href=\"" (baseHRef) "\"/>"))
   (when Css
      (prinl
         "<link rel=\"stylesheet\" href=\""
         (baseHRef *Port1) Css
         "\" type=\"text/css\"/>" ) )
   (prinl "</head>")
   (cond
      ((not (num? (car Prg)))
         (tag 'body Attr 2 Prg) )
      ((not (num? (cadr Prg)))
         (prinl
            "<frameset cols=\""
            (eval (pop 'Prg) 1)
            ",*\"><frame name=\"menu\" src=\""
            *SesId
            "1\"/><frame name=\"main\" src=\""
            *SesId
            (eval (pop 'Prg) 1)
            "\"/></frameset>" )
         (setq *Frame
            (cons Ttl (cons Css (cons Attr (list (cons NIL Prg))))) ) )
      (T
         (prinl
            "<frameset rows=\""
            (eval (pop 'Prg) 1)
            ",*\"><frame src=\""
            *SesId
            "0\"/><frameset cols=\""
            (eval (pop 'Prg) 1)
            ",*\"><frame name=\"menu\" src=\""
            *SesId
            "1\"/><frame name=\"main\" src=\""
            *SesId
            (eval (pop 'Prg) 1)
            "\"/></frameset></frameset>" )
         (setq *Frame (cons Ttl (cons Css (cons Attr Prg)))) ) )
   (prinl "</html>") )

(undef 'urlN)

(de urlN (Str)
   (xhtml NIL (eval (car *Frame)) (cadr *Frame) (caddr *Frame)
      (if (= "0" Str)
         (quote
            (<ul> 'menu
               (for (N . L) (cdddr *Frame)
                  (<li> NIL
                     (prin "<a href=\"" *SesId N "\" target=\"menu\">")
                     (ht:Prin (eval (car L)))
                     (prinl "</a>") ) ) ) )
         (nth (cdddr *Frame) (format Str) 2) ) ) )

(de style (Str)
   (cons 'style Str) )

(de <div> (Attr . Prg)
   (tag 'div Attr 2 Prg) )

(de <span> (Attr . Prg)
   (tag 'span Attr 2 Prg) )

(de <br> Prg
   (htPrin 2 Prg)
   (prinl "<br/>") )

(de <em> Prg
   (tag 'em NIL 2 Prg) )

(de <strong> Prg
   (tag 'strong NIL 2 Prg) )

(de <h1> (Attr . Prg)
   (tag 'h1 Attr 2 Prg) )

(de <h2> (Attr . Prg)
   (tag 'h2 Attr 2 Prg) )

(de <h3> (Attr . Prg)
   (tag 'h3 Attr 2 Prg) )

(de <h4> (Attr . Prg)
   (tag 'h4 Attr 2 Prg) )

(de <h5> (Attr . Prg)
   (tag 'h5 Attr 2 Prg) )

(de <h6> (Attr . Prg)
   (tag 'h6 Attr 2 Prg) )

(de <p> (Attr . Prg)
   (tag 'p Attr 2 Prg) )

(de <pre> (Attr . Prg)
   (tag 'pre Attr 2 Prg) )

(de <ol> (Attr . Prg)
   (tag 'ol Attr 2 Prg) )

(de <ul> (Attr . Prg)
   (tag 'ul Attr 2 Prg) )

(de <li> (Attr . Prg)
   (tag 'li Attr 2 Prg) )

(de <href> (Str Url Tar)
   (prin "<a href=\"" (sesId Url))
   (cond
      (Tar (prin "\" target=\"" Tar))
      (*Frame (prin "\" target=\"main")) )
   (prin "\">")
   (ht:Prin Str)
   (prin "</a>") )

(de <img> (Src Alt Url)
   (and Url (prin "<a href=\"" (sesId Url)  "\">"))
   (prin "<img src=\"" (sesId Src) "\" alt=\"" Alt "\"/>")
   (and Url (prin "</a>")) )

(de <menu> (Url Bits . Lst)
   (let N 1
      (for L Lst
         (<ul> NIL
            (if (=T (car L))
               (<li> 'top
                  (<href> (cadr L) (run (cddr L) 2)) )
               (<li> 'ttl
                  (<href> (car L) (pack Url (ht:Fmt (x| N Bits))))
                  (<ul> (unless (bit? N Bits) 'hide)
                     (for X (cdr L)
                        (<li> 'sub
                           (if (atom X)
                              (ht:Prin X)
                              (<href> (car X) (run (cdr X) 2)) ) ) ) ) ) ) )
         (setq N (>> -1 N)) ) ) )

(de <table> ("Attr" "Ttl" "Head" . "Prg")
   (tag 'table "Attr" 1
      (quote
         (and "Ttl" (tag 'caption NIL 1 "Ttl"))
         (when (find cdr "Head")
            (tag 'tr NIL 1
               (quote
                  (for X "Head"
                     (tag 'th (car X) 2 (cdr X)) ) ) ) )
         (htPrin 1 "Prg") ) ) )

(de <row> (Cls . Prg)
   (tag 'tr NIL 1
      (quote
         (mapc
            '((X H)
               (tag 'td (pack Cls (and Cls (car H) " ") (car H)) 1
                  (quote
                     (if (atom X)
                        (ht:Prin (eval X 2))
                        (eval X 2) ) ) ) )
            Prg
            "Head" ) ) ) )

(de <tr> (Attr . Prg)
   (tag 'tr Attr 2 Prg) )

(de <td> (Attr . Prg)
   (tag 'td Attr 2 Prg) )

### HTML Form ###
(de <post> (Attr S . Prg)
   (prin
      "<form enctype=\"multipart/form-data\" action=\""
      (sesId S)
      "\" method=\"post\""
      (and *Frame " target=\"main\"")
      '> )
   (tag 'fieldset Attr 2 Prg)
   (prinl "</form>") )

(de htmlVar ("Var")
   (prin "name=\"")
   (if (pair "Var")
      (prin (car "Var") "(" (ht:Fmt (cdr "Var")) ")")
      (prin "Var") )
   (prin "\"") )

(de htmlVal ("Var")
   (if (pair "Var")
      (cdr (assoc (cdr "Var") (val (car "Var"))))
      (val "Var") ) )

(de <field> (N "Var" Max)
   (prin "<input type=\"text\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prin "\" size=\"" N "\"")
   (and Max (prin " maxlength=\"" Max "\""))
   (prinl "/>") )

(de <hidden> ("Var" Val)
   (prin "<input type=\"hidden\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin Val)
   (prinl "\"/>") )

(de <passwd> (N "Var")
   (prin "<input type=\"password\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" size=\"" N "\" maxlength=\"" N "\"/>") )

(de <upload> (N "Var")
   (prin "<input type=\"file\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prinl "\" size=\"" N "\"/>") )

(de <area> (Cols Rows "Var")
   (prin "<textarea ")
   (htmlVar "Var")
   (prin " cols=\"" Cols "\" rows=\"" Rows "\" wrap=\"off\">")
   (ht:Prin (htmlVal "Var"))
   (prinl "</textarea>") )

(de <select> (Lst "Var")
   (prin "<select ")
   (htmlVar "Var")
   (prin '>)
   (for X Lst
      (prin
         (if (= X (htmlVal "Var"))
            "<option selected=\"selected\">"
            "<option>" ) )
      (ht:Prin X)
      (prin "</option>") )
   (prinl "</select>") )

(de <check> ("Var")
   (prin "<input type=\"hidden\" ")
   (htmlVar "Var")
   (prin " value=\"\">")
   (prin "<input type=\"checkbox\" ")
   (htmlVar "Var")
   (prinl " value=\"T\"" (and (htmlVal "Var") " checked=\"checked\"") "/>") )

(de <radio> ("Var" Val)
   (prin "<input type=\"radio\" ")
   (htmlVar "Var")
   (prinl
      " value=\"" Val "\""
      (and (= Val (htmlVal "Var")) " checked=\"checked\"")
      "/>" ) )

(de <submit> (S)
   (prin "<input type=\"submit\" value=\"")
   (ht:Prin S)
   (prinl "\"/>") )

(de <reset> (S)
   (prin "<input type=\"reset\" value=\"")
   (ht:Prin S)
   (prinl "\"/>") )

# Interactive tree
(de <tree> ("Url" "Path" "Tree" "Able?" "Excl?" "Expand" "Print")
   (default "Print" ht:Prin)
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
   (prinl "<ul>")
   (for ("N" . "X") "Tree"
      (prin "<li><a id=\"T" (inc '"A") "\"></a>")
      (cond
         ((pair "X")
            (let "L" (append "Lst" (cons "N"))
               (<href> (if (== "X" "Pos") "<+>" "[+]")
                  (pack "Url"
                     "?" (ht:Fmt (cons NIL "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("Print" (car "X"))
               (and (cdr "X") ("tree" @ "L")) ) )
         (("Able?" "X")
            (let "L" (append "Lst" (cons (- "N")))
               (<href> (if (== "X" "Pos") "< >" "[ ]")
                  (pack "Url"
                     "?" (ht:Fmt (cons ("Excl?" "X") "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("Print" "X") ) )
         (T ("Print" "X")) )
      (prin "</li>") )
   (prinl "</ul>") )
