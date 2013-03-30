;;; picolisp-wiki-mode.el --- Emacs Major mode for PicoLisp-Wiki formatted text files

;; Copyright (C) 2012-13 Thorsten Jolitz <tjolitz@gmail.com>

;; Author: Thorsten Jolitz <tjolitz@gmail.com>
;; Maintainer: Thorsten Jolitz <tjolitz@gmail.com>
;; Created: September 01, 2012
;; Version: 1.0
;; Keywords: PicoLisp, wiki
;; URL: http://picolisp.com/5000/!wiki?home

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; picolisp-wiki-mode is a major mode for editing text files for
;; PicoLisp-Wiki in GNU Emacs. picolisp-wiki-mode is free software,
;; licensed under the GNU GPL.

;;; Dependencies:

;; picolisp-wiki-mode requires easymenu, a standard package since GNU Emacs
;; 19 and XEmacs 19, which provides a uniform interface for creating
;; menus in GNU Emacs and XEmacs.

;;; Installation:

;; Make sure to place `picolisp-wiki-mode.el` somewhere in the
;; load-path and add the following lines to your `.emacs` file to
;; associate picolisp-wiki-mode with `.text` files:

    (autoload 'picolisp-wiki-mode "picolisp-wiki-mode"
       "Major mode for editing Picolisp-Wiki files" t)
    (setq auto-mode-alist
       ;; (cons '("\\.text" . picolisp-wiki-mode) auto-mode-alist))
       (cons '("\\.plw" . picolisp-wiki-mode) auto-mode-alist))

;; There is no consensus on an official file extension so change `.text` to
;; `.plw`, `.lw`, `.lwik`, or whatever you call your picolisp-wiki files.

;;; Customization:

;; Although no configuration is *necessary* there are a few things
;; that can be customized.  The `M-x customize-mode` command
;; provides an interface to all of the possible customizations.

;; Usage:

;; Keybindings for inserting are grouped by prefixes based on their
;; function. For example, commands inserting links and lists begin
;; with `C-c C-l`, those inserting floating content with `C-c C-f`,
;; all other inserting commands with `C-c C-c`. The commands in each
;; group are described below. You can obtain a list of all keybindings
;; by pressing `C-c C-h`.

;;     ;; Element insertion
;;     "\C-c\C-l n" Insert Internal Link
;;     "\C-c\C-l x" Insert External Link
;;     "\C-c\C-l u" Insert Unordered List
;;     "\C-c\C-l o" Insert Ordered List
;;     "\C-c\C-l i" Insert List Item
;;     "\C-c\C-f l" Insert Left-Floating-Content
;;     "\C-c\C-f n" Insert Non-Floating Content
;;     "\C-c\C-f r" Insert Right-Floating-Content
;;     "\C-c\C-c k" Insert Line Breaks
;;     "\C-c\C-c 1" Insert Header 1
;;     "\C-c\C-c 2" Insert Header 2
;;     "\C-c\C-c 3" Insert Header 3
;;     "\C-c\C-c 4" Insert Header 4
;;     "\C-c\C-c 5" Insert Header 5
;;     "\C-c\C-c 6" Insert Header 6
;;     "\C-c\C-c b" Insert Bold
;;     "\C-c\C-c i" Insert Italic
;;     "\C-c\C-c u" Insert Underlined
;;     "\C-c\C-c p" Insert Pre Block
;;     "\C-c\C-c c" Insert Comment
;;     "\C-c\C-c -" Insert Horizontal Rule (hr)
;;     ;; Visibility cycling
;;     "<tab>" Picolisp Wiki Cycle
;;     "<S-iso-lefttab>" Picolisp Wiki Shifttab
;;     ;; Header navigation
;;     "C-M-n" Outline Next Visible Heading
;;     "C-M-p" Outline Previous Visible Heading
;;     "C-M-f" Outline Forward Same Level
;;     "C-M-b" Outline Backward Same Level
;;     "C-M-u" Outline Up Heading

;; Many of the commands described above behave differently depending on
;; whether Transient Mark mode is enabled or not.  When it makes sense,
;; if Transient Mark mode is on and a region is active, the command
;; applies to the text in the region (e.g., `C-c C-c b` makes the region
;; bold).  For users who prefer to work outside of Transient Mark mode,
;; in Emacs 22 it can be enabled temporarily by pressing `C-SPC C-SPC`.
;;
;; picolisp-wiki-mode supports outline-minor-mode as well as
;; org-mode-style visibility cycling for PicoLisp-Wikli-style headers.
;; There are two types of visibility cycling: Pressing `S-TAB` cycles
;; globally between the table of contents view (headers only), outline
;; view (top-level headers only), and the full document view. Pressing
;; `TAB` while the point is at a header will cycle through levels of
;; visibility for the subtree: completely folded, visible children,
;; and fully visible. 

;;   * Outline Navigation:
;;
;;     Navigation between headings is possible using `outline-mode'.
;;     Use `C-M-n` and `C-M-p` to move between the next and previous
;;     visible headings.  Similarly, `C-M-f` and `C-M-b` move to the
;;     next and previous visible headings at the same level as the one
;;     at the point.  Finally, `C-M-u` will move up to a lower-level
;;     (more inclusive) visible heading.
;;
;; FIXME: different headers levels are not yet recognized by the outine
;; commands.


;;; Acknowledgments:

;; picolisp-wiki-mode is based on markdown.el (available from ELPA).
;; It has benefited greatly from the efforts of the following people:
;;
;;   * Thorsten Jolitz <tjolitz [AT] gmail [DOT] com>
;;   * Doug Lewan <dougl [@] shubertticketing [DOT] com>
;;; Bugs:

;; picolisp-wiki-mode is developed and tested primarily using GNU
;; Emacs 24, compatibility with earlier Emacsen is no priority. For
;; bugs and todo's, see the HISTORY.org file in the github-repo
;; (https://github.com/tj64/picolisp-wiki-mode).
;;
;; If you find any bugs in picolisp-wiki-mode, please construct a test case
;; or a patch and email me at <tjolitz@gmail.com>.

;;; History:

;; picolisp-wiki-mode was written and is maintained by Thorsten
;; Joltiz. The first version (0.9) was released on Sept 01, 2012. For
;; further information see the HISTORY.org file in the github-repo
;; (https://github.com/tj64/picolisp-wiki-mode).


;;; Code:

(require 'easymenu)
(require 'outline)
(require 'cl)

;;; Constants =================================================================

(defconst picolisp-wiki-mode-version "1.0"
  "Picolisp-Wiki mode version number.")

;;; Customizable variables ====================================================

(defvar picolisp-wiki-mode-hook nil
  "Hook runs when Picolisp-Wiki mode is loaded.")

(defgroup picolisp-wiki nil
  "Major mode for editing text files in Picolisp-Wiki format."
  :prefix "picolisp-wiki-"
  :group 'wp
  :link '(url-link "http://picolisp.com/5000/!wiki?homef"))


(defcustom picolisp-wiki-hr-string "------------------------------------"
  "String to use for horizonal rules."
  :group 'picolisp-wiki
  :type 'string)

(defcustom picolisp-wiki-uri-types
  '("acap" "cid" "data" "dav" "fax" "file" "ftp" "gopher" "http" "https"
    "imap" "ldap" "mailto" "mid" "modem" "news" "nfs" "nntp" "pop" "prospero"
    "rtsp" "service" "sip" "tel" "telnet" "tip" "urn" "vemmi" "wais")
  "Link types for syntax highlighting of URIs."
  :group 'picolisp-wiki
  :type 'list)


(defcustom picolisp-wiki-link-space-sub-char
  "_"
  "Character to use instead of spaces when mapping wiki links to filenames."
  :group 'picolisp-wiki
  :type 'string)


;;; Font lock =================================================================

(require 'font-lock)

(defvar picolisp-wiki-starting-brace-face
  'picolisp-wiki-starting-brace-face
  "Face name to use for starting braces.")

(defvar picolisp-wiki-closing-brace-face
  'picolisp-wiki-closing-brace-face
  "Face name to use for closing braces.")

(defvar picolisp-wiki-line-break-face 'picolisp-wiki-line-break-face
  "Face name to use for line breaks.")

(defvar picolisp-wiki-italic-face 'picolisp-wiki-italic-face
  "Face name to use for italic text.")

(defvar picolisp-wiki-bold-face 'picolisp-wiki-bold-face
  "Face name to use for bold text.")

(defvar picolisp-wiki-underlined-face 'picolisp-wiki-underlined-face
  "Face name to use for underlined text.")

(defvar picolisp-wiki-header-face 'picolisp-wiki-header-face
  "Face name to use as a base for headers.")

(defvar picolisp-wiki-header-face-1 'picolisp-wiki-header-face-1
  "Face name to use for level-1 headers.")

(defvar picolisp-wiki-header-face-2 'picolisp-wiki-header-face-2
  "Face name to use for level-2 headers.")

(defvar picolisp-wiki-header-face-3 'picolisp-wiki-header-face-3
  "Face name to use for level-3 headers.")

(defvar picolisp-wiki-header-face-4 'picolisp-wiki-header-face-4
  "Face name to use for level-4 headers.")

(defvar picolisp-wiki-header-face-5 'picolisp-wiki-header-face-5
  "Face name to use for level-5 headers.")

(defvar picolisp-wiki-header-face-6 'picolisp-wiki-header-face-6
  "Face name to use for level-6 headers.")

(defvar picolisp-wiki-list-item-face 'picolisp-wiki-list-item-face
  "Face name to use for list markers.")

(defvar picolisp-wiki-left-floating-content-face
  'picolisp-wiki-left-floating-content-face
  "Face name to use for left floating content.")

(defvar picolisp-wiki-non-floating-content-face
  'picolisp-wiki-non-floating-content-face
  "Face name to use for non floating content.")

(defvar picolisp-wiki-right-floating-content-face
  'picolisp-wiki-right-floating-content-face
  "Face name to use for right floating content.")

(defvar picolisp-wiki-pre-face 'picolisp-wiki-pre-face
  "Face name to use for preformatted text.")

(defvar picolisp-wiki-link-label-face 'picolisp-wiki-link-label-face
  "Face name to use for link labels.")

(defvar picolisp-wiki-url-face 'picolisp-wiki-url-face
  "Face name to use for URLs.")

(defvar picolisp-wiki-link-title-face 'picolisp-wiki-link-title-face
  "Face name to use for reference link titles.")

(defvar picolisp-wiki-comment-face 'picolisp-wiki-comment-face
  "Face name to use for HTML comments.")



;; FACE definitions

(defgroup picolisp-wiki-faces nil
  "Faces used in Picolisp-Wiki Mode"
  :group 'picolisp-wiki
  :group 'faces)

(defface picolisp-wiki-hr-face
  '((t (:inherit font-lock-comment-delimiter-face)))
  "Face for starting braces."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-starting-brace-face
  '((t (:inherit font-lock-comment-delimiter-face)))
  "Face for starting braces."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-closing-brace-face
  '((t (:inherit font-lock-comment-delimiter-face)))
  "Face for closing braces."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-italic-face
  '((t (:inherit font-lock-negation-char-face :slant italic)))
  "Face for italic text."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-bold-face
  '((t (:inherit font-lock-negation-char-face :weight bold)))
  "Face for bold text."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-underlined-face
  '((t (:inherit font-lock-negation-char-face :underline t)))
  "Face for underlined text."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-line-break-face
  '((t (:inherit font-lock-warning-face)))
  "Face for underlined text."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face
  '((t (:inherit font-lock-function-name-face :weight bold)))
  "Base face for headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face-1
  '((t (:inherit picolisp-wiki-header-face)))
  "Face for level-1 headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face-2
  '((t (:inherit picolisp-wiki-header-face)))
  "Face for level-2 headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face-3
  '((t (:inherit picolisp-wiki-header-face)))
  "Face for level-3 headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face-4
  '((t (:inherit picolisp-wiki-header-face)))
  "Face for level-4 headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face-5
  '((t (:inherit picolisp-wiki-header-face)))
  "Face for level-5 headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-header-face-6
  '((t (:inherit picolisp-wiki-header-face)))
  "Face for level-6 headers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-list-item-face
  '((t (:inherit font-lock-string-face)))
  "Face for list item markers."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-pre-face
  '((t (:inherit font-lock-constant-face)))
  ;; '((t (:inherit font-lock-string-face)))
  "Face for preformatted text."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-internal-link-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for internal links."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-external-link-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for external links."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-url-face
  '((t (:inherit font-lock-string-face)))
  "Face for URLs."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-link-label-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for reference link titles."
  :group 'picolisp-wiki-faces)

(defface picolisp-wiki-comment-face
  '((t (:inherit font-lock-comment-face)))
  "Face for HTML comments."
  :group 'picolisp-wiki-faces)


;; REGEXP
;; FIXME consider linebreaks in pattern

;; [start] regexp by Doug Lewan (Newsgroups: gmane.emacs.help)

(defconst picolisp-wiki-regex-plain-text 
  (concat "\\([[:space:]]*[^}]+\\)[[:space:]]*" ; Matches "123$%^ Чебурашка &*(0-="
	  )
  "Regular expression defining what 'plain text' is.")

(defconst  picolisp-wiki-regex-bold-text
  (concat "\\(!{\\)"
	  picolisp-wiki-regex-plain-text
	  "\\(}\\)")
  "Regular expression defining what 'bold text' is.")

(defconst picolisp-wiki-regex-text
  (concat "\\("
	  picolisp-wiki-regex-plain-text
	  "\\|"
	  picolisp-wiki-regex-bold-text
	  "\\)")
  "Regular expression defining what 'text'.
Text is a mix of plain text and bold text.")

(defconst picolisp-wiki-regex-list-item-text
  (concat "\\(-{\\)"
	  picolisp-wiki-regex-text "+"
	  "\\(}\\)")
  "Regular expression defining what a 'list item' is.")

;; [end] regexp by Doug Lewan (Newsgroups: gmane.emacs.help)

;; [start] testcode for regexp by Doug Lewan

;; ;; 
;; ;; Sunny day test code
;; ;; 
;; (defconst test-plain-text (list "foo"
;; 				"foo bar "
;; 				"	foo bar baz bat"
;; 				" --- 123$%^ Чебурашка &*(0-= --- "))
;; (defconst test-bold-text (mapcar (lambda (text)
;; 				   (concat "!{" text "}"))
;; 				 test-plain-text))
;; (defconst test-list-item-text (mapcar (lambda (list-text)
;; 				   (concat "-{" list-text "}"))
;; 				 (append test-plain-text test-bold-text)))

;; (mapc (lambda (test-spec)
;; 	(let ((re (car test-spec))
;; 	      (test-data (cdr test-spec)))
;; 	  (mapc (lambda (item)
;; 		  (if (string-match re item)
;; 		      (message "PASS -- [[%s]] matches [[%s]]" re item)
;; 		    (message "FAIL -- [[%s]] DIDN'T match [[%s]]" re item))
;; 		  (sit-for 1))
;; 		test-data)))
;;       (list (cons picolisp-wiki-regex-plain-text test-plain-text)
;; 	    (cons picolisp-wiki-regex-bold-text test-bold-text)
;; 	    (cons picolisp-wiki-regex-list-item-text test-list-item-text)))

;; [end] testcode testcode for regexp by Doug Lewan

(defconst picolisp-wiki-regex-internal-link
  "\\(={\\)\\([^ ]+\\)\\( \\)\\(.*\\)\\(}\\)"
  "Regular expression for an internal link.")

(defconst picolisp-wiki-regex-external-link
   "\\(\\^{\\)\\([^ ]+\\)\\( \\)\\(.*\\)\\(}\\)"
  "Regular expression for an external link.")

(defconst picolisp-wiki-regex-comment
  "\\(#{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for an external link.")

(defconst picolisp-wiki-regex-header-1
  "\\(1{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for level 1 headers.")

(defconst picolisp-wiki-regex-header-2
  "\\(2{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for level 2 headers.")

(defconst picolisp-wiki-regex-header-3
  "\\(3{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for level 3 headers.")

(defconst picolisp-wiki-regex-header-4
  "\\(4{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for level 4 headers.")

(defconst picolisp-wiki-regex-header-5
  "\\(5{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for level 5 headers.")

(defconst picolisp-wiki-regex-header-6
  "\\(6{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for level 6 headers.")

(defconst picolisp-wiki-regex-hr
  "\\(--\\)+\\(---\\)*$"
  "Regular expression for matching Picolisp-Wiki horizontal rules.")

(defconst picolisp-wiki-regex-left-floating-content
  "\\(<{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching left-floating-content.")

(defconst picolisp-wiki-regex-non-floating-content
  "\\(@{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching non-floating-content.")

(defconst picolisp-wiki-regex-right-floating-content
  "\\(>{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching right-floating-content.")

(defconst picolisp-wiki-regex-pre-block
   "\\(:{\\)\\([ 	
]*[^}]+\\)\\(}\\)"

;;  "\\(:{\\)\\([ \t\n]*[^}]+\\)\\(}\\)"

;;   "\\(:{\\)\\([ 	
;; ][^}]+\\)\\(}\\)"
  "Regular expression for matching preformatted text sections.")

;; (defconst picolisp-wiki-regex-unordered-list
;;   "\\(^[\\t ]*\\*{\\)\\([ 	]*[ 
;; ]+\\)\\(-{.*}[ 	
;; ]+\\)\\{1,\\}\\(}\\)"
;;   "Regular expression for matching unordered list markers.")

;; (defconst picolisp-wiki-regex-ordered-list
;;   "\\(^[\\t ]*\\+{\\)\\([ 	]*[ 
;; ]+\\)\\(-{.*}[ 	
;; ]+\\)\\{1,\\}\\(}\\)"
;;   "Regular expression for matching ordered list markers.")

;; (defconst picolisp-wiki-regex-unordered-list-start
;;   "\\(^\\*{\\)\\([ \t\n]*$\\)"
;;   "Regular expression for matching the start of an unordered list.")

;; (defconst picolisp-wiki-regex-ordered-list-start
;;   "\\(^\\+{\\)\\([ \t\n]*$\\)"
;;   "Regular expression for matching the start of an ordered list.")

(defconst picolisp-wiki-regex-starting-brace
  (concat "\\(\\*\\|\\+\\|-\\|&\\|/\\|_\\|\\^\\|"
          "<\\|>\\|@\\|!\\|=\\|:\\|#\\|1\\|2\\|"
          "3\\|4\\|5\\|6\\)\\({\\)")
  "Regular expression for matching a starting brace.")

(defconst picolisp-wiki-regex-closing-brace
  "\\([^\\]\\)\\(}\\)"
  "Regular expression for matching a closing brace.")

(defconst picolisp-wiki-regex-list-item
  "\\(-{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching a list item.")

(defconst picolisp-wiki-regex-bold
  "\\(!{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching bold text.")

(defconst picolisp-wiki-regex-italic
  "\\(/{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching italic text.")

(defconst picolisp-wiki-regex-underlined
   "\\(_{\\)\\([ 	
]*[^}]+\\)\\(}\\)"
  "Regular expression for matching underlined text.")

(defconst picolisp-wiki-regex-line-break
  "\\(&{\\)\\([-]?[0-9]\\)\\(}\\)"
  "Regular expression for matching line breaks.")

(defconst picolisp-wiki-regex-wiki-link
  "\\[\\[\\([^]|]+\\)\\(|\\([^]]+\\)\\)?\\]\\]"
  "Regular expression for matching wiki links.
This matches typical bracketed [[WikiLinks]] as well as 'aliased'
wiki links of the form [[PageName|link text]].  In this regular
expression, #1 matches the page name and #3 matches the link
text.")

(defconst picolisp-wiki-regex-uri
  (concat
   "\\(" (mapconcat 'identity picolisp-wiki-uri-types "\\|")
   "\\):[^]\t\n\r<>,;() ]+")
  "Regular expression for matching inline URIs.")

(defconst picolisp-wiki-regex-angle-uri
  (concat
   "\\(<\\)\\("
   (mapconcat 'identity picolisp-wiki-uri-types "\\|")
   "\\):[^]\t\n\r<>,;()]+\\(>\\)")
  "Regular expression for matching inline URIs in angle brackets.")

(defconst picolisp-wiki-regex-email
  "<\\(\\sw\\|\\s_\\|\\s.\\)+@\\(\\sw\\|\\s_\\|\\s.\\)+>"
  "Regular expression for matching inline email addresses.")



;; Keywords

(defvar picolisp-wiki-mode-font-lock-keywords-basic
  (list
   (cons picolisp-wiki-regex-header-1 '(2 picolisp-wiki-header-face-1))
   (cons picolisp-wiki-regex-header-2 '(2 picolisp-wiki-header-face-2))
   (cons picolisp-wiki-regex-header-3 '(2 picolisp-wiki-header-face-3))
   (cons picolisp-wiki-regex-header-4 '(2 picolisp-wiki-header-face-4))
   (cons picolisp-wiki-regex-header-5 '(2 picolisp-wiki-header-face-5))
   (cons picolisp-wiki-regex-header-6 '(2 picolisp-wiki-header-face-6))
   (cons picolisp-wiki-regex-starting-brace 'picolisp-wiki-starting-brace-face)
   (cons picolisp-wiki-regex-closing-brace '(2 picolisp-wiki-closing-brace-face))
   (cons picolisp-wiki-regex-pre-block '(2 picolisp-wiki-pre-face))
   (cons picolisp-wiki-regex-hr '(2 picolisp-wiki-hr-face))
   (cons picolisp-wiki-regex-line-break '(2 picolisp-wiki-line-break-face))
   (cons picolisp-wiki-regex-comment '(2 picolisp-wiki-comment-face))
   (cons picolisp-wiki-regex-angle-uri '(2 picolisp-wiki-url-face))
   (cons picolisp-wiki-regex-uri '(2 picolisp-wiki-url-face))
   (cons picolisp-wiki-regex-email '(2 picolisp-wiki-url-face))
   ;; (cons picolisp-wiki-regex-left-floating-content
   ;;       '(2 picolisp-wiki-left-floating-content-fact))
   ;; (cons picolisp-wiki-regex-non-floating-content
   ;;       '(2 picolisp-wiki-non-floating-content-fact))
   ;; (cons picolisp-wiki-regex-right-floating-content
   ;;       '(2 picolisp-wiki-right-floating-content-fact))
   (cons picolisp-wiki-regex-email '(2 picolisp-wiki-url-face))
   ;; changed from picolisp-wiki-regex-list-item
   ;; (cons picolisp-wiki-regex-list-item '(2 picolisp-wiki-list-item-face))
   ;; (cons picolisp-wiki-regex-list-item-text 'picolisp-wiki-list-item-face)
   (cons picolisp-wiki-regex-internal-link
         '((2 picolisp-wiki-url-face t)
           (4 picolisp-wiki-internal-link-face t)))
   (cons picolisp-wiki-regex-external-link
         '((2 picolisp-wiki-url-face t)
           (4 picolisp-wiki-external-link-face t)))
   (cons picolisp-wiki-regex-bold '(2 picolisp-wiki-bold-face))
   ;; (cons picolisp-wiki-regex-bold-text 'picolisp-wiki-bold-face)
   (cons picolisp-wiki-regex-italic '(2 picolisp-wiki-italic-face))
   (cons picolisp-wiki-regex-underlined '(2 picolisp-wiki-underlined-face))
    )
   "Syntax highlighting for Picolisp-Wiki files.")

(defvar picolisp-wiki-mode-font-lock-keywords
  (append picolisp-wiki-mode-font-lock-keywords-basic)
  "Default highlighting expressions for Picolisp-Wiki mode.")



;;; Syntax Table ==============================================================

(defvar picolisp-wiki-mode-syntax-table
  (let ((picolisp-wiki-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\" "w" picolisp-wiki-mode-syntax-table)
    picolisp-wiki-mode-syntax-table)
  "Syntax table for `picolisp-wiki-mode'.")



;;; Element Insertion =========================================================

(defun picolisp-wiki-wrap-or-insert (s1 s2 &optional beg-newline-p)
  "Insert the strings S1 and S2.
If Transient Mark mode is on and a region is active, wrap the strings S1
and S2 around the region."
  (if (and transient-mark-mode mark-active)
      (let ((a (region-beginning)) (b (region-end)))
        (goto-char a)
        (insert s1)
        (goto-char (+ b (length s1)))
        (insert s2))
    (if (not beg-newline-p)
        (insert s1 s2)
      (end-of-line)
      (newline 2)
      (insert s1 s2))))

(defun picolisp-wiki-insert-hr ()
  "Insert a horizonal rule using `picolisp-wiki-hr-string'."
  (interactive)
  ;; Leading blank line
  (when (and (>= (point) (+ (point-min) 2))
             (not (looking-back "\n\n" 2)))
    (insert "\n"))
  ;; Insert custom HR string
  (insert (concat picolisp-wiki-hr-string "\n"))
  ;; Following blank line
  (backward-char)
  (unless (looking-at "\n\n")
          (insert "\n")))

(defun picolisp-wiki-insert-bold ()
  "Insert markup for a bold word or phrase.
If Transient Mark mode is on and a region is active, it is made bold."
  (interactive)
  (picolisp-wiki-wrap-or-insert "!{" "}")
  (backward-char 1))

(defun picolisp-wiki-insert-italic ()
  "Insert markup for an italic word or phrase.
If Transient Mark mode is on and a region is active, it is made italic."
  (interactive)
  (picolisp-wiki-wrap-or-insert "/{" "}")
  (backward-char 1))

(defun picolisp-wiki-insert-underlined ()
  "Insert markup for an underlined word or phrase.
If Transient Mark mode is on and a region is active, it is underlined."
  (interactive)
  (picolisp-wiki-wrap-or-insert "_{" "}")
  (backward-char 1))


(defun picolisp-wiki-insert-pre-block ()
  "Insert markup for a pre-formatted block.
If Transient Mark mode is on and a region is active, it is marked
as inline code."
  (interactive)
  (picolisp-wiki-wrap-or-insert ":{" "}")
  (backward-char 1))

(defun picolisp-wiki-insert-comment ()
  "Insert markup for an comment.
If Transient Mark mode is on and a region is active, it is marked
as inline code."
  (interactive)
  (picolisp-wiki-wrap-or-insert "#{" "}")
  (backward-char 1))


(defun picolisp-wiki-insert-internal-link ()
  "Insert an internal link.
If Transient Mark mode is on and a region is active, it is used
as the link text."
  (interactive)
  (picolisp-wiki-wrap-or-insert "={" "}")
  (backward-char 1))

(defun picolisp-wiki-insert-external-link ()
  "Insert an external link.
If Transient Mark mode is on and a region is active, it is used
as the link text."
  (interactive)
  (picolisp-wiki-wrap-or-insert "^{" "}")
  (backward-char 1))


(defun picolisp-wiki-insert-left-floating-content ()
  "Insert an inline image tag of the form <{content}.
If Transient Mark mode is on and a region is active, it is used
as the alt text of the image."
  (interactive)
  (picolisp-wiki-wrap-or-insert "<{" "}")
  (backward-char 1))

(defun picolisp-wiki-insert-non-floating-content ()
  "Insert an inline image tag of the form @{content}.
If Transient Mark mode is on and a region is active, it is used
as the alt text of the image."
  (interactive)
  (picolisp-wiki-wrap-or-insert "@{" "}")
  (backward-char 1))

(defun picolisp-wiki-insert-right-floating-content ()
  "Insert an inline image tag of the form >{content}.
If Transient Mark mode is on and a region is active, it is used
as the alt text of the image."
  (interactive)
  (picolisp-wiki-wrap-or-insert ">{" "}")
  (backward-char 1))


(defun picolisp-wiki-insert-line-breaks (n)
  "Insert line-breaks. With no prefix argument, insert 1
line-break. With prefix N, insert N line-breaks. With prefix N,
insert N line-breaks. With negative prefix -N, insert N
line-breaks and clear float style."
  (interactive "p")
  (unless n                             ; Test to see if n is defined
    (setq n 1))                         ; Default to level 1 header
  (insert
   (format "&{%d}" n )))


(defun picolisp-wiki-insert-unordered-list ()
  "Insert an unordered list.
If Transient Mark mode is on and a region is active, it is wrapped in an unordered list (the region should only contain list-items)."
  (interactive)
  (end-of-line)
  (newline)
  (insert "*{")
  (newline)
  (insert "   -{}")
  (newline)
  (insert "}")
  (newline)
  (search-backward "-{" nil t 1)
  (forward-char 2))


(defun picolisp-wiki-insert-ordered-list ()
  "Insert an ordered list.
If Transient Mark mode is on and a region is active, it is
wrapped in an ordered list (the region should only contain
list-items)."
  (interactive)
  (end-of-line)
  (newline)
  (insert "+{")
  (newline)
  (insert "   -{}")
  (newline)
  (insert "}")
  (newline)
  (search-backward "-{" nil t 1)
  (forward-char 2))


;; FIXME consider escaped braces '\{'and '\}' inside list items
(defun picolisp-wiki--inside-list-item-p (&optional second-trial-p)
  "Return t if inside list-item, nil otherwise.
This function takes care of the (common) case when there is one
nested markup inside the list item, e.g. a link or a bold text,
and point is inside the nested markup braces."
  (save-excursion
    (let ((pt (point)))
      (search-backward "{" nil t 1)
      (backward-char)
      (if (not (looking-at "-{"))
          (if (and               
               (not second-trial-p)
               (looking-at
                (concat "\\(\\*\\|\\+\\|&\\|/\\|_\\|\\^\\|"
                        "<\\|>\\|@\\|!\\|=\\|:\\|#\\)\\({\\)")))
              (picolisp-wiki--inside-list-item-p 'SECOND-TRIAL-P)
            nil)
        (and
         (if second-trial-p
             (search-forward-regexp "}[^}]*}" nil t 1)
           (search-forward "}" nil t 1))
         (setq item-end (point))
         (> item-end pt))))))
        
(defun picolisp-wiki-insert-list-item ()
  "Insert a list-item.
If Transient Mark mode is on and a region is active, it becomes the text of a list item."
  (interactive)
  (if (not (picolisp-wiki--inside-list-item-p))   
      (progn  
        (picolisp-wiki-wrap-or-insert "-{" "}")
        (backward-char 1))
    (end-of-line)
    (newline)
    (insert "   -{}")
    (backward-char 1)
    ))


(defun picolisp-wiki-insert-header-1 ()
  "Insert a first level picolisp-wiki-style header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (picolisp-wiki-insert-header 1))

(defun picolisp-wiki-insert-header-2 ()
  "Insert a second level picolisp-wiki-style header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (picolisp-wiki-insert-header 2))

(defun picolisp-wiki-insert-header-3 ()
  "Insert a third level picolisp-wiki-style header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (picolisp-wiki-insert-header 3))

(defun picolisp-wiki-insert-header-4 ()
  "Insert a fourth level picolisp-wiki-style header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (picolisp-wiki-insert-header 4))

(defun picolisp-wiki-insert-header-5 ()
  "Insert a fifth level picolisp-wiki-style header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (picolisp-wiki-insert-header 5))

(defun picolisp-wiki-insert-header-6 ()
  "Insert a sixth level picolisp-wiki-style header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (picolisp-wiki-insert-header 6))

(defun picolisp-wiki-insert-header (n)
  "Insert an picolisp-wiki-style header.
With no prefix argument, insert a level-1 header.  With prefix N,
insert a level-N header.  If Transient Mark mode is on and the
region is active, it is used as the header text."
  (interactive "p")
  (unless n                             ; Test to see if n is defined
    (setq n 1))                         ; Default to level 1 header
  (picolisp-wiki-wrap-or-insert
   (concat (number-to-string n) "{") "}" 'BEG-NEWLINE-P)
  (backward-char 1))



;;; Keymap ====================================================================

(defvar picolisp-wiki-mode-map
  (let ((map (make-keymap)))
    ;; Element insertion
    (define-key map "\C-c\C-ln" 'picolisp-wiki-insert-internal-link)
    (define-key map "\C-c\C-lx" 'picolisp-wiki-insert-external-link)
    (define-key map "\C-c\C-lu" 'picolisp-wiki-insert-unordered-list)
    (define-key map "\C-c\C-lo" 'picolisp-wiki-insert-ordered-list)
    (define-key map "\C-c\C-li" 'picolisp-wiki-insert-list-item)
    (define-key map "\C-c\C-fl" 'picolisp-wiki-insert-left-floating-content)
    (define-key map "\C-c\C-fn" 'picolisp-wiki-insert-non-floating-content)
    (define-key map "\C-c\C-fr" 'picolisp-wiki-insert-right-floating-content)
    (define-key map "\C-c\C-ck" 'picolisp-wiki-insert-line-breaks)
    (define-key map "\C-c\C-c1" 'picolisp-wiki-insert-header-1)
    (define-key map "\C-c\C-c2" 'picolisp-wiki-insert-header-2)
    (define-key map "\C-c\C-c3" 'picolisp-wiki-insert-header-3)
    (define-key map "\C-c\C-c4" 'picolisp-wiki-insert-header-4)
    (define-key map "\C-c\C-c5" 'picolisp-wiki-insert-header-5)
    (define-key map "\C-c\C-c6" 'picolisp-wiki-insert-header-6)
    (define-key map "\C-c\C-cb" 'picolisp-wiki-insert-bold)
    (define-key map "\C-c\C-ci" 'picolisp-wiki-insert-italic)
    (define-key map "\C-c\C-cu" 'picolisp-wiki-insert-underlined)
    (define-key map "\C-c\C-cp" 'picolisp-wiki-insert-pre-block)
    (define-key map "\C-c\C-cc" 'picolisp-wiki-insert-comment)
    (define-key map "\C-c\C-c-" 'picolisp-wiki-insert-hr)
    ;; Visibility cycling
    (define-key map (kbd "<tab>") 'picolisp-wiki-cycle)
    (define-key map (kbd "<S-iso-lefttab>") 'picolisp-wiki-shifttab)
    ;; Header navigation
    (define-key map (kbd "C-M-n") 'outline-next-visible-heading)
    (define-key map (kbd "C-M-p") 'outline-previous-visible-heading)
    (define-key map (kbd "C-M-f") 'outline-forward-same-level)
    (define-key map (kbd "C-M-b") 'outline-backward-same-level)
    (define-key map (kbd "C-M-u") 'outline-up-heading)
    ;; Picolisp-Wiki functions
    ;; (define-key map "\C-c\C-cm" 'picolisp-wiki)
    ;; (define-key map "\C-c\C-cp" 'picolisp-wiki-preview)
    ;; (define-key map "\C-c\C-ce" 'picolisp-wiki-export)
    ;; (define-key map "\C-c\C-cv" 'picolisp-wiki-export-and-view)
    map)
  "Keymap for Picolisp-Wiki major mode.")





;;; Menu ==================================================================

(easy-menu-define picolisp-wiki-mode-menu picolisp-wiki-mode-map
  "Menu for Picolisp-Wiki mode"
  '("Picolisp-Wiki"
    ("Show/Hide"
     ["Cycle visibility" picolisp-wiki-cycle (outline-on-heading-p)]
     ["Cycle global visibility" picolisp-wiki-shifttab])
    "---"
    ("Headers"
     ["First level" picolisp-wiki-insert-header-1]
     ["Second level" picolisp-wiki-insert-header-2]
     ["Third level" picolisp-wiki-insert-header-3]
     ["Fourth level" picolisp-wiki-insert-header-4]
     ["Fifth level" picolisp-wiki-insert-header-5]
     ["Sixth level" picolisp-wiki-insert-header-6])
    "---"
    ["Bold" picolisp-wiki-insert-bold]
    ["Italic" picolisp-wiki-insert-italic]
    ["Underlined" picolisp-wiki-insert-underlined]
    ["Preformatted" picolisp-wiki-insert-pre-block]
    ["Comment" picolisp-wiki-insert-comment]
    ["Insert horizontal rule" picolisp-wiki-insert-hr]
    "---"
    ["Insert internal link" picolisp-wiki-insert-internal-link]
    ["Insert external link" picolisp-wiki-insert-external-link]
    "---"
    ["Insert left-floating content" picolisp-wiki-insert-left-floating-content]
    ["Insert non-floating content" picolisp-wiki-insert-non-floating-content]
    ["Insert right-floating content" picolisp-wiki-insert-right-floating-content]
    "---"
    ["Insert unordered list" picolisp-wiki-insert-unordered-list]
    ["Insert ordered list" picolisp-wiki-insert-ordered-list]
    "---"
    ["Version" picolisp-wiki-show-version]
    ))



;;; Outline ===================================================================

;; The following visibility cycling code was taken from org-mode
;; by Carsten Dominik and adapted for picolisp-wiki-mode.

(defvar picolisp-wiki-cycle-global-status 1)
(defvar picolisp-wiki-cycle-subtree-status nil)

;; Based on org-end-of-subtree from org.el
(defun picolisp-wiki-end-of-subtree (&optional invisible-OK)
  "Move to the end of the current subtree.
Only visible heading lines are considered, unless INVISIBLE-OK is
non-nil."
  (outline-back-to-heading invisible-OK)
  (let ((first t)
        (level (funcall outline-level)))
    (while (and (not (eobp))
                (or first (> (funcall outline-level) level)))
      (setq first nil)
      (outline-next-heading))
    (if (memq (preceding-char) '(?\n ?\^M))
        (progn
          ;; Go to end of line before heading
          (forward-char -1)
          (if (memq (preceding-char) '(?\n ?\^M))
              ;; leave blank line before heading
              (forward-char -1)))))
  (point))

;; Based on org-cycle from org.el.
(defun picolisp-wiki-cycle (&optional arg)
  "Visibility cycling for Picolisp-Wiki mode.
If ARG is t, perform global visibility cycling. If the point is
at an picolisp-wiki-style header, cycle visibility of the
corresponding subtree. Otherwise, insert a tab using
`indent-relative'."
  (interactive "P")
  (cond
     ((eq arg t) ;; Global cycling
      (cond
       ((and (eq last-command this-command)
             (eq picolisp-wiki-cycle-global-status 2))
        ;; Move from overview to contents
        (hide-sublevels 1)
        (message "CONTENTS")
        (setq picolisp-wiki-cycle-global-status 3))

       ((and (eq last-command this-command)
             (eq picolisp-wiki-cycle-global-status 3))
        ;; Move from contents to all
        (show-all)
        (message "SHOW ALL")
        (setq picolisp-wiki-cycle-global-status 1))

       (t
        ;; Defaults to overview
        (hide-body)
        (message "OVERVIEW")
        (setq picolisp-wiki-cycle-global-status 2))))

     ((save-excursion (beginning-of-line 1) (looking-at outline-regexp))
      ;; At a heading: rotate between three different views
      (outline-back-to-heading)
      (let ((goal-column 0) eoh eol eos)
        ;; Determine boundaries
        (save-excursion
          (outline-back-to-heading)
          (save-excursion
            (beginning-of-line 2)
            (while (and (not (eobp)) ;; this is like `next-line'
                        (get-char-property (1- (point)) 'invisible))
              (beginning-of-line 2)) (setq eol (point)))
          (outline-end-of-heading)   (setq eoh (point))
          (picolisp-wiki-end-of-subtree t)
          (skip-chars-forward " \t\n")
          (beginning-of-line 1) ; in case this is an item
          (setq eos (1- (point))))
        ;; Find out what to do next and set `this-command'
      (cond
         ((= eos eoh)
          ;; Nothing is hidden behind this heading
          (message "EMPTY ENTRY")
          (setq picolisp-wiki-cycle-subtree-status nil))
         ((>= eol eos)
          ;; Entire subtree is hidden in one line: open it
          (show-entry)
          (show-children)
          (message "CHILDREN")
          (setq picolisp-wiki-cycle-subtree-status 'children))
         ((and (eq last-command this-command)
               (eq picolisp-wiki-cycle-subtree-status 'children))
          ;; We just showed the children, now show everything.
          (show-subtree)
          (message "SUBTREE")
          (setq picolisp-wiki-cycle-subtree-status 'subtree))
         (t
          ;; Default action: hide the subtree.
          (hide-subtree)
          (message "FOLDED")
          (setq picolisp-wiki-cycle-subtree-status 'folded)))))

     (t
      (indent-for-tab-command))))

;; Based on org-shifttab from org.el.
(defun picolisp-wiki-shifttab ()
  "Global visibility cycling.
Calls `picolisp-wiki-cycle' with argument t."
  (interactive)
  (picolisp-wiki-cycle t))


;;; Miscellaneous =============================================================

(defun picolisp-wiki-line-number-at-pos (&optional pos)
  "Return (narrowed) buffer line number at position POS.
If POS is nil, use current buffer location.
This is an exact copy of `line-number-at-pos' for use in emacs21."
  (let ((opoint (or pos (point))) start)
    (save-excursion
      (goto-char (point-min))
      (setq start (point))
      (goto-char opoint)
      (forward-line 0)
      (1+ (count-lines start (point))))))

(defun picolisp-wiki-nobreak-p ()
  "Return nil if it is acceptable to break the current line at the point."
  ;; inside in square brackets (e.g., link anchor text)
  (looking-back "\\[[^]]*"))



;;; Mode definition  ==========================================================

(defun picolisp-wiki-show-version ()
  "Show the version number in the minibuffer."
  (interactive)
  (message "picolisp-wiki-mode, version %s" picolisp-wiki-mode-version))

;;;###autoload
(define-derived-mode picolisp-wiki-mode text-mode "PicoLisp-Wiki"
  "Major mode for editing PicoLisp-Wiki files."
  ;; Natural Picolisp-Wiki tab width
  (setq tab-width 4)
  ;; Comments
  (make-local-variable 'comment-start)
  (setq comment-start "#{")
  (make-local-variable 'comment-end)
  (setq comment-end "}")
  ;; (make-local-variable 'comment-start-skip)
  ;; (setq comment-start-skip "#{ \t}*")
  (make-local-variable 'comment-column)
  (setq comment-column 0)
  ;; Font lock.
  (set (make-local-variable 'font-lock-defaults)
       '(picolisp-wiki-mode-font-lock-keywords))
  (set (make-local-variable 'font-lock-multiline) t)
  ;; Make filling work with lists (unordered, ordered, and definition)
  ;; (set (make-local-variable 'paragraph-start)
  ;;      "\f\\|[ \t]*$\\|^[ \t]*[*+-] \\|^[ \t*][0-9]+\\.\\|^[ \t]*: ")
  ;; Outline mode
  (make-local-variable 'eval)
  (setq eval (outline-minor-mode))
  (make-local-variable 'outline-regexp)
  ;; (setq outline-regexp "^[ \t]*[0-9]{")
  (setq outline-regexp
        "^[ 	]*\\(1{\\|2{.\\|3{..\\|4{...\\|5{....\\|6{.....\\)")
  ;; Cause use of ellipses for invisible text.
  (add-to-invisibility-spec '(outline . t)))


(provide 'picolisp-wiki-mode)

;;; picolisp-wiki-mode.el ends here
