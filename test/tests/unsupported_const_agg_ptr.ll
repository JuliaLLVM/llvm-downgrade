; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; A constant aggregate containing pointers (e.g. @llvm.used) is not yet handled
; by the typed-pointer reconstruction; the downgrader aborts.
; XFAIL-AS: pointers in constant aggregates are not yet supported

@llvm.used = appending global [1 x ptr] [ptr @used1]

define internal void @used1() {
entry:
  ret void
}