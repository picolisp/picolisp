;;;;;; tsm-mode: Minor mode to display transient symbols in picolisp-mode.
;;;;;; Version: 1.0

;;; Copyright (c) 2009, Guillermo R. Palavecino

;; This file is NOT part of GNU emacs.

;;;; Contact:
;; For comments, bug reports, questions, etc, you can contact me via IRC
;; to the user named grpala (or armadillo) on irc.freenode.net in the
;; #picolisp channel or via email to the author's nickname at gmail.com
;;
;;;; License:
;; This work is released under the GPL 2 or (at your option) any later
;; version.

(defvar tsm-face 'tsm-face)

(defface tsm-face
  '((((class color))
     (:inherit font-lock-string-face :underline t) ) )
  "Face for displaying transient symbols in picolisp-mode"
  :group 'faces )

(defun tsm-revert (beg end)
  (remove-text-properties beg end '(display ""))
  (remove-text-properties beg end '(face tsm-face)) )

(defvar tsm-regex "\"")

;;; Sorry, but the following 3 function definitions are write-only for now.

(defun find-opening-dblquote ()
  (catch 'return
    (while (re-search-forward "\\(\"\\)" (line-end-position) t)
      (when (save-excursion
              (and (ignore-errors (match-beginning 1))
                   (not (progn
                          (goto-char (match-beginning 1))
                          (picolisp-in-string-p) ) )
                   (progn
                     (forward-char)
                     (picolisp-in-string-p) ) ) )
        (throw 'return (point)) ) )
    (backward-char) ) )

(defun find-closing-dblquote ()
  (catch 'return
    (while (re-search-forward "\\(\"\\)" (line-end-position) t)
      (when (save-excursion
              (and (ignore-errors (match-beginning 1))
                   (progn
                     (goto-char (match-beginning 1))
                     (picolisp-in-string-p) ) 
                   (not (progn
                          (forward-char)
                          (picolisp-in-string-p) ) ) ) )
        (throw 'return (point)) ) ) ) )

(defun tsm-line ()
  (while (and (find-opening-dblquote)
              (save-excursion (find-closing-dblquote)) )
    (let ((opening (point))
          (closing (find-closing-dblquote)) )
      (add-text-properties (1- opening) opening '(display ""))
      (add-text-properties (1- closing) closing '(display ""))
      (add-text-properties (1- opening) closing '(face tsm-face))
      (dotimes (i (- closing opening 1))
        (let ((i (+ i opening)))
          (when (and (eq 92 (char-before i))
                     (eq 34 (char-before (1+ i))) )
            (add-text-properties (1- i) i '(display "")) ) ) ) ) ) )

(defun tsm-change (beg end)
  (save-excursion
    (goto-char beg)
    (while (re-search-forward "^.*\"" (save-excursion
                                        (goto-char end)
                                        (line-end-position) ) t )
      (beginning-of-line)
      (tsm-revert (line-beginning-position) (line-end-position))
      (tsm-line) ) ) )

(defvar tsm-lock
  '(("\""
     (0 (when tsm-mode
          (setq global-disable-point-adjustment t) 
          (save-excursion
            (beginning-of-line)
            (remove-text-properties (line-beginning-position) (line-end-position) '(display ""))
            (tsm-line) )
          nil ) ) ) ) )


;;;###autoload
(define-minor-mode tsm-mode
  "Minor mode to display transient symbols like in the terminal repl in picolisp-mode."
  :group 'tsm :lighter " *Tsm"
  (save-excursion
    (save-restriction
      (widen)
      ;; We erase all the properties to avoid problems.
      (tsm-revert (point-min) (point-max))

      (if tsm-mode
          (progn 
            (if (not (and (not font-lock-mode) (not global-font-lock-mode)))
                (font-lock-add-keywords major-mode tsm-lock)
              (jit-lock-register 'tsm-change)
              (remove-hook 'after-change-functions
                           'font-lock-after-change-function t )
              (set (make-local-variable 'font-lock-fontified) t)

              ;; Tell jit-lock how we extend the region to refontify.
              (add-hook 'jit-lock-after-change-extend-region-functions
                        'font-lock-extend-jit-lock-region-after-change
                        nil t ) )
            
            (setq global-disable-point-adjustment t) )
        (progn 
          (if (and (not font-lock-mode) (not global-font-lock-mode))
              (jit-lock-unregister 'tsm-change)
            (font-lock-remove-keywords major-mode tsm-lock) )
          (setq global-disable-point-adjustment nil) ) )

      (if font-lock-mode (font-lock-fontify-buffer)) ) ) )

;;; Announce

(provide 'tsm)
