; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 16
; memory(...) postdates all targets; it must be decomposed into the legacy
; readnone/readonly/writeonly/argmemonly/inaccessiblememonly attributes
; rather than dropped (5.0/7.0 previously dropped it entirely).
declare void @m_none() memory(none)
declare void @m_read() memory(read)
declare void @m_write() memory(write)
declare void @m_argread() memory(argmem: read)
declare void @m_argrw() memory(argmem: readwrite)
declare void @m_inacc() memory(inaccessiblemem: readwrite)
declare void @m_inacc_arg() memory(argmem: readwrite, inaccessiblemem: readwrite)

; A group that decomposes to nothing must be dropped entirely, not emitted as
; an empty attribute group record (which legacy readers reject).
declare void @m_rw() memory(readwrite)

; CHECK: ; Function Attrs: readnone
; CHECK-NEXT: declare void @m_none()
; CHECK: ; Function Attrs: readonly
; CHECK-NEXT: declare void @m_read()
; CHECK: ; Function Attrs: writeonly
; CHECK-NEXT: declare void @m_write()
; CHECK: ; Function Attrs: argmemonly readonly
; CHECK-NEXT: declare void @m_argread()
; CHECK: ; Function Attrs: argmemonly
; CHECK-NEXT: declare void @m_argrw()
; CHECK: ; Function Attrs: inaccessiblememonly
; CHECK-NEXT: declare void @m_inacc()
; CHECK: ; Function Attrs: inaccessiblemem_or_argmemonly
; CHECK-NEXT: declare void @m_inacc_arg()
; CHECK-NOT: Function Attrs
; CHECK: declare void @m_rw()
