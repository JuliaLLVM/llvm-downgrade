; MIN-LLVM: 16  (the memory(...) attribute is LLVM 16+)
; VERSIONS: 15.0 18.0
; LLVM 15 has no memory(...) attribute: the 15.0 writer decomposes it into the
; legacy argmemonly/readonly/... enum attributes. LLVM 18 knows it natively.
define i32 @f(ptr %p) memory(argmem: read) {
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

; CHECK: define i32 @f(ptr %p) [[ATTRS:#[0-9]+]]
; CHECK-V15: attributes [[ATTRS]] = { argmemonly readonly }
; CHECK-V18: attributes [[ATTRS]] = { memory(argmem: read) }
