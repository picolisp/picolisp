# 24jun06abu
# (c) Software Lab. Alexander Burger

# *Style *Menu *Tab *ID

(mapc allow '(*Menu *Tab *ID))

(default *Menu 0  *Tab 1)

(de htPrin (Ofs Prg)
   (for X Prg
      (if (atom X)
         (ht:Prin (eval X Ofs))
         (eval X Ofs) ) ) )

(de htStyle (Attr)
   (cond
      ((atom Attr)
         (prin " class=\"" Attr "\"") )
      ((and (atom (car Attr)) (atom (cdr Attr)))
         (prin " " (car Attr) "=\"" (cdr Attr) "\"") )
      (T (mapc htStyle Attr)) ) )

(de tag (Nm Attr Ofs Prg)
   (prin '< Nm)
   (and Attr (htStyle @))
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
(de html (Upd Ttl Css Attr . Prg)
   (httpHead NIL Upd)
   ## (prinl "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
   (prinl "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">")
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
      (if (atom Css) ("css" Css) (mapc "css" Css)) )
   (prinl "</head>")
   (tag 'body Attr 2 Prg)
   (prinl "</html>") )

(de "css" (Css)
   (prinl
      "<link rel=\"stylesheet\" href=\""
      (baseHRef *Port1) Css
      "\" type=\"text/css\"/>" ) )

(de style (*Style . "Prg")
   (run "Prg") )

(de <div> (Attr . Prg)
   (tag 'div Attr 2 Prg) )

(de <span> (Attr . Prg)
   (tag 'span Attr 2 Prg) )

(de <br> Prg
   (htPrin 2 Prg)
   (prinl "<br/>") )

(de <hr> ()
   (prinl "<hr/>") )

(de <nbsp> (N)
   (do (or N 1) (prin "&nbsp;")) )

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
   (and Tar (prin "\" target=\"" Tar))
   (prin "\"")
   (and *Style (htStyle @))
   (prin '>)
   (ht:Prin Str)
   (prin "</a>") )

(de <img> (Src Alt Url Tar DX DY)
   (when Url
      (prin "<a href=\"" (sesId Url))
      (and Tar (prin "\" target=\"" Tar))
      (prin "\">") )
   (prin "<img src=\"" (sesId Src) "\" alt=\"" Alt "\"")
   (and DX (prin " width=\"" DX "\""))
   (and DY (prin " height=\"" DY "\""))
   (and *Style (htStyle @))
   (prin "/>")
   (and Url (prin "</a>")) )

(de <this> (Var Val . Prg)
   (prin "<a href=\"" (sesId *Url) '? Var '= (ht:Fmt Val) "\"")
   (and *Style (htStyle @))
   (prin '>)
   (htPrin 2 Prg)
   (prin "</a>") )

(de urlMT (Url Menu Tab Id)
   (pack Url '?  "*Menu=+" Menu  "&*Tab=+" Tab  "&*ID=" (ht:Fmt Id)) )

(de <menu> Lst
   (let N 1
      (for L Lst
         (<ul> NIL
            (cond
               ((not (car L)) (htPrin 2 (cdr L)))
               ((=T (car L))
                  (<li> 'top
                     (<href>
                        (eval (cadr L) 1)
                        (urlMT (eval (caddr L) 1) *Menu 1)
                        (cdddr L) ) ) )
               (T
                  (<li> 'top
                     (<href> (eval (car L) 1) (urlMT *Url (x| N *Menu) *Tab *ID))
                     (when (bit? N *Menu)
                        (<ul> NIL
                           (for X (cdr L)
                              (<li> 'sub
                                 (cond
                                    ((atom X) (ht:Prin (eval X 1)))
                                    ((eval (cadr X) 1)
                                       (<href>
                                          (eval (car X) 1)
                                          (urlMT @ *Menu 1)
                                          (cddr X) ) )
                                    (T (ht:Prin (eval (car X) 1))) ) ) ) ) ) ) ) ) )
         (setq N (>> -1 N)) ) ) )

(de <tab> Lst
   (<table> 'tab NIL NIL
      (for (N . L) Lst
         (if (= N *Tab)
            (<td> 'top (ht:Prin (eval (car L) 1)))
            (<td> 'sub
               (<href> (eval (car L) 1) (urlMT *Url *Menu N *ID)) ) ) ) )
   (htPrin 2 (get Lst *Tab -1)) )

(de <table> (Attr Ttl "Head" . Prg)
   (tag 'table Attr 1
      (quote
         (and Ttl (tag 'caption NIL 1 Ttl))
         (when (find cdr "Head")
            (tag 'tr NIL 1
               (quote
                  (for X "Head"
                     (tag 'th (car X) 2 (cdr X)) ) ) ) )
         (htPrin 2 Prg) ) ) )

(de <row> (Cls . Prg)
   (tag 'tr NIL 1
      (quote
         (let (L Prg  H (up "Head"))
            (while L
               (let
                  (X (pop 'L)
                     C (pack Cls (and Cls (caar H) " ") (car (pop 'H)))
                     N 1 )
                  (while (== '- (car L))
                     (inc 'N)
                     (pop 'L)
                     (pop 'H) )
                  (tag 'td
                     (if2 C (> N 1)
                        (list C (cons 'colspan N))
                        C
                        (cons 'colspan N) )
                     1
                     (quote
                        (if (atom X)
                           (ht:Prin (eval X 1))
                           (eval X 1) ) ) ) ) ) ) ) ) )

(de <th> (Attr . Prg)
   (tag 'th Attr 2 Prg) )

(de <tr> (Attr . Prg)
   (tag 'tr Attr 2 Prg) )

(de <td> (Attr . Prg)
   (tag 'td Attr 2 Prg) )

(de <grid> (X . Lst)
   (tag 'table 'grid 1
      (quote
         (while Lst
            (tag 'tr NIL 1
               (quote
                  (use X
                     (do (or (num? X) (length X))
                        (tag 'td (and (pair X) (pop 'X)) 1
                           (quote
                              (if (atom (car Lst))
                                 (ht:Prin (eval (pop 'Lst) 1))
                                 (eval (pop 'Lst) 1) ) ) ) ) ) ) ) ) ) ) )

### HTML Form ###
(de <post> (Attr Url . Prg)
   (prin
      "<form enctype=\"multipart/form-data\" action=\""
      (sesId Url)
      "\" method=\"post\">" )
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

(de <label> (Attr . Prg)
   (tag 'label Attr 2 Prg) )

(de <field> (N "Var" Max Flg)
   (prin "<input type=\"text\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prin "\" size=\"")
   (if (lt0 N)
      (prin (- N) "\" style=\"text-align: right;\"")
      (prin N "\"") )
   (and Max (prin " maxlength=\"" Max "\""))
   (and *Style (htStyle @))
   (and Flg (prin " readonly"))
   (prinl "/>") )

(de <hidden> ("Var" Val)
   (prin "<input type=\"hidden\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin Val)
   (prinl "\"/>") )

(de <passwd> (N "Var" Flg)
   (prin "<input type=\"password\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prin "\" size=\"" N "\" maxlength=\"" N "\"")
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

(de <upload> (N "Var" Flg)
   (prin "<input type=\"file\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prin "\" size=\"" N "\"")
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

(de <area> (Cols Rows "Var" Flg)
   (prin "<textarea ")
   (htmlVar "Var")
   (prin " cols=\"" Cols "\" rows=\"" Rows "\" wrap=\"off\"")
   (and *Style (htStyle @))
   (and Flg (prin " readonly"))
   (prin '>)
   (ht:Prin (htmlVal "Var"))
   (prinl "</textarea>") )

(de <select> (Lst "Var" Flg)
   (prin "<select ")
   (htmlVar "Var")
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prin '>)
   (for "X" Lst
      (let "V" (if (atom "X") "X" (cdr "X"))
         (prin
            "<option"
            (and (pair "X") (pack " value=\"" "V" "\""))
            (if (= "V" (htmlVal "Var"))
               " selected=\"selected\">"
               '> ) ) )
      (ht:Prin (if (atom "X") "X" (car "X")))
      (prin "</option>") )
   (prinl "</select>") )

(de <check> ("Var" Flg)
   (prin "<input type=\"hidden\" ")
   (htmlVar "Var")
   (prin " value=\"\">")
   (prin "<input type=\"checkbox\" ")
   (htmlVar "Var")
   (prin " value=\"T\"" (and (htmlVal "Var") " checked=\"checked\""))
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

(de <radio> ("Var" Val Flg)
   (prin "<input type=\"radio\" ")
   (htmlVar "Var")
   (prin
      " value=\"" Val "\""
      (and (= Val (htmlVal "Var")) " checked=\"checked\"") )
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

(de <submit> (S "Var" Flg)
   (prin "<input type=\"submit\"")
   (and "Var" (space) (htmlVar "Var"))
   (prin " value=\"")
   (ht:Prin S)
   (prin "\"")
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

(de <image> (Src "Var" Flg)
   (prin "<input type=\"image\"")
   (and "Var" (space) (htmlVar "Var"))
   (prin " src=\"" (sesId Src) "\"")
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

(de <reset> (S Flg)
   (prin "<input type=\"reset\" value=\"")
   (ht:Prin S)
   (prin "\"")
   (and *Style (htStyle @))
   (and Flg (prin " disabled"))
   (prinl "/>") )

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
                     "?" (ht:Fmt (cons ("Excl?" "X") "L"))
                     "#T" (max 1 (- "A" 12)) )
                  "_self" )
               (space)
               ("Print" "X") ) )
         (T ("Print" "X")) )
      (prin "</li>") )
   (prinl "</ul>") )

# vim:syntax=picolisp:ts=3:sw=3:expandtab
