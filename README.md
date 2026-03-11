# cl-h2c

Hash-to-curve implementation per IETF draft-irtf-cfrg-hash-to-curve for secp256k1.
Zero external dependencies with inlined field/curve arithmetic.

## Installation

```lisp
(asdf:load-system :cl-h2c)
```

## API

- `(hash-to-curve msg &key dst)` - Hash arbitrary message to secp256k1 point
- `(hash-to-field msg count &key dst)` - Hash message to field elements
- `(expand-message-xmd msg dst len-in-bytes)` - XMD message expansion (SHA-256)
- `(map-to-curve u)` - Map field element to curve point (simplified SWU)
- `(clear-cofactor point)` - Clear cofactor (identity for secp256k1)

## Example

```lisp
(cl-h2c:hash-to-curve "test message" :dst "QUUX-V01-CS02-with-secp256k1_XMD:SHA-256_SSWU_RO_")
; => (x . y) point on secp256k1
```

## License

BSD-3-Clause - Parkian Company LLC 2024-2026
