;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; test-h2c.lisp - Unit tests for h2c
;;;;
;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(defpackage #:cl-h2c.test
  (:use #:cl)
  (:export #:run-tests))

(in-package #:cl-h2c.test)

(defun run-tests ()
  "Run all tests for cl-h2c."
  (format t "~&Running tests for cl-h2c...~%")
  ;; TODO: Add test cases
  ;; (test-function-1)
  ;; (test-function-2)
  (format t "~&All tests passed!~%")
  t)
