; VERSIONS: 5.0 7.0 14.0 18.0 20.0 22.0
; MIN-LLVM: 23
; LLVM 23 promoted the denormal-fp-math(-f32) and nooutline string attributes
; to first-class attributes and made "uniform-work-group-size" valueless. The
; older formats only know the string forms (a valueless uniform-work-group-size
; reads as false there), so they are restored instead of being dropped.
; Releases before 17 cannot parse the dynamic mode and assume IEEE when no mode
; is given, so dynamic components become ieee for them.
define void @ftz() denormal_fpenv(preservesign) { ret void }
define void @ftz_f32() denormal_fpenv(float: preservesign) { ret void }
define void @dyn() denormal_fpenv(dynamic) { ret void }
define void @dyn_ftz_f32() denormal_fpenv(dynamic, float: preservesign|ieee) { ret void }
define void @other() nooutline "uniform-work-group-size" { ret void }

; CHECK: define void @ftz() #[[FTZ:[0-9]+]]
; CHECK: define void @ftz_f32() #[[FTZ_F32:[0-9]+]]
; CHECK-V5: define void @dyn() {
; CHECK-V7: define void @dyn() {
; CHECK-V14: define void @dyn() {
; CHECK-V18: define void @dyn() #[[DYN:[0-9]+]]
; CHECK-V20: define void @dyn() #[[DYN:[0-9]+]]
; CHECK-V22: define void @dyn() #[[DYN:[0-9]+]]
; CHECK: define void @dyn_ftz_f32() #[[DYN_FTZ_F32:[0-9]+]]
; CHECK: define void @other() #[[OTHER:[0-9]+]]
; CHECK-DAG: attributes #[[FTZ]] = { "denormal-fp-math"="preserve-sign" }
; CHECK-DAG: attributes #[[FTZ_F32]] = { "denormal-fp-math-f32"="preserve-sign" }
; CHECK-DAG: attributes #[[OTHER]] = { "nooutline" "uniform-work-group-size"="true" }
; CHECK-V5-DAG: attributes #[[DYN_FTZ_F32]] = { "denormal-fp-math-f32"="preserve-sign,ieee" }
; CHECK-V7-DAG: attributes #[[DYN_FTZ_F32]] = { "denormal-fp-math-f32"="preserve-sign,ieee" }
; CHECK-V14-DAG: attributes #[[DYN_FTZ_F32]] = { "denormal-fp-math-f32"="preserve-sign,ieee" }
; CHECK-V18-DAG: attributes #[[DYN]] = { "denormal-fp-math"="dynamic" }
; CHECK-V18-DAG: attributes #[[DYN_FTZ_F32]] = { "denormal-fp-math"="dynamic" "denormal-fp-math-f32"="preserve-sign,ieee" }
; CHECK-V20-DAG: attributes #[[DYN]] = { "denormal-fp-math"="dynamic" }
; CHECK-V20-DAG: attributes #[[DYN_FTZ_F32]] = { "denormal-fp-math"="dynamic" "denormal-fp-math-f32"="preserve-sign,ieee" }
; CHECK-V22-DAG: attributes #[[DYN]] = { "denormal-fp-math"="dynamic" }
; CHECK-V22-DAG: attributes #[[DYN_FTZ_F32]] = { "denormal-fp-math"="dynamic" "denormal-fp-math-f32"="preserve-sign,ieee" }
