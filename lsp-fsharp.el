;;; lsp-fsharp.el --- description -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Reed Mullanix

;; Author: Reed Mullanix <reedmullanix@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; lsp-fsharp client

;;; Code:

(require 'lsp-mode)
(require 'pcase)

(defgroup lsp-fsharp nil
  "LSP support for the F# Programming Language, using the FsharpAutoComplete server."
  :link '(url-link "https://github.com/fsharp/FsAutoComplete")
  :group 'lsp-mode
  :package-version '(lsp-mode . "6.1"))

(defcustom lsp-fsharp-server-runtime 'net-core
  "The .NET runtime to use."
  :group 'lsp-fsharp
  :type '(choice (const :tag "Use .Net Core" 'net-core)
                 (const :tag "Use Mono" 'mono)
                 (const :tag "Use .Net Framework" 'net-framework))
  :package-version '(lsp-mode . "6.1"))

(defcustom lsp-fsharp-server-install-dir (locate-user-emacs-file "fsautocomplete/")
  "Install directory for fsautocomplete server.
The slash is expected at the end."
  :group 'lsp-fsharp
  :risky t
  :type 'directory
  :package-version '(lsp-mode . "6.1"))

(defcustom lsp-fsharp-server-download-url "https://ci.appveyor.com/api/projects/fsautocomplete/fsautocomplete/artifacts/bin/pkgs/fsautocomplete.netcore.zip?branch=master"
  "Fsautocomplete download url."
  :group 'lsp-fsharp
  :risky t
  :type 'string
  :package-version '(lsp-mode . "6.1"))

(defcustom lsp-fsharp-server-args nil
  "Extra arguments for the F# language server."
  :type '(repeat string)
  :group 'lsp-fsharp
  :package-version '(lsp-mode . "6.1"))

(defun lsp-fsharp--fsac-runtime-cmd ()
  "Get the command required to run fsautocomplete based off of the current runtime."
  (pcase lsp-fsharp-server-runtime
    ('net-core "dotnet")
    ('mono "mono")
    ('net-framework nil)))

(defun lsp-fsharp--fsac-cmd ()
  "The location of fsautocomplete.dll."
  (expand-file-name "fsautocomplete.dll" lsp-fsharp-server-install-dir))

(defun lsp-fsharp--fsac-locate ()
  "Return the location of the fsautocomplete langauge server."
  (let ((fsac (lsp-fsharp--fsac-cmd)))
    (unless (file-exists-p fsac)
      (if (yes-or-no-p "Server is not installed. Do you want to install it?")
          (lsp-fsharp--fsac-install)
        (error "LSP F# cannot be started without FsAutoComplete Server"))))
  fsac)

(defun lsp-fsharp--fsac-install ()
  "Downloads the latest version of fsautocomplete, and set `lsp-fsharp-server-path'."
  (let ((temp-file (make-temp-file "fsautocomplete" nil ".zip")))
    (url-copy-file lsp-fsharp-server-download-url temp-file t)
    (if (executable-find "unzip")
        (progn
          (call-process "unzip" nil nil nil temp-file "-d" (expand-file-name lsp-fsharp-server-install-dir))
          (shell-command (format "%s %s --version" (lsp-fsharp--fsac-runtime-cmd) (lsp-fsharp--fsac-cmd))))
      (user-error "Unable to unzip server - file %s cannot be extracted, please extract it manually"))))

(defun lsp-fsharp--make-launch-cmd ()
  "Build the command required to launch fsautocomplete."
  (append (list (lsp-fsharp--fsac-runtime-cmd) (lsp-fsharp--fsac-locate) "--mode" "lsp")
          lsp-fsharp-server-args))

(defun lsp-fsharp--make-init-options ()
  "Init options for F#."
  `(:automaticWorkspaceInit true))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection 'lsp-fsharp--make-launch-cmd)
                  :major-modes '(fsharp-mode)
                  :notification-handlers (ht ("fsharp/notifyCancel" #'ignore)
                                             ("fsharp/notifyWorkspace" #'ignore)
                                             ("fsharp/fileParsed" #'ignore)
                                             ("fsharp/notifyWorkspacePeek" #'ignore))
                  :initialization-options 'lsp-fsharp--make-init-options
                  :server-id 'fsac))

(provide 'lsp-fsharp)
;;; lsp-fsharp.el ends here
