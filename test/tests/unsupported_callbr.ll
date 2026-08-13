; VERSIONS: 5.0 7.0 14.0
; callbr cannot be represented: it postdates 5.0/7.0 entirely, and modern
; callbr no longer carries the blockaddress arguments LLVM 14's verifier
; requires. It used to crash (5.0/7.0) or emit invalid bitcode (14.0).
; XFAIL-AS: cannot encode CallBr instruction for LLVM
define void @f() {
  callbr void asm sideeffect "", "!i"() to label %fallthru [label %other]
fallthru:
  ret void
other:
  ret void
}
