; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; XFAIL-AS: pointers in constant aggregates are not yet supported

@used = global { i32, [1 x ptr] } { i32 0, [1 x ptr] [ptr @used1] }

define internal void @used1() {
entry:
  ret void
}
