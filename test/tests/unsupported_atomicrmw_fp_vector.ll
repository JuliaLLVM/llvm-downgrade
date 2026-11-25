; VERSIONS: 14.0 18.0
; Floating-point vector atomicrmw operands are LLVM 19+; the LLVM 14 and 18
; verifiers reject them.
; XFAIL-AS: atomicrmw on a vector is not supported
define <2 x float> @f(ptr %p, <2 x float> %v) {
  %r = atomicrmw fadd ptr %p, <2 x float> %v monotonic
  ret <2 x float> %r
}
