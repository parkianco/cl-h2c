;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-h2c)

;;; Core types for cl-h2c
(deftype cl-h2c-id () '(unsigned-byte 64))
(deftype cl-h2c-status () '(member :ready :active :error :shutdown))
