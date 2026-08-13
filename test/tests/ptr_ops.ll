; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; Pointer-level operations that need no element type: select, icmp,
; ptrtoint/inttoptr round-trip through the opaque {}* form.
define i32 @f(i1 %c, ptr %p, ptr %q) {
  %r = select i1 %c, ptr %p, ptr %q
  %e = icmp eq ptr %r, %q
  %i = ptrtoint ptr %r to i64
  %b = inttoptr i64 %i to ptr
  %v = load i32, ptr %b, align 4
  ret i32 %v
}
; CHECK: select i1 %c, {}* %p, {}* %q
; CHECK: icmp eq {}* %r, %q
; CHECK: ptrtoint {}* %r to i64
; CHECK: inttoptr i64 %i to {}*
; CHECK: load i32, i32* %{{.*}}, align 4
