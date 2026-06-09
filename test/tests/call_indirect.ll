; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; Indirect / non-Function call callees must be bitcast to the function-pointer
; type for typed-pointer output (regression test for the Phase 2 callee fix).
define void @test(ptr %fptr) {
  call void %fptr()
  call void (...) null()
  ret void
}

; CHECK: bitcast {}* %fptr to void ()*
; CHECK: call void %
; CHECK: bitcast {}* null to void (...)*
; CHECK: call void (...) %