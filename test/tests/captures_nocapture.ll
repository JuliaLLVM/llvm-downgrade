; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 21
; captures(...) replaced nocapture in LLVM 21. captures(none) must map to the
; legacy nocapture -- also when it is the only attribute in its group (the
; 5.0/7.0 enumerator used to drop such groups entirely) -- and weaker capture
; information must be dropped.
define void @f(ptr captures(none) %p, ptr noalias captures(none) %q, ptr captures(address) %r) {
  ret void
}
; CHECK: define void @f({}* nocapture %p, {}* noalias nocapture %q, {}* %r)
