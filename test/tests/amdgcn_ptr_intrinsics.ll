; VERSIONS: 7.0 14.0
; MIN-LLVM: 15
; The AMDGPU pointer-typed intrinsics are declared with an i8 pointee in typed
; LLVM; without the known signature they would be emitted with {}* pointers
; and rejected by the legacy verifiers ("Intrinsic has incorrect return
; type!"). A retyped call result is also bridged back to the opaque type with
; a bitcast, so operands the reader type-checks against their user's type
; (phi incoming values) still match. The i8 addrspace(4)* signature only
; exists from LLVM 7 on; a 5.0 target aborts instead (see
; unsupported_amdgcn_ptr_intrinsic_v5.ll).

declare align 4 ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
declare align 4 ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
declare i1 @llvm.amdgcn.is.shared(ptr nocapture)

define i64 @f() {
entry:
  %p = call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %q = call ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
  %v = load i32, ptr addrspace(4) %p, align 4
  %i = ptrtoint ptr addrspace(4) %q to i64
  %j = zext i32 %v to i64
  %s = add i64 %i, %j
  ret i64 %s
}

define ptr addrspace(4) @g(i1 %c) {
entry:
  %p = call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  br i1 %c, label %a, label %b

a:
  br label %b

b:
  %r = phi ptr addrspace(4) [ %p, %a ], [ null, %entry ]
  ret ptr addrspace(4) %r
}

define i1 @h(ptr %p) {
entry:
  %r = call i1 @llvm.amdgcn.is.shared(ptr %p)
  ret i1 %r
}

; CHECK: declare {{(align 4 )?}}i8 addrspace(4)* @llvm.amdgcn.implicitarg.ptr()
; CHECK: declare {{(align 4 )?}}i8 addrspace(4)* @llvm.amdgcn.dispatch.ptr()
; CHECK: declare i1 @llvm.amdgcn.is.shared(i8*{{( nocapture)?}})
; CHECK-LABEL: define i64 @f()
; CHECK: %p = call i8 addrspace(4)* @llvm.amdgcn.implicitarg.ptr()
; CHECK: %q = call i8 addrspace(4)* @llvm.amdgcn.dispatch.ptr()
; CHECK: load i32, i32 addrspace(4)*
; CHECK: ptrtoint {} addrspace(4)* {{%.*}} to i64
; CHECK-LABEL: define {} addrspace(4)* @g(i1 %c)
; CHECK: [[P:%.*]] = call i8 addrspace(4)* @llvm.amdgcn.implicitarg.ptr()
; CHECK: [[CAST:%.*]] = bitcast i8 addrspace(4)* [[P]] to {} addrspace(4)*
; CHECK: phi {} addrspace(4)* [ [[CAST]], %a ], [ null, %entry ]
; CHECK-LABEL: define i1 @h({}* %p)
; CHECK: call i1 @llvm.amdgcn.is.shared(i8* {{%.*}})
