;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Adam Frey"
      user-mail-address "adam@adamfrey.me")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-font (font-spec :family "JetBrains Mono" :size 18 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 18)
      doom-unicode-font (font-spec :family "Noto Color Emoji"))

(setq doom-theme 'doom-solarized-light)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/99.Unorganized/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type nil)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Helpful Keybindings
;; Align C-M-q: indent-pp-sexp

;; Emacs settings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package! cascading-dir-locals
  :config
  (cascading-dir-locals-mode 1))

;; General Helpers ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun af/read-file (path)
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

;; Completion  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; C-u M-x list-faces-display RET vertico RET
;; (set-face-foreground 'vertico-group-title "cadet blue")

;; Editing  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "C-t") 'forward-char)
(global-set-key (kbd "M-z") 'zap-up-to-char)

(defun comment-header (b e)
  "Turn the current line into a comment header. Right now it
only works for semicolons."
  (interactive "r")
  (let ((e (copy-marker e t)))
    (goto-char b)
    (insert-char ?\; 2)
    (insert-char (char-from-name "SPACE"))
    (end-of-line)
    (insert-char (char-from-name "SPACE"))
    (insert-char ?\;)
    (insert-char ?\; (- fill-column (current-column)))
    (goto-char e)
    (set-marker e nil)))

(global-set-key (kbd "C-c #") 'comment-header)

(use-package! multiple-cursors
  :config
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this))

(defun whack-whitespace (arg)
  "Delete all white space from point to the next word.  With prefix ARG
    delete across newlines as well.  The only danger in this is that you
    don't have to actually be at the end of a word to make it work.  It
    skips over to the next whitespace and then whacks it all to the next
    word."
  (interactive "P")
  (let ((regexp (if arg "[ \t\n]+" "[ \t]+")))
    (re-search-forward regexp nil t)
    (replace-match "" nil nil)))

(global-set-key (kbd "C-c d") 'whack-whitespace)

;; Navigation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "M-c") 'other-window)

(defun afrey/pop-current-window-into-frame ()
  (interactive)
  (let ((buffer (current-buffer)))
    (unless (one-window-p)
      (delete-window))
    (display-buffer-pop-up-frame buffer nil)))

(global-set-key (kbd "M-t") 'afrey/pop-current-window-into-frame)
(global-set-key (kbd "M-=") #'flycheck-next-error)
(global-set-key (kbd "M--") #'flycheck-previous-error)

(global-set-key (kbd "M-N") 'avy-goto-char-timer)
(define-key isearch-mode-map (kbd "M-N") 'avy-isearch)

;; TODO http://ergoemacs.org/emacs/modernization_mark-word.html
;; extend selection

;; Version Control ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "C-c C-v RET") 'magit-status)
(global-set-key (kbd "C-c v RET") 'magit-status)

(defun magit-display-buffer-pop-up-frame (buffer)
  (if (with-current-buffer buffer (eq major-mode 'magit-status-mode))
      (display-buffer buffer
                      '((display-buffer-reuse-window
                         display-buffer-pop-up-frame)
                        (reusable-frames . t)))
    (magit-display-buffer-traditional buffer)))

(after! magit
  (setq magit-display-buffer-function #'magit-display-buffer-pop-up-frame)
  (setq magit-list-refs-sortby "-creatordate")
  (add-hook 'magit-status-mode-hook (lambda () (company-mode -1))))

(defun endless/visit-pull-request-url ()
  "Visit the current branch's PR on Github."
  (interactive)
  (browse-url
   (format "https://github.com/%s/pull/new/%s"
           (replace-regexp-in-string
            "\\`.+github\\.com:\\(.+\\)\\.git\\'" "\\1"
            (magit-get "remote"
                       (magit-get-push-remote)
                       "url"))
           (magit-get-current-branch))))

;; Dotfiles ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package! chezmoi)

;; Projects ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "M-r") 'projectile-find-file)
(global-set-key (kbd "M-u") 'projectile-find-file-other-frame)
(global-set-key (kbd "M-s M-l") 'projectile-previous-project-buffer)
(global-set-key (kbd "M-s M-h") 'projectile-next-project-buffer)
(global-set-key (kbd "C-c /") '+default/search-project)


(defun af/open-implementation-or-test-in-new-frame ()
  (interactive)
  (switch-to-buffer-other-frame
   (find-file-noselect
    (projectile-find-implementation-or-test (buffer-file-name)))))

(after! projectile
  (setq projectile-create-missing-test-files t)
  (define-key doom-leader-map (kbd "p t") 'af/open-implementation-or-test-in-new-frame)
  (define-key projectile-mode-map (kbd "C-c p t") 'af/open-implementation-or-test-in-new-frame)
  (define-key projectile-mode-map (kbd "C-c p T") 'magit-todos-list))

;; After running project search, 'C-o' for search options, then 'a' to open
;; every match, then the above commands for next/previous project buffer
(after! counsel
  (ivy-add-actions
   #'counsel-rg
   '(("a" (lambda (_path) (mapc #'counsel-git-grep-action ivy--all-candidates))
      "Open all matches"))))

;; Org Mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(after! ob
  (add-to-list 'org-babel-tangle-lang-exts '("clojure" . "clj")))

(defun af/open-journal-file ()
  (interactive)
  (find-file "~/10-19.Software/software-journal.org"))

(global-unset-key (kbd "C-o"))
(global-set-key (kbd "C-o 1") 'af/open-journal-file)

;; Lisp ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package! lispy
  :init
  (setq lispy-compat '(edebug cider magit-blame-mode)))

(after! lispy
  (add-hook 'magit-blame-mode-hook #'(lambda () (lispy-mode 0)))
  (add-hook 'lispy-mode-hook
            (lambda ()
              (define-key lispy-mode-map (kbd "M-m") nil)))
  (define-key lispy-mode-map (kbd "M-R") 'lispy-raise-sexp)
  (define-key lispy-mode-map (kbd "M-p") 'lispy-mark-symbol)
  (define-key lispy-mode-map (kbd "C-)") 'paredit-forward-slurp-sexp)
  (define-key lispy-mode-map (kbd "_") nil))

;; Clojure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar clojure-tonsky-indent t)

(defun af/set-clojure-indent-style ()
  (interactive)
  (if clojure-tonsky-indent
      (setq-local clojure-indent-style 'always-indent)
    (setq-local clojure-indent-style 'always-align)))

(defun af/set-clojure-indent-style-hook ()
  (interactive)
  ;; https://stackoverflow.com/a/5148435
  (add-hook 'hack-local-variables-hook 'af/set-clojure-indent-style nil t)
  )

(if (boundp '+format-on-save-enabled-modes)
    (progn
      (add-to-list '+format-on-save-enabled-modes 'clojure-mode 'append)
      (add-to-list '+format-on-save-enabled-modes 'clojurescript-mode 'append)
      (add-to-list '+format-on-save-enabled-modes 'clojurec-mode 'append)))

;; TODO can I remove this part?
;; (setq +format-on-save-enabled-modes '(not emacs-lisp-mode sql-mode tex-mode latex-mode org-msg-edit-mode))

(defun cljfmt-current-file ()
  (interactive)
  (let ((default-directory (locate-dominating-file buffer-file-name ".git")))
    (shell-command
     (format "cljfmt fix %s" (shell-quote-argument (buffer-file-name))))
    (revert-buffer t t t)))

;; (set-formatter! 'cljfmt 'cljfmt-current-file :modes '(clojure-mode))

(after! clojure-mode
  (define-clojure-indent
    (or 0)
    (and 0)
    (= 0)
    (not= 0)
    (+ 0)
    (- 0)
    (* 0)
    (/ 0)
    (< 0)
    (> 0)
    (str 0)
    (concat 0)
    (require 0)
    (import 0)
    (recur 0)
    (some-fn 0)
    (conj 1)
    (cons 1)
    (merge 0)
    (some-> 0)
    (some->> 0)
    ;; nubank/matcher-combinators
    (match? 0)
    (health/send-timing 1)
    )

  (add-hook 'clojure-mode-hook 'af/set-clojure-indent-style-hook)

  ;; here because of weird error when up in the define-clojure-indent
  ;; also, peer pressure. I'd prefer val of 1 to 0
  (put-clojure-indent '-> 0)
  (put-clojure-indent '->> 0)

  (add-to-list 'clojure-align-cond-forms "assoc")
  (add-to-list 'clojure-align-cond-forms "given")
  (add-to-list 'clojure-align-cond-forms "set-env!")
  (add-to-list 'clojure-align-cond-forms "s/cat"))

(after! clj-refactor
  (cljr-add-keybindings-with-prefix "C-c C-r")
  (setq cljr-clojure-test-declaration "[clojure.test :refer [deftest is]]"))

(defun af/cider-switch-to-repl-buffer ()
  (interactive)
  (switch-to-buffer-other-frame (cider-current-repl nil 'ensure))
  (goto-char (point-max)))

(defun af/cider-connect-clj&cljs ()
  (interactive)
  (let* ((root-dir (locate-dominating-file buffer-file-name ".shadow-cljs"))
         (port (af/read-file (concat root-dir ".shadow-cljs/nrepl.port"))))
    (cider-connect-clj&cljs
     (list :host "localhost" :port port :cljs-repl-type 'shadow-select))))

(defun af/pop-cider-error ()
  (interactive)
  (if-let
      ((cider-error
        (get-buffer "*cider-error*")))
      (pop-to-buffer cider-error)
    (message
     "no cider error buffer")))

;; https://github.com/clojure-emacs/cider/issues/3019#issuecomment-1330342147
(defun af/cider-complete-at-point ()
  "Complete the symbol at point."
  (interactive)
  (message "cider complete at point")
  (when (and (cider-connected-p)
             (not (cider-in-string-p)))
    (when-let*
        ((bounds
	  (bounds-of-thing-at-point
	   'symbol))
	 (beg (car bounds))
	 (end (cdr bounds))
	 (completion
	  (append
	   (cider-complete
	    (buffer-substring beg end))
	   (get-text-property (point) 'cider-locals))))
      (list
       beg
       end
       (completion-table-dynamic
	(lambda (_) completion))
       :annotation-function #'cider-annotate-symbol))))

(after! cider
  ;; change cider pprint to comment so it uses the comment macro
  (setq cider-comment-prefix "\n#_")
  (setq cider-comment-continued-prefix "")
  (setq cider-comment-postfix "\n")
  (setq cider-clojure-cli-global-options "-A:performance/benchmark:performance/memory-meter:dev/debug:dev") ;; :performance/profiler
  (setq cider-lein-parameters "with-profile +dbg repl :headless :host localhost")
  (setq cider-print-fn 'puget)
  (setq cider-repl-use-content-types t)
  ;; (setq cider-enrich-classpath t) ;; this was causing a problem with google java libraries "this should be overridden by subclasses"
  (setq cider-enrich-classpath nil)
  (setq-default cider-show-error-buffer nil)
  (setq-default cider-auto-jump-to-error nil)
  (setq cider-repl-pop-to-buffer-on-connect nil)
  (setq nrepl-sync-request-timeout 30)
  (define-key cider-mode-map (kbd "C-c C-z") 'af/cider-switch-to-repl-buffer)
  (define-key cider-mode-map (kbd "C-c x") 'af/pop-cider-error)
  (set-face-attribute 'cider-error-overlay-face nil
                      :background "IndianRed"
                      :foreground "white")

  (remove-hook 'cider-connected-hook 'cider--maybe-inspire-on-connect)

  (add-hook 'cider-repl-mode-hook #'cider-company-enable-fuzzy-completion)
  (add-hook 'cider-mode-hook #'cider-company-enable-fuzzy-completion)

  ;; NOTE I'm using my own complete-at-point largely to get fuzzy matching on java imports
  (advice-add 'cider-complete-at-point :override #'af/cider-complete-at-point)
  ;; (setq completion-category-overrides '((cider (orderless basic))))
  ;; (add-to-list 'completion-category-defaults '(cider (styles basic))))

  (add-hook 'cider-mode
            (lambda ()
              (setq xref-backend-functions '(cider--xref-backend))))
  ;; TODO this
  (add-hook 'cider-test-report-mode
            (lambda ()
              (message "cider test report!")
              (afrey/pop-current-window-into-frame))))


;; JavaScript ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq js-indent-level 2)
(setq-default js2-basic-offset 2)
(add-to-list 'auto-mode-alist '("\\.cjs\\'" . js2-mode))

;; Common ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(after! company-mode
  (define-key company-mode-map (kbd "TAB") 'company-indent-or-complete-common))

;; AwesomeWM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(after! friar
  ;; M-x friar gives you a fennel REPL that can connect to a running awesomeWM instance
  ;; it seems like you should run it from a non-daemon Emacs instance
  (setq friar-fennel-file-path "~/.local/bin/fennel"))

;; ChatGPT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(after! gptel
  ;; (setq gptel-api-key (lambda ()
  ;;                       (with-temp-buffer
  ;;                         (insert-file-contents "~/.config/chatgpt/api-key.txt")
  ;;                         (buffer-string))))
  )
