; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; Operand bundles exist on all targets (LLVM 3.8+); pointer bundle arguments
; stay opaque, which is fine since bundles are not type-checked.
declare void @llvm.assume(i1)
define void @f(i1 %c, ptr %p) {
  call void @llvm.assume(i1 %c) [ "align"(ptr %p, i64 16) ]
  ret void
}
; CHECK: call void @llvm.assume(i1 %c) [ "align"({}* %p, i64 16) ]
