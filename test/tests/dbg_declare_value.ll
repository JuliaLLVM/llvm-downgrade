; VERSIONS: 20.0
; MIN-LLVM: 22
; #dbg_declare_value (LLVM 22) has no LLVM 20 record kind; it is dropped, while
; the other debug records in the function are kept.
define void @f(ptr %p, i32 %x) !dbg !5 {
    #dbg_declare_value(ptr %p, !8, !DIExpression(), !9)
    #dbg_value(i32 %x, !11, !DIExpression(), !9)
  ret void, !dbg !9
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug)
!1 = !DIFile(filename: "t.c", directory: "/")
!3 = !{i32 2, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "f", scope: !1, file: !1, line: 1, type: !6, unit: !0)
!6 = !DISubroutineType(types: !7)
!7 = !{null}
!8 = !DILocalVariable(name: "p", scope: !5, file: !1, line: 1, type: !10)
!9 = !DILocation(line: 1, column: 1, scope: !5)
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !DILocalVariable(name: "x", scope: !5, file: !1, line: 1, type: !10)

; CHECK: define void @f(
; CHECK-NOT: #dbg_declare
; CHECK: #dbg_value(i32 %x,
; CHECK-NOT: #dbg_declare
; CHECK: ret void
