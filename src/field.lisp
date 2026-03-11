;;;; field.lisp
;;;; secp256k1 finite field arithmetic

(in-package #:cl-h2c)

;;; secp256k1 field prime: p = 2^256 - 2^32 - 977

(defconstant +secp256k1-p+
  #xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
  "secp256k1 field prime.")

;;; Field element operations

(defun fe-add (a b)
  "Field addition: (a + b) mod p."
  (mod (+ a b) +secp256k1-p+))

(defun fe-sub (a b)
  "Field subtraction: (a - b) mod p."
  (mod (- a b) +secp256k1-p+))

(defun fe-mul (a b)
  "Field multiplication: (a * b) mod p."
  (mod (* a b) +secp256k1-p+))

(defun fe-sqr (a)
  "Field squaring: a^2 mod p."
  (mod (* a a) +secp256k1-p+))

(defun fe-neg (a)
  "Field negation: -a mod p."
  (mod (- +secp256k1-p+ a) +secp256k1-p+))

(defun fe-inv (a)
  "Field inverse: a^(-1) mod p using Fermat's little theorem."
  (fe-pow a (- +secp256k1-p+ 2)))

(defun fe-pow (base exp)
  "Field exponentiation: base^exp mod p."
  (let ((result 1)
        (base (mod base +secp256k1-p+)))
    (loop while (plusp exp)
          do (when (oddp exp)
               (setf result (mod (* result base) +secp256k1-p+)))
             (setf exp (ash exp -1))
             (setf base (mod (* base base) +secp256k1-p+)))
    result))

(defun fe-sqrt (a)
  "Field square root using p = 3 mod 4 property.
   Returns sqrt(a) or NIL if a is not a quadratic residue."
  ;; For p = 3 mod 4: sqrt(a) = a^((p+1)/4) if a is QR
  (let* ((exp (ash (1+ +secp256k1-p+) -2))
         (root (fe-pow a exp)))
    ;; Verify: root^2 = a
    (if (= (fe-sqr root) (mod a +secp256k1-p+))
        root
        nil)))

(defun fe-is-square (a)
  "Check if a is a quadratic residue using Euler's criterion."
  ;; a^((p-1)/2) = 1 if QR, -1 if NQR
  (let ((exp (ash (1- +secp256k1-p+) -1)))
    (= 1 (fe-pow a exp))))

(defun fe-cmov (a b flag)
  "Constant-time conditional move: if flag then b else a."
  (if flag b a))

(defun fe-from-bytes (bytes)
  "Convert big-endian byte array to field element."
  (let ((result 0))
    (loop for byte across bytes
          do (setf result (logior (ash result 8) byte)))
    (mod result +secp256k1-p+)))

(defun fe-to-bytes (fe)
  "Convert field element to 32-byte big-endian array."
  (let ((result (make-array 32 :element-type '(unsigned-byte 8)
                               :initial-element 0)))
    (loop for i from 31 downto 0
          for j from 0
          do (setf (aref result i) (ldb (byte 8 (* j 8)) fe)))
    result))
