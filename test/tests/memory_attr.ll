; MIN-LLVM: 16  (the memory(...) attribute is LLVM 16+)
; VERSIONS: 18.0
; LLVM 18 knows the memory(...) attribute natively (the pre-16 targets
; decompose it into the legacy argmemonly/readonly/... enum attributes, see
; memory_attrs.ll).
define i32 @f(ptr %p) memory(argmem: read) {
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

; CHECK: define i32 @f(ptr %p) [[ATTRS:#[0-9]+]]
; CHECK-V18: attributes [[ATTRS]] = { memory(argmem: read) }
