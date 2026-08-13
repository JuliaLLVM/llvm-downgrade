; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; A pointer-valued global takes its emitted value type from its initializer,
; so `global ptr @g` round-trips as `global i32* @g`. Previously the opaque
; {}* value type mismatched the typed initializer ("Global variable
; initializer type does not match global variable type").
@g = global i32 42
@p = global ptr @g
@pp = global ptr @p
@f = global ptr @fun
@n = global ptr null

define void @fun() {
  ret void
}

; CHECK: @g = global i32 42
; CHECK: @p = global i32* @g
; CHECK: @pp = global i32** @p
; CHECK: @f = global void ()* @fun
; CHECK: @n = global {}* null
