; VERSIONS: 14.0
; MIN-LLVM: 15
; bfloat (TYPE_CODE_BFLOAT, LLVM 11+) is rejected by the 5.0/7.0 targets but is
; native in LLVM 14. This checks the 14.0 downgrade target preserves the bfloat
; type, emits a valid bfloat constant, and reconstructs typed pointers from the
; opaque ones (so a genuine LLVM 14 reader round-trips it).
target triple = "air64-apple-macosx14.0.0"

define void @bf_add(ptr addrspace(1) %a, ptr addrspace(1) %b, ptr addrspace(1) %c) {
  %va = load bfloat, ptr addrspace(1) %a, align 2
  %vb = load bfloat, ptr addrspace(1) %b, align 2
  %sum = fadd bfloat %va, %vb
  %cst = fadd bfloat %sum, 0xR3F80
  store bfloat %cst, ptr addrspace(1) %c, align 2
  ret void
}

; CHECK: load bfloat, bfloat addrspace(1)*
; CHECK: fadd bfloat
; CHECK: fadd bfloat %{{[0-9a-z.]+}}, 0xR3F80
; CHECK: store bfloat
