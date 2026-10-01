; VERSIONS: 5.0 7.0 14.0 18.0 20.0
; MIN-LLVM: 23
; LLVM 21 and 23 made llvm.thread.pointer, llvm.returnaddress and
; llvm.clear_cache overloaded on their pointer type (llvm.returnaddress.p0).
; The targets only know the unmangled names; without renaming, the legacy
; reader treats the calls as calls to external functions.
declare ptr @llvm.thread.pointer.p0()
declare ptr @llvm.returnaddress.p0(i32 immarg)
declare void @llvm.clear_cache.p0(ptr, ptr)

define ptr @f(ptr %a, ptr %b) {
  %t = call ptr @llvm.thread.pointer.p0()
  %r = call ptr @llvm.returnaddress.p0(i32 0)
  call void @llvm.clear_cache.p0(ptr %a, ptr %b)
  ret ptr %r
}

; CHECK: call {{.*}}@llvm.thread.pointer()
; CHECK: call {{.*}}@llvm.returnaddress(i32 0)
; CHECK: call void @llvm.clear_cache(
