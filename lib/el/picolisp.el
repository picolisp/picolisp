;;;;;; picolisp-mode: Major mode to edit picoLisp.
;;;;;; Version: 1.3

;;; Copyright (c) 2009, Guillermo R. Palavecino
;;; Copyright (c) 2011, 2012 Thorsten Jolitz

;; This file is NOT part of GNU emacs.

;;;; Credits:
;; It's based on GNU emacs' lisp-mode and scheme-mode.
;; Some bits were taken from paredit.el
;; Two functions were copied from Xah Lee (http://xahlee.org/)
;;
;;;; Contact:
;; For comments, bug reports, questions, etc, you can contact the
;; first author via IRC to the user named grpala (or armadillo) on
;; irc.freenode.net in the #picolisp channel or via email to the
;; author's nickname at gmail.com 
;; 
;; Or contact the second author and curent maintainer via email: 
;; t <lastname in lowercase letters> AT gmail DOT com
;; 
;;;; License:
;; This work is released under the GPL 2 or (at your option) any later
;; version.


(require 'lisp-mode)

(defcustom picolisp-parsep t
  "This is to toggle picolisp-mode's multi-line s-exps closing parens separation capability."
  :type 'boolean
  :group 'picolisp )

;; I know... this shouldn't be here, but you see, people may want to keep
;; their body-indent value unaltered and have a different one for picolisp
;; sources, so...
(defcustom picolisp-body-indent 3
  "Number of columns to indent the second line of a `(de ...)' form."
  :group 'picolisp
  :type 'integer )

(defvar picolisp-mode-syntax-table
  (let ((st (make-syntax-table))
        (i 0) )

    ;; Default is atom-constituent.
    (while (< i 256)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)) )

    ;; Word components.
    (setq i ?0)
    (while (<= i ?9)
      (modify-syntax-entry i "w   " st)
      (setq i (1+ i)) )
    (setq i ?A)
    (while (<= i ?Z)
      (modify-syntax-entry i "w   " st)
      (setq i (1+ i)) )
    (setq i ?a)
    (while (<= i ?z)
      (modify-syntax-entry i "w   " st)
      (setq i (1+ i)) )

    ;; Whitespace
    (modify-syntax-entry ?\t "    " st)
    (modify-syntax-entry ?\n ">   " st)
    (modify-syntax-entry ?\f "    " st)
    (modify-syntax-entry ?\r "    " st)
    (modify-syntax-entry ?\s "    " st)

    ;; These characters are delimiters but otherwise undefined.
    ;; Brackets and braces balance for editing convenience.
    (modify-syntax-entry ?\[ "(]  " st)
    (modify-syntax-entry ?\] ")[  " st)
    (modify-syntax-entry ?{  "(}  " st)
    (modify-syntax-entry ?}  "){  " st)

    ;; Other atom delimiters
    (modify-syntax-entry ?\( "()  " st)
    (modify-syntax-entry ?\) ")(  " st)
    ;; It's used for single-line comments.
    (modify-syntax-entry ?#  "<   " st)
    (modify-syntax-entry ?\" "\"   " st)
    (modify-syntax-entry ?'  "'   " st)
    (modify-syntax-entry ?`  "'   " st)
    (modify-syntax-entry ?~  "'   " st)

    ;; Special characters
    (modify-syntax-entry ?,  "'   " st)
    (modify-syntax-entry ?\\ "\\   " st)
    st ) )

(defvar picolisp-mode-abbrev-table nil)
(define-abbrev-table 'picolisp-mode-abbrev-table ())


(defun picolisp-mode-variables ()
  (set-syntax-table picolisp-mode-syntax-table)
  ;;(setq local-abbrev-table picolisp-mode-abbrev-table)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "$\\|" page-delimiter))
  ;;(setq comint-input-ring-file-name "~/.pil_history")

  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)

  (make-local-variable 'paragraph-ignore-fill-prefix)
  (setq paragraph-ignore-fill-prefix t)

  (make-local-variable 'fill-paragraph-function)
  (setq fill-paragraph-function 'lisp-fill-paragraph)
  ;; Adaptive fill mode gets in the way of auto-fill,
  ;; and should make no difference for explicit fill
  ;; because lisp-fill-paragraph should do the job.
  (make-local-variable 'adaptive-fill-mode)
  (setq adaptive-fill-mode nil)

  (make-local-variable 'normal-auto-fill-function)
  (setq normal-auto-fill-function 'lisp-mode-auto-fill)

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'picolisp-indent-line)

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)

  (make-local-variable 'comment-start)
  (setq comment-start "#")

  (set (make-local-variable 'comment-add) 1)
  (make-local-variable 'comment-start-skip)
  ;; Look within the line for a # following an even number of backslashes
  ;; after either a non-backslash or the line beginning.
  (setq comment-start-skip "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\)#+[ \t]*");  ((^|[^\n])(\\\\)*)#+[ t]*
  (set (make-local-variable 'font-lock-comment-start-skip) "#+ *")

  (make-local-variable 'comment-column)
  (setq comment-column 40)

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)

  (make-local-variable 'lisp-indent-function)
  (setq lisp-indent-function 'picolisp-indent-function)

  ;; This is just to avoid tabsize-variations fuck-up.
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode nil)

  (setq dabbrev-case-fold-search t)
  (setq dabbrev-case-replace nil)

  (setq mode-line-process '("" picolisp-mode-line-process))
  (set (make-local-variable 'font-lock-defaults)
       '((picolisp-font-lock-keywords
          picolisp-font-lock-keywords-1
          picolisp-font-lock-keywords-2 )
         nil t (("+-*/.<>=!?$%_&~^:" . "w"))
         beginning-of-defun
         (font-lock-mark-block-function . mark-defun)
         (font-lock-keywords-case-fold-search . nil)
         (parse-sexp-lookup-properties . t)
         (font-lock-extra-managed-props syntax-table) ) )
  (set (make-local-variable 'lisp-doc-string-elt-property)
       'picolisp-doc-string-elt ) )

(defvar picolisp-mode-line-process "")

(defvar picolisp-mode-map
  (let ((map (make-sparse-keymap "Picolisp")))
    (set-keymap-parent map lisp-mode-shared-map)

    ;; more convenient than "C-ck"
    (define-key map "\C-c\C-v" 'picolisp-edit-K)
    ;; more convenient than "C-cq"
    (define-key map "\C-c\C-c" 'picolisp-edit-Q) 
    ;; not necesary: picolisp-edit-Q exits on last undo
    ;; (define-key map "\C-q" '(save-buffers-kill-terminal 1))

    (define-key map [menu-bar picolisp] (cons "Picolisp" map))
    (define-key map [run-picolisp] '("Run Inferior Picolisp" . run-picolisp))
    (define-key map [uncomment-region]
      '("Uncomment Out Region" . (lambda (beg end)
                                   (interactive "r")
                                   (comment-region beg end '(4)) ) ) )
    (define-key map [comment-region] '("Comment Out Region" . comment-region))
    (define-key map [indent-region] '("Indent Region" . indent-region))
    (define-key map [indent-line] '("Indent Line" . picolisp-indent-line))
    (define-key map "\t" 'picolisp-indent-line)
    (put 'comment-region 'menu-enable 'mark-active)
    (put 'uncomment-region 'menu-enable 'mark-active)
    (put 'indent-region 'menu-enable 'mark-active)
    map )
  "Keymap for Picolisp mode.
All commands in `lisp-mode-shared-map' are inherited by this map." )


;;;###autoload
(define-derived-mode picolisp-mode prog-mode "PicoLisp"
  "Major mode for editing Picolisp code.
Editing commands are similar to those of `lisp-mode'.

Commands:
Delete converts tabs to spaces as it moves back.
Blank lines separate paragraphs.  Semicolons start comments.
\\{picolisp-mode-map}
Entry to this mode calls the value of `picolisp-mode-hook'
if that value is non-nil."
  (remove-text-properties (point-min) (point-max) '(display ""))
  (picolisp-mode-variables)
  (defun paredit-delete-leading-whitespace ()
    (picolisp-delete-leading-whitespace) ) )

(autoload 'run-picolisp "inferior-picolisp"
  "Run an inferior Picolisp process, input and output via buffer `*picolisp*'.
If there is a process already running in `*picolisp*', switch to that buffer.
With argument, allows you to edit the command line (default is value
of `picolisp-program-name').
Runs the hook `inferior-picolisp-mode-hook' \(after the `comint-mode-hook'
is run).
\(Type \\[describe-mode] in the process buffer for a list of commands.)"
  t )

(defgroup picolisp nil
  "Editing Picolisp code."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'lisp )

(defcustom picolisp-mode-hook nil
  "Normal hook run when entering `picolisp-mode'.
See `run-hooks'."
  :type 'hook
  :group 'picolisp )


(defconst picolisp-font-lock-keywords-1
  (eval-when-compile
    (list
     ;;
     ;; Declarations.
     (list 
      (concat "(" (regexp-opt '("be" "de" "dm") t) "\\>"
              ;; Any whitespace and declared object.
              "[ \t]*"
              "\\(\\sw+\\)?" )
      '(2 font-lock-function-name-face
          nil t ) )
     (list (concat "\\<"
                   (regexp-opt '("NIL" "T") t)  
                   "\\>" )
           '(1 font-lock-constant-face) )
     (list
      (concat "\\<"
              (regexp-opt '("*OS" "*DB" "*Solo" "*PPid" "*Pid" "@" "@@" "@@@"
                            "This" "*Dbg" "*Zap" "*Scl" "*Class" "*Dbs" "*Run"
                            "*Hup" "*Sig1" "*Sig2" "^" "*Err" "*Msg" "*Uni" 
                            "*Led" "*Adr" "*Allow" "*Fork" "*Bye" ) t )
              "\\>" )
      '(1 font-lock-builtin-face) )
     ;; This is so we make the point used in conses more visible
     '("\\<\\(\\.\\)\\>" (1 font-lock-negation-char-face))
     '("(\\(====\\)\\>" (1 font-lock-negation-char-face)) 
     (list ;; Functions that modify @
      (concat "("
              (regexp-opt '("prog1" "prog2"
                            "cond" "case"
                            "if" "if2" "ifn"
                            "when" "unless"
                            "and" "or" "nor" "not"
                            "nand" "nond"
                            "loop" "do" "while" "until" "for"
                            "state" ) t )
              "\\>" )
      '(1 font-lock-preprocessor-face) ) ) )
  "Subdued expressions to highlight in Picolisp modes." )


(defconst picolisp-font-lock-keywords-2
  (append picolisp-font-lock-keywords-1
          (eval-when-compile
            (list
             ;; Control structures.
             (cons
              (concat
               "(" (regexp-opt
                    '( ;; Symbol Functions
                      "new" "sym" "str" "char" "name" "sp?" "pat?" "fun?" "all" 
                      "intern" "extern" "qsym" "loc" "box?" "str?" "ext?" 
                      "touch" "zap" "length" "size" "format" "chop" "pack" 
                      "glue" "pad" "align" "center" "text" "wrap" "pre?" "sub?" 
                      "low?" "upp?" "lowc" "uppc" "fold" "val" "getd" "set" 
                      "setq" "def" "de" "dm" "recur" "undef" "redef" "daemon" 
                      "patch" "xchg" "on" "off" "onOff" "zero" "one" "default" 
                      "expr" "subr" "let" "let?" "use" "accu" "push" "push1" 
                      "pop" "cut" "del" "queue" "fifo" "idx" "lup" "cache" 
                      "locale" "dirname"
                      ;; Property Access
                      "put" "get" "prop" ";" "=:" ":" "::" "putl" "getl" "wipe" ;
                      "meta"
                      ;; Predicates
                      "atom" "pair" "lst?" "num?" "sym?" "flg?" "sp?" "pat?" 
                      "fun?" "box?" "str?" "ext?" "bool" "not" "==" "n==" "=" 
                      "<>" "=0" "=T" "n0" "nT" "<" "<=" ">" ">=" "match"
                      ;; Arithmetics
                      "+" "-" "*" "/" "%" "*/" "**" "inc" "dec" ">>" "lt0" 
                      "ge0" "gt0" "abs" "bit?" "&" "|" "x|" "sqrt" "seed" 
                      "rand" "max" "min" "length" "size" "accu" "format" "pad" 
                      "oct" "hex" "fmt64" "money"
                      ;; List Processing
                      "car" "cdr" "caar" "cadr" "cdar" "cddr" "caaar" "caadr" 
                      "cadar" "caddr" "cdaar" "cdadr" "cddar" "cdddr" "cadddr" 
                      "cddddr" "nth" "con" "cons" "conc" "circ" "rot" "list" 
                      "need" "full" "make" "made" "chain" "link" "yoke" "copy" 
                      "mix" "append" "delete" "delq" "replace" "insert" 
                      "remove" "place" "strip" "split" "reverse" "flip" "trim" 
                      "clip" "head" "tail" "stem" "fin" "last" "member" "memq" 
                      "mmeq" "sect" "diff" "index" "offset" "assoc" "asoq" 
                      "rank" "sort" "uniq" "group" "length" "size" "val" "set" 
                      "xchg" "push" "push1" "pop" "cut" "queue" "fifo" "idx" 
                      "balance" "get" "fill" "apply" "range"
                      ;; Control Flow
                      "load" "args" "next" "arg" "rest" "pass" "quote" "as" 
                      "pid" "lit" "eval" "run" "macro" "curry" "def" "de" "dm" 
                      "recur" "recurse" "undef" "box" "new" "type" "isa" 
                      "method" "meth" "send" "try" "super" "extra" "with" 
                      "bind" "job" "let" "let?" "use" "xor" "bool" "nil" "t"
                      "prog" "at" "catch" "throw" "finally" "!" "e" "$" "sys"
                      "call" "tick" "ipid" "opid" "kill" "quit" "task" "fork"
                      "pipe" "later" "timeout" "abort" "bye"
                      ;; Mapping
                      "apply" "pass" "maps" "map" "mapc" "maplist" "mapcar" 
                      "mapcon" "mapcan" "filter" "extract" "seek" "find" "pick" 
                      "cnt" "sum" "maxi" "mini" "fish" "by" 
                      ;; Input/Output
                      "path" "in" "ipid" "out" "opid" "pipe" "ctl" "any" "sym" 
                      "str" "load" "hear" "tell" "key" "poll" "peek" "char" 
                      "skip" "eol" "eof" "from" "till" "line" "format" "scl" 
                      "read" "print" "println" "printsp" "prin" "prinl" "msg" 
                      "space" "beep" "tab" "flush" "rewind" "rd" "pr" "wr" 
                      "rpc" "wait" "sync" "echo" "info" "file" "dir" "lines" 
                      "open" "close" "port" "listen" "accept" "host" "connect" 
                      "nagle" "udp" "script" "once" "rc" "pretty" "pp" "show" 
                      "view" "here" "prEval" "mail"
                      ;; Object Orientation
                      "*Class" "class" "dm" "rel" "var" "var:" "new" "type" 
                      "isa" "method" "meth" "send" "try" "object" "extend" 
                      "super" "extra" "with" "This" 
                      ;; Database
                      "pool" "journal" "id" "seq" "lieu" "lock" "begin" 
                      "commit" "rollback" "mark" "free" "dbck" "rel" "dbs" 
                      "dbs+" "db:" "fmt64" "tree" "root" "fetch" "store" 
                      "count" "leaf" "minKey" "maxKey" "genKey" "useKey" "init" 
                      "step" "scan" "iter" "prune" "zapTree" "chkTree" "db" 
                      "aux" "collect" 
                      ;; Pilog
                      "goal" "prove" "->" "unify" "?" 
                      ;; Debugging
                      "pretty" "pp" "show" "loc" "debug" "vi" "ld" "trace" 
                      "lint" "lintAll" "fmt64"
                      ;; System Functions
                      "cmd" "argv" "opt" "gc" "raw" "alarm" "protect" "heap" 
                      "env" "up" "date" "time" "usec" "stamp" "dat$" "$dat" 
                      "datSym" "datStr" "strDat" "expDat" "day" "week" "ultimo" 
                      "tim$" "$tim" "telStr" "expTel" "locale" "allowed" 
                      "allow" "pwd" "cd" "chdir" "ctty" "info" "dir" "dirname" 
                      "call" "tick" "kill" "quit" "task" "fork" "pipe" 
                      "timeout" "mail" "test" "bye" ) t )
               "\\>" ) 1 ) ) ) )
  "Gaudy expressions to highlight in Picolisp modes." )

(defvar picolisp-font-lock-keywords picolisp-font-lock-keywords-1
  "Default expressions to highlight in Picolisp modes." )

(defconst picolisp-sexp-comment-syntax-table
  (let ((st (make-syntax-table picolisp-mode-syntax-table)))
    (modify-syntax-entry ?\n " " st)
    (modify-syntax-entry ?#  "." st)
    st ) )

(put 'lambda 'picolisp-doc-string-elt 2)
;; Docstring's pos in a `define' depends on whether it's a var or fun def.
(put 'define 'picolisp-doc-string-elt
     (lambda ()
       ;; The function is called with point right after "define".
       (forward-comment (point-max))
       (if (eq (char-after) ?\() 2 0) ) )


;; Indentation functions

;; Copied from lisp-indent-line,
;; because Picolisp doesn't care about how many comment chars you use.
(defun picolisp-indent-line (&optional whole-exp)
  "Indent current line as Picolisp code.
With argument, indent any additional lines of the same expression
rigidly along with this one."
  (interactive "P")
  (let ((indent (calculate-lisp-indent)) shift-amt end
        (pos (- (point-max) (point)))
        (beg (progn (beginning-of-line) (point))) )
    (skip-chars-forward " \t")
    (if (or (null indent) (looking-at "\\s<\\s<\\s<"))
        ;; Don't alter indentation of a ;;; comment line
        ;; or a line that starts in a string.
        (goto-char (- (point-max) pos))
      (if (listp indent) (setq indent (car indent)))
      (setq shift-amt (- indent (current-column)))
      (if (zerop shift-amt)
          nil
        (delete-region beg (point))
        (indent-to indent) ) )
    ;; If initial point was within line's indentation,
    ;; position after the indentation.  Else stay at same point in text.
    (if (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos)) )
    ;; If desired, shift remaining lines of expression the same amount.
    (and whole-exp (not (zerop shift-amt))
         (save-excursion
           (goto-char beg)
           (forward-sexp 1)
           (setq end (point))
           (goto-char beg)
           (forward-line 1)
           (setq beg (point))
           (> end beg) )
         (indent-code-rigidly beg end shift-amt) ) ) )

(defvar calculate-lisp-indent-last-sexp)

;; Copied from lisp-indent-function, but with gets of
;; picolisp-indent-{function,hook}, and minor modifications.
(defun picolisp-indent-function (indent-point state)
  (picolisp-parensep)
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (if (and (elt state 2)
             (not (looking-at "\"?\\sw\\|\\s_")) )
        ;; car of form doesn't seem to be a symbol
        (progn
          (if (not (> (save-excursion (forward-line 1) (point))
                      calculate-lisp-indent-last-sexp ) )
              (progn (goto-char calculate-lisp-indent-last-sexp)
                     (beginning-of-line)
                     (parse-partial-sexp (point)
                                         calculate-lisp-indent-last-sexp 0 t ) ) )
          ;; Indent under the list or under the first sexp on the same
          ;; line as calculate-lisp-indent-last-sexp.  Note that first
          ;; thing on that line has to be complete sexp since we are
          ;; inside the innermost containing sexp.
          (backward-prefix-chars)
          (current-column) )
      (let* ((function (buffer-substring (point)
                                         (progn (forward-sexp 1) (point)) ) )
             (method (or (get (intern-soft function) 'picolisp-indent-function)
                         (get (intern-soft function) 'picolisp-indent-hook)
                         ;;(and picolisp-indent-style 'picolisp-indent-defform)
                         'picolisp-indent ) ) )
        (if (integerp method)
            (lisp-indent-specform method state indent-point normal-indent)
          (funcall (if (save-excursion
                         (let ((state9 (reverse (elt state 9))))
                           (when (cadr state9)
                             (goto-char (+ 1 (cadr (reverse (elt state 9)))))
                             (and (looking-at "let\\|use")
                                 (save-excursion
                                   (forward-sexp)
                                   (forward-sexp)
                                   (backward-sexp)
                                   (when (equal (point)  (car state9))
                                     (looking-at "(") ) ) ) ) ) )
                       'picolisp-indent-let
                     method )
                   state indent-point normal-indent ) ) ) ) ) )


;;; Some functions are different in picoLisp
(defun picolisp-indent (state indent-point normal-indent)
  (let ((lisp-body-indent picolisp-body-indent))
    (lisp-indent-defform state indent-point) ) )

(defun picolisp-indent-let (state indent-point normal-indent)
  (goto-char (cadr state))
  (forward-line 1)
  (if (> (point) (elt state 2))
      (progn
	(goto-char (car (cdr state)))
	(+ 1 (current-column)) ) ) )


;;; This is to space closing parens when they close a previous line.
(defun picolisp-parensep ()
  (save-excursion
    (condition-case nil     ; This is to avoid fuck-ups when there are
        (progn              ; unbalanced expressions.
          (up-list)
          (back-to-indentation)     
          (while (and (re-search-forward ")" (line-end-position) t)
                      (< (point) (line-end-position)) )
            (if (and (not (picolisp-in-comment-p))
                     (not (picolisp-in-string-p)) )
                (picolisp-delete-leading-whitespace) ) )        
          (if (and (not (picolisp-in-comment-p))
                   (not (picolisp-in-string-p)) )
              (picolisp-delete-leading-whitespace) ) )
      (error nil) ) ) )

(defun picolisp-delete-leading-whitespace ()
  ;; This assumes that we're on the closing delimiter already.
  (save-excursion
    (backward-char)
    (while (let ((syn (char-syntax (char-before))))
             (and (or (eq syn ?\ ) (eq syn ?-)) ; whitespace syntax
                  ;; The above line is a perfect example of why the
                  ;; following test is necessary.
                  (not (picolisp-in-char-p (1- (point)))) ) )
      (backward-delete-char 1) ) )
  (when (and (equal 'picolisp-mode major-mode) ; We don't want to screw-up
                                        ; the formatting of other buffers making
                                        ; use of paredit, do we?
             (not (picolisp-in-string-p)) )
    (let ((another-line? (save-excursion
                           (backward-sexp)
                           (line-number-at-pos) ) ) )
      (if (< another-line? (line-number-at-pos))
          (save-excursion
            (backward-char)
            (when picolisp-parsep
              (insert " ") ) ) ) ) ) )


;; Parser functions
  
(defun picolisp-current-parse-state ()
  "Return parse state of point from beginning of defun."
  (let ((point (point)))
    (beginning-of-defun)
    ;; Calling PARSE-PARTIAL-SEXP will advance the point to its second
    ;; argument (unless parsing stops due to an error, but we assume it
    ;; won't in picolisp-mode).
    (parse-partial-sexp (point) point) ) )  

(defun picolisp-in-string-p (&optional state)
  "True if the parse state is within a double-quote-delimited string.
If no parse state is supplied, compute one from the beginning of the
  defun to the point."
  ;; 3. non-nil if inside a string (the terminator character, really)
  (and (nth 3 (or state (picolisp-current-parse-state)))
       t ) )  
(defun picolisp-in-comment-p (&optional state)
  "True if parse state STATE is within a comment.
If no parse state is supplied, compute one from the beginning of the
  defun to the point."
  ;; 4. nil if outside a comment, t if inside a non-nestable comment,
  ;;    else an integer (the current comment nesting)
  (and (nth 4 (or state (picolisp-current-parse-state)))
       t ) )  

(defun picolisp-in-char-p (&optional argument)
  "True if the point is immediately after a character literal.
A preceding escape character, not preceded by another escape character,
  is considered a character literal prefix.  (This works for elisp,
  Common Lisp, and Scheme.)
Assumes that `picolisp-in-string-p' is false, so that it need not handle
  long sequences of preceding backslashes in string escapes.  (This
  assumes some other leading character token -- ? in elisp, # in Scheme
  and Common Lisp.)"
  (let ((argument (or argument (point))))
    (and (eq (char-before argument) ?\\)
         (not (eq (char-before (1- argument)) ?\\)) ) ) ) 

(add-to-list 'auto-mode-alist '("\\.l$" . picolisp-mode))


;; The following two functions implement the K and Q (macro)
;; functionality used in Vi while editing a buffer opened from the
;; PicoLisp command-line with the 'edit' function.

(defun picolisp-edit-K ()
  "Write symbol at point with line number in last line of edit-buffer.

If the symbol is a transient symbol, write it with double-quotes,
otherwise as unquoted word. The output-format is: 

\(<line-number> <symbol>\)
 e.g.
\(50  edit\)
\(56 \"edit\"\)

when point is on the edit or \(transient\) \"edit\" symbol in the
PicoLisp sourcefile edit.l and `picolisp-edit-K' is called (the
line-numbers may be different in your version of edit.l).

Recognition of transient symbols works by getting the
text-property 'face' at point and checking if it is equal to
'font-lock-string-face'. Thus, this function works correctly only
if the edit-buffer is in an Emacs major-mode that fontifies
strings with 'font-lock-string-face' \(like `picolisp-mode'
does\)."

  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (unless (mark 'FORCE)
        (forward-word)
        (forward-word -1)
        (mark-word))
      (let* ((thing (thing-at-point 'word))  
             (unit (get-selection-or-unit 'word))
             (line (line-number-at-pos))
             (transient-p
              (string-equal (get-text-property (point) 'face)
                            "font-lock-string-face"))
             (k-list nil))
        (setq k-list (list line
                           (if transient-p
                               (elt unit 0)
                             (make-symbol (elt unit 0)))))
        (message "K-list: %S transient: %S" k-list transient-p)
        (goto-char (max-char))
        (newline)
        (insert (format "%S" k-list))
        (save-buffers-kill-terminal 1)))))


(defun picolisp-edit-Q ()
  "Write '(0)' in last line of PicoLisp edit-buffer."
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (max-char))
      (newline)
      (insert "(0)")
      (save-buffers-kill-terminal 1))))


;; The following two functions have been written by Xah Lee and copied
;; from: http://ergoemacs.org/emacs/elisp_get-selection-or-unit.html

(defun get-selection-or-unit (unit)
  "Return the string and boundary of text selection or UNIT under cursor.

If `region-active-p' is true, then the region is the unit.  Else,
it depends on the UNIT. See `unit-at-cursor' for detail about
UNIT.

Returns a vector [text a b], where text is the string and a and b
are its boundary.

Example usage:
 (setq bds (get-selection-or-unit 'line))
 (setq inputstr (elt bds 0) p1 (elt bds 1) p2 (elt bds 2)  )"
  (interactive)

  (let ((p1 (region-beginning)) (p2 (region-end)))
    (if (region-active-p)
        (vector (buffer-substring-no-properties p1 p2) p1 p2 )
      (unit-at-cursor unit) ) ) )

;; This function get-selection-or-unit gets you the text selection if
;; there's one. If not, it calls unit-at-cursor. unit-at-cursor

(defun unit-at-cursor (unit)
  "Return the string and boundary of UNIT under cursor.

Returns a vector [text a b], where text is the string and a and b are its boundary.

UNIT can be:
• 'word — sequence of 0 to 9, A to Z, a to z, and hyphen.
• 'glyphs — sequence of visible glyphs. Useful for file name, URL, …, that doesn't have spaces in it.
• 'line — delimited by “\\n”.
• 'block — delimited by “\\n\\n” or beginning/end of buffer.
• 'buffer — whole buffer. (respects `narrow-to-region')
• a vector [beginRegex endRegex] — The elements are regex strings used to determine the beginning/end of boundary chars. They are passed to `skip-chars-backward' and `skip-chars-forward'. For example, if you want paren as delimiter, use [\"^(\" \"^)\"]

Example usage:
    (setq bds (unit-at-cursor 'line))
    (setq myText (elt bds 0) p1 (elt bds 1) p2 (elt bds 2)  )

This function is similar to `thing-at-point' and `bounds-of-thing-at-point'.
The main differences are:
• this function returns the text and the 2 boundaries as a vector in one shot.
• 'line always returns the line without end of line character, avoiding inconsistency when the line is at end of buffer.
• 'word does not depend on syntax table.
• 'block does not depend on syntax table."
  (let (p1 p2)
    (save-excursion
      (cond
       ( (eq unit 'word)
         (let ((wordcharset "-A-Za-zÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"))
           (skip-chars-backward wordcharset)
           (setq p1 (point))
           (skip-chars-forward wordcharset)
           (setq p2 (point)))
         )

       ( (eq unit 'glyphs)
         (progn
           (skip-chars-backward "[:graph:]")
           (setq p1 (point))
           (skip-chars-forward "[:graph:]")
           (setq p2 (point)))
         )

       ( (eq unit 'buffer)
         (progn
           (setq p1 (point-min))
           (setq p2 (point-max))
           )
         )

       ((eq unit 'line)
        (progn
          (setq p1 (line-beginning-position))
          (setq p2 (line-end-position))))
       ((eq unit 'block)
        (progn
          (if (re-search-backward "\n\n" nil t)
              (progn (forward-char 2)
                     (setq p1 (point) ) )
            (setq p1 (line-beginning-position) )
            )

          (if (re-search-forward "\n\n" nil t)
              (progn (backward-char)
                     (setq p2 (point) ))
            (setq p2 (line-end-position) ) ) ))

       ((vectorp unit)
        (let (p0)
          (setq p0 (point))
          (skip-chars-backward (elt unit 0))
          (setq p1 (point))
          (goto-char p0)
          (skip-chars-forward (elt unit 1))
          (setq p2 (point))))
       ) )

    (vector (buffer-substring-no-properties p1 p2) p1 p2 )
    ) )


;; tsm-mode
(when (and (require 'tsm nil t) tsm-lock)
  (font-lock-add-keywords 'picolisp-mode tsm-lock)
  (font-lock-add-keywords 'inferior-picolisp-mode tsm-lock) )

(provide 'picolisp)
