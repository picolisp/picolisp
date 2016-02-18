# 29nov12tj
# Authors Alexander Burger, Thorsten Joltiz
# (c) Software Lab. Alexander Burger

# "*F" "*Lst" "*X" "*K"

#{ 

* Emacs Server

** Start the Emacs server you want to use for PicoLisp editing with
server-name 'server', only then it will be automatically recognized by
the calls to emacsclient. Example shellscript 'emacsd' for starting
emacs as daemon (make it executable):

 ,------------------------------------------------
 | -rwxr-xr-x 1 me users   83 12. Nov 12:27 emacsd
 `------------------------------------------------

,-----------------------------------------------
| #!/bin/sh
| 
| exec emacs --daemon=server  -l  ~/my/home/emacs/init.el
`-----------------------------------------------

If there is no Emacs server running, or none with server-name
'server', the call to emacsclient will start a new server and open an
emacsclient for this server.

* Customize Emacs:

** Make Emacs revert the edit-buffers without querying
(see http://www.gnu.org/software/emacs/manual/html_node/elisp/Reverting.html)

,--------------------------------------------------------------------
| You can customize how revert-buffer does its work by setting the
| variables described in the rest of this section. 
| 
| — User Option: revert-without-query
| 
| This variable holds a list of files that should be reverted without
| query. The value is a list of regular expressions.
`--------------------------------------------------------------------

Use a regexp like this, replacing 'my/home/directory/' with the path
to your home directory:

,-------------------------------
| my/home/directory/\.pil/tmp/.+
`-------------------------------

** Make Emacs save the edited buffer on exit without querying

Do not exit with "C-x #" (server-edit) but with "C-x C-c" or "C-u C-x
C-c":

,---------------------------------------------------------------------
| (save-buffers-kill-terminal &optional ARG)
| 
| Offer to save each buffer, then kill the current connection.
| If the current frame has no client, kill Emacs itself.
| 
| With prefix ARG, silently save all file-visiting buffers, then kill.
| 
| If emacsclient was started with a list of filenames to edit, then
| only these files will be asked to be saved.
`---------------------------------------------------------------------

** Put the edited buffer into PicoLisp Mode 

The PicoLisp distribution contains a PicoLisp major mode for Emacs,
'picolisp.el' in the "el/" directory (that is "@lib/el" for a local
installation, or some system dependent directory for a global installation).
Make sure that you load this file on Emacs startup and automatically put '.l'
files into picolisp-mode, e.g. with the following code in you .emacs:

,------------------------------------------------------------
| (add-to-list 'load-path "~/path/to/picolisp/lib/el/")
| (require 'picolisp)
| (add-to-list 'auto-mode-alist '("\\.l\\'" . picolisp-mode))
`------------------------------------------------------------

** Add and remove symbols from the 'edit' buffer

With point on a symbol (or with a symbol marked as region in transient
mark mode), 'C-c C-v' (picolisp-edit-K) adds this symbol on top of the
editing buffer. A subsequent 'C-c C-c' (picolisp-edit-Q) removes it
again and puts point back to its previous line. Using 'C-c C-c' when
only one symbol is left exits the 'edit' buffer.

 }#


(de edit @
   (let *Dbg NIL
      (setq "*F" (tmp '"edit.l"))
      (catch NIL
         ("edit" (rest)) ) ) )

(de "edit" ("Lst")
   (let "N" 1
      (loop
         (out "*F"
            (setq "*Lst"
               (make
                  (for "S" "Lst"
                     ("loc" (printsp "S"))
                     ("loc" (val "S"))
                     (pretty (val "S"))
                     (prinl)
                     (for "X" (sort (getl "S"))
                        ("loc" "X")
                        (space 3)
                        (if (atom "X")
                           (println "X" T)
                           (printsp (cdr "X"))
                           (pretty (setq "X" (car "X")) -3)
                           (cond
                              ((type "X")
                                 (prin "  # ")
                                 (print @) )
                              ((>= 799999 "X" 700000)
                                 (prin "  # " (datStr "X")) ) )
                           (prinl) ) )
                     (prinl)
                     (println '(=======))
                     (prinl) ) ) ) )
         (call "emacsclient"
            "-a" ""
            "-c"
            (pack "+" "N")
            "*F" )
         (apply ==== "*Lst")
         (in "*F"
            (while (and (setq "*X" (read)) (atom "*X"))
               (def "*X" (read))
               (until (= '(=======) (setq "*K" (read)))
                  (def "*X" "*K" (read)) ) ) )
         (====)
         (NIL "*X" (throw))
         (T (=0 (car "*X")))
         (setq "N" (car "*X"))
         ("edit" (conc (cdr "*X") "Lst")) ) ) )

(de "loc" ("X" "Lst")
   (cond
      ((memq "X" "Lst"))
      ((and (str? "X") (not (memq "X" (made))))
         (link "X") )
      ((pair "X")
         (push '"Lst" "X")
         ("loc" (car "X") "Lst")
         ("loc" (cdr "X") "Lst") ) ) )
