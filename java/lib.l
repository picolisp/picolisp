# 27feb16abu
# (c) Software Lab. Alexander Burger

# *Java

(de java @
   (pass jre 0) )

(de public @
   (pass jre 1) )

(de interface @
   (let Obj (next)
      (prog1
         (jre 2 Obj (next))
         (while (args)
            (def (next) Obj (next)) ) ) ) )

(de reflect (X)
   (jre 3 X) )

(de jre @
   (unless *Java
      (let
         (Path (tmp ":" (path "@java/reflector.jar") (and *Classpath ":") *Classpath)
            Rqst (tmp "rqst")
            Rply (tmp "rply") )
         (call "mkfifo" Rqst)
         (call "mkfifo" Rply)
         (task (open Rqst)  R (open Rply)
            (in @
               (out R
                  (ext (car *Java)
                     (pr
                        (with (rd)  # Obj
                           (if (get (rd) This)
                              (apply @ (rd))
                              (rd)
                              NIL ) ) ) ) ) ) )
         (forked)
         (setq *Java
            (cons
               65535  # External symbol offset
               (pipe (exec 'java "-cp" Path "Reflector" Rqst Rply)) ) )
         (queue '*Ext
            (cons (car *Java) reflect) )
         (con jre (cddr jre)) ) )
   (ext (car *Java)
      (out (cdr *Java) (pr (rest)))
      (in (cdr *Java) (rd)) ) )

# Inline Java Code
(de javac (Cls Ext Impl . @)
   (let (J (tmp Cls ".java")  C (tmp Cls ".class"))
      (out J
         (while (args)
            (prinl "import " (next) ";") )
         (prinl "public class " Cls
            (and Ext (pack " extends " @))
            (and Impl (pack " implements " (glue ", " Impl)))
            " {"  )
         (here "/**/")
         (prinl "}") )
      (call "javac" "-O" "-g:none" J) ) )

# vi:et:ts=3:sw=3
