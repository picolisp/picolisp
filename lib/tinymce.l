# 07may14abu
# (c) Software Lab. Alexander Burger

### TinyMCE Interface ###
(allow "tinymce/" T)

(de <tinymce> ()
   (javascript "tinymce/tinymce.min.js" "
      tinymce.init({
         selector: 'textarea',
         plugins: 'textcolor hr directionality paste',
         toolbar: 'forecolor bold italic underline strikethrough | hr | removeformat',
         menubar: false,
         statusbar: false,
         toolbar_items_size: 'small',
         language: '" (or *Lang "en") "',
         entity_encoding: 'raw',
         setup: function(ed) {
            ed.on('init', function(e) {
               var fld = ed.getElement();
               fld.pilSetValue = function(val) {
                  ed.setContent(val);
               }
               fld.pilDisable = function(flg) {
                  ed.getBody().setAttribute('contenteditable', !flg);
               }
               fld.pilDisable(fld.disabled);
            } )
            ed.on('change', function(e) {
               ed.getElement().value = ed.getContent();
               fldChg(ed.getElement());
            } )
         } } )" ) )

# Parse HTML text
(de htmlText (Size Font Text)
   (let (Lst (split (chop Text)  "<" ">")  Tag)
      (make
         (recur (Tag)
            (loop
               (let? S (pop 'Lst)
                  (unless (= S '("^J"))
                     (link (ht:Pack S)) ) )
               (NIL Lst)
               (T (and (= "/" (caar Lst)) (= Tag (cdar Lst)))
                  (pop 'Lst) )
               (let S (pop 'Lst)
                  (cond
                     ((= S '`(chop "br /"))
                        (link 0) )
                     ((= S '`(chop "hr /"))
                        (link '(H 0)) )
                     ((= S '`(chop "p"))
                        (and (made) (link 0))
                        (recurse S)
                        (and (find bool Lst) (link 0)) )
                     ((= S '`(chop "em"))
                        (let Font (pack Font "-Italic")
                           (link (cons 'F Size Font))
                           (recurse S)
                           (link '(F)) ) )
                     ((= S '`(chop "strong"))
                        (let Font (pack Font "-Bold")
                           (link (cons 'F Size Font))
                           (recurse S)
                           (link '(F)) ) )
                     ((= S '`(chop "span style=\"text-decoration: underline;\""))
                        (link (list 'U (/ Size 6)))
                        (recurse '("s" "p" "a" "n"))
                        (link '(U)) )
                     ((= S '`(chop "span style=\"text-decoration: line-through;\""))
                        (link (list 'U (/ Size -4)))
                        (recurse '("s" "p" "a" "n"))
                        (link '(U)) )
                     ((head '`(chop "span style=\"color: ") S)
                        (setq S (nth S 21))
                        (link
                           (list 'C
                              (*/ 100 (hex (cut 2 'S)) 255)
                              (*/ 100 (hex (cut 2 'S)) 255)
                              (*/ 100 (hex (head 2 S)) 255) ) )
                        (recurse '("s" "p" "a" "n"))
                        (link '(C)) )
                     (T (msg S " -- " Text " ?")) ) ) ) ) ) ) )

# Remove markup
(de unmarkup (Text)
   (let L (chop Text)
      (use (@A @X @Z)
         (while (match '(@A "<" @X ">" @Z) L)
            (setq L
               (conc
                  @A
                  (and @A @Z (head '("b" "r") @X) (cons " "))
                  @Z ) ) ) )
      (extract pack (split L " " "^J")) ) )

# HTML text index relation
(class +HtIdx +Fold +Idx)

(dm has> (Val X)
   (and
      (or
         (= Val X)
         (member Val (mapcar fold (unmarkup X))) )
      X ) )

(dm rel> (Obj Old New Hook)
   (setq Old (unmarkup Old)  New (unmarkup New))
   (for O (diff Old New)
      (super Obj O NIL Hook) )
   (for N (diff New Old)
      (super Obj NIL N Hook) ) )

(dm rel?> (Obj Val Hook)
   (for V (unmarkup Val)
      (NIL (super Obj V Hook))
      T ) )

(dm lose> (Obj Val Hook)
   (for V (unmarkup Val)
      (super Obj V Hook) ) )

(dm keep> (Obj Val Hook)
   (for V (unmarkup Val)
      (super Obj V Hook) ) )

NIL ####### README #######

Using the TinyMCE 4.x Javascript/HTML WYSIWYG editor in PicoLisp applications

1. Get 'tinymce'

   $ (cd /some/path; unzip tinymce_4.0.21.zip)

2. In the application's runtime directory, create a link to the tinymce
   installation, e.g.:

   $ ln -s /some/path/tinymce/js/tinymce tinymce

3. Load "@lib/tinymce.l" at startup

   (load .. "@lib/tinymce.l" ..)

4. On each page where you want to use tinymce in textareas, call (<tinymce>)
   before the first textarea, e.g.:

   (action
      (html 0 "Title" "lib.css" NIL
         (form NIL
            ..
            (<tinymce>)
            (gui '(+Var +TextField) '*Text 60 8)  # Textarea
            ..

# vi:et:ts=3:sw=3
