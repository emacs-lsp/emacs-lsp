;;; lsp-actionscript.el --- ActionScript Client settings         -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jen-Chieh Shen

;; Author: Jen-Chieh Shen <jcs090218@gmail.com>
;; Keywords: actionscript lsp

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

;; LSP client for ActionScript

;;; Code:

(require 'lsp-mode)

(defgroup lsp-actionscript nil
  "LSP support for ActionScript."
  :group 'lsp-mode
  :link '(url-link "https://github.com/BowlerHatLLC/vscode-as3mxml")
  :package-version `(lsp-mode . "7.1.0"))

(defcustom lsp-actionscript-sdk-path ""
  "Path to supported SDK.
See https://github.com/BowlerHatLLC/vscode-as3mxml/wiki/Choose-an-ActionScript-SDK-for-the-current-workspace-in-Visual-Studio-Code."
  :type 'string
  :group 'lsp-actionscript
  :package-version '(lsp-mode . "7.1.0"))

(defcustom lsp-actionscript-version "1.5.0"
  "Version of ActionScript language server."
  :type 'string
  :group 'lsp-actionscript
  :package-version '(lsp-mode . "7.1.0"))

(defcustom lsp-actionscript-server-download-url
  (format "https://github.com/BowlerHatLLC/vscode-as3mxml/releases/download/v%s/vscode-nextgenas-%s.vsix"
          lsp-actionscript-version lsp-actionscript-version)
  "Automatic download url for lsp-actionscript."
  :type 'string
  :group 'lsp-actionscript
  :package-version '(lsp-mode . "7.1.0"))

(defcustom lsp-actionscript-server-store-path
  (f-join lsp-server-install-dir "as3mxml")
  "The path to the file in which `lsp-actionscript' will be stored."
  :type 'file
  :group 'lsp-actionscript
  :package-version '(lsp-mode . "7.1.0"))

(defcustom lsp-actionscript-option-charset "UTF8"
  "The charset to use by the ActionScript Language server."
  :type 'string
  :group 'lsp-actionscript
  :package-version '(lsp-mode . "7.1.0"))

(defun lsp-actionscript--server-command ()
  "Startup command for ActionScript language server."
  (list "java"
        (format "-Droyalelib=%s" lsp-actionscript-sdk-path)
        (format "-Dfile.encoding=%s" lsp-actionscript-option-charset)
        "-cp"
        (format "%s/vscode-as3mxml/bundled-compiler/*;%s/vscode-as3mxml/bin/*"
                lsp-actionscript-server-store-path lsp-actionscript-server-store-path)
        "com.as3mxml.vscode.Main"))

(lsp-dependency
 'as3mxml
 '(:system "lsp-actionscript")
 `(:download :url lsp-actionscript-server-download-url
             :store-path lsp-actionscript-server-store-path))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection #'lsp-actionscript--server-command)
  :major-modes '(actionscript-mode)
  :priority -1
  :server-id 'as3mxml-ls))

(provide 'lsp-actionscript)
;;; lsp-actionscript.el ends here
