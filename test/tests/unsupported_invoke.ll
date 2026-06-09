; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; invoke/landingpad (exception handling) is not implemented by the downgrader;
; it must abort loudly rather than emit bad bitcode.
; XFAIL-AS: InvokeInst not yet supported

declare i32 @__gxx_personality_v0(...)

define void @fn(ptr %this, ptr %ptr) personality ptr @__gxx_personality_v0 {
  invoke i32 undef(ptr undef)
     to label %invoke unwind label %lpad
invoke:
  unreachable
lpad:
  landingpad { ptr, i32 }
     catch ptr null
  unreachable
}