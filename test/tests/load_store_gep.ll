; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; Basic opaque-pointer reconstruction for load / store / getelementptr.
@g = external global [4 x i32]

define i32 @f(ptr %p) {
  %e = getelementptr inbounds i32, ptr %p, i64 2
  store i32 7, ptr %e, align 4
  %v = load i32, ptr %e, align 4
  ret i32 %v
}

; CHECK: getelementptr inbounds i32, i32*
; CHECK: store i32 7, i32*
; CHECK: load i32, i32*