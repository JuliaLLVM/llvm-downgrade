; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; XFAIL-AS: module flag with a behavior the target LLVM cannot represent

!llvm.module.flags = !{!0}
!0 = !{i32 8, !"some_min_flag", i32 3}
