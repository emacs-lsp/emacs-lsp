;;; test-mock-lsp-server.el --- unit test utilities -*- lexical-binding: t -*-

(require 'lsp-mode)
(require 'lsp-test-utils)

;; Taken from lsp-integration-tests.el
(defconst lsp-test-location (file-name-directory (or load-file-name buffer-file-name)))

(defun register-mock-client ()
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection
                     '("emacs" "--script" "/home/necto/proj/lsp-mode/test/mock-lsp-server.el"))
    :major-modes '(awk-mode)
    :priority 100
    :server-id 'mock-server)))

(defun lsp-test-total-server-count ()
  (hash-table-count (lsp-session-folder->servers (lsp-session))))

(defun lsp-test-diag-make-summary (file-content line-number line marker)
  (with-temp-buffer
    (insert file-content)
    (goto-char (point-min))
    (forward-line line-number)
    ;; Make sure line-number is correct
    (should (string-equal (string-trim-right (thing-at-point 'line t)) line)))
  (should (eq (length marker) (length line)))
  (should (string-match "^ *\\(\\^+\\) *$" marker))
  (list :line line-number :from (match-beginning 1) :to (match-end 1)))

(defun lsp-test-diag-get-summary (diagnostic)
  (let* ((range (ht-get diagnostic "range"))
         (start (ht-get range "start"))
         (end (ht-get range "end")))
    (should (eq (ht-get start "line") (ht-get end "line")))
    (list :line (ht-get start "line")
          :from (ht-get start "character")
          :to (ht-get end "character"))))

(ert-deftest lsp-mock-server-reports-issues ()
  (let ((lsp-clients (lsp-ht)) ; clear all clients
        (lsp-enable-snippets nil) ; Avoid warning that lsp-yasnippet is not intalled
        (workspace-root (f-join lsp-test-location "fixtures/SamplesForMock"))
        (sample-file (f-join lsp-test-location "fixtures/SamplesForMock/sample.awk"))
        (initial-server-count (lsp-test-total-server-count)))
    (register-mock-client) ; register mock client as the one an only lsp client
    (lsp-workspace-folders-add workspace-root)
    (let* ((buf (find-file-noselect sample-file)))
      (unwind-protect
          (with-timeout (5 (error "Timeout trying to get diagnostics from mock server"))
            (with-current-buffer buf
              (lsp)
              ;; Make sure the server started
              (should (eq (lsp-test-total-server-count) (1+ initial-server-count)))
              (deferred:sync! (lsp-test-wait (gethash sample-file (lsp-diagnostics t))))
              (should (eq (length (gethash sample-file (lsp-diagnostics t))) 1))
              (should (equal (lsp-test-diag-get-summary (car (gethash sample-file (lsp-diagnostics t))))
                             (lsp-test-diag-make-summary (buffer-string) 1
                                                         "line 1 is here broming and here"
                                                         "               ^^^^^^^         ")))))
        (kill-buffer buf)
        (lsp-workspace-folders-remove workspace-root)))
    (with-timeout (5 (error "LSP server refuses to stop"))
      ;; Make sure the server stopped
      (deferred:sync! (lsp-test-wait (= initial-server-count (lsp-test-total-server-count)))))))