;; Set customize file
(setq custom-file "~/.config/emacs/.emacs.custom.el")
(load custom-file 'noerror)

(require 'package)

(load "~/.config/emacs/customize.rc/theme.rc.el")

;; Please load file before the package-initialize
(package-initialize)

;; Set config
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)
(set-frame-parameter nil 'alpha 90)
(add-to-list 'default-frame-alist '(alpha . 90))

(rc/require-theme 'gruber-darker)
