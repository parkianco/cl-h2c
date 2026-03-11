;;;; cl-h2c.asd
;;;; Hash-to-curve for secp256k1 - zero external dependencies

(asdf:defsystem #:cl-h2c
  :description "Hash-to-curve IETF draft for secp256k1"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
  :version "1.0.0"
  :serial t
  :components ((:file "package")
               (:module "src"
                :components ((:file "field")
                             (:file "curve")
                             (:file "sha256")
                             (:file "h2c")))))
