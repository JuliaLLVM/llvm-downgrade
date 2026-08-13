; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 18
; Attribute kinds that postdate a target must be dropped cleanly -- the 14.0
; encoder used to emit garbage codes for them (llvm_unreachable fallthrough in
; a release build) -- while attributes with a legacy encoding survive.
define float @f(float nofpclass(nan) %x, ptr dead_on_unwind writable align 8 %p) mustprogress willreturn {
  ret float %x
}
; nofpclass/dead_on_unwind/writable are dropped; align survives everywhere;
; mustprogress/willreturn postdate 5.0/7.0, so only 14.0 keeps them.
; CHECK-V5: define float @f(float %x, {}* align 8 %p) {
; CHECK-V7: define float @f(float %x, {}* align 8 %p) {
; CHECK-V14: define float @f(float %x, {}* align 8 %p) #0 {
; CHECK-V14: attributes #0 = { mustprogress willreturn }
