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

(let ((font-size (string-to-number (or (getenv "EMACS_FONT_SIZE")
                                       "18"))))
  (setq doom-font (font-spec :family "JetBrains Mono" :size font-size :weight 'semi-light)
        doom-variable-pitch-font (font-spec :family "sans" :size font-size)
        doom-unicode-font (font-spec :family "Noto Color Emoji")))

(setq doom-theme 'alabaster-themes-light)

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

(global-set-key (kbd "C-x C-c") 'save-some-buffers)

;; Browser ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setenv "DISPLAY" "wayland-1")

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "zen-beta")

;; Completion  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; C-u M-x list-faces-display RET vertico RET
;; (set-face-foreground 'vertico-group-title "cadet blue")

(after! corfu
  (setq corfu-preselect 'first)
  (map! :map corfu-map
        "TAB"      #'corfu-insert
        [tab]      #'corfu-insert
        "RET"      #'corfu-insert
        [return]   #'corfu-insert))

;; Editing  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-unset-key (kbd "M-l")) ;; I don't need downcase-word
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
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)

  ;; to remove a function accidentally marked as run only once,
  ;; ~/.config/emacs/.local/cache/.mc-lists.el and change mc/cmds-to-run-once
  )

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
  (setq magit-list-refs-sortby "-creatordate"))

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
  (define-key projectile-mode-map (kbd "C-c p T") 'magit-todos-list)
  (projectile-register-project-type
   'clojure-components
   '(".clojure-components.edn")
   :test-suffix "_test"))



;; After running project search, 'C-o' for search options, then 'a' to open
;; every match, then the above commands for next/previous project buffer
(after! counsel
  (ivy-add-actions
   #'counsel-rg
   '(("a" (lambda (_path) (mapc #'counsel-git-grep-action ivy--all-candidates))
      "Open all matches"))))

(defun af/grep-current-dir (regexp)
  "Ripgrep for REGEXP in files at or under the current file's directory.
Respects .gitignore and other ignore files."
  (interactive "sRegexp: ")
  (ripgrep-regexp regexp (file-name-directory (buffer-file-name)) nil))

;; IBuffer ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar af/ibuffer-flex-formats
  '((mark modified read-only locked " "
     (name 18 60 :left :elide :flex)
     " " (size 9 -1 :right)
     " " (mode 16 30 :left :elide :flex)
     " " filename-and-process)
    (mark " " (name 16 -1 :left) " " filename))
  "Source ibuffer formats. A column tuple may end in `:flex' to declare
itself flexible; declared MIN is its weight, declared MAX is its cap.")

