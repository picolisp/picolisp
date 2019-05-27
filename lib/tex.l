# 24nov16abu
# (c) Software Lab. Alexander Burger

# Convert to PDF document
(de dviPdf (Doc)
   (prog1
      (tmp Doc ".pdf")
      (call "/usr/bin/dvips" "-q" (pack Doc ".dvi"))
      (call "ps2pdf" (pack Doc ".ps") @)
      (call "rm" "-f"
         (pack Doc ".tex")
         (pack Doc ".dvi")
         (pack Doc ".ps") ) ) )

# Tex Formatting
(de tex (S  . @)
   (prin "\\" (or S (next)))
   (when (args)
      (prin "{")
      (texPrin (next))
      (while (args)
         (when (next)
            (prin "\\\\")
            (texPrin (arg)) ) )
      (prin "}") )
   (and S (prinl)) )

(de texl (S . @)
   (prin "\\" (or S (next)) "{")
   (loop
      (let Lst (next)
         (texPrin (++ Lst))
         (while Lst
            (when (++ Lst)
               (prin "\\\\")
               (texPrin @) ) ) )
      (NIL (args))
      (prin (next)) )
   (prin "}")
   (and S (prinl)) )

(de texPrin (X)
   (let Q NIL
      (for C (chop X)
         (cond
            ((sub? C "#$%&_{}")
               (prin "\\" C) )
            ((sub? C "<²>")
               (prin "$" C "$") )
            (T
               (prin
                  (case C
                     (`(char 8364) "\\EUR")
                     ("\"" (if (onOff Q) "``" "''"))
                     ("\\" "$\\backslash$")
                     ("\^" "\\char94")
                     ("~" "\\char126")
                     (T C) ) ) ) ) ) ) )


### TeX Document ###
(de document (Doc Cls Typ Use . Prg)
   (out (list "@bin/lat1" (pack Doc ".tex"))
      (prinl "\\documentclass[" Cls "]{" Typ "}")
      (while Use
         (if (atom (car Use))
            (prinl "\\usepackage{" (++ Use) "}")
            (prinl "\\usepackage[" (caar Use) "]{" (cdr (++ Use)) "}") ) )
      (prinl "\\begin{document}")
      (prEval Prg 2)
      (prinl "\\end{document}") )
   (call "sh" "-c"
      (pack "latex -interaction=batchmode " Doc ".tex >/dev/null") )
   (call "rm" (pack Doc ".aux") (pack Doc ".log")) )

(de \\block (S . Prg)
   (prinl "\\begin{" S "}")
   (prEval Prg 2)
   (prinl "\\end{" S "}") )

(de \\figure (S . Prg)
   (prinl "\\begin{figure}" S)
   (prEval Prg 2)
   (prinl "\\end{figure}") )


### Tabular environment ###
(de \\table (Fmt . Prg)
   (prinl "\\begin{tabular}[c]{" Fmt "}")
   (prEval Prg 2)
   (prinl "\\end{tabular}") )

(de \\carry ()
   (prinl "\\end{tabular}")
   (prinl)
   (prinl "\\begin{tabular}[c]{" "Fmt" "}") )

(de \\head @
   (prin "\\textbf{" (next) "}")
   (while (args)
      (prin " & \\textbf{")
      (texPrin (next))
      (prin "}") )
   (prinl "\\\\") )

(de \\row @
   (when (=0 (next))
      (next)
      (prin "\\raggedleft ") )
   (ifn (=T (arg))
      (texPrin (arg))
      (prin "\\textbf{")
      (texPrin (next))
      (prin "}") )
   (while (args)
      (prin " & ")
      (when (=0 (next))
         (next)
         (prin "\\raggedleft ") )
      (ifn (=T (arg))
         (texPrin (arg))
         (prin "\\textbf{")
         (texPrin (next))
         (prin "}") ) )
   (prinl "\\\\") )

(de \\hline ()
   (prinl "\\hline") )

(de \\cline (C1 C2)
   (prinl "\\cline{" C1 "-" C2 "}") )


### Letter Document Class ###
(de \\letter (Lst . Prg)
   (prin "\\begin{letter}{" (++ Lst))
   (while Lst
      (when (++ Lst)
         (prin "\\\\" @) ) )
   (prinl "}")
   (prEval Prg 2)
   (prinl "\\end{letter}") )

(de \\signature (S)
   (tex "signature" S) )

(de \\opening (S)
   (tex "opening" S) )

(de \\closing (S)
   (tex "closing" S) )
