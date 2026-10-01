; VERSIONS: 18.0 20.0
; callbr encodes natively on the 18.0 and 20.0 targets: LLVM 17 dropped the
; requirement that the asm lists its indirect destinations, so their verifiers
; accept the modern form.
define void @f() {
  callbr void asm sideeffect "", "!i"() to label %fallthru [label %other]
fallthru:
  ret void
other:
  ret void
}

; CHECK: callbr void asm sideeffect "", "!i"()
; CHECK: to label %fallthru [label %other]
