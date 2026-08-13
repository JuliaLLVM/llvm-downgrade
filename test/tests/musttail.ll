; VERSIONS: 5.0 7.0 14.0
; musttail/tail call markers survive on all targets.
define void @tgt(i32 %x) {
  ret void
}
define void @f(i32 %x) {
  musttail call void @tgt(i32 %x)
  ret void
}
; CHECK: musttail call void @tgt(i32 %x)