(defun af/ibuffer-fit-format (format width)
  "Resolve :flex tags in FORMAT, sizing flex columns to fill WIDTH.

Leftover = WIDTH minus the sum of every column's declared MIN.
Leftover is split among flex columns weighted by MIN, each capped at MAX.
Capped-column surplus respills among uncapped flex columns until the pool
empties or all flex columns hit their caps."
  (cl-labels ((entry-min (e)
                (cond ((stringp e) (string-width e))
                      ((memq e '(mark modified read-only locked)) 1)
                      ((symbolp e) 0)
                      (t (or (nth 1 e) 0))))
              (flex-p (e) (and (listp e) (eq (nth 5 e) :flex))))
    (let* ((flex-entries (cl-remove-if-not #'flex-p format))
           (reserved (apply #'+ (mapcar #'entry-min format)))
           (pool (max 0 (- width reserved)))
           (extras (make-hash-table :test 'eq))
           (uncapped (copy-sequence flex-entries)))
      (dolist (e flex-entries)
        (unless (and (integerp (nth 1 e)) (integerp (nth 2 e))
                     (> (nth 2 e) 0) (>= (nth 2 e) (nth 1 e)))
          (user-error
           ":flex column %S needs explicit MIN and MAX (MAX > 0, MAX >= MIN)"
           (nth 0 e)))
        (puthash e 0 extras))
      (catch 'af/ibuffer-fit-done
        (while (and (> pool 0) uncapped)
          (let* ((weight-sum (apply #'+ (mapcar (lambda (e) (nth 1 e)) uncapped)))
                 (distributed 0)
                 (still-uncapped nil))
            (when (zerop weight-sum)
              (throw 'af/ibuffer-fit-done nil))
            (dolist (e uncapped)
              (let* ((min (nth 1 e))
                     (max (nth 2 e))
                     (current (+ min (gethash e extras)))
                     (share (/ (* pool min) weight-sum)))
                (if (> (+ current share) max)
                    (let ((room (- max current)))
                      (puthash e (+ (gethash e extras) room) extras)
                      (cl-incf distributed room))
                  (puthash e (+ (gethash e extras) share) extras)
                  (cl-incf distributed share)
                  (push e still-uncapped))))
            (setq uncapped (nreverse still-uncapped))
            (cl-decf pool distributed)
            (when (zerop distributed)
              (throw 'af/ibuffer-fit-done nil)))))
      (when (and (> pool 0) uncapped)
        (let* ((e (car uncapped))
               (current (+ (nth 1 e) (gethash e extras)))
               (give (min pool (- (nth 2 e) current))))
          (puthash e (+ (gethash e extras) give) extras)))
      (mapcar (lambda (e)
                (if (flex-p e)
                    (let ((final (+ (nth 1 e) (gethash e extras))))
                      (list (nth 0 e) final final
                            (or (nth 3 e) :left)
                            (or (nth 4 e) nil)))
                  e))
              format))))

(defun af/ibuffer-refit (&optional window)
  "Rebuild buffer-local `ibuffer-formats' from `af/ibuffer-flex-formats'.

When called from `window-size-change-functions', WINDOW is the resized
window and the refit routes to its buffer. When called interactively or
from setup, WINDOW is nil and the refit applies to the current buffer,
sized to any visible window showing it."
  (let ((buf (if window (window-buffer window) (current-buffer))))
    (with-current-buffer buf
      (when (derived-mode-p 'ibuffer-mode)
        (when-let ((win (or window
                            (get-buffer-window buf)
                            (get-buffer-window buf 'visible))))
          (setq-local ibuffer-formats
                      (mapcar (lambda (fmt)
                                (af/ibuffer-fit-format fmt (window-body-width win)))
                              af/ibuffer-flex-formats))
          (ibuffer-redisplay t))))))

(defun af/ibuffer-setup ()
  "Install resize-aware refit on the current ibuffer buffer."
  (add-hook 'window-size-change-functions #'af/ibuffer-refit nil t)
  (let ((buf (current-buffer)))
    (run-at-time 0 nil
                 (lambda ()
                   (when (buffer-live-p buf)
                     (with-current-buffer buf (af/ibuffer-refit)))))))

(after! ibuffer
  (add-hook 'ibuffer-mode-hook #'af/ibuffer-setup))

;; Org Mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(after! ob
  (add-to-list 'org-babel-tangle-lang-exts '("clojure" . "clj")))

;; (defun af/open-journal-file ()
;;   (interactive)
;;   (find-file "~/10-19.Software/software-journal.org"))

;; (global-unset-key (kbd "C-o"))
;; (global-set-key (kbd "C-o 1") 'af/open-journal-file)

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
  (add-hook 'hack-local-variables-hook 'af/set-clojure-indent-style nil t))

;; Override apheleia's cljfmt to pass --config pointing to the nearest .cljfmt.edn,
(after! apheleia
  (setf (alist-get 'cljfmt apheleia-formatters)
        '("cljfmt" "fix"
          (when-let ((dir (locate-dominating-file
                           (or (apheleia-formatters-local-buffer-file-name)
                               default-directory)
                           ".cljfmt.edn")))
            (list "--config" (expand-file-name ".cljfmt.edn" dir)))
          "-")))

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

  (put-clojure-indent '*let 1)

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

(defun af/repl-go ()
  (interactive)
  (let* ((current-ns (cider-current-ns)))
    (cider-interactive-eval "(do (require 'repl) (repl/go))"
                            nil
                            nil
                            `("ns" ,current-ns))))

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
  (setq cider-clojure-cli-aliases ":my/dev")
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
  (define-key cider-mode-map (kbd "C-c r") 'af/repl-go)

  ;; remove syntax highlighting for typical functions
  (setq cider-font-lock-dynamically '(deprecated))


  ;; TODO get ctrl - return working for eval
  (define-key cider-mode-map (kbd "C-RET") 'cider-eval-last-sexp)
  (set-face-attribute 'cider-error-overlay-face nil
                      :background "IndianRed"
                      :foreground "white")

  (setq cider-repl-init-code
        '("(when-let [requires (resolve 'clojure.main/repl-requires)]\n  (clojure.core/apply clojure.core/require @requires))"
          "(require 'adam.user)"))
  (remove-hook 'cider-connected-hook 'cider--maybe-inspire-on-connect)
  (setq cider-inspector-fill-frame t)
  (setq cider-inspector-pretty-print t)

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

(use-package! neil
  :config
  (setq neil-prompt-for-version-p nil
        neil-inject-dep-to-project-p t))

;; JavaScript ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq js-indent-level 2)
(setq-default js2-basic-offset 2)
(add-to-list 'auto-mode-alist '("\\.cjs\\'" . js2-mode))

;; SML ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(after! sml-mode
  (set-formatter! 'smlformat '("smlfmt") :modes '(sml-mode))
  )
;; AwesomeWM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(after! friar
  ;; M-x friar gives you a fennel REPL that can connect to a running awesomeWM instance
  ;; it seems like you should run it from a non-daemon Emacs instance
  (setq friar-fennel-file-path "~/.local/bin/fennel"))

;; ChatGPT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; '(recentf-exclude
;; '("/\\(\\(\\(COMMIT\\|NOTES\\|PULLREQ\\|MERGEREQ\\|TAG\\)_EDIT\\|MERGE_\\|\\)MSG\\|\\(BRANCH\\|EDIT\\)_DESCRIPTION\\)\\'" "^/run/user/1000" "^/var/home/adam/nas"))

(after! writeroom-mode
  (setq writeroom-width 40))
