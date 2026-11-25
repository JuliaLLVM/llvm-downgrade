; VERSIONS: 5.0 7.0 14.0 18.0 20.0 22.0
; MIN-LLVM: 23
; atomicrmw fmaximumnum/fminimumnum (LLVM 23) have no older encoding.
; XFAIL-AS: unsupported atomicrmw operation for the requested bitcode version: fmaximumnum
define float @f(ptr %p, float %v) {
  %r = atomicrmw fmaximumnum ptr %p, float %v monotonic
  ret float %r
}
