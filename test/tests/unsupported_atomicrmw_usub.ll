; VERSIONS: 5.0 7.0 14.0 15.0 18.0
; MIN-LLVM: 20
; atomicrmw usub_cond (LLVM 20) has no legacy encoding on any target.
; XFAIL-AS: unsupported atomicrmw operation
define i32 @f(ptr %p, i32 %x) {
  %old = atomicrmw usub_cond ptr %p, i32 %x seq_cst
  ret i32 %old
}
