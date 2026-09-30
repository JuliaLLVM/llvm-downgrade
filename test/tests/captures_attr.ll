; MIN-LLVM: 21  (the captures(...) attribute is LLVM 21+)
; VERSIONS: 18.0
; LLVM 18 has no captures(...): captures(none) is lowered to the
; legacy nocapture enum attribute; anything weaker is dropped.
define void @f(ptr captures(none) %p, ptr captures(address) %q) {
  ret void
}

; CHECK: define void @f(ptr nocapture %p, ptr %q)
