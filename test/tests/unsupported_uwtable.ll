; The uwtable attribute is encoded differently in LLVM 5/7; the downgrader
; currently rejects it rather than emit an incompatible attribute group.
; XFAIL-AS: uwtable attribute is not supported

define void @main() uwtable {
entry:
  ret void
}
