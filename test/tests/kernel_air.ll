; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 16
; End-to-end smoke test resembling a GPU kernel: address spaces, a loop with
; phis, FMA, shared memory, and intrinsic declarations that pick up modern
; attributes (which used to break the 7.0 and 14.0 attribute tables).
target triple = "air64-apple-macosx14.0.0"

define void @kern(ptr addrspace(1) %out, ptr addrspace(1) %in, i32 %n, ptr addrspace(3) %shm) {
entry:
  %tid = call i32 @get_tid()
  br label %loop
loop:
  %i = phi i32 [ %tid, %entry ], [ %inext, %loop ]
  %idx = zext i32 %i to i64
  %src = getelementptr inbounds float, ptr addrspace(1) %in, i64 %idx
  %v = load float, ptr addrspace(1) %src, align 4
  %fma = call float @llvm.fma.f32(float %v, float 2.0, float 1.0)
  %shp = getelementptr inbounds float, ptr addrspace(3) %shm, i64 %idx
  store float %fma, ptr addrspace(3) %shp, align 4
  %dst = getelementptr inbounds float, ptr addrspace(1) %out, i64 %idx
  store float %fma, ptr addrspace(1) %dst, align 4
  %inext = add nuw nsw i32 %i, 32
  %cmp = icmp ult i32 %inext, %n
  br i1 %cmp, label %loop, label %exit
exit:
  ret void
}
declare i32 @get_tid() memory(none)
declare float @llvm.fma.f32(float, float, float)

; CHECK: define void @kern({} addrspace(1)* %out, {} addrspace(1)* %in, i32 %n, {} addrspace(3)* %shm)
; CHECK: %i = phi i32 [ %tid, %entry ], [ %inext, %loop ]
; CHECK: getelementptr inbounds float, float addrspace(1)*
; CHECK: call float @llvm.fma.f32(float %v, float 2.000000e+00, float 1.000000e+00)
; CHECK: store float %fma, float addrspace(3)*
; CHECK: add nuw nsw i32 %i, 32
; CHECK: ; Function Attrs: readnone
; CHECK: declare i32 @get_tid()
