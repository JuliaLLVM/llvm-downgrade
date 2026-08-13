; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; The memory intrinsics need their legacy typed names (llvm.memcpy.p0i8...)
; and i8* arguments; 5.0 additionally requires the explicit align argument
; that LLVM 7 moved into parameter attributes. Previously the modern p0 names
; with {}* arguments failed the legacy verifiers.
define void @f(ptr %d, ptr %s) {
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %d, ptr align 4 %s, i64 16, i1 false)
  call void @llvm.memset.p0.i64(ptr align 8 %d, i8 0, i64 16, i1 false)
  ret void
}
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

; CHECK-V5: call void @llvm.memcpy.p0i8.p0i8.i64(i8* %{{.*}}, i8* %{{.*}}, i64 16, i32 4, i1 false)
; CHECK-V5: call void @llvm.memset.p0i8.i64(i8* %{{.*}}, i8 0, i64 16, i32 8, i1 false)
; CHECK-V7: call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %{{.*}}, i8* align 4 %{{.*}}, i64 16, i1 false)
; CHECK-V7: call void @llvm.memset.p0i8.i64(i8* align 8 %{{.*}}, i8 0, i64 16, i1 false)
; CHECK-V14: call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %{{.*}}, i8* align 4 %{{.*}}, i64 16, i1 false)
; CHECK-V14: call void @llvm.memset.p0i8.i64(i8* align 8 %{{.*}}, i8 0, i64 16, i1 false)
