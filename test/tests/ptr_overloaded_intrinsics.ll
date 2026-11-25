; VERSIONS: 5.0 7.0 14.0 18.0 20.0 22.0
; MIN-LLVM: 23
; LLVM 21 and 23 made llvm.thread.pointer, llvm.returnaddress and
; llvm.clear_cache overloaded on their pointer type (llvm.returnaddress.p0).
; The targets only know the unmangled names; without renaming, the legacy
; reader treats the calls as calls to external functions. LLVM 22 already
; knows the mangled llvm.thread.pointer.
declare ptr @llvm.thread.pointer.p0()
declare ptr @llvm.returnaddress.p0(i32 immarg)
declare void @llvm.clear_cache.p0(ptr, ptr)

define ptr @f(ptr %a, ptr %b) {
  %t = call ptr @llvm.thread.pointer.p0()
  %r = call ptr @llvm.returnaddress.p0(i32 0)
  call void @llvm.clear_cache.p0(ptr %a, ptr %b)
  ret ptr %r
}

; CHECK-V5: call {{.*}}@llvm.thread.pointer()
; CHECK-V7: call {{.*}}@llvm.thread.pointer()
; CHECK-V14: call {{.*}}@llvm.thread.pointer()
; CHECK-V18: call {{.*}}@llvm.thread.pointer()
; CHECK-V20: call {{.*}}@llvm.thread.pointer()
; CHECK-V22: call {{.*}}@llvm.thread.pointer.p0()
; CHECK: call {{.*}}@llvm.returnaddress(i32 0)
; CHECK: call void @llvm.clear_cache(
