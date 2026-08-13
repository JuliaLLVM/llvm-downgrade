; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; Parameters with pointee-type attributes are emitted with that pointee as the
; pointer element type: legacy byval/sret derive their meaning from it, and
; the LLVM 14 verifier requires the typed attribute payload to match the
; parameter type. 5.0/7.0 previously dropped sret entirely and emitted byval
; against an unrelated {}* parameter.
%T = type { i32, i32 }

define void @f(ptr sret(%T) %out, ptr byval(%T) %in) {
  %v = load i32, ptr %in, align 4
  store i32 %v, ptr %out, align 4
  ret void
}

define void @caller(ptr %a, ptr %b) {
  call void @f(ptr sret(%T) %a, ptr byval(%T) %b)
  ret void
}

; CHECK-V5: define void @f(%T* sret %out, %T* byval %in)
; CHECK-V7: define void @f(%T* sret %out, %T* byval %in)
; CHECK-V14: define void @f(%T* sret(%T) %out, %T* byval(%T) %in)
; CHECK: call void @f(%T* sret
