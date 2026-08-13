; VERSIONS: 5.0 7.0 14.0
; half/fp128 arithmetic and wide integer constants exist on all targets.
define half @h(half %x) {
  %r = fadd half %x, 0xH3C00
  ret half %r
}
define fp128 @q(fp128 %x) {
  ret fp128 %x
}
define i128 @w() {
  ret i128 123456789012345678901234567890
}
; CHECK: fadd half %x, 0xH3C00
; CHECK: ret fp128 %x
; CHECK: ret i128 123456789012345678901234567890
