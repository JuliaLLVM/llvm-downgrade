; VERSIONS: 5.0 7.0
; MIN-LLVM: 15
; Intrinsics with pointer parameters and no known typed legacy signature
; would be emitted with {}* arguments against the old typed signatures
; ("Intrinsic has incorrect argument type!"); they are rejected loudly.
; XFAIL-AS: intrinsic with pointer arguments cannot be downgraded
define <4 x i32> @f(ptr %p, <4 x i1> %mask) {
  %v = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %mask, <4 x i32> zeroinitializer)
  ret <4 x i32> %v
}
declare <4 x i32> @llvm.masked.load.v4i32.p0(ptr, i32, <4 x i1>, <4 x i32>)
