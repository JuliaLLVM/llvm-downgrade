; VERSIONS: 5.0 7.0 14.0
; Line-table debug info (DISubprogram/DILocation) survives on all targets.
; NOTE: variable locations (#dbg_value records) are currently dropped: the
; legacy writers predate debug records and there is no intrinsic form left in
; the host LLVM to lower them to.
define i32 @f(i32 %x) !dbg !5 {
  %y = add i32 %x, 1, !dbg !9
    #dbg_value(i32 %y, !8, !DIExpression(), !9)
  ret i32 %y, !dbg !9
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
!8 = !DILocalVariable(name: "y", scope: !5, file: !1, line: 1, type: !10)
!9 = !DILocation(line: 1, column: 1, scope: !5)
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)

; CHECK: add i32 %x, 1, !dbg
; CHECK: distinct !DISubprogram(name: "f"
; CHECK: !DILocation(line: 1, column: 1
