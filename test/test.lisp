;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-h2c.test
  (:use #:cl #:cl-h2c)
  (:export #:run-tests))

(in-package #:cl-h2c.test)

(defun run-tests ()
  (format t "Executing functional test suite for cl-h2c...~%")
  (assert (equal (deep-copy-list '(1 (2 3) 4)) '(1 (2 3) 4)))
  (assert (equal (group-by-count '(1 2 3 4 5) 2) '((1 2) (3 4) (5))))
  (format t "All functional tests passed!~%")
  t)
