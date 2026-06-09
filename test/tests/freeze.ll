; freeze was introduced in LLVM 10; LLVM 5/7 cannot represent it, so the
; downgrader drops it (replacing uses with the operand).
define i32 @f(i32 %x) {
  %y = freeze i32 %x
  %z = add i32 %y, 1
  ret i32 %z
}

; CHECK-NOT: = freeze
; CHECK: add i32 %x, 1
