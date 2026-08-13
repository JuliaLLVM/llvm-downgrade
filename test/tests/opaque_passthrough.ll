; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; VERSIONS: 15.0 18.0
; The 15.0/18.0 targets emit opaque pointers natively: no retyping, `ptr`
; survives the round trip (unlike the 5.0/7.0/14.0 targets, which lower to
; typed pointers).
@g = external global [4 x i32]

define i32 @f(ptr %p) {
  %e = getelementptr inbounds i32, ptr %p, i64 2
  store i32 7, ptr %e, align 4
  %v = load i32, ptr %e, align 4
  %old = atomicrmw add ptr %p, i32 1 seq_cst
  %pair = cmpxchg ptr %p, i32 0, i32 1 seq_cst seq_cst
  ret i32 %v
}

; CHECK: define i32 @f(ptr
; CHECK: getelementptr inbounds i32, ptr
; CHECK: store i32 7, ptr
; CHECK: load i32, ptr
; CHECK: atomicrmw add ptr
; CHECK: cmpxchg ptr
