; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; byref is a pointee-type attribute like byval/sret/inalloca: the parameter
; must be emitted with that pointee, or the LLVM 14 verifier rejects the
; mismatch ("Attribute 'byref' type does not match parameter!"). The 5.0/7.0
; targets drop the attribute (it postdates them) but keep the typed parameter.

%ndrange = type { i64, [3 x i64] }

define i64 @callee(ptr addrspace(5) noundef readonly byref(%ndrange) align 8 %p) {
entry:
  %v = load i64, ptr addrspace(5) %p, align 8
  ret i64 %v
}

define i64 @caller(ptr addrspace(5) %p) {
entry:
  %r = call i64 @callee(ptr addrspace(5) noundef readonly byref(%ndrange) align 8 %p)
  ret i64 %r
}

; CHECK-V14: define i64 @callee(%ndrange addrspace(5)* noundef readonly byref(%ndrange) align 8 %p)
; CHECK-V5: define i64 @callee(%ndrange addrspace(5)* readonly align 8 %p)
; CHECK-V7: define i64 @callee(%ndrange addrspace(5)* readonly align 8 %p)
; CHECK: load i64, i64 addrspace(5)*
; CHECK-LABEL: define i64 @caller({} addrspace(5)* %p)
; CHECK: [[CAST:%.*]] = bitcast {} addrspace(5)* %p to %ndrange addrspace(5)*
; CHECK-V14: call i64 @callee(%ndrange addrspace(5)* noundef readonly byref(%ndrange) align 8 [[CAST]])
; CHECK-V5: call i64 @callee(%ndrange addrspace(5)* readonly align 8 [[CAST]])
; CHECK-V7: call i64 @callee(%ndrange addrspace(5)* readonly align 8 [[CAST]])
