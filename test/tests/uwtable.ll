; VERSIONS: 5.0 7.0 14.0
; uwtable became an int attribute (sync/async) in LLVM 15; older readers only
; know the plain enum form. All targets emit that instead of rejecting (5.0,
; 7.0) or emitting the int encoding LLVM 14 cannot read ("Not an int
; attribute").
define void @sync_kind() uwtable(sync) {
  ret void
}

define void @async_kind() uwtable {
  ret void
}

; CHECK: define void @sync_kind() #[[ATTR:[0-9]+]]
; CHECK: define void @async_kind() #[[ATTR]]
; CHECK: attributes #[[ATTR]] = { uwtable }
