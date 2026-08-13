; VERSIONS: 18.0
; MIN-LLVM: 16
; atomicrmw uinc_wrap/udec_wrap (LLVM 16) encode natively on the 18.0 target.
define i32 @f(ptr %p, i32 %x) {
  %a = atomicrmw uinc_wrap ptr %p, i32 %x seq_cst
  %b = atomicrmw udec_wrap ptr %p, i32 %x seq_cst
  ret i32 %b
}

; CHECK: atomicrmw uinc_wrap ptr %p, i32 %x seq_cst
; CHECK: atomicrmw udec_wrap ptr %p, i32 %x seq_cst
