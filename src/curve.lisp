;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; curve.lisp
;;;; secp256k1 curve arithmetic

(in-package #:cl-h2c)

;;; secp256k1 curve parameters
;;; y^2 = x^3 + 7 over F_p

(defconstant +secp256k1-a+ 0
  "secp256k1 curve parameter a.")

(defconstant +secp256k1-b+ 7
  "secp256k1 curve parameter b.")

(defconstant +secp256k1-n+
  #xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  "secp256k1 curve order.")

;;; Generator point
(defconstant +secp256k1-gx+
  #x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798)

(defconstant +secp256k1-gy+
  #x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8)

;;; Point representation: (x . y) or :infinity

(defun point-infinity-p (p)
  "Check if point is at infinity."
  (eq p :infinity))

(defun point-x (p)
  "Get x coordinate."
  (car p))

(defun point-y (p)
  "Get y coordinate."
  (cdr p))

(defun make-point (x y)
  "Create point from coordinates."
  (cons x y))

(defun point-on-curve-p (p)
  "Check if point is on secp256k1 curve."
  (if (point-infinity-p p)
      t
      (let ((x (point-x p))
            (y (point-y p)))
        ;; y^2 = x^3 + 7
        (= (fe-sqr y)
           (fe-add (fe-pow x 3) +secp256k1-b+)))))

(defun point-add (p1 p2)
  "Add two points on secp256k1."
  (cond ((point-infinity-p p1) p2)
        ((point-infinity-p p2) p1)
        (t
         (let ((x1 (point-x p1)) (y1 (point-y p1))
               (x2 (point-x p2)) (y2 (point-y p2)))
           (cond
             ;; P + (-P) = O
             ((and (= x1 x2) (= (fe-add y1 y2) 0))
              :infinity)
             ;; Point doubling
             ((and (= x1 x2) (= y1 y2))
              (point-double p1))
             ;; General addition
             (t
              (let* ((lambda-val (fe-mul (fe-sub y2 y1)
                                         (fe-inv (fe-sub x2 x1))))
                     (x3 (fe-sub (fe-sub (fe-sqr lambda-val) x1) x2))
                     (y3 (fe-sub (fe-mul lambda-val (fe-sub x1 x3)) y1)))
                (make-point x3 y3))))))))

(defun point-double (p)
  "Double a point on secp256k1."
  (if (or (point-infinity-p p)
          (zerop (point-y p)))
      :infinity
      (let* ((x (point-x p))
             (y (point-y p))
             ;; lambda = (3x^2 + a) / 2y, a = 0 for secp256k1
             (lambda-val (fe-mul (fe-mul 3 (fe-sqr x))
                                 (fe-inv (fe-mul 2 y))))
             (x3 (fe-sub (fe-sqr lambda-val) (fe-mul 2 x)))
             (y3 (fe-sub (fe-mul lambda-val (fe-sub x x3)) y)))
        (make-point x3 y3))))

(defun point-mul (k p)
  "Scalar multiplication: k * P using double-and-add."
  (let ((result :infinity)
        (addend p))
    (loop while (plusp k)
          do (when (oddp k)
               (setf result (point-add result addend)))
             (setf addend (point-double addend))
             (setf k (ash k -1)))
    result))

(defun point-neg (p)
  "Negate point: -P = (x, -y)."
  (if (point-infinity-p p)
      :infinity
      (make-point (point-x p) (fe-neg (point-y p)))))
