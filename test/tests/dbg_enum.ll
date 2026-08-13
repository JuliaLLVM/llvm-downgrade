; VERSIONS: 5.0 7.0 14.0
; DIEnumerator must use the legacy 3-field METADATA_ENUMERATOR record on
; 5.0/7.0; the wide-APInt form the fork used to emit only exists from LLVM 9,
; so enum debug info made the old readers fail with "Invalid record".
@g = global i32 0, !dbg !5

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!9, !10}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug, enums: !2, globals: !4)
!1 = !DIFile(filename: "t.c", directory: "/")
!2 = !{!3}
!3 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "E", baseType: !7, size: 32, elements: !6)
!4 = !{!5}
!5 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!6 = !{!11, !12}
!7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!8 = distinct !DIGlobalVariable(name: "g", scope: !0, file: !1, line: 1, type: !7, isLocal: false, isDefinition: true)
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = !{i32 2, !"Debug Info Version", i32 3}
!11 = !DIEnumerator(name: "A", value: 0)
!12 = !DIEnumerator(name: "B", value: -5)

; CHECK: !DIEnumerator(name: "A", value: 0)
; CHECK: !DIEnumerator(name: "B", value: -5)
