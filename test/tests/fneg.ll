; fneg was introduced in LLVM 8; LLVM 5/7 need it lowered to fsub -0.0, x.
define float @f(float %x) {
  %n = fneg float %x
  ret float %n
}

define float @g(float %x) {
  %n = fneg fast float %x
  ret float %n
}

; CHECK-NOT: = fneg
; CHECK: fsub float -0.000000e+00, %x
; fast-math flags survive the lowering
; CHECK: fsub fast float -0.000000e+00, %x
