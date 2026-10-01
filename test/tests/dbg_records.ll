; VERSIONS: 20.0
; Variable-location debug records (#dbg_value/#dbg_declare/#dbg_assign) encode
; natively on the 20.0 target (LLVM 19 introduced the record form); the older
; targets drop them, see dbg_line_info.ll.
define i32 @f(i32 %x) !dbg !5 {
  %p = alloca i32, !dbg !9
    #dbg_declare(ptr %p, !11, !DIExpression(), !9)
  %q = alloca i32, !dbg !9, !DIAssignID !12
    #dbg_assign(i32 %x, !8, !DIExpression(), !12, ptr %q, !DIExpression(), !9)
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
!11 = !DILocalVariable(name: "p", scope: !5, file: !1, line: 1, type: !10)
!12 = distinct !DIAssignID()

; CHECK: #dbg_declare(ptr %p, ![[P:[0-9]+]], !DIExpression(), ![[LOC:[0-9]+]])
; CHECK: alloca i32, align 4, !dbg ![[LOC]], !DIAssignID ![[ID:[0-9]+]]
; CHECK: #dbg_assign(i32 %x, ![[Y:[0-9]+]], !DIExpression(), ![[ID]], ptr %q, !DIExpression(), ![[LOC]])
; CHECK: add i32 %x, 1, !dbg ![[LOC]]
; CHECK: #dbg_value(i32 %y, ![[Y]], !DIExpression(), ![[LOC]])
; CHECK-DAG: ![[Y]] = !DILocalVariable(name: "y"
; CHECK-DAG: ![[P]] = !DILocalVariable(name: "p"
