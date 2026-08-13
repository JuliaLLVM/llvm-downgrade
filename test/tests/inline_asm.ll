; VERSIONS: 5.0 7.0 14.0
; Inline asm callees stay direct calls: the asm constant record carries the
; pointer-to-function type instead of the callee being wrapped in a bitcast
; (which old verifiers reject: "Cannot take the address of an inline asm").
; The 7.0 writer also used the modern INLINEASM record code its reader does
; not know, which silently turned the asm into a call through undef.
define void @f() {
  call void asm sideeffect "nop", ""()
  ret void
}
; CHECK: call void asm sideeffect "nop", ""()
