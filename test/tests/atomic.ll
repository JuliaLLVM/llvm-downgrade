; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; atomicrmw / cmpxchg with opaque pointers: the element type is inferred from
; the value operand and the pointer retyped accordingly. The 7.0 writer must
; use the old atomicrmw record code (38), not the modern one (59).
define void @f(ptr %p) {
  %old = atomicrmw add ptr %p, i32 1 seq_cst
  %pair = cmpxchg ptr %p, i32 0, i32 1 seq_cst seq_cst
  ret void
}

; CHECK: atomicrmw add i32*
; CHECK: cmpxchg i32*