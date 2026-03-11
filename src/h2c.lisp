;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; h2c.lisp
;;;; Hash-to-curve for secp256k1 per IETF draft-irtf-cfrg-hash-to-curve

(in-package #:cl-h2c)

;;; Constants for secp256k1_XMD:SHA-256_SSWU_RO_

;; Use defvar to avoid SBCL DEFCONSTANT-UNEQL on string constants
(defvar +default-dst+
  "QUUX-V01-CS02-with-secp256k1_XMD:SHA-256_SSWU_RO_"
  "Default Domain Separation Tag.")

(defconstant +h2c-l+ 48
  "Security parameter L = ceil((ceil(log2(p)) + k) / 8) where k=128.")

;;; Simplified SWU constants for secp256k1
;;; Z is the smallest (in abs value) non-square in F_p

(defconstant +sswu-z+
  (- +secp256k1-p+ 11)  ; Z = -11 for secp256k1
  "Simplified SWU parameter Z.")

;;; For secp256k1, we use isogeny map from E' to E
;;; E': y^2 = x^3 + A'*x + B' where A' != 0
;;; Constants for 3-isogeny

(defconstant +iso-a+
  #x3f8731abdd661adca08a5558f0f5d272e953d363cb6f0e5d405447c01a444533
  "Isogenous curve parameter A'.")

(defconstant +iso-b+
  1771
  "Isogenous curve parameter B'.")

;;; expand_message_xmd (Section 5.4.1)

(defun i2osp (n len)
  "Integer to Octet String Primitive (big-endian)."
  (let ((result (make-array len :element-type '(unsigned-byte 8)
                               :initial-element 0)))
    (loop for i from (1- len) downto 0
          for j from 0
          while (plusp n)
          do (setf (aref result i) (ldb (byte 8 0) n))
             (setf n (ash n -8)))
    result))

(defun expand-message-xmd (msg dst len-in-bytes)
  "Expand message using XMD with SHA-256.
   MSG and DST are byte arrays or strings.
   Returns LEN-IN-BYTES bytes."
  (let* ((msg-bytes (etypecase msg
                      (string (string-to-bytes msg))
                      (vector msg)))
         (dst-bytes (etypecase dst
                      (string (string-to-bytes dst))
                      (vector dst)))
         (b-in-bytes 32)  ; SHA-256 output length
         (s-in-bytes 64)  ; SHA-256 block length
         (ell (ceiling len-in-bytes b-in-bytes)))
    (when (> ell 255)
      (error "expand_message_xmd: output too large"))
    (when (> (length dst-bytes) 255)
      (error "expand_message_xmd: DST too long"))
    (let* (;; DST_prime = DST || I2OSP(len(DST), 1)
           (dst-prime (concat-bytes dst-bytes
                                    (i2osp (length dst-bytes) 1)))
           ;; Z_pad = I2OSP(0, s_in_bytes)
           (z-pad (make-array s-in-bytes :element-type '(unsigned-byte 8)
                                         :initial-element 0))
           ;; l_i_b_str = I2OSP(len_in_bytes, 2)
           (lib-str (i2osp len-in-bytes 2))
           ;; b_0 = H(Z_pad || msg || l_i_b_str || I2OSP(0, 1) || DST_prime)
           (b-0 (sha256 (concat-bytes z-pad msg-bytes lib-str
                                      (i2osp 0 1) dst-prime)))
           ;; b_1 = H(b_0 || I2OSP(1, 1) || DST_prime)
           (b-vals (make-array (1+ ell)))
           (uniform-bytes (make-array len-in-bytes
                                      :element-type '(unsigned-byte 8))))
      (setf (aref b-vals 0) b-0)
      (setf (aref b-vals 1)
            (sha256 (concat-bytes b-0 (i2osp 1 1) dst-prime)))
      ;; b_i = H(strxor(b_0, b_{i-1}) || I2OSP(i, 1) || DST_prime)
      (loop for i from 2 to ell
            for strxor = (let ((result (make-array b-in-bytes
                                                   :element-type '(unsigned-byte 8))))
                           (loop for j from 0 below b-in-bytes
                                 do (setf (aref result j)
                                          (logxor (aref b-0 j)
                                                  (aref (aref b-vals (1- i)) j))))
                           result)
            do (setf (aref b-vals i)
                     (sha256 (concat-bytes strxor (i2osp i 1) dst-prime))))
      ;; uniform_bytes = b_1 || ... || b_ell
      (loop for i from 1 to ell
            for start = (* (1- i) b-in-bytes)
            do (loop for j from 0 below (min b-in-bytes (- len-in-bytes start))
                     do (setf (aref uniform-bytes (+ start j))
                              (aref (aref b-vals i) j))))
      uniform-bytes)))

;;; hash_to_field (Section 5.3)

(defun hash-to-field (msg count &key (dst +default-dst+))
  "Hash message to COUNT field elements.
   Returns list of field elements."
  (let* ((len-in-bytes (* count +h2c-l+))
         (uniform-bytes (expand-message-xmd msg dst len-in-bytes))
         (result nil))
    (loop for i from 0 below count
          for offset = (* i +h2c-l+)
          for tv = (subseq uniform-bytes offset (+ offset +h2c-l+))
          for e = (mod (fe-from-bytes tv) +secp256k1-p+)
          do (push e result))
    (nreverse result)))

;;; Simplified SWU map (Section 6.6.2)

(defun sswu-map-to-curve-simple (u)
  "Simplified SWU map to isogenous curve E'.
   U is a field element. Returns point (x, y) on E'."
  (let* ((z +sswu-z+)
         (a +iso-a+)
         (b +iso-b+)
         ;; tv1 = 1 / (Z^2 * u^4 + Z * u^2)
         (u2 (fe-sqr u))
         (u4 (fe-sqr u2))
         (zu2 (fe-mul z u2))
         (z2u4 (fe-mul (fe-sqr z) u4))
         (tv1-denom (fe-add z2u4 zu2))
         (tv1 (if (zerop tv1-denom)
                  (fe-inv z)  ; Special case
                  (fe-inv tv1-denom)))
         ;; x1 = (-B / A) * (1 + tv1)
         (neg-b-over-a (fe-mul (fe-neg b) (fe-inv a)))
         (x1 (fe-mul neg-b-over-a (fe-add 1 tv1)))
         ;; x2 = Z * u^2 * x1
         (x2 (fe-mul zu2 x1))
         ;; gx1 = x1^3 + A*x1 + B
         (gx1 (fe-add (fe-add (fe-pow x1 3) (fe-mul a x1)) b))
         ;; gx2 = x2^3 + A*x2 + B
         (gx2 (fe-add (fe-add (fe-pow x2 3) (fe-mul a x2)) b))
         ;; If gx1 is square, use x1, else use x2
         (gx1-square (fe-is-square gx1))
         (x (if gx1-square x1 x2))
         (y2 (if gx1-square gx1 gx2))
         (y (fe-sqrt y2)))
    ;; Ensure sign of y matches sign of u
    (let ((y-final (if (= (logand u 1) (logand y 1))
                       y
                       (fe-neg y))))
      (make-point x y-final))))

;;; 3-isogeny map from E' to secp256k1

(defun iso-map (p)
  "Map point from isogenous curve E' to secp256k1.
   Using rational maps for 3-isogeny."
  (when (point-infinity-p p)
    (return-from iso-map :infinity))
  (let* ((x (point-x p))
         (y (point-y p))
         ;; Isogeny map coefficients (simplified for demonstration)
         ;; In practice, these are specific polynomial coefficients
         ;; For now, use identity approximation
         (x2 (fe-sqr x))
         (x3 (fe-mul x x2))
         ;; Numerator and denominator polynomials
         ;; These are the actual 3-isogeny map coefficients
         (k1-0 #x8e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38daaaaa8c7)
         (k1-1 #x7d3d4c80bc321d5b9f315cea7fd44c5d595d2fc0bf63b92dfff1044f17c6581)
         (k1-2 #x534c328d23f234e6e2a413deca25caece4506144037c40314ecbd0b53d9dd262)
         (k1-3 #x8e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38e38daaaaa88c)
         (k2-0 #xd35771193d94918a9ca34ccbb7b640dd86cd409542f8487d9fe6b745781eb49b)
         (k2-1 #xedadc6f64383dc1df7c4b2d51b54225406d36b641f5e41bbc52a56612a8c6d14)
         (k3-0 #x4bda12f684bda12f684bda12f684bda12f684bda12f684bda12f684b8e38e23c)
         (k3-1 #xc75e0c32d5cb7c0fa9d0a54b12a0a6d5647ab046d686da6fdffc90fc201d71a3)
         (k3-2 #x29a6194691f91a73715209ef6512e576722830a201be2018a765e85a9ecee931)
         (k3-3 #x2f684bda12f684bda12f684bda12f684bda12f684bda12f684bda12f38e38d84)
         (k4-0 #xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffff93b)
         (k4-1 #x7a06534bb8bdb49fd5e9e6632722c2989467c1bfc8e8d978dfb425d2685c2573)
         (k4-2 #x6484aa716545ca2cf3a70c3fa8fe337e0a3d21162f0d6299a7bf8192bfd2a76f)
         ;; x' = x_num / x_den
         (x-num (fe-add (fe-add (fe-add (fe-mul k1-3 x3)
                                        (fe-mul k1-2 x2))
                                (fe-mul k1-1 x))
                        k1-0))
         (x-den (fe-add (fe-add x2 (fe-mul k2-1 x)) k2-0))
         ;; y' = y * y_num / y_den
         (y-num (fe-add (fe-add (fe-add (fe-mul k3-3 x3)
                                        (fe-mul k3-2 x2))
                                (fe-mul k3-1 x))
                        k3-0))
         (y-den (fe-add (fe-add x3 (fe-mul k4-2 x2))
                        (fe-add (fe-mul k4-1 x) k4-0)))
         (new-x (fe-mul x-num (fe-inv x-den)))
         (new-y (fe-mul y (fe-mul y-num (fe-inv y-den)))))
    (make-point new-x new-y)))

;;; map_to_curve (Section 6)

(defun map-to-curve (u)
  "Map field element to secp256k1 curve point.
   Uses simplified SWU to isogenous curve + isogeny map."
  (let ((p-iso (sswu-map-to-curve-simple u)))
    (iso-map p-iso)))

;;; clear_cofactor (Section 7)

(defun clear-cofactor (point)
  "Clear cofactor. For secp256k1, h=1, so this is identity."
  point)

;;; hash_to_curve (Section 3)

(defun hash-to-curve (msg &key (dst +default-dst+))
  "Hash arbitrary message to secp256k1 curve point.
   Uses random oracle method (encode to 2 points, add)."
  (let ((u-list (hash-to-field msg 2 :dst dst)))
    (let* ((q0 (map-to-curve (first u-list)))
           (q1 (map-to-curve (second u-list)))
           (r (point-add q0 q1))
           (p (clear-cofactor r)))
      p)))
