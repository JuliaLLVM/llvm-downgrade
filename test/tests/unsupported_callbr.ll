; VERSIONS: 5.0 7.0 14.0
; callbr cannot be represented: it postdates 5.0/7.0 entirely, and modern
; callbr no longer carries the blockaddress arguments the 14.0 verifier
; requires (LLVM 17 dropped that; 18.0/20.0 encode callbr natively, see
; callbr.ll).
; It used to crash (5.0/7.0) or emit invalid bitcode (14.0).
; XFAIL-AS: cannot encode CallBr instruction for LLVM
define void @f() {
  callbr void asm sideeffect "", "!i"() to label %fallthru [label %other]
fallthru:
  ret void
other:
  ret void
}
