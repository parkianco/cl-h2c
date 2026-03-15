;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(load "cl-h2c.asd")
(handler-case
  (progn
    (asdf:test-system :cl-h2c/test)
    (format t "PASS~%"))
  (error (e)
    (format t "FAIL~%")))
(quit)
