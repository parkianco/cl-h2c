# cl-h2c

Pure Common Lisp implementation of H2C

## Overview
This library provides a robust, zero-dependency implementation of H2C for the Common Lisp ecosystem. It is designed to be highly portable, performant, and easy to integrate into any SBCL/CCL/ECL environment.

## Getting Started

Load the system using ASDF:

```lisp
(asdf:load-system #:cl-h2c)
```

## Usage Example

```lisp
;; Initialize the environment
(let ((ctx (cl-h2c:initialize-h2c :initial-id 42)))
  ;; Perform batch processing using the built-in standard toolkit
  (multiple-value-bind (results errors)
      (cl-h2c:h2c-batch-process '(1 2 3) #'identity)
    (format t "Processed ~A items with ~A errors.~%" (length results) (length errors))))
```

## License
Apache-2.0
