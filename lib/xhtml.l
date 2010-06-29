# 20apr10abu
# (c) Software Lab. Alexander Burger

# *JS *Style *Menu *Tab *ID

(mapc allow '(*Menu *Tab *ID))
(setq *Menu 0  *Tab 1)

(de htPrin (Prg Ofs)
   (default Ofs 1)
   (for X Prg
      (if (atom X)
         (ht:Prin (eval X Ofs))
         (eval X Ofs) ) ) )

(de htStyle (Attr)
   (cond
      ((atom Attr)
         (prin " class=\"")
         (ht:Prin Attr)
         (prin "\"") )
      ((and (atom (car Attr)) (atom (cdr Attr)))
         (prin " " (car Attr) "=\"")
         (ht:Prin (cdr Attr))
         (prin "\"") )
      (T (mapc htStyle Attr)) ) )

(de dfltCss (Cls)
   (htStyle
      (cond
         ((not *Style) Cls)
         ((atom *Style) (pack *Style " " Cls))
         ((and (atom (car *Style)) (atom (cdr *Style)))
            (list Cls *Style) )
         ((find atom *Style)
            (replace *Style @ (pack @ " " Cls)) )
         (T (cons Cls *Style)) ) ) )

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
   (prin "</" Nm '>) )

(de <tag> (Nm Attr . Prg)
   (tag Nm Attr 2 Prg) )

(de style (X Prg)
   (let *Style
      (nond
         (X *Style)
         (*Style X)
         ((pair X)
            (cond
               ((atom *Style) (pack *Style " " X))
               ((and (atom (car *Style)) (atom (cdr *Style)))
                  (list X *Style) )
               ((find atom *Style)
                  (replace *Style @ (pack @ " " X)) )
               (T (cons X *Style)) ) )
         ((or (pair (car X)) (pair (cdr X)))
            (cond
               ((atom *Style) (list *Style X))
               ((and (atom (car *Style)) (atom (cdr *Style)))
                  (if (= (car X) (car *Style))
                     X
                     (list *Style X) ) )
               (T
                  (cons X (delete (assoc (car X) *Style) *Style)) ) ) )
         (NIL X) )
      (run Prg 2 '(*Style)) ) )

(de <style> ("X" . "Prg")
   (style "X" "Prg") )

(de nonblank (Str)
   (or Str `(pack (char 160) (char 160))) )


### XHTML output ###
(de html (Upd Ttl Css Attr . Prg)
   (httpHead NIL Upd)
   (ht:Out *Chunked
      ## (xml? T)
      (prinl "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">")
      (prinl
         "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\""
         (or *Lang "en")
         "\" lang=\""
         (or *Lang "en")
         "\">" )
      (prinl "<head>")
      (and Ttl (<tag> 'title NIL Ttl) (prinl))
      (and *Host *Port (prinl "<base href=\"" (baseHRef) "\"/>"))
      (when Css
         (if (atom Css) ("css" Css) (mapc "css" Css)) )
      (mapc javascript *JS)
      (prinl "</head>")
      (tag 'body Attr 2 Prg)
      (prinl "</html>") ) )

(de "css" (Css)
   (prinl "<link rel=\"stylesheet\" type=\"text/css\" href=\"" (srcUrl Css) "\"/>") )

(de javascript (JS . @)
   (when *JS
      (when JS
         (prinl "<script type=\"text/javascript\" src=\"" (srcUrl JS) "\"></script>") )
      (when (rest)
         (prinl "<script type=\"text/javascript\">" @ "</script>") ) ) )

(de <div> (Attr . Prg)
   (tag 'div Attr 2 Prg)
   (prinl) )

(de <span> (Attr . Prg)
   (tag 'span Attr 2 Prg) )

(de <br> Prg
   (htPrin Prg 2)
   (prinl "<br/>") )

(de -- ()
   (prinl "<br/>") )

(de ---- ()
   (prinl "<br/><br/>") )

(de <hr> ()
   (prinl "<hr/>") )

(de <nbsp> (N)
   (do (or N 1) (prin "&nbsp;")) )

(de <small> Prg
   (tag 'small NIL 2 Prg) )

(de <big> Prg
   (tag 'big NIL 2 Prg) )

(de <em> Prg
   (tag 'em NIL 2 Prg) )

(de <strong> Prg
   (tag 'strong NIL 2 Prg) )

(de <h1> (Attr . Prg)
   (tag 'h1 Attr 2 Prg)
   (prinl) )

(de <h2> (Attr . Prg)
   (tag 'h2 Attr 2 Prg)
   (prinl) )

(de <h3> (Attr . Prg)
   (tag 'h3 Attr 2 Prg)
   (prinl) )

(de <h4> (Attr . Prg)
   (tag 'h4 Attr 2 Prg)
   (prinl) )

(de <h5> (Attr . Prg)
   (tag 'h5 Attr 2 Prg)
   (prinl) )

(de <h6> (Attr . Prg)
   (tag 'h6 Attr 2 Prg)
   (prinl) )

(de <p> (Attr . Prg)
   (tag 'p Attr 2 Prg)
   (prinl) )

(de <pre> (Attr . Prg)
   (tag 'pre Attr 2 Prg)
   (prinl) )

(de <ol> (Attr . Prg)
   (tag 'ol Attr 2 Prg)
   (prinl) )

(de <ul> (Attr . Prg)
   (tag 'ul Attr 2 Prg)
   (prinl) )

(de <li> (Attr . Prg)
   (tag 'li Attr 2 Prg)
   (prinl) )

(de <href> (Str Url)
   (prin "<a href=\"" (sesId Url) "\"")
   (and *Style (htStyle @))
   (prin '>)
   (ht:Prin Str)
   (prin "</a>") )

(de <img> (Src Alt Url DX DY)
   (and Url (prin "<a href=\"" (sesId Url) "\">"))
   (prin "<img src=\"" (sesId Src) "\"")
   (when Alt
      (prin " alt=\"")
      (ht:Prin Alt)
      (prin "\"") )
   (and DX (prin " width=\"" DX "\""))
   (and DY (prin " height=\"" DY "\""))
   (and *Style (htStyle @))
   (prin "/>")
   (and Url (prin "</a>")) )

(de <this> (Var Val . Prg)
   (prin "<a href=\"" (sesId *Url) '? Var '= (ht:Fmt Val) "\"")
   (and *Style (htStyle @))
   (prin '>)
   (htPrin Prg 2)
   (prin "</a>") )

(de <table> (Attr Ttl "Head" . Prg)
   (tag 'table Attr 1
      (quote
         (and Ttl (tag 'caption NIL 1 Ttl))
         (when (find cdr "Head")
            (tag 'tr NIL 1
               (quote
                  (for X "Head"
                     (tag 'th (car X) 2 (cdr X)) ) ) ) )
         (htPrin Prg 2) ) )
   (prinl) )

(de <row> (Cls . Prg)
   (tag 'tr NIL 1
      (quote
         (let (L Prg  H (up "Head"))
            (while L
               (let (X (pop 'L)  C (pack Cls (and Cls (caar H) " ") (caar H))  N 1)
                  (while (== '- (car L))
                     (inc 'N)
                     (pop 'L)
                     (pop 'H) )
                  (setq C
                     (if2 C (> N 1)
                        (list C (cons 'colspan N))
                        C
                        (cons 'colspan N) ) )
                  (tag 'td
                     (if (== 'align (car (pop 'H)))
                        (list '(align . right) C)
                        C )
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
                     (let L (and (sym? X) (chop X))
                        (do (or (num? X) (length X))
                           (tag 'td
                              (cond
                                 ((pair X) (pop 'X))
                                 ((= "." (pop 'L)) 'align) )
                              1
                              (quote
                                 (if (atom (car Lst))
                                    (ht:Prin (eval (pop 'Lst) 1))
                                    (eval (pop 'Lst) 1) ) ) ) ) ) ) ) ) ) ) )
   (prinl) )

(de <spread> Lst
   (<table> '(width . "100%") NIL '((norm) (align))
      (<row> NIL
         (eval (car Lst) 1)
         (run (cdr Lst) 1) ) ) )

(de tip ("Str" "Txt")
   (<span> (cons 'title "Str") "Txt") )

(de <tip> ("Str" . "Prg")
   (style (cons 'title "Str") "Prg") )


# Menus
(de urlMT (Url Menu Tab Id Str)
   (pack Url '?  "*Menu=+" Menu  "&*Tab=+" Tab  "&*ID=" (ht:Fmt Id) Str) )

(de <menu> Lst
   (let (M 1  N 1  E 2  U)
      (recur (Lst N E)
         (<ul> NIL
            (for L Lst
               (nond
                  ((car L) (<li> NIL (htPrin (cdr L) 2)))
                  ((=T (car L))
                     (if (setq U (eval (cadr L) E))
                        (<li> (pack (if (= U *Url) 'act 'cmd) N)
                           (<tip> "-->"
                              (<href> (eval (car L) E)
                                 (urlMT U *Menu (if (= U *Url) *Tab 1)
                                    (eval (caddr L))
                                    (eval (cadddr L)) ) ) ) )
                        (<li> (pack 'cmd N)
                           (ht:Prin (eval (car L) E)) ) ) )
                  ((bit? M *Menu)
                     (<li> (pack 'sub N)
                        (<tip> ,"Open submenu"
                           (<href>
                              (eval (cadr L) E)
                              (urlMT *Url (| M *Menu) *Tab *ID) ) ) )
                     (setq M (>> -1 M))
                     (recur (L)
                        (for X (cddr L)
                           (when (=T (car X))
                              (recurse X)
                              (setq M (>> -1 M)) ) ) ) )
                  (NIL
                     (<li> (pack 'top N)
                        (<tip> ,"Close submenu"
                           (<href>
                              (eval (cadr L) E)
                              (urlMT *Url (x| M *Menu) *Tab *ID) ) )
                        (setq M (>> -1 M))
                        (recurse (cddr L) (inc N) (inc E)) ) ) ) ) ) ) ) )

# Update link
(de updLink ()
   (<tip> ,"Update"
      (<span> 'step (<href> "@" (urlMT *Url *Menu *Tab *ID))) ) )

# Tabs
(de <tab> Lst
   (<table> 'tab NIL NIL
      (for (N . L) Lst
         (if (= N *Tab)
            (<td> 'top (ht:Prin (eval (car L) 1)))
            (<td> 'sub
               (<href> (eval (car L) 1) (urlMT *Url *Menu N *ID)) ) ) ) )
   (htPrin (get Lst *Tab -1) 2) )


### DB Linkage ###
(de mkUrl (Lst)
   (pack (pop 'Lst) '?
      (make
         (while Lst
            (and
               (sym? (car Lst))
               (= `(char '*) (char (car Lst)))
               (link (pop 'Lst) '=) )
            (link (ht:Fmt (pop 'Lst)))
            (and Lst (link '&)) ) ) ) )

(de <$> (Str Obj Msg Tab)
   (cond
      ((not Obj) (ht:Prin Str))
      ((=T Obj) (<href> Str (pack Msg Str)))
      ((send (or Msg 'url>) Obj (or Tab 1))
         (<href> Str (mkUrl @)) )
      (T (ht:Prin Str)) ) )

# Links to previous and next object
(de stepBtn (Var Cls Hook Msg)
   (default Msg 'url>)
   (<span> 'step
      (use (Rel S1 S2)
         (if (isa '+Joint (setq Rel (meta *ID Var)))
            (let Lst (get *ID Var (; Rel slot))
               (setq
                  S2 (lit (cadr (memq *ID Lst)))
                  S1 (lit (car (seek '((L) (== *ID (cadr L))) Lst))) ) )
            (let
               (K
                  (cond
                     ((isa '+Key Rel)
                        (get *ID Var) )
                     ((isa '+Fold Rel)
                        (cons (fold (get *ID Var)) *ID) )
                     (T
                        (cons
                           (get *ID Var)
                           (conc
                              (mapcar '((S) (get *ID S)) (; Rel aux))
                              *ID ) ) ) )
                  Q1 (init (tree Var Cls Hook) K NIL)
                  Q2 (init (tree Var Cls Hook) K T) )
               (unless (get *ID T)
                  (step Q1 T)
                  (step Q2 T) )
               (setq
                  S1 (list 'step (lit Q1) T)
                  S2 (list 'step (lit Q2) T) ) ) )
         (if (and (eval S1) (send Msg @ *Tab))
            (<tip> ,"Next object of the same type"
               (<href> "<<<" (mkUrl @)) )
            (prin "&lt;&lt;&lt;") )
         (prin "&nbsp;--&nbsp;")
         (if (and (eval S2) (send Msg @ *Tab))
            (<tip> ,"Next object of the same type"
               (<href> ">>>" (mkUrl @)) )
            (prin "&gt;&gt;&gt;") ) ) ) )

# Character Separated Values
(off "*CSV")

(de csv ("Nm" . "Prg")
   (call 'rm "-f" (tmp "Nm" ".csv"))
   (let "*CSV" (pack "+" (tmp "Nm" ".csv"))
      (run "Prg") )
   (<href> "CSV" (tmp "Nm" ".csv")) )

(de <0> @
   (when "*CSV"
      (out @
         (prin (next))
         (while (args)
            (prin "^I" (next)) )
         (prinl "^M") ) ) )

(de <%> @
   (prog1 (pass pack)
      (ht:Prin @)
      (prinl "<br/>")
      (<0> @) ) )

(de <!> ("Lst")
   (when "*CSV"
      (out @
         (prin (eval (cadar "Lst")))
         (for "S" (cdr "Lst")
            (prin "^I" (eval (cadr "S"))) )
         (prinl "^M") ) )
   "Lst" )

(de <+> (Str Obj Msg Tab)
   (<$> Str Obj Msg Tab)
   (and "*CSV" (out @ (prin Str "^I"))) )

(de <-> (Str Obj Msg Tab)
   (<$> Str Obj Msg Tab)
   (<0> Str) )


# Interactive tree
(de <tree> ("Url" "Path" "Tree" "Able?" "Excl?" "Expand" "Print")
   (default "Print" 'ht:Prin)
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
                     "#T" (max 1 (- "A" 12)) ) )
               (space)
               ("Print" (car "X"))
               (and (cdr "X") ("tree" @ "L")) ) )
         (("Able?" "X")
            (let "L" (append "Lst" (cons (- "N")))
               (<href> (if (== "X" "Pos") "< >" "[ ]")
                  (pack "Url"
                     "?" (ht:Fmt (cons ("Excl?" "X") "L"))
                     "#T" (max 1 (- "A" 12)) ) )
               (space)
               ("Print" "X") ) )
         (T ("Print" "X")) )
      (prin "</li>") )
   (prinl "</ul>") )


### HTML form ###
(de <post> (Attr Url . Prg)
   (prin
      "<form enctype=\"multipart/form-data\" action=\""
      (sesId Url)
      (and *JS "\" onkeypress=\"formKey(event)\" onsubmit=\"return doPost(this)")
      "\" method=\"post\">" )
   (tag 'fieldset Attr 2 Prg)
   (prinl "</form>") )

(de htmlVar ("Var")
   (prin "name=\"")
   (if (pair "Var")
      (prin (car "Var") ":" (cdr "Var") ":")
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
   (and *JS (prin " onchange=\"return fldChg(this)\""))
   (dfltCss "field")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

(de <hidden> ("Var" Val)
   (prin "<input type=\"hidden\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin Val)
   (prinl "\"/>") )

(de <passwd> (N "Var" Max Flg)
   (prin "<input type=\"password\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prin "\" size=\"" N "\"")
   (and Max (prin " maxlength=\"" Max "\""))
   (and *JS (prin " onchange=\"return fldChg(this)\""))
   (dfltCss "passwd")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

(de <upload> (N "Var" Flg)
   (prin "<input type=\"file\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin (htmlVal "Var"))
   (prin "\" size=\"" N "\"")
   (and *JS (prin " onchange=\"return fldChg(this)\""))
   (dfltCss "upload")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

(de <area> (Cols Rows "Var" Flg)
   (prin "<textarea ")
   (htmlVar "Var")
   (prin " cols=\"" Cols "\" rows=\"" Rows "\" wrap=\"off\"")
   (and *JS (prin " onchange=\"return fldChg(this)\""))
   (dfltCss "area")
   (and Flg (prin " disabled=\"disabled\""))
   (prin '>)
   (ht:Prin (htmlVal "Var"))
   (prinl "</textarea>") )

(de <select> (Lst "Var" Flg)
   (prin "<select ")
   (htmlVar "Var")
   (and *JS (prin " onchange=\"return fldChg(this)\""))
   (dfltCss "select")
   (prin '>)
   (for "X" Lst
      (let "V" (if (atom "X") "X" (car "X"))
         (prin
            "<option"
            (and (pair "X") (pack " title=\"" (cdr "X") "\""))
            (cond
               ((= "V" (htmlVal "Var")) " selected=\"selected\"")
               (Flg " disabled=\"disabled\"") )
            '> )
         (ht:Prin "V") )
      (prin "</option>") )
   (prinl "</select>") )

(de <check> ("Var" Flg)
   (let Val (htmlVal "Var")
      (prin "<input type=\"hidden\" ")
      (htmlVar "Var")
      (prin " value=\"" (and Flg Val T) "\">")
      (prin "<input type=\"checkbox\" ")
      (htmlVar "Var")
      (prin " value=\"T\"" (and Val " checked=\"checked\""))
      (and *JS (prin " onchange=\"return fldChg(this)\""))
      (dfltCss "check")
      (and Flg (prin " disabled=\"disabled\""))
      (prinl "/>") ) )

(de <radio> ("Var" Val Flg)
   (prin "<input type=\"radio\" ")
   (htmlVar "Var")
   (prin " value=\"")
   (ht:Prin Val)
   (prin "\"" (and (= Val (htmlVal "Var")) " checked=\"checked\""))
   (and *JS (prin " onchange=\"return fldChg(this)\""))
   (dfltCss "radio")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

(de <submit> (S "Var" Flg JS)
   (prin "<input type=\"submit\"")
   (and "Var" (space) (htmlVar "Var"))
   (prin " value=\"")
   (ht:Prin S)
   (prin "\"")
   (when *JS
      (prin " onmousedown=\"inBtn(1)\" onblur=\"inBtn(0)\"")
      (and JS (prin " onclick=\"return doBtn(this)\"")) )
   (dfltCss "submit")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

(de <image> (Src "Var" Flg JS)
   (prin "<input type=\"image\"")
   (and "Var" (space) (htmlVar "Var"))
   (prin " src=\"" (sesId Src) "\"")
   (when *JS
      (prin " onmousedown=\"inBtn(1)\" onblur=\"inBtn(0)\"")
      (and JS (prin " onclick=\"return doBtn(this)\"")) )
   (dfltCss "image")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

(de <reset> (S Flg)
   (prin "<input type=\"reset\" value=\"")
   (ht:Prin S)
   (prin "\"")
   (dfltCss "reset")
   (and Flg (prin " disabled=\"disabled\""))
   (prinl "/>") )

# vi:et:ts=3:sw=3
