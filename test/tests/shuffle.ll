; VERSIONS: 5.0 7.0 14.0
; The shuffle mask stopped being a real operand in LLVM 11; the 7.0 writer
; used to read the out-of-bounds operand 2 and crash.
define <4 x float> @f(<4 x float> %a, <4 x float> %b) {
  %s = shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 4, i32 1, i32 5>
  ret <4 x float> %s
}
; CHECK: shufflevector <4 x float> %a, <4 x float> %b, <4 x i32> <i32 0, i32 4, i32 1, i32 5>
