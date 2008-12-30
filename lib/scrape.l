# 03dec08abu
# (c) Software Lab. Alexander Burger

# *ScrHost *ScrPort *Title *Expect *Found
# *Links *Forms *Buttons *Fields *Errors

# Scrape HTML form(s)
(de scrape (Host Port How)
   (client (setq *ScrHost Host) (setq *ScrPort Port) How
      (off *Links *Forms *Buttons *Fields *Errors)
      (while
         (from
            "<title>"
            "<base href=\"http://"
            "<a href=\""
            " action=\""
            "<input type=\"submit\" name=\""
            "<input type=\"hidden\" name=\""
            "<input type=\"text\" name=\""
            "<input type=\"password\" name=\""
            "<select name=\""
            "<option selected=\"selected\">"
            "<textarea name=\""
            "<span id=\""
            "<div class=\"err\">"
            *Expect )
         (case @
            ("<title>"
               (setq *Title (ht:Pack (till "<"))) )
            ("<base href=\"http://"
               (setq
                  *ScrHost (rot (cdr (rot (split (till "\"") '/ ':))))
                  *ScrPort (format (pack (pop '*ScrHost)))
                  *ScrHost (pack *ScrHost) ) )
            ("<a href=\""
               (let Url (till "\"" T)
                  (from ">")
                  (when (till "<")
                     (queue '*Links (cons (ht:Pack @) Url)) ) ) )
            (" action=\""
               (queue '*Forms (list (till "\"" T))) )  # (action . fields)
            ("<input type=\"submit\" name=\""
               (let Nm (till "\"" T)
                  (from "value=\"")
                  (queue '*Buttons  # (label field . form)
                     (cons
                        (ht:Pack (till "\""))
                        (cons Nm T)
                        (last *Forms) ) ) ) )
            ("<input type=\"hidden\" name=\""
               (conc (last *Forms)
                  (cons
                     (cons (till "\"" T)
                        (prog (from "value=\"") (ht:Pack (till "\"")))) ) ) )
            (("<input type=\"text\" name=\"" "<input type=\"password\" name=\"")
               (conc (last *Forms)
                  (cons
                     (queue '*Fields
                        (cons (till "\"" T)
                           (prog (from "value=\"") (ht:Pack (till "\"")))) ) ) ) )
            ("<select name=\""
               (conc (last *Forms)
                  (cons
                     (queue '*Fields (cons (till "\"" T))) ) ) )
            ("<option selected=\"selected\">"
               (con (last *Fields) (ht:Pack (till "<"))) )
            ("<textarea name=\""
               (conc (last *Forms)
                  (cons
                     (queue '*Fields
                        (cons (till "\"" T)
                           (prog (from ">") (ht:Pack (till "<"))) ) ) ) ) )
            ("<span id=\""
               (from ">")
               (queue '*Fields (ht:Pack (till "<"))) )
            ("<div class=\"err\">"
               (queue '*Errors (ht:Pack (till "<"))) )
            (T  (on *Found)) ) )
      (or *Errors *Title) ) )

# Expect content
(de expect (*Expect . "Prg")
   (let *Found NIL
      (run "Prg")
      (unless *Found
         (quit "Content not found" *Expect) ) ) )

# Click on a link
(de click (Lbl Cnt)
   (let L (cdr (target *Links Lbl Cnt))
      (when (pre? "http://" L)
         (setq
            L (split (nth (chop L) 8) '/ ':)
            *ScrHost (pack (pop 'L))
            *ScrPort (ifn (format (pack (car L))) 80 (pop 'L) @)
            L (glue '/ L) ) )
      (scrape *ScrHost *ScrPort L) ) )

# Press a button
(de press (Lbl Cnt)
   (let B (target *Buttons Lbl Cnt)
      (scrape *ScrHost *ScrPort
         (cons
            (caddr B)
            (glue "&"
               (mapcar
                  '((X)
                     (list (car X) '= (ht:Fmt (cdr X))) )
                  (cons (cadr B) (cdddr B)) ) ) ) ) ) )

# Retrieve a field's value
(de value (Fld Cnt)
   (fin (field Fld Cnt)) )

# Set a field's value
(de enter (Fld Str Cnt)
   (con (field Fld Cnt) Str) )

### Utilities ###
(de display ()
   (prinl "###############")
   (apply println (mapcar car *Links) 'click)
   (prinl)
   (apply println (mapcar car *Buttons) 'press)
   (prinl)
   (apply println (trim (mapcar fin *Fields)) 'value)
   (prinl)
   *Title )

(de target (Lst Lbl Cnt)
   (default Cnt 1)
   (or
      (find
         '((L)
            (and
               (= Lbl (car L))
               (=0 (dec 'Cnt)) ) )
         Lst )
      (quit "Target not found" Lbl) ) )

(de field (Fld Cnt)
   (or
      (cond
         ((gt0 Fld)
            (get *Fields Fld) )
         ((lt0 Fld)
            (get *Fields (+ (length *Fields) Fld 1)) )
         (T (assoc Fld (cdr (get *Forms (or Cnt 1))))) )
      (quit "Field not found" Fld) ) )

# vi:et:ts=3:sw=3
