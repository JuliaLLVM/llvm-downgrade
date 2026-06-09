; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; Opaque pointer incoming to a phi must be retyped via a bitcast placed in the
; predecessor block (you cannot insert before a phi).
@threadgroup_memory = external global [256 x i8]

define void @kernel() {
entry:
  br label %exit

loop_entry:
  %0 = phi ptr [ @threadgroup_memory, %loop_cont1 ], [ null, %loop_cont2 ]
  br label %exit

loop_cont1:
  br i1 false, label %exit, label %loop_entry

loop_cont2:
  br label %loop_entry

exit:
  ret void
}

; The bitcast feeding the phi is emitted in the incoming block, not before the phi.
; CHECK: phi {}*
; CHECK: loop_cont1:
; CHECK: bitcast [256 x i8]* @threadgroup_memory to {}*