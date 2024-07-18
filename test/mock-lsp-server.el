#!/usr/bin/emacs --script
;; -*- lexical-binding: t; -*-
;; -*- coding: utf-8; -*-

(defconst server-name "mock-server")
(defconst server-version "0.0.1")

(defconst json-rpc-header
  "Content-Length: %d\r\nContent-Type: application/vscode-jsonrpc; charset=utf8\r\n\r\n")

(defun json-rpc-string (body)
  ;; 1+ - extra new-line at the end
  (format json-rpc-header  (1+ (string-bytes body)) body))

;; TODO: mock and check
;; - quick fixes
;; - highlighting
;; - folding
;; - formatting
;; - codeLens: go to def, go to use
;; - hover? does it involve source ranges?
;; - rename
(defun greeting (id)
  (json-rpc-string
   (format
    "{\"jsonrpc\":\"2.0\",\"id\":%d,\"result\":{\"capabilities\":{\"textDocumentSync\":{\"change\":2,\"save\":{\"includeText\":true},\"openClose\":true}},\"serverInfo\":{\"name\":\"%s\",\"version\":\"%s\"}}}"
    id
    server-name
    server-version)))

(defun ack (id)
  (json-rpc-string (format "{\"jsonrpc\":\"2.0\",\"id\":%d,\"result\":[]}" id)))

(defun shutdown-ack (id)
  (json-rpc-string (format "{\"jsonrpc\":\"2.0\",\"id\":%d,\"result\":null}" id)))

(defun diagnostics (for-file)
  (json-rpc-string
   (format "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument\\/publishDiagnostics\",\"params\":{\"uri\":\"%s\",\"diagnostics\":[{\"source\":\"flake8\",\"code\":\"F821\",\"range\":{\"start\":{\"line\":2,\"character\":3},\"end\":{\"line\":2,\"character\":18}},\"message\":\"F821 undefined name 'true'\",\"severity\":2},{\"source\":\"flake8\",\"code\":\"F821\",\"range\":{\"start\":{\"line\":2,\"character\":11},\"end\":{\"line\":2,\"character\":18}},\"message\":\"F821 undefined name 'false'\",\"severity\":2},{\"source\":\"flake8\",\"code\":\"F701\",\"range\":{\"start\":{\"line\":3,\"character\":4},\"end\":{\"line\":3,\"character\":10}},\"message\":\"F701 'broke' outside loop\",\"severity\":2}]}}"
           for-file)))

(defun get-id (input)
  (if (string-match "\"id\":\\([0-9]+\\)" input)
      (string-to-number (match-string 1 input))
    nil))

(defun get-file-path (input)
  (if (string-match "\"uri\":\"\\(file:\\/\\/[^,]+\\)\"," input)
      (match-string 1 input)
    nil))

(let (line stopped)
  (while (and (not stopped) (setq line (read-string "")))
    (cond
     ((string-match "method\":\"initialize\"" line)
      (princ (greeting (get-id line))))
     ((string-match "method\":\"initialized\"" line)
      ;; No need to acknowledge
      )
     ((string-match "method\":\"exit" line)
      (setq stopped t))
     ((string-match "method\":\"shutdown" line)
      (princ (shutdown-ack (get-id line))))
     ((string-match "didOpen" line)
      (princ (diagnostics (get-file-path line))))
     ((string-match "method\":\"workspace/didChangeConfiguration" line)
      ;; No need to acknowledge
      )
     ((string-match "method\":\"textDocument/didClose" line)
      ;; No need to acknowledge
      )
     ((get-id line)
      (princ (ack (get-id line))))
     ((or (string-match "Content-Length" line)
          (string-match "Content-Type" line))
      ;; Ignore header
      )
     ((string-match "^$" line)
      ;; Ignore the empty lines delimitting header and content
      )
     ((string-match "^$" line)
      ;; Ignore other empty lines
      )
     (t (error "unexpected input '%s'" line)))))
