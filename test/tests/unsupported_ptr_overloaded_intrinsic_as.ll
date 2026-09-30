; VERSIONS: 5.0 7.0 14.0 18.0 20.0
; MIN-LLVM: 23
; The legacy llvm.returnaddress returns an address-space-0 pointer; other
; address spaces have no legacy form.
; XFAIL-AS: llvm.returnaddress on a pointer outside address space 0
declare ptr addrspace(5) @llvm.returnaddress.p5(i32 immarg)

define ptr addrspace(5) @f() {
  %r = call ptr addrspace(5) @llvm.returnaddress.p5(i32 0)
  ret ptr addrspace(5) %r
}
