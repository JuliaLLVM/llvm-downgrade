; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; A named (identified) struct must be emitted as STRUCT_NAMED with its body, not
; OPAQUE (regression test for the Phase 2 named-struct fix). Previously any named
; struct made the 5.0/7.0 reader fail with "Invalid record" in the type table.
%S = type { i32, i32 }

define void @f(ptr %p) {
  %a = getelementptr %S, ptr %p, i64 0, i32 1
  store i32 7, ptr %a
  ret void
}

; CHECK: %S = type { i32, i32 }
; CHECK: getelementptr %S, %S*