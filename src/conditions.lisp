;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-h2c)

(define-condition cl-h2c-error (error)
  ((message :initarg :message :reader cl-h2c-error-message))
  (:report (lambda (condition stream)
             (format stream "cl-h2c error: ~A" (cl-h2c-error-message condition)))))
