; Typed-pointer regime (LLVM 13-16, before opaque `ptr` is the only form):
; atomicrmw must use the old 7.0 record code and named structs must emit
; STRUCT_NAMED. The opaque-pointer tests cover 15+ separately.
; MAX-LLVM: 16
%S = type { i32, i32 }

define void @f(i32* %p, %S* %s) {
  %old = atomicrmw add i32* %p, i32 1 seq_cst
  %g = getelementptr %S, %S* %s, i64 0, i32 1
  store i32 0, i32* %g
  ret void
}

; CHECK: %S = type { i32, i32 }
; CHECK: atomicrmw add i32*
