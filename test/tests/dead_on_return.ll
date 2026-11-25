; VERSIONS: 18.0 20.0 22.0
; MIN-LLVM: 23
; dead_on_return (LLVM 21) gained an optional byte count in LLVM 23. LLVM 22
; only knows the unsized form, which covers all reachable memory, so a sized
; one is dropped rather than widened; the older targets drop both.
define void @f(ptr dead_on_return(16) %sized, ptr dead_on_return %unsized) {
  ret void
}

; CHECK-V18: define void @f(ptr %sized, ptr %unsized)
; CHECK-V20: define void @f(ptr %sized, ptr %unsized)
; CHECK-V22: define void @f(ptr %sized, ptr dead_on_return %unsized)
