; VERSIONS: 5.0 7.0 14.0 18.0 20.0
; MIN-LLVM: 23
; The byte type (LLVM 23) has no legacy encoding on any target.
; XFAIL-AS: Byte types are not supported
define b8 @f(b8 %x) {
  ret b8 %x
}
