; VERSIONS: 20.0 22.0
; Floating-point vector atomicrmw operands (LLVM 19) encode natively on the
; 20.0 and 22.0 targets.
define <2 x float> @f(ptr %p, <2 x float> %v) {
  %r = atomicrmw fadd ptr %p, <2 x float> %v monotonic
  ret <2 x float> %r
}

; CHECK: atomicrmw fadd ptr %p, <2 x float> %v monotonic
