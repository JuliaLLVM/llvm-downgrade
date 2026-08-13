; VERSIONS: 14.0
; atomicrmw fadd/fsub exist since LLVM 9, so the 14.0 target must encode them.
define float @f(ptr %p, float %x) {
  %old = atomicrmw fadd ptr %p, float %x seq_cst
  ret float %old
}
; CHECK: atomicrmw fadd float* %{{.*}}, float %x seq_cst
