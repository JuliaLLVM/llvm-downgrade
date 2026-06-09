; JuliaGPU/Metal.jl#799: LLVM 19+ mangles the vararg intrinsics (llvm.va_start.p0).
; LLVM 5/7 only know the unmangled names; the downgrader must rename them back.
; The .p0 mangling only exists from LLVM 19 on, so this test is 19+ only.
; MIN-LLVM: 19
declare void @llvm.va_start.p0(ptr)
declare void @llvm.va_end.p0(ptr)
declare void @llvm.va_copy.p0(ptr, ptr)

define void @gpu_kernel_print(ptr %fmt, ...) {
entry:
  %ap = alloca ptr, align 8
  %ap2 = alloca ptr, align 8
  call void @llvm.va_start.p0(ptr %ap)
  call void @llvm.va_copy.p0(ptr %ap2, ptr %ap)
  call void @llvm.va_end.p0(ptr %ap)
  ret void
}

; CHECK-NOT: va_start.p0
; CHECK-NOT: va_end.p0
; CHECK-NOT: va_copy.p0
; CHECK-DAG: declare void @llvm.va_start(i8*)
; CHECK-DAG: declare void @llvm.va_end(i8*)
; CHECK-DAG: declare void @llvm.va_copy(i8*, i8*)
; CHECK: call void @llvm.va_start(i8*
; CHECK: call void @llvm.va_copy(i8*
; CHECK: call void @llvm.va_end(i8*
