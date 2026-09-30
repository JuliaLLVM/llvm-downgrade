; MIN-LLVM: 21  (the captures(...) attribute is LLVM 21+)
; VERSIONS: 18.0 20.0
; LLVM 18 has no captures(...): captures(none) is lowered to the legacy
; nocapture enum attribute; anything weaker is dropped. LLVM 20 knows
; captures(...), but its optimizer only looks at nocapture, so captures(none)
; is lowered there as well and only the weaker forms are kept.
define ptr @f(ptr captures(none) %p, ptr captures(address) %q, ptr captures(ret: address) %r) {
  ret ptr %r
}

; CHECK-V18: define ptr @f(ptr nocapture %p, ptr %q, ptr %r)
; CHECK-V20: define ptr @f(ptr nocapture %p, ptr captures(address) %q, ptr captures(ret: address) %r)
