; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; A function used as an operand (not a callee) is emitted with its own typed
; pointer type; such uses must be bridged to the opaque pointer type with a
; bitcast. Previously the raw use produced invalid bitcode on every target
; ("Invalid record" / type mismatches). Same for aliases used as values.
@g1 = global i32 1
@ga = alias i32, ptr @g1

declare void @sink(ptr)

define void @take(ptr %p) {
  call void @sink(ptr @target)
  store ptr @ga, ptr %p
  ret void
}

define void @target() {
  ret void
}

; CHECK: @ga = alias i32, i32* @g1
; CHECK: bitcast void ()* @target to {}*
; CHECK: call void @sink({}*
; CHECK: store {}* %{{.*}}, {}** %{{.*}}
