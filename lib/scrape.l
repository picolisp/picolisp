# 24nov16abu
# (c) Software Lab. Alexander Burger

# *ScrHost *ScrPort *ScrGate *Title *Expect *Found
# *Links *Forms *Buttons *Fields *Errors

# Scrape HTML form(s)
(de scrape (Host Port How)
   (client (setq *ScrHost Host) (setq *ScrPort Port) How
      (off *ScrGate *Links *Forms *Buttons *Fields *Errors)
      (while
         (from
            "303 See Other"
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
            "<div class=\"error\">"
            *Expect )
         (casq @
            ("303 See Other"
               (when (from "Location: http://")
                  (let L (split (line) ':)
                     (if (cdr L)
                        (scrape
                           (pack (++ L))
                           (ifn (format (car (setq L (split (car L) '/))))
                              80
                              (++ L)
                              @ )
                           (glue '/ L) )
                        (setq L (split (car L) '/))
                        (scrape (pack (++ L)) 80 (glue '/ L)) ) ) ) )
            ("<title>"
               (setq *Title (ht:Pack (till "<"))) )
            ("<base href=\"http://"
               (let L (split (till "\"") ':)
                  (if (cdr L)
                     (setq
                        *ScrHost (pack (++ L))
                        *ScrPort (format (cdr (rot (car L)))) )
                     (setq *ScrGate (pack (cdr (member '/ (car L))))) ) ) )
            ("<a href=\""
               (let Url (pack *ScrGate (till "\"" T))
                  (from ">")
                  (cond
                     ((<> "<" (peek))
                        (queue '*Links (cons (ht:Pack (till "<")) Url)) )
                     ((= "<img" (till " " T))
                        (from "alt=\"")
                        (queue '*Links (cons (ht:Pack (till "\"")) Url)) ) ) ) )
            (" action=\""
               (queue '*Forms  # (action . fields)
                  (list (pack *ScrGate (till "\"" T))) ) )
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
            ("<div class=\"error\">"
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
            *ScrHost (pack (++ L))
            *ScrPort (ifn (format (car L)) 80 (++ L) @)
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

# Inspect current page
(de display ()
   (prinl "###############")
   (apply println (mapcar car *Links) 'click)
   (prinl)
   (apply println (mapcar car *Buttons) 'press)
   (prinl)
   (apply println (trim (mapcar fin *Fields)) 'value)
   (prinl)
   *Title )

### Utility functions ###
(de target (Lst Lbl Cnt)
   (cond
      ((num? Lbl)
         (get Lst Lbl) )
      ((pair Lbl) Lbl)
      (T
         (default Cnt 1)
         (or
            (find
               '((L)
                  (and
                     (pre? Lbl (car L))
                     (=0 (dec 'Cnt)) ) )
               Lst )
            (quit "Target not found" Lbl) ) ) ) )

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
