; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 22
; LLVM 22 dropped the size argument of llvm.lifetime.start/end, so the modern
; form cannot be expressed against any legacy signature (old readers upgrade
; the call by name and crash on the missing argument). The markers are pure
; optimization hints and are dropped.
define void @f() {
  %a = alloca [16 x i8]
  call void @llvm.lifetime.start.p0(ptr %a)
  call void @llvm.lifetime.end.p0(ptr %a)
  ret void
}
declare void @llvm.lifetime.start.p0(ptr)
declare void @llvm.lifetime.end.p0(ptr)

; CHECK: define void @f()
; CHECK-NOT: llvm.lifetime
; CHECK: ret void
