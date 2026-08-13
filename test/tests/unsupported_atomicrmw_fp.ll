; VERSIONS: 5.0 7.0
; atomicrmw fadd postdates LLVM 5/7; it must be rejected loudly instead of
; being emitted with a garbage operation code ("Invalid record" on read).
; XFAIL-AS: unsupported atomicrmw operation
define float @f(ptr %p, float %x) {
  %old = atomicrmw fadd ptr %p, float %x seq_cst
  ret float %old
}
