; VERSIONS: 5.0
; MIN-LLVM: 15
; Before LLVM 7 switched AMDGPU to its current address-space mapping, the
; pointer-returning AMDGPU intrinsics returned i8 addrspace(2)*, not i8
; addrspace(4)*, and LLVM 5's verifier rejects the addrspace(4) declaration
; ("Intrinsic has incorrect return type!"). A module using the current
; mapping cannot be renumbered locally, so the 5.0 target rejects it loudly.
; XFAIL-AS: AMDGPU intrinsic predates the LLVM 7 address-space remapping
declare align 4 ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()

define i32 @f() {
entry:
  %p = call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %v = load i32, ptr addrspace(4) %p, align 4
  ret i32 %v
}
