;;;;;; inferior-picolisp: Picolisp repl in a buffer.
;;;;;; Version: 1.2

;;; Copyright (c) 2009, 2012, 2013, Guillermo R. Palavecino, Thorsten Jolitz

;; This file is NOT part of GNU emacs.

;;;; Credits:
;; It's and adaptation of GNU emacs' cmuscheme.el
;;
;;;; Contact:
;; For comments, bug reports, questions, etc, you can contact me via IRC
;; to the user named grpala (or armadillo) on irc.freenode.net in the
;; #picolisp channel or via email to the author's nickname at gmail.com
;;
;;;; License:
;; This work is released under the GPL 2 or (at your option) any later
;; version.

(require 'picolisp)
(require 'comint)


(defgroup picolisp nil
  "Run an Picolisp process in a buffer."
  :group 'picolisp )

;;; INFERIOR PICOLISP MODE STUFF
;;;============================================================================

(defconst inferior-picolisp-version "1.2"
  "Verion-number of library")

(defcustom inferior-picolisp-mode-hook nil
  "*Hook for customizing inferior-picolisp mode."
  :type 'hook
  :group 'picolisp )

(defvar inferior-picolisp-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\M-\C-x" 'picolisp-send-definition) ;gnu convention
    (define-key m "\C-x\C-e" 'picolisp-send-last-sexp)
    (define-key m "\C-c\C-l" 'picolisp-load-file)
    m ) )

(defvar picolisp-local-program-name "./pil +")
(defvar picolisp-process-number 0)

(defvar picolisp-program-name "pil +"
  "The name of the program used to run Picolisp." )

;; Install the process communication commands in the picolisp-mode keymap.
(define-key picolisp-mode-map "\M-\C-x" 'picolisp-send-definition);gnu convention
(define-key picolisp-mode-map "\C-x\C-e" 'picolisp-send-last-sexp);gnu convention
(define-key picolisp-mode-map "\C-c\C-e" 'picolisp-send-definition)
(define-key picolisp-mode-map "\C-c\M-e" 'picolisp-send-definition-and-go)
(define-key picolisp-mode-map "\C-c\C-r" 'picolisp-send-region)
(define-key picolisp-mode-map "\C-c\M-r" 'picolisp-send-region-and-go)
(define-key picolisp-mode-map "\C-c\C-x" 'switch-to-picolisp)
(define-key picolisp-mode-map "\C-c\C-l" 'picolisp-load-file)

(let ((map (lookup-key picolisp-mode-map [menu-bar picolisp])))
  (define-key map [separator-eval] '("--"))
  (define-key map [load-file]
    '("Load Picolisp File" . picolisp-load-file) )
  (define-key map [switch]
    '("Switch to Picolisp" . switch-to-picolisp) )
  (define-key map [send-def-go]
    '("Evaluate Last Definition & Go" . picolisp-send-definition-and-go) )
  (define-key map [send-def]
    '("Evaluate Last Definition" . picolisp-send-definition) )
  (define-key map [send-region-go]
    '("Evaluate Region & Go" . picolisp-send-region-and-go) )
  (define-key map [send-region]
    '("Evaluate Region" . picolisp-send-region) )
  (define-key map [send-sexp]
    '("Evaluate Last S-expression" . picolisp-send-last-sexp) ) )

(defvar picolisp-buffer)

(define-derived-mode inferior-picolisp-mode comint-mode "Inferior Picolisp"
  "Major mode for interacting with an inferior Picolisp process.

The following commands are available:
\\{inferior-picolisp-mode-map}

An Picolisp process can be fired up with M-x run-picolisp.

Customization: Entry to this mode runs the hooks on comint-mode-hook and
inferior-picolisp-mode-hook (in that order).

You can send text to the inferior Picolisp process from other buffers containing
Picolisp source.
    switch-to-picolisp switches the current buffer to the Picolisp process buffer.
    picolisp-send-definition sends the current definition to the Picolisp process.
    picolisp-send-region sends the current region to the Picolisp process.

    picolisp-send-definition-and-go and picolisp-send-region-and-go
        switch to the Picolisp process buffer after sending their text.
For information on running multiple processes in multiple buffers, see
documentation for variable picolisp-buffer.

Commands:
Return after the end of the process' output sends the text from the
    end of process to point.
Return before the end of the process' output copies the sexp ending at point
    to the end of the process' output, and sends it.
Delete converts tabs to spaces as it moves back.
Tab indents for Picolisp; with argument, shifts rest
    of expression rigidly with the current line.
C-M-q does Tab on each line starting within following expression.
Paragraphs are separated only by blank lines.  Semicolons start comments.
If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it."
  ;; Customize in inferior-picolisp-mode-hook
  (picolisp-mode-variables)
  (setq comint-prompt-regexp "^[^\n:?!]*[?!:]+ *")
  (setq comint-prompt-read-only nil)
  (setq comint-input-filter (function picolisp-input-filter))
  (setq comint-get-old-input (function picolisp-get-old-input))
  (setq mode-line-process '(":%s"))
  (setq comint-input-ring-file-name "~/.pil_history") )

(defcustom inferior-picolisp-filter-regexp "\\`\\s *\\S ?\\S ?\\s *\\'"
  "*Input matching this regexp are not saved on the history list.
Defaults to a regexp ignoring all inputs of 0, 1, or 2 letters."
  :type 'regexp
  :group 'picolisp )

(defun picolisp-input-filter (str)
  "Don't save anything matching `inferior-picolisp-filter-regexp'."
  (not (string-match inferior-picolisp-filter-regexp str)) )

(defun picolisp-get-old-input ()
  "Snarf the sexp ending at point."
  (save-excursion
    (let ((end (point)))
      (backward-sexp)
      (buffer-substring (point) end) ) ) )

(defun picolisp-disable-line-editor ()
  "Disable inbuild PicoLisp line-editor.
Not needed when PicoLisp is run as Emacs subprocess."
  (let ((pil-tmp-dir (expand-file-name "~/.pil/")))
  (and (member
        "editor" (directory-files pil-tmp-dir ))
      (rename-file
       (expand-file-name "editor" pil-tmp-dir)
       (expand-file-name "editor-orig" pil-tmp-dir)))
    (with-current-buffer
     (find-file-noselect
     (expand-file-name "editor" pil-tmp-dir))
     (save-buffer)
     (kill-buffer))))

(defun picolisp-reset-line-editor ()
  "Reset inbuild PicoLisp line-editor to original state."
  (let ((pil-tmp-dir (expand-file-name "~/.pil/")))
    (if (member "editor-orig" (directory-files pil-tmp-dir))
        (rename-file
         (expand-file-name "editor-orig" pil-tmp-dir)
         (expand-file-name "editor" pil-tmp-dir)
         'OK-IF-ALREADY-EXISTS)
      (delete-file
       (expand-file-name "editor" pil-tmp-dir)))))


;;;###autoload
(defun run-picolisp-new-local (cmd)
  "Run a new inferior Picolisp process for a locally installed
PicoLisp, input and output via buffer `*picolisp<N>*'. Works only
as intended, when called from inside a picolisp directory, e.g.
from a dired buffer showing the top-level directory of a local
picolisp installation. Otherwise, calls a global picolisp
installation instead (with `picolisp-program-name', see function
`picolisp-interactively-start-process'). If there is a process
already running in `*picolisp<N>*', create a new process in
buffer `*picolisp<N+1>*'. With argument, allows you to edit the
command line (default is value of `picolisp-local-program-name').
Runs the hook `inferior-picolisp-mode-hook' \(after the
`comint-mode-hook' is run). \(Type \\[describe-mode] in the
process buffer for a list of commands.)"

  (interactive (list (if current-prefix-arg
                         (read-string "Run Picolisp: " picolisp-local-program-name)
                         picolisp-local-program-name) ) )
  (setq picolisp-process-number (1+ picolisp-process-number))
  (setq pl-proc-buf (concat
                     "picolisp<"
                     (number-to-string picolisp-process-number)
                     ">"))
  (let ((cmdlist (split-string cmd)))
    (picolisp-disable-line-editor)
    (set-buffer
     (apply 'make-comint pl-proc-buf (car cmdlist)
                         nil (cdr cmdlist)))
     (picolisp-reset-line-editor)
      (inferior-picolisp-mode) ) 
  (pop-to-buffer (concat "*" pl-proc-buf "*")) ) 


;;;###autoload
(defun run-picolisp (cmd)
  "Run an inferior Picolisp process, input and output via buffer `*picolisp*'.
If there is a process already running in `*picolisp*', switch to that buffer.
With argument, allows you to edit the command line (default is value
of `picolisp-program-name').
Runs the hook `inferior-picolisp-mode-hook' \(after the `comint-mode-hook'
is run).
\(Type \\[describe-mode] in the process buffer for a list of commands.)"

  (interactive (list (if current-prefix-arg
                         (read-string "Run Picolisp: " picolisp-program-name)
                         picolisp-program-name ) ) )
  (when (not (comint-check-proc "*picolisp*"))
    (let ((cmdlist (split-string cmd)))
      (picolisp-disable-line-editor)
      (set-buffer (apply 'make-comint "picolisp" (car cmdlist)
                         nil (cdr cmdlist) ) )
      (picolisp-reset-line-editor)
      (inferior-picolisp-mode) ) )
  (setq picolisp-program-name cmd)
  (setq picolisp-buffer "*picolisp*")
  (pop-to-buffer "*picolisp*") )
;;;###autoload (add-hook 'same-window-buffer-names "*picolisp*")

(defun picolisp-send-region (start end)
  "Send the current region to the inferior Picolisp process."
  (interactive "r")
  (let ((regionsubstring (replace-regexp-in-string "^
" "" (buffer-substring start end) ) ) )
    (comint-send-string 
     (picolisp-proc) 
     (if (string= "" (car (last (split-string regionsubstring "
" ) ) ) )
         regionsubstring
       (concat regionsubstring "\n") ) ) ) )

(defun picolisp-send-definition ()
  "Send the current definition to the inferior Picolisp process."
  (interactive)
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (picolisp-send-region
       (point) (progn (forward-sexp) (point)) ) ) ) )

(defun picolisp-send-last-sexp ()
  "Send the previous sexp to the inferior Picolisp process."
  (interactive)
  (picolisp-send-region (save-excursion (backward-sexp) (point)) (point)) )

(defun switch-to-picolisp (eob-p)
  "Switch to the picolisp process buffer.
With argument, position cursor at end of buffer."
  (interactive "P")
  (if (or (and picolisp-buffer (get-buffer picolisp-buffer))
          (picolisp-interactively-start-process) )
      (pop-to-buffer picolisp-buffer)
    (error "No current process buffer.  See variable `picolisp-buffer'") )
  (when eob-p
    (push-mark)
    (goto-char (point-max)) ) )

(defun picolisp-send-region-and-go (start end)
  "Send the current region to the inferior Picolisp process.
Then switch to the process buffer."
  (interactive "r")
  (picolisp-send-region start end)
  (switch-to-picolisp t) )

(defun picolisp-send-definition-and-go ()
  "Send the current definition to the inferior Picolisp.
Then switch to the process buffer."
  (interactive)
  (picolisp-send-definition)
  (switch-to-picolisp t) )

(defcustom picolisp-source-modes '(picolisp-mode)
  "*Used to determine if a buffer contains Picolisp source code.
If it's loaded into a buffer that is in one of these major modes,
it's considered a picolisp source file by `picolisp-load-file'.  Used by
these commands to determine defaults."
  :type '(repeat function)
  :group 'picolisp )

(defvar picolisp-prev-load-dir/file nil
  "Caches the last (directory . file) pair.
Caches the last pair used in the last `picolisp-load-file' command.
Used for determining the default in the next one." )

(defun picolisp-load-file (file-name)
  "Load a Picolisp file FILE-NAME into the inferior Picolisp process."
  (interactive (comint-get-source "Load Picolisp file: " picolisp-prev-load-dir/file
                                  picolisp-source-modes t ) ) ; t because `load'
                                                       ; needs an exact name
  (comint-check-source file-name) ; Check to see if buffer needs saved.
  (setq picolisp-prev-l/c-dir/file (cons (file-name-directory    file-name)
                                       (file-name-nondirectory file-name) ) )
  (comint-send-string (picolisp-proc) (concat "(load \""
                                            file-name
                                            "\"\)\n" ) ) )


(defvar picolisp-buffer nil "*The current picolisp process buffer.

MULTIPLE PROCESS SUPPORT
===========================================================================
inferior-picolisp.el supports, in a fairly simple fashion, running multiple Picolisp
processes.  To run multiple Picolisp processes, you start the first up with
\\[run-picolisp].  It will be in a buffer named *picolisp*.  Rename this buffer
with \\[rename-buffer].  You may now start up a new process with another
\\[run-picolisp].  It will be in a new buffer, named *picolisp*.  You can
switch between the different process buffers with \\[switch-to-buffer].

Commands that send text from source buffers to Picolisp processes -- like
`picolisp-send-definition' -- have to choose a process to send to, when you
have more than one Picolisp process around.  This is determined by the
global variable `picolisp-buffer'.  Suppose you have three inferior Picolisps
running:
    Buffer      Process
    foo         picolisp
    bar         picolisp<2>
    *picolisp*  picolisp<3>
If you do a \\[picolisp-send-definition-and-go] command on some Picolisp source
code, what process do you send it to?

- If you're in a process buffer (foo, bar, or *picolisp*),
  you send it to that process.
- If you're in some other buffer (e.g., a source file), you
  send it to the process attached to buffer `picolisp-buffer'.
This process selection is performed by function `picolisp-proc'.

Whenever \\[run-picolisp] fires up a new process, it resets `picolisp-buffer'
to be the new process's buffer.  If you only run one process, this will
do the right thing.  If you run multiple processes, you can change
`picolisp-buffer' to another process buffer with \\[set-variable].

More sophisticated approaches are, of course, possible.  If you find yourself
needing to switch back and forth between multiple processes frequently,
you may wish to consider ilisp.el, a larger, more sophisticated package
for running inferior Lisp and Picolisp processes.  The approach taken here is
for a minimal, simple implementation.  Feel free to extend it." )

(defun picolisp-proc ()
  "Return the current Picolisp process, starting one if necessary.
See variable `picolisp-buffer'."
  (unless (and picolisp-buffer
               (get-buffer picolisp-buffer)
               (comint-check-proc picolisp-buffer) )
    (picolisp-interactively-start-process) )
  (or (picolisp-get-process)
      (error "No current process.  See variable `picolisp-buffer'") ) )

(defun picolisp-get-process ()
  "Return the current Picolisp process or nil if none is running."
  (get-buffer-process (if (eq major-mode 'inferior-picolisp-mode)
                          (current-buffer)
                        picolisp-buffer ) ) )

(defun picolisp-interactively-start-process (&optional cmd)
  "Start an inferior Picolisp process.  Return the process started.
Since this command is run implicitly, always ask the user for the
command to run."
  (save-window-excursion
    (run-picolisp (read-string "Run Picolisp: " picolisp-program-name)) ) )

;;; Do the user's customization...

(defcustom inferior-picolisp-load-hook nil
  "This hook is run when inferior-picolisp is loaded in.
This is a good place to put keybindings."
  :type 'hook
  :group 'picolisp )

(run-hooks 'inferior-picolisp-load-hook)

(provide 'inferior-picolisp)

