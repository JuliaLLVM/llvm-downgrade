; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; Pointer-typed global values (and blockaddresses) referenced from constant
; aggregates are emitted through synthetic bitcast constants: the aggregate's
; element slots read back with the opaque {}* type, while the referenced value
; keeps its typed pointer type.

@g = global i32 42
@a = alias i32, ptr @g
@used = global { i32, [2 x ptr] } { i32 0, [2 x ptr] [ptr @used1, ptr null] }
@tab = global [3 x ptr] [ptr @g, ptr @a, ptr @used]
@jt = global { i64, [2 x ptr] } { i64 1, [2 x ptr] [ptr blockaddress(@f, %bb), ptr null] }
@llvm.compiler.used = appending global [2 x ptr] [ptr @used1, ptr @g], section "llvm.metadata"

define internal void @used1() {
entry:
  ret void
}

define void @f() {
entry:
  br label %bb

bb:
  ret void
}

; CHECK: @g = global i32 42
; CHECK: @used = global { i32, [2 x {}*] } { i32 0, [2 x {}*] [{}* bitcast (void ()* @used1 to {}*), {}* null] }
; CHECK: @tab = global [3 x {}*] [{}* bitcast (i32* @g to {}*), {}* bitcast (i32* @a to {}*), {}* bitcast ({ i32, [2 x {}*] }* @used to {}*)]
; CHECK: @jt = global { i64, [2 x {}*] } { i64 1, [2 x {}*] [{}* bitcast (i8* blockaddress(@f, %bb) to {}*), {}* null] }
; CHECK: @llvm.compiler.used = appending global [2 x {}*] [{}* bitcast (void ()* @used1 to {}*), {}* bitcast (i32* @g to {}*)], section "llvm.metadata"
; CHECK: @a = alias i32, i32* @g
; CHECK: define internal void @used1()
