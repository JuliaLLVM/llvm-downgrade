; VERSIONS: 5.0 7.0 14.0 15.0
; MIN-LLVM: 16
; atomicrmw uinc_wrap (LLVM 16) has no legacy encoding on any pre-16 target
; (18.0 encodes it natively; see atomicrmw_wrap.ll).
; XFAIL-AS: unsupported atomicrmw operation
define i32 @f(ptr %p, i32 %x) {
  %old = atomicrmw uinc_wrap ptr %p, i32 %x seq_cst
  ret i32 %old
}
