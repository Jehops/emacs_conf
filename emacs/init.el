;;; -*- lexical-binding: t -*-
                              
(setq gc-cons-threshold most-positive-fixnum)
(add-to-list 'load-path "~/.emacs.d/elisp/")
(require 'benchmark-init-loaddefs)
(benchmark-init/activate)
(add-hook 'after-init-hook 'benchmark-init/deactivate)

(unless package--initialized (package-initialize t))

;; custom set varaibles --------------------------------------------------------
;; tell customize to use ' instead of (quote ..) and #' instead of (function ..)
(advice-add 'custom-save-all
            :around (lambda (orig) (let ((print-quoted t)) (funcall orig))))

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

(load-file "~/.emacs.d/secret.el")

;; exwm
;; (require 'exwm)
;; (require 'exwm-randr)

;; (exwm-input-set-key (kbd "C-t") #'exwm-reset)

;; (add-hook 'exwm-update-class-hook
;;           (lambda ()
;;             (exwm-workspace-rename-buffer exwm-class-name)))

;; (setq exwm-randr-workspace-output-plist '(0 "LVDS1" 1 "VGA1")
;;       exwm-workspace-show-all-buffers t
;;       exwm-layout-show-all-buffers t
;;       exwm-input-line-mode-passthrough t)
;; (add-hook 'exwm-randr-screen-change-hook
;;           (lambda ()
;;             (start-process-shell-command
;;              "xrandr" nil "xrandr --output VGA1 --above LVDS1 --auto")))
;; (defun jrm/exwm-launch (command)
;;   (interactive (list (read-shell-command "$ ")))
;;   (start-process-shell-command command nil command))

;; (exwm-randr-enable)

;; (require 'exwm-systemtray)
;; (exwm-systemtray-enable)

;; (exwm-enable)

;; variables that can't be customized ------------------------------------------
(setq scpaste-http-destination "http://ftfl.ca/paste"
      scpaste-scp-destination  "gly:/www/paste"
      scpaste-user-name        "jrm"
      org-irc-link-to-logs     t)
(setq scpaste-make-name-function 'scpaste-make-name-from-buffer-name)

;; enable some functions that are disabled by default --------------------------
(put 'dired-find-alternate-file 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'set-goal-column 'disabled nil)
(put 'upcase-region 'disabled nil)

;; quick buffer switching by mode ----------------------------------------------
(defun jrm/sbm (prompt mode-list)
  "PROMPT for buffers that have a major mode matching an element of MODE-LIST."
  (let ((blist
         (delq nil
               (mapcar
                (lambda (buf)
                  (with-current-buffer buf
                    (and (member major-mode mode-list) (buffer-name buf))))
                (buffer-list)))))
    (if (null blist)
      nil
      (switch-to-buffer (completing-read prompt blist nil t)))))

(defun jrm/sb-dired   ()
  (interactive)
  (unless (jrm/sbm "Dired: "  '(dired-mode))
    (when (y-or-n-p "No dired buffer.  Open one? ")
      (dired (read-directory-name "Directory: ")))))
(defun jrm/sb-erc     ()
  (interactive)
  (unless (jrm/sbm "Erc: "    '(erc-mode))
    (when (y-or-n-p "ERC is not running.  Start it? ") (jrm/erc))))
(defun jrm/sb-eshell  ()
  "Call multi-eshell if necessary, otherwise just call jrm/sb for eshell."
  (interactive)
  (unless (jrm/sbm "Eshell: " '(eshell-mode))
    (when (y-or-n-p "No eshell buffer.  Start one? ") (multi-eshell 1))))
(defun jrm/sb-gnus    ()
  "Start Gnus if necessary, otherwise call jrm/sb for Gnus
buffers."
  (interactive)
  (autoload 'gnus-alive-p "gnus-util")
  (if
      (null (gnus-alive-p))
      (when (y-or-n-p "Gnus is not running.  Start it? ") (gnus-unplugged))
    (jrm/sbm "Gnus: "   '(gnus-group-mode
                          gnus-summary-mode
                          gnus-article-mode
                          message-mode))))
(defun jrm/sb-magit   () (interactive) (jrm/sbm "Magit: "  '(magit-diff-mode
                                                             magit-log-mode
                                                             magit-process-mode
                                                             git-rebase-mode
                                                             magit-revision-mode
                                                             magit-status-mode)))
(defun jrm/sb-notmuch    ()
  "Open a notmuch-hello buffer if necessary, otherwise call
jrm/sb for Notmuch buffers."
  (interactive)
  (if
      (null (get-buffer "*notmuch-hello*"))
      (notmuch)
    (jrm/sbm "Notmuch: " '(notmuch-hello-mode
                           notmuch-search-mode
                           notmuch-show-mode
                           notmuch-tree-mode))))
(defun jrm/sb-pdf     () (interactive) (jrm/sbm "PDF: "    '(pdf-view-mode)))
(defun jrm/sb-rt ()
  (interactive)
  (unless (jrm/sbm "R/TeX: "  '(ess-mode
                                inferior-ess-r-mode
                                latex-mode))
    (when (y-or-n-p "No R buffer.  Start R? ") (R))))
(defun jrm/sb-term    () (interactive) (jrm/sbm "Term: "   '(term-mode)))
(defun jrm/sb-twit    () (interactive) (jrm/sbm "Twit: "   '(twittering-mode)))
(defun jrm/sb-scratch () (interactive) (switch-to-buffer   "*scratch*"))

(defun jrm/split-win-right-focus ()
  "Split window right and switch focus to it."
  (interactive)
  (split-window-right)
  (windmove-right))

(defun jrm/split-win-below-focus ()
  "Split window below and switch focus to it."
  (interactive)
  (split-window-below)
  (windmove-down))

;; via offby1
(defun buffer-fname-to-kill-ring (use-backslashes)
  "Add buffer's file name to the kill ring.
When no file is being visit, add the associated directory to the
kill ring.  With an argument, USE-BACKSLASHES instead of forward
slashes."
  (interactive "P")
  (let ((fn (subst-char-in-string
             ?/
             (if use-backslashes ?\\ ?/)
             (or
              (buffer-file-name (current-buffer))
              (expand-file-name default-directory)))))
    (when (null fn)
      (error "Buffer is not associated with any file or directory"))
    (kill-new fn)
    (message "%s" fn)
    fn))

(defun jrm/getmail ()
  "Call make in the current directory."
  (interactive)
  (call-process-shell-command "getmail"))

(defun jrm/make ()
  "Call make in the current directory."
  (interactive)
  (call-process-shell-command "make"))

(defun jrm/sort-lines-nocase ()
  "Sort lines ignoring case."
  (interactive)
  (let ((sort-fold-case t))
    (call-interactively 'sort-lines)))

;; ace-link for various modes --------------------------------------------------
;; needs to be evaluated after init so gnus-*-mode-map are defined
;; (add-hook 'after-init-hook
;;           (lambda ()
;;             (require 'ert)
;;             (ace-link-setup-default (kbd "C-,"))
;;             (define-key ert-results-mode-map  (kbd "C-,") 'ace-link-help)
;;             (define-key gnus-summary-mode-map (kbd "C-,") 'ace-link-gnus)
;;             (define-key gnus-article-mode-map (kbd "C-,") 'ace-link-gnus)))
(ace-link-setup-default (kbd "C-,"))
(with-eval-after-load 'ert
  (define-key ert-results-mode-map  (kbd "C-,") 'ace-link-help))
(with-eval-after-load 'gnus
  (define-key gnus-summary-mode-map (kbd "C-,") 'ace-link-gnus))
(with-eval-after-load 'gnus-art
  (define-key gnus-summary-mode-map (kbd "C-,") 'ace-link-gnus))

;; appointments in the diary (commented b/c using org-mode exclusively now -----
;; without after-init-hook, customized holiday-general-holidays is not respected
;; (add-hook 'after-init-hook (lambda () (appt-activate 1)))

;; beacon ----------------------------------------------------------------------
;;(beacon-mode 1)

;; c/c++ -----------------------------------------------------------------------
(with-eval-after-load 'cc-mode
  (require 'cquery)
  (push 'company-lsp company-backends))

(add-hook 'c-mode-common-hook 'google-set-c-style)
(add-hook 'c-mode-common-hook 'google-make-newline-indent)
(add-hook 'c-mode-common-hook 'lsp)
(add-hook 'c-mode-common-hook 'flycheck-mode)

(defun knf ()
  "Set up kernel normal form.  See style(9) on FreeBSD."
  (interactive)
  ;; Basic indent is 4 spaces
  (make-local-variable 'c-basic-offset)
  (setq c-basic-offset 4)
  ;; Continuation lines are indented 8 spaces
  (make-local-variable 'c-offsets-alist)
  (c-set-offset 'arglist-cont 8)
  (c-set-offset 'arglist-cont-nonempty 8)
  (c-set-offset 'statement-cont 8)
  ;; Labels are flush to the left
  (c-set-offset 'label [0])
  ;; Fill column
  (make-local-variable 'fill-column)
  (define-key c-mode-map (kbd "C-c c") 'compile))
;;(add-hook 'c-mode-common-hook (lambda () (flyspell-prog-mode) (knf)))

;; calfw -----------------------------------------------------------------------
;; Only load calfw after custom-set variables are loaded, otherwise unwated
;; holidays will be shown in calfw and calendar.  This happends because calfw
;; calls (require 'holiday), which sets calendar-holidays using values of,
;; e.g. holiday-bahai-holidays, before they are set to nil.
;; (add-hook 'after-init-hook
;;           (lambda ()
;;             (require 'calfw)
;;             (require 'calfw-cal)
;;             (require 'calfw-org)

;;             (defun jrm/open-calendar ()
;;               (interactive)
;;               (cfw:open-calendar-buffer
;;                :contents-sources
;;                (list
;;                 (cfw:org-create-source "OliveDrab4")
;;                 (cfw:cal-create-source "DarkOrange3"))))))

(defun jrm/open-calendar ()
  (require 'calfw)
  (require 'calfw-cal)
  (require 'calfw-org)

  (interactive)
  (cfw:open-calendar-buffer
   :contents-sources
   (list
    (cfw:org-create-source "OliveDrab4")
    (cfw:cal-create-source "DarkOrange3"))))

;; dired / dired+ --------------------------------------------------------------
;;(with-eval-after-load 'dired
;;  (require 'dired+))
;  (toggle-diredp-find-file-reuse-dir 1))

;; erc -------------------------------------------------------------------------
(with-eval-after-load 'erc
  (require 'erc-tex)

  (erc-track-minor-mode) ;; this will turn on erc-track-mode

  ;; track query buffers as if everything contains current nick
  (defadvice erc-track-find-face
      (around erc-track-find-face-promote-query activate)
    (if (erc-query-buffer-p)
        (setq ad-return-value (intern "erc-current-nick-face"))
      ad-do-it))
  (defadvice erc-track-modified-channels
      (around erc-track-modified-channels-promote-query activate)
    (if (erc-query-buffer-p) (setq erc-track-priority-faces-only 'nil))
    ad-do-it
    (if (erc-query-buffer-p) (setq erc-track-priority-faces-only 'all)))

(defun jrm/erc-generate-log-file-name-network (buffer target nick server port)
  "Generate erc BUFFER log file, TARGET for user NICK on SERVER:PORT.
Using the network name rather than server name.  This results in
a file name of the form channel@network.txt.  This function is a
possible value for `erc-generate-log-file-name-function'."
  (require 'erc-networks)
  (let ((file
         (concat
          (if target (s-replace "#" "" target))
          "@"
          (or (with-current-buffer buffer (erc-network-name)) server) ".txt")))
    ;; we need a make-safe-file-name function.
    (convert-standard-filename file)))

(defun jrm/erc-open-log-file ()
  "Open the log file for the IRC channel in the current buffer."
  (interactive)
  (require 'erc-networks)
  (if (string= major-mode "erc-mode")
      (find-file (erc-current-logfile))
    (message "This is not an ERC channel buffer."))))

;; (defun jrm/update-erc-fill-column ()
;;   "Set erc-fill-column to a value just smaller than the window width."
;;   (setq erc-fill-column (- (window-body-width) 2)))

;;(add-hook 'window-configuration-change-hook 'jrm/update-erc-fill-column)

(defun jrm/erc ()
  "Connect to irc networks set up in my znc bouncer."
  (interactive)
  (znc-erc "network-slug-efnet")
  (znc-erc "network-slug-freenode"))


;; eshell ----------------------------------------------------------------------
;; Could not get this working as an alias
(defun eshell/gp (&optional port)
  (cd (concat "~/scm/freebsd/ports/head/" port))
  nil)

(defun jrm/eshell-visual-ports-make (command args)
  "Run FreeBSD port make commands in a terminal"
  (when (and (or (string-match "scm/freebsd/ports/head" default-directory)
                 (string-match "/usr/ports" default-directory))
             (or
             (and (string-match "make" command)
                  (or (null args)
                      (string-match "config" (car args))))
             (and (or (string-match "sudo" command) (string-match "s" command))
                  (string-match "make" (car args))
                  (or (null (cdr args))
                      (string-match "config" (nth 1 args))))))
    (throw 'eshell-replace-command
           (eshell-parse-command "ls" args))))
;;(apply (eshell-exec-visual (cons command args))))))

(defun jrm/eshell-prompt ()
  "Customize the eshell prompt."
  (concat
   (propertize (user-login-name) 'face '(:foreground "gray"))
   "@"
   (propertize
    (car (split-string (system-name) "[.]")) 'face '(:foreground "gray"))
   " "
   (propertize
    (replace-regexp-in-string
     (concat "^\\(/usr\\)?/home/" (user-login-name)) "~" (eshell/pwd))
    'face '(:foreground "orange"))
   (if (= (user-uid) 0) " # " " % ")))

(defun pcomplete/gp ()
  "Completion for eshell/gp"
  (cd "~/scm/freebsd/ports/head/")
    (pcomplete-here (pcomplete-dirs)))

(defalias 'pcomplete/sudo 'pcomplete/xargs)
(defalias 'pcomplete/s 'pcomplete/xargs)

(defconst pcmpl-pkg-commands
  '("add" "annotate" "audit" "autoremove" "backup" "check" "clean" "config"
    "convert" "create" "delete" "fetch" "help" "info" "install" "lock" "plugins"
    "query" "register" "remove" "repo" "rquery" "search" "set" "ssh" "shell"
    "shlib" "stats" "unlock" "update" "updating" "upgrade" "version" "which")
  "List of 'pkg' commands.")

(defconst pcmpl-pkg-cats
  '("accessibility" "arabic" "archivers" "astro" "audio" "benchmarks" "biology"
    "cad" "chinese" "comms" "converters" "databases" "deskutils" "devel"
    "distfiles" "dns" "editors" "emulators" "finance" "french" "ftp" "games"
    "german" "graphics" "hebrew" "hungarian" "irc" "japanese" "java" "korean"
    "lang" "mail" "math" "misc" "multimedia" "net" "net-im" "net-mgmt" "net-p2p"
    "news" "old_ports" "packages" "palm" "polish" "ports-mgmt" "portuguese"
    "print" "russian" "science" "security" "shells" "sysutils" "textproc"
    "ukrainian" "vietnamese" "www" "x11" "x11-clocks" "x11-drivers" "x11-fm"
    "x11-fonts" "x11-servers" "x11-themes" "x11-toolkits" "x11-wm")
  "List of port categories.")

(defun pcomplete/pkg ()
  "Completion for 'pkg'."
  (pcomplete-opt "djcCRlvN")
  (pcomplete-here* pcmpl-pkg-commands)
  (cond
   ((pcomplete-match "info" 1)
    "Completion for 'pkg info'."
    (pcomplete-opt "aAfReDgixdrklbBsqOEopF")
    (pcomplete-here*
     (split-string (shell-command-to-string "pkg info -q") "\n" t)))
   ((pcomplete-match "which" 1)
    "Completion for 'pkg which'."
    (pcomplete-opt "qog")
    (while (pcomplete-here (pcomplete-entries))))
   ((pcomplete-match "help" 1)
    "Completion for 'pkg help'."
    (pcomplete-here* pcmpl-pkg-commands))
   ((pcomplete-match "lock" 1)
    "Completion for 'pkg lock'."
    (pcomplete-opt "aqxy")
    (pcomplete-here* pcmpl-pkg-commands))
   ((pcomplete-match "audit" 1)
    "Completion for 'pkg audit'."
    (pcomplete-opt "Fqc")
    (pcomplete-here* pcmpl-pkg-commands))
   ((pcomplete-match "autoremove" 1)
    "Completion for 'pkg autoremove'."
    (pcomplete-opt "ynq"))
   ((pcomplete-match "backup" 1)
    "Completion for 'pkg backup'."
    (pcomplete-opt "dr")
    (pcomplete-here (pcomplete-entries)))
   ((pcomplete-match "check" 1)
    "Completion for 'pkg check'."
    (pcomplete-opt "Bdsrvyna")
    (pcomplete-here* pcmpl-pkg-commands))
   ((pcomplete-match "clean" 1)
    "Completion for 'pkg clean'."
    (pcomplete-opt "anqy"))
   ((pcomplete-match "delete" 1)
    "Completion for 'pkg delete'."
    (pcomplete-opt "DfginqRxya")
    (while (pcomplete-here*
            (split-string (shell-command-to-string "pkg info -q") "\n" t))))
   ((pcomplete-match "install" 1)
    "Completion for 'pkg install'."
    (pcomplete-opt "AfIMnFqRUy")
    (let ((default-directory "/usr/ports/"))
      ;;(pcomplete-here* (pcomplete-dirs))
      (pcomplete-here*
       (split-string
        (shell-command-to-string "pkg rquery -a '%n-%v'") "\n" t))))))

(defconst pcmpl-zfs-commands
  '("allow" "bookmark" "clone" "create" "destroy"
    "diff" "get" "groupspace" "hold" "holds" "inherit" "jail" "list" "mount"
    "promote" "receive" "release" "rename" "rollback" "send" "set" "share"
    "snapshot" "unallow" "unjail" "unmount" "unshare" "upgrade" "userspace")
  "List of 'zfs' commands.")

(defun pcomplete/service ()
  "Completion for 'service'."
  (pcomplete-opt "eRlrv")
  (pcomplete-here* (split-string (shell-command-to-string "service -l") "\n" t)))

(defun pcomplete/zfs ()
  "Completion for 'zfs'."
  (pcomplete-here* pcmpl-zfs-commands)
  (cond
   ((pcomplete-match "allow" 1)
    "Completion for 'pkg allow'."
    (pcomplete-opt "ldug"))))

(add-hook 'eshell-mode-hook
          (lambda ()
            (local-set-key (kbd "C-l") (lambda () (interactive) (recenter 0)))))

(defun jrm/eshell-complete-history ()
  "Complete eshell history."
  (interactive)
  (insert (completing-read
           "Eshell history: "
           (delete-dups (ring-elements eshell-history-ring)))))

(add-hook 'eshell-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-r") 'jrm/eshell-complete-history)))


;; ess -------------------------------------------------------------------------
;;(require 'ess-site)
(with-eval-after-load 'ess-r-mode
  (define-key ess-r-mode-map "_" #'ess-insert-assign)
  (define-key inferior-ess-r-mode-map "_" #'ess-insert-assign))

;; flyspell --------------------------------------------------------------------
;; stop flyspell-auto-correct-word from hijacking C-.
;; (customizing flyspell-auto-correct-binding doesn't help)
(eval-after-load "flyspell" '(define-key flyspell-mode-map (kbd "C-.") nil))

;; garbage callection ----------------------------------------------------------
;;(defun jrm/minibuffer-setup-hook ()
;;  (setq gc-cons-threshold most-positive-fixnum))

;;(defun jrm/minibuffer-exit-hook ()
;;  (setq gc-cons-threshold 800000))

;;(add-hook 'minibuffer-setup-hook #'jrm/minibuffer-setup-hook)
;;(add-hook 'minibuffer-exit-hook  #'jrm/minibuffer-exit-hook)

;; gnus -----------------------------------------------------------------------
;; I am NO LONGER using this to coerce Gnus into sending format=flowed messages.
;; While the concept sounds clever, having the client tinker with the message
;; after it is composed is error-prone.
(defun jrm/harden-newlines ()
  "Use all hard newlines, so Gnus will use format=flowed.
Add this to message-send-hook, so that it is called before each
message is sent.  See
https://www.emacswiki.org/emacs/GnusFormatFlowed for details."
  (save-excursion
    (goto-char (point-min))
    (while (search-forward "\n" nil t)
      (put-text-property (1- (point)) (point) 'hard t))))

(defun jrm/gnus-group ()
  "Start Gnus if necessary and enter GROUP."
  (interactive)
  (unless (gnus-alive-p) (gnus))
  (let ((group (gnus-group-completing-read "Group: " gnus-active-hashtb t)))
    (gnus-group-read-group nil t group)))

;; I am not using this to coerce Gnus into sending format=flowed messages.
;; While the concept sounds clever, having the client tinker with the message
;; after it's composed is error-prone.
(defun jrm/message-setup ()
  "Compose messages in a way that is suitable for format=flowed.
That is, avoid using any hard newlines, but when the message is
sent, all the newlines will be converted to hard newlines, so
that format=flowed will be used.  I choose to wrap the message
when composing, because I want to see what is sent."
  (use-hard-newlines t 'never))

;; Gnus gets loaded on startup if gnus-select-method is customized
(with-eval-after-load 'gnus
  (setq gnus-select-method '(nnml "")))

(with-eval-after-load 'gnus-group
  ;; make quitting Emacs less interactive
  (add-hook 'kill-emacs-hook 'gnus-group-exit)
  (define-key gnus-group-mode-map (kbd "C-k") nil)
  (define-key gnus-group-mode-map (kbd "C-w") nil)
  (define-key gnus-group-mode-map (kbd "u") nil))

(with-eval-after-load 'gnus-topic
  (define-key gnus-topic-mode-map (kbd "C-k") nil))

(add-hook 'gnus-summary-mode-hook 'hl-line-mode)

(defun jrm/toggle-personal-work-message-fields ()
  "Toggle message fields for personal and work messages."
  (interactive)
  (save-excursion
    (cond ((string-match (concat user-full-name " <" user-mail-address ">")
                         (message-field-value "From" t))
           (progn
             (message-remove-header "From")
             (message-add-header (concat "From: " user-full-name
                                         " <" user-work-mail-address ">"))
             (message-add-header (concat "X-Message-SMTP-Method: smtp "
                                         work-smtp-server " 587"))
             (unless (string-match (message-field-value "Gcc" t)
                                   user-work-mail-folder)
               (message-remove-header "Gcc")
               (message-add-header (concat "Gcc: " user-work-mail-folder)))
             (turn-off-auto-fill)))

          ((string-match (concat user-full-name " <" user-work-mail-address ">")
                         (message-field-value "From" t))
           (progn
             (message-remove-header "From")
             (message-add-header (concat "From: " user-full-name
                                         " <" user-FreeBSD-mail-address ">"))
             (message-remove-header "X-Message-SMTP-Method")
             (unless (string-match (message-field-value "Gcc" t)
                                   user-FreeBSD-mail-folder)
               (message-remove-header "Gcc")
               (message-add-header (concat "Gcc: " user-FreeBSD-mail-folder)))
             (turn-on-auto-fill)))
          (t
           (message-remove-header "From")
           (message-add-header (concat "From: " user-full-name
                                       " <" user-mail-address ">"))
           (message-remove-header "X-Message-SMTP-Method")
           (unless (string-match (message-field-value "Gcc" t) "mail.misc")
             (message-remove-header "Gcc")
             (message-add-header "Gcc: mail.misc"))
           (turn-off-auto-fill)))))

(defun jrm/gnus-set-auto-fill ()
  (save-excursion
    (cond ((string-match
            (concat user-full-name " <" user-FreeBSD-mail-address ">")
            (message-field-value "From" t))
           (turn-on-auto-fill))
          (t (turn-off-auto-fill)))))

;; google ----------------------------------------------------------------------
;; Is this the only way to unset google-this-mode key binding?
;; The default conflicts with org-sparse-tree and customizing it does not work.
(setq google-this-keybind (kbd "C-<f12>"))

;; haskell-mode workaround
;; http://emacs.stackexchange.com/questions/28967/haskell-mode-hook-is-nil
(setq haskell-mode-hook nil)

;; helm ------------------------------------------------------------------------
;; (define-key global-map [remap find-file] 'helm-find-files)
;; (define-key global-map [remap occur] 'helm-occur)
;; (define-key global-map [remap switch-to-buffer] 'helm-buffers-list)
;; (define-key global-map [remap dabbrev-expand] 'helm-dabbrev)
;; (define-key global-map [remap yank-pop] 'helm-show-kill-ring)
;; (global-set-key (kbd "M-x") 'helm-M-x)
;; (unless (boundp 'completion-in-region-function)
;;   (define-key lisp-interaction-mode-map
;;     [remap completion-at-point] 'helm-lisp-completion-at-point)
;;   (define-key emacs-lisp-mode-map
;;     [remap completion-at-point] 'helm-lisp-completion-at-point))

;; ido -------------------------------------------------------------------------
;; (ido-mode t)
;; (ido-everywhere 1)
;; (ido-ubiquitous-mode 1)
;; (ido-vertical-mode 1)
;; (setq ido-vertical-define-keys 'C-n-and-C-p-only)
;; (setq ido-vertical-show-count t)

;; ivy
;; (run-with-idle-timer 1 nil (lambda () (ivy-mode) (counsel-mode)))

(defun jrm/cf-as-root ()
  "Visit the current file with root privileges."
  (interactive)
  ;; Check for remote host (must have sudo root access on remote host)
  (let ((x (buffer-file-name)))
    (cond
     ((null x) (message "Not visiting a file."))
     ((file-writable-p buffer-file-name)
      (message "The file is already writable."))
     ((string-match "^/ssh:\\(.*\\):\\(.*\\)" x)
      (let ( (host (match-string 1 x))
             (path (match-string 2 x)))
        (find-alternate-file (concat "/ssh:" host "|sudo:" host ":" path))))
     (t (find-alternate-file (concat "/sudo::" x))))))

(defun jrm/counsel-find-file-cd-bookmark-action (_)
  "Reset `counsel-find-file' from selected directory."
  (require 'bookmark)
  (bookmark-maybe-load-default-file)
  (ivy-read ": "
       (delq nil (mapcar #'bookmark-get-filename (copy-sequence bookmark-alist)))
       :action (lambda (x)
                 (let ((default-directory (file-name-directory x)))
                   (counsel-find-file)))))

(defun jrm/confirm-delete-file (x)
  (dired-delete-file x 'top))

(defun jrm/ff-as-root (x)
  ;; Check for remote host (must have sudo root access on remote host)
  (if (string-match "^/ssh:\\(.*\\):\\(.*\\)" x)
      (let ( (host (match-string 1 x))
             (path (match-string 2 x)))
        (find-file (concat "/ssh:" host "|sudo:" host ":" path)))
    (find-file (concat "/sudo::" x))))

(with-eval-after-load "counsel"
  (define-key ivy-minibuffer-map (kbd "C-.") 'ivy-avy)
  (define-key global-map [remap yank-pop] 'counsel-yank-pop)

  (ivy-add-actions
   'counsel-find-file
   `(("b" jrm/counsel-find-file-cd-bookmark-action "bookmark")
     ("r" jrm/ff-as-root "root")
     ("d" jrm/confirm-delete-file "delete")))

  (ivy-add-actions
   'counsel-notmuch
   `(("g" jrm/notmuch-message-to-gnus-article "Gnus")))

  (ivy-set-actions
   'counsel-yank-pop
   '(("t" kill-new "top"))))

;; Does not work, ivy caches something about ivy-height
;; (add-hook 'window-configuration-change-hook
;;           (lambda () (set-variable 'ivy-height
;;                                    (max (/ (window-total-height) 2) 10))))

;; ivy-bibtex -----------------------------------------------------------------
(setq bibtex-completion-bibliography '("~/scm/references.git/refs.bib"))

;; igor -----------------------------------------------------------------------
(with-eval-after-load 'flycheck
  (flycheck-define-checker igor
    "FreeBSD Documentation Project sanity checker.

  See URLs http://www.freebsd.org/docproj/ and
  http://www.freshports.org/textproc/igor/."
    :command ("igor" "-X" source-inplace)
    :error-parser flycheck-parse-checkstyle
    :modes (nxml-mode)
    :standard-input t))

  ;; register the igor checker for automatic syntax checking
  ;;(add-to-list 'flycheck-checkers 'igor 'append))

;; keybindings -----------------------------------------------------------------

;; general stuff
(global-set-key (kbd "M-<f4>")          'save-buffers-kill-emacs)
(global-set-key (kbd "<f12>")           'jrm/make)
(global-set-key (kbd "C-c g")           'jrm/getmail)
(global-set-key (kbd "C-c r")           'jrm/cf-as-root)
(global-set-key (kbd "C-c s")           'swiper)
(global-unset-key (kbd "C-h"))
(global-set-key (kbd "C-x h")           'help-command) ; help-key should be set
(global-set-key (kbd "C-x p")           'list-packages)
;;(global-set-key (kbd "C-<tab>")         'helm-dabbrev)
(global-set-key (kbd "C-<tab>")         'company-complete)
(global-set-key (kbd "M-SPC")           'cycle-spacing)

;; buffers and windows
(global-set-key (kbd "C-x C-b")         'ibuffer)
(global-set-key (kbd "C-x K")           'kill-buffer-and-its-windows)
(global-set-key (kbd "C-x o")           'ace-window)
(global-set-key (kbd "C-0")             'buffer-fname-to-kill-ring)
(global-set-key (kbd "C-c m")           'magit-status)
(global-set-key (kbd "C-c e c")         'multi-eshell)
(global-set-key (kbd "C-c o a")         'org-agenda)
(global-set-key (kbd "C-c o b")         'org-iswitchb)
(global-set-key (kbd "C-c o c")         'org-capture)
(global-set-key (kbd "C-c o l")         'org-store-link)
(global-set-key (kbd "C-c W")           'wttrin)

;; erc
(global-set-key
 (kbd "C-c i")
 (defhydra hydra-erc (:color blue)
   "erc"
   ("c"                         jrm/erc                     "connect")
   ("l"                         jrm/erc-open-log-file       "log")))

;; switching buffers
(global-set-key
 (kbd "C-c b")
 (defhydra hydra-buf (:color blue)
   "buf switch"
   ("C"                         jrm/open-calendar           "cfw")
   ("c"                         calendar                    "cal")
   ("d"                         jrm/sb-dired                "dired")
   ("i"                         jrm/sb-erc                  "erc")
   ("e"                         jrm/sb-eshell               "eshell")
   ("g"                         jrm/sb-gnus                 "Gnus")
   ("G"                         jrm/gnus-group              "Group")
   ("m"                         jrm/sb-magit                "magit")
   ("n"                         jrm/sb-notmuch              "notmuch")
   ("p"                         jrm/sb-pdf                  "pdf")
   ("r"                         jrm/sb-rt                   "R")
   ("s"                         jrm/sb-scratch              "scratch")
   ("t"                         jrm/sb-term                 "term")
   ("w"                         jrm/sb-twit                 "twit")))

;; moving resizing buffers and windows
(global-set-key
 (kbd "C-c w")
 (defhydra hydra-window ()
   "buf/win"
   ("h"                         windmove-left               "wleft"  :color blue)
   ("l"                         windmove-right              "wright" :color blue)
   ("j"                         windmove-down               "wdown"  :color blue)
   ("k"                         windmove-up                 "wup"    :color blue)
   ("H"                         buf-move-left               "bleft"  :color blue)
   ("L"                         buf-move-right              "bright" :color blue)
   ("J"                         buf-move-down               "bdown"  :color blue)
   ("K"                         buf-move-up                 "bup"    :color blue)
   ("<right>"                   enlarge-window-horizontally "henlarge")
   ("<left>"                    shrink-window-horizontally  "hshrink")
   ("<up>"                      enlarge-window              "venlarge")
   ("<down>"                    shrink-window               "vshrink")
   ("o"                         ace-maximize-window         "one"    :color blue)
   ("r"                         winner-redo                 "wredo"  :color blue)
   ("s"                         ace-swap-window             "swap"   :color blue)
   ("u"                         winner-undo                 "wundo"  :color blue)
   ("3"                         jrm/split-win-right-focus   "sright" :color blue)
   ("2"                         jrm/split-win-below-focus   "sbelow" :color blue)
   ("q"                         nil                         "cancel")))

;; mark and point
(global-set-key (kbd "C-.")     'avy-goto-word-or-subword-1)
(global-set-key (kbd "M-h")     'backward-kill-word)
(global-set-key (kbd "M-?")     'mark-paragraph)
(global-set-key (kbd "M-z")     'avy-zap-to-char-dwim)
(global-set-key (kbd "M-Z")     'avy-zap-up-to-char-dwim)

;; notmuch
(autoload 'notmuch "notmuch" "notmuch mail" t)
(with-eval-after-load "notmuch"
  (define-key notmuch-show-mode-map
    (kbd "C-c C-c") 'jrm/notmuch-message-to-gnus-article)
  (define-key notmuch-tree-mode-map
    (kbd "C-c C-c") 'jrm/notmuch-message-to-gnus-article))

;; origami code folding
(global-set-key
 (kbd "C-c f")
 (defhydra hydra-origami (:color teal :hint nil)
   "
_o_pen node, _c_lose node, _n_ext fold, _p_revious fold, toggle _f_orward, \
toggle _a_ll _q_uit
"
   ("o" origami-open-node)
   ("c" origami-close-node)
   ("n" origami-next-fold)
   ("p" origami-previous-fold)
   ("f" origami-forward-toggle-node)
   ("a" origami-toggle-all-nodes)
   ("q" nil)))

;; translation to make C-h work with M-x in the minibuffer
(define-key key-translation-map (kbd "C-h") (kbd "<DEL>"))

;; toggling
(global-set-key
 (kbd "C-x t")
 (defhydra hydra-toggle (:color blue :hint nil)
   "
fly_c_heck _d_ebug _e_rc-track auto-_f_ill _g_it-gutter _h_l-line fc_i_ _l_inum \
_m_enu _p_aredit fly_s_pell _S_auron _t_runcate _v_isual _w_hitspace _q_uit"
   ("c"  flycheck-mode)
   ("d"  toggle-debug-on-error)
   ("e"  erc-track-mode)
   ("f"  auto-fill-mode)
   ("g"  git-gutter:toggle)
   ("h"  hl-line-mode)
   ("i"  fci-mode)
   ("l"  linum-mode)
   ("m"  menu-bar-mode)
   ("p"  paredit-mode)
   ("s"  flyspell-mode)
   ("S"  sauron-toggle-hide-show)
   ("t"  toggle-truncate-lines)
   ("v"  visual-line-mode)
   ("w"  whitespace-mode)
   ("q"  nil)))

;; tramp
(run-with-idle-timer 1 nil (lambda () (require 'tramp)))
(with-eval-after-load 'tramp
  (setq tramp-use-ssh-controlmaster-options nil))

;; vcs
(global-set-key
 (kbd "C-c v")
 (defhydra hydra-vcs (:color blue)
   "vcs"
   ("h"                         git-gutter:popup-hunk       "popup-hunk")
   ("m"                         magit-status                "magit")
   ("n"                         git-gutter:next-hunk        "next-hunk")
   ("p"                         git-gutter:previous-hunk    "previous-hunk")
   ("r"                         git-gutter:revert-hunk      "revert-hunk")
   ("s"                         git-gutter:previous-hunk    "stage-hunk")
   ("q"                         nil                         "cancel")))

;; Google
(global-set-key
 (kbd "C-c G")
 (defhydra hydra-google (:color blue)
   "Google"
   ("RET" google-this                      "prompt")
   ("SPC" google-this-noconfirm            "noconfirm")
   ("f"   google-this-forecast             "forecast")
   ("i"   google-this-lucky-and-insert-url "lucky+intert")
   ("w"   google-this-word                 "word")
   ("s"   google-this-symbol               "symbol")
   ("e"   google-this-error                "error")
   ("l"   google-this-line                 "line")
   ("r"   google-this-region               "region")
   ("m"   google-maps                      "maps")
   ("T"   google-translate-at-point        "t8 point")
   ("t"   google-translate-query-translate "t8")
   ("R"   google-this-cpp-reference        "cpp-ref")
   ("L"   google-this-lucky-search         "lucky")
   ("R"   google-this-ray                  "ray")
   ("q"   nil                              "cancel")))

;; webjump
(global-set-key (kbd "C-c j") 'webjump)

(defun cperl-mode-keybindings ()
  "Additional keybindings for 'cperl-mode'."
  (local-set-key (kbd "C-c c") 'cperl-check-syntax)
  (local-set-key (kbd "M-n")   'next-error)
  (local-set-key (kbd "M-p")   'previous-error))

;; key chords ------------------------------------------------------------------
;;(key-chord-mode 1)
;;(key-chord-define-global "jf" 'forward-to-word)
;;(key-chord-define-global "jb" 'backward-to-word)
;;(key-chord-define-global "jg" 'avy-goto-line)
;;(key-chord-define-global "jx" 'multi-eshell)

;; lsp (language server protocol) ----------------------------------------------
(add-hook 'lsp-mode-hook
          (lambda ()
            (lsp-ui-mode)
            (local-set-key
             (kbd "C-c l")
             (defhydra hydra-lsp (:color blue :hint nil)
   "
_d_efinition _i_menu _p_op _r_eferences _s_ideline _q_uit"
   ("d"  lsp-ui-peek-find-definitions)
   ("i"  lsp-ui-imenu)
   ("p"  xref-pop-marker-stack)
   ("r"  lsp-ui-peek-find-references)
   ("s"  lsp-ui-sideline-mode)
   ("q"  nil)))))

;; magithub --------------------------------------------------------------------
;; (with-eval-after-load 'magit
;;   (require 'magithub)
;;   (magithub-feature-autoinject t)
;;   (setq ghub-username 'Jehops))

;; magit-todo --------------------------------------------------------------------
;;(with-eval-after-load 'magit
;;  (magit-todos-mode))

;; misc is part of emacs; for forward/backward-to-word -------------------------
(require 'misc)

;; mozrepl ---------------------------------------------------------------------
(autoload 'moz-minor-mode "moz" "Mozilla Minor and Inferior Mozilla Modes" t)

(add-hook 'javascript-mode-hook 'javascript-custom-setup)
(add-hook 'js-mode-hook 'javascript-custom-setup)
(defun javascript-custom-setup () (moz-minor-mode 1))

;; multi-term ------------------------------------------------------------------
(add-hook 'term-mode-hook (lambda () (setq show-trailing-whitespace nil)))
(autoload 'multi-term "multi-term" nil t)
(autoload 'multi-term-next "multi-term" nil t)

;;multi-web-mode for lon-capa problems ----------------------------------------
;;(add-hook 'after-init-hook (lambda ()
;;                             (multi-web-global-mode 1)))

;; noweb -----------------------------------------------------------------------
;;(add-hook 'LaTeX-mode-hook '(lambda ()
;;                              (if (string-match "\\.Rnw\\'" buffer-file-name)
;;                                  (setq fill-column 80))))

;; org-mode --------------------------------------------------------------------
(with-eval-after-load 'org
  (org-clock-persistence-insinuate)
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

;; notmuch ---------------------------------------------------------------------
(defun jrm/notmuch-message-to-gnus-article ()
  "Open a summary buffer containing the current notmuch article."
  (interactive)
  (autoload 'org-gnus-follow-link "org-gnus")
  (let ((group
         (replace-regexp-in-string
          "/" "."
          (replace-regexp-in-string
           "Stashed: /home/jrm/Mail/\\(.*\\)/[[:digit:]]+" "\\1"
           (notmuch-show-stash-filename))))
        (article
         (replace-regexp-in-string
          "[^[:digit:]]*\\([[:digit:]]+\\)" "\\1"
          (notmuch-show-stash-filename))))
    (if (and group article)
        (org-gnus-follow-link group article)
      (message "Unable to switch to Gnus article."))))

;; nov.el
(add-to-list 'auto-mode-alist '("\\.[eE][pP][uU][bB]\\'" . nov-mode))

;; pdf-tools -------------------------------------------------------------------
(load "pdf-tools-init.el")

;; perl ------------------------------------------------------------------------
(defalias 'perl-mode 'cperl-mode)
;;(autoload 'perl-mode "cperl-mode" "alternate mode for editing Perl programs" t)
(add-hook 'cperl-mode-hook 'cperl-mode-keybindings)
(setq cperl-close-paren-offset -4)
(setq cperl-continued-statement-offset 0)
(setq cperl-extra-newline-before-brace nil)
(setq cperl-font-lock t)
;;(setq cperl-hairy t)
(setq cperl-indent-level 4)
(setq cperl-indent-parens-as-block t)
(setq cperl-tab-always-indent t)

;; php -------------------------------------------------------------------------
(autoload 'php-mode "php-mode" "Mode for editing PHP source files")
(add-to-list 'auto-mode-alist '("\\.\\(inc\\|php[s34]?\\)" . php-mode))

;; polymode --------------------------------------------------------------------
(add-to-list 'auto-mode-alist '("\\.md"  . poly-markdown-mode))
(add-to-list 'auto-mode-alist '("\\.Snw" . poly-noweb+r-mode))
(add-to-list 'auto-mode-alist '("\\.Rnw" . poly-noweb+r-mode))
(add-to-list 'auto-mode-alist '("\\.Rmd" . poly-markdown+r-mode))

;; rainbow delimeters ----------------------------------------------------------
;;(global-rainbow-delimiters-mode)

;; registers -------------------------------------------------------------------
(set-register ?2 '(file . "~/files/edu/classes/STAT2080/TA/"))
(set-register ?a '(file . "~/scm/freebsd/core.git/agenda/agenda.txt"))
(set-register ?c '(file . "~/scm/org.git/core.org"))
(set-register ?C '(file . "~/scm/org.git/capture.org"))
(set-register ?d '(file . "~/scm/org.git/diary.org"))
(set-register ?g '(file . "~/scm/freebsd/ports/head"))
(set-register ?i '(file . "~/.emacs.d/init.el"))
(set-register ?P '(file . "~/files/crypt/passwords.org.gpg"))
(set-register ?p '(file . "~/scm/org.git/personal.org"))
(set-register ?r '(file . "~/scm/org.git/research.org"))
(set-register ?s '(file . "~/scm/org.git/sites.org"))
(set-register ?S '(file . "~/.emacs.d/secret.el"))
(set-register ?u '(file . "~/.emacs.d/custom.el"))
(set-register ?w '(file . "~/scm/org.git/work.org"))

;; s.el ------------------------------------------------------------------------
(require 's)

;; -----------------------------------------------------------------------------
(defadvice kill-buffer (around kill-buffer-around-advice activate)
  "Bury the scratch buffer, do not kill it."
  (let ((buffer-to-kill (ad-get-arg 0)))
    (if (equal buffer-to-kill "*scratch*")
        (bury-buffer)
      ad-do-it)))

;; sauron ----------------------------------------------------------------------
;;(require 'sauron)

(setq sauron-nick-insensitivity 5)
(setq sauron-hide-mode-line t)
(setq sauron-modules '(sauron-erc))
;; ;; (setq sauron-modules
;; ;;       '(sauron-erc sauron-org sauron-notifications sauron-twittering
;; ;;                    sauron-jabber sauron-identica sauron-elfeed))

;; old version with espeak
;; (defun jrm/saruon-speak-erc (origin prio msg props)
;;   "When ORIGIN is erc with priority at least PRIO, say MSG ignoring PROPS."
;;   (when (eq origin 'erc)
;;     (call-process-shell-command
;;      (concat "espeak " "\"ERC alert: "
;;              (replace-regexp-in-string "\\(jrm\\)?@jrm:" "" msg) "\"&") nil 0)))

;; new version with festival
;; (defun jrm/saruon-speak-erc (origin prio msg props)
;;   "When ORIGIN is erc with priority at least PRIO, say MSG ignoring PROPS."
;;   (when (eq origin 'erc)
;;     (call-process-shell-command
;;      (concat "echo " "\"IRC message: " msg "\" | festival --tts&") nil 0)))

;; new version with flite
(defun jrm/saruon-speak-erc (origin prio msg props)
  "When ORIGIN is erc with priority at least PRIO, say MSG ignoring PROPS."
  (when (eq origin 'erc)
    (call-process-shell-command
     (concat "flite -voice /home/" (user-login-name)
             "/local/share/data/flite/cmu_us_aew.flitevox \"I-R-C message: "
             msg "\"&") nil 0)))

(defun jrm/sauron-erc-events-to-block (origin prio msg props)
  "When ORIGIN is erc with priority PRIO, match MSG to block it, ignoring PROPS."
  (when (eq origin 'erc)
    (or
     (string-match "^jrm has joined" msg)
     (string-match "[[:alnum:]]+jrm" msg)
     (string-match "jrm[[:alnum:]]+" msg)
     (string-match "[[:alnum:]]+jrm[[:alnum:]]+" msg))))

(add-hook 'sauron-event-added-functions 'jrm/saruon-speak-erc)
(add-hook 'sauron-event-block-functions 'jrm/sauron-erc-events-to-block)

(with-eval-after-load 'erc
  (sauron-start-hidden))

;; scratch ---------------------------------------------------------------------
;; Do not put this in custom.el, because it screws up indentation
(setq initial-scratch-message
      (format ";; %s\n\n"
              (replace-regexp-in-string "\n" "\n;; "
                                        (shell-command-to-string
                                         "/usr/bin/fortune freebsd-tips"))))

;; slime/swank -----------------------------------------------------------------
;;(load (expand-file-name "~/.quicklisp/slime-helper.el"))
;;(setq inferior-lisp-program "~/local/bin/sbcl")

;;(require 'slime)
(with-eval-after-load 'slime
  (slime-setup '(slime-company slime-fancy)))

;; smart mode line -------------------------------------------------------------
;; without after-init-hook there is always a warning about loading a theme
;;(add-hook 'after-init-hook 'sml/setup)
(sml/setup)

;; transpar (transpose-paragraph-as-table) -------------------------------------
;;(require 'transpar)
(autoload 'transpose-paragraph-as-table "transpar"
  "Transpose paragraph as table." t)

;; twittering-mode -------------------------------------------------------------
(add-hook 'twittering-edit-mode-hook
          (lambda () (ispell-minor-mode) (flyspell-mode)))

;; undo-tree -------------------------------------------------------------------
(global-undo-tree-mode)

;; yasnippet -------------------------------------------------------------------
;; (yas-global-mode)

;; yes-or-no--------------------------------------------------------------------
(fset 'yes-or-no-p 'y-or-n-p)

(setq gc-cons-threshold 800000)
