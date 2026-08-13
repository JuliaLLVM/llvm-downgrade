; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; poison postdates 5.0/7.0; PoisonValue derives from UndefValue, so it is
; emitted as undef there (a sound refinement). LLVM 14 has poison natively.
define i32 @f() {
  ret i32 poison
}
define <2 x i32> @g() {
  ret <2 x i32> <i32 poison, i32 1>
}
; CHECK-V5: ret i32 undef
; CHECK-V5: ret <2 x i32> <i32 undef, i32 1>
; CHECK-V7: ret i32 undef
; CHECK-V7: ret <2 x i32> <i32 undef, i32 1>
; CHECK-V14: ret i32 poison
; CHECK-V14: ret <2 x i32> <i32 poison, i32 1>
