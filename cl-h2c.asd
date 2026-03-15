;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-h2c.asd
;;;; Hash-to-curve for secp256k1 - zero external dependencies

(asdf:defsystem #:cl-h2c
  :description "Hash-to-curve IETF draft for secp256k1"
  :author "Parkian Company LLC"
  :license "Apache-2.0"
  :version "0.1.0"
  :serial t
  :components ((:file "package")
               (:module "src"
                :components ((:file "field")
                             (:file "curve")
                             (:file "sha256")
                             (:file "h2c")))))

(asdf:defsystem #:cl-h2c/test
  :description "Tests for cl-h2c"
  :depends-on (#:cl-h2c)
  :serial t
  :components ((:module "test"
                :components ((:file "test-h2c"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-h2c.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
