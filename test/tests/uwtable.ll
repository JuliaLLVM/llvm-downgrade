; VERSIONS: 5.0 7.0 14.0 15.0 18.0
; uwtable became an int attribute (sync/async) in LLVM 15; older readers only
; know the plain enum form. The pre-15 targets emit that instead of rejecting
; (5.0, 7.0) or emitting the int encoding LLVM 14 cannot read ("Not an int
; attribute"); 15.0/18.0 keep the int form.
define void @sync_kind() uwtable(sync) {
  ret void
}

define void @async_kind() uwtable {
  ret void
}

; CHECK-V5: define void @sync_kind() #[[ATTR:[0-9]+]]
; CHECK-V5: define void @async_kind() #[[ATTR]]
; CHECK-V5: attributes #[[ATTR]] = { uwtable }
; CHECK-V7: define void @sync_kind() #[[ATTR:[0-9]+]]
; CHECK-V7: define void @async_kind() #[[ATTR]]
; CHECK-V7: attributes #[[ATTR]] = { uwtable }
; CHECK-V14: define void @sync_kind() #[[ATTR:[0-9]+]]
; CHECK-V14: define void @async_kind() #[[ATTR]]
; CHECK-V14: attributes #[[ATTR]] = { uwtable }
; CHECK-V15: define void @sync_kind() #[[SYNC:[0-9]+]]
; CHECK-V15: define void @async_kind() #[[ASYNC:[0-9]+]]
; CHECK-V15: attributes #[[SYNC]] = { uwtable(sync) }
; CHECK-V15: attributes #[[ASYNC]] = { uwtable }
; CHECK-V18: define void @sync_kind() #[[SYNC:[0-9]+]]
; CHECK-V18: define void @async_kind() #[[ASYNC:[0-9]+]]
; CHECK-V18: attributes #[[SYNC]] = { uwtable(sync) }
; CHECK-V18: attributes #[[ASYNC]] = { uwtable }
