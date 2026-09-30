; VERSIONS: 18.0 20.0
; MIN-LLVM: 20  (the initializes(...) attribute is LLVM 20+)
; The ConstantRange(-list) attributes range (LLVM 19) and initializes (LLVM 20)
; have no LLVM 18 representation and are dropped there; the 20.0 target encodes
; them natively.
define range(i32 0, 10) i32 @f(ptr initializes((0, 4)) %p, i32 range(i32 -1, 1) %x) {
  store i32 %x, ptr %p
  ret i32 %x
}

; CHECK-V18: define i32 @f(ptr %p, i32 %x)
; CHECK-V20: define range(i32 0, 10) i32 @f(ptr initializes((0, 4)) %p, i32 range(i32 -1, 1) %x)
