; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; The Min module-flag behavior postdates the typed targets; clang emitted
; "PIC Level" with the Max behavior before LLVM 15, so the flag is rewritten
; to that spelling.

!llvm.module.flags = !{!0, !1}
!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{i32 1, !"wchar_size", i32 4}

; CHECK: !llvm.module.flags = !{!0, !1}
; CHECK: !0 = !{i32 7, !"PIC Level", i32 2}
; CHECK: !1 = !{i32 1, !"wchar_size", i32 4}
