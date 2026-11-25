; VERSIONS: 22.0
; DIFixedPointType and DISubrangeType (LLVM 21) are rejected by the older
; targets (see unsupported_di_fixed_point.ll), but LLVM 22 reads them.
define void @f() !dbg !5 {
  ret void, !dbg !9
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug, retainedTypes: !{!11, !12})
!1 = !DIFile(filename: "t.c", directory: "/")
!3 = !{i32 2, !"Dwarf Version", i32 5}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "f", scope: !1, file: !1, line: 1, type: !6, unit: !0, spFlags: DISPFlagDefinition)
!6 = !DISubroutineType(types: !{null})
!9 = !DILocation(line: 1, column: 1, scope: !5)
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !DIFixedPointType(name: "fp", size: 32, align: 32, encoding: DW_ATE_signed_fixed, kind: Binary, factor: -4)
!12 = !DISubrangeType(name: "sr", size: 32, align: 32, baseType: !10, lowerBound: i64 1, upperBound: i64 5)

; CHECK-DAG: !DIFixedPointType(name: "fp", size: 32, align: 32, encoding: DW_ATE_signed_fixed, kind: Binary, factor: -4)
; CHECK-DAG: !DISubrangeType(name: "sr", size: 32, align: 32, baseType: !{{[0-9]+}}, lowerBound: i64 1, upperBound: i64 5)
