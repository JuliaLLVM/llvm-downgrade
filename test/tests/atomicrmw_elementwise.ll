; VERSIONS: 20.0 22.0
; MIN-LLVM: 23
; The elementwise modifier (LLVM 23) makes a vector atomicrmw atomic per
; element. Floating-point vector atomicrmw (LLVM 19) is atomic as a whole,
; which is strictly stronger, so the modifier is dropped.
define <2 x float> @f(ptr %p, <2 x float> %v) {
  %r = atomicrmw elementwise fadd ptr %p, <2 x float> %v monotonic
  ret <2 x float> %r
}

; CHECK: atomicrmw fadd ptr %p, <2 x float> %v monotonic
