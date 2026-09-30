; VERSIONS: 20.0
; MIN-LLVM: 23
; LLVM 23 allows fast-math flags on uitofp/sitofp. LLVM 20 has no encoding for
; them, but uitofp's nneg flag must survive next to them.
define float @f(i32 %x) {
  %a = uitofp nnan nneg i32 %x to float
  %b = sitofp ninf i32 %x to float
  %c = fadd float %a, %b
  ret float %c
}
; CHECK: %a = uitofp nneg i32 %x to float
; CHECK: %b = sitofp i32 %x to float
