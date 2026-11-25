; VERSIONS: 22.0
; LLVM 22 has the size-less llvm.lifetime.start/end the host emits, so unlike
; the older targets (see lifetime_dropped.ll) the 22.0 target keeps them.
define void @f() {
  %a = alloca [16 x i8]
  call void @llvm.lifetime.start.p0(ptr %a)
  call void @llvm.lifetime.end.p0(ptr %a)
  ret void
}
declare void @llvm.lifetime.start.p0(ptr)
declare void @llvm.lifetime.end.p0(ptr)

; CHECK: call void @llvm.lifetime.start.p0(ptr %a)
; CHECK: call void @llvm.lifetime.end.p0(ptr %a)
