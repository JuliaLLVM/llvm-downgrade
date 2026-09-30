; VERSIONS: 20.0
; MIN-LLVM: 20
; atomicrmw usub_cond/usub_sat (LLVM 20) encode natively on the 20.0 target.
define i32 @f(ptr %p, i32 %x) {
  %a = atomicrmw usub_cond ptr %p, i32 %x seq_cst
  %b = atomicrmw usub_sat ptr %p, i32 %x seq_cst
  ret i32 %b
}

; CHECK: atomicrmw usub_cond ptr %p, i32 %x seq_cst
; CHECK: atomicrmw usub_sat ptr %p, i32 %x seq_cst
