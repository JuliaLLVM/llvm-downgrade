; VERSIONS: 14.0 18.0 20.0
; MIN-LLVM: 21  (DIFixedPointType and DISubrangeType are LLVM 21+)
; The fixed-point debug-info type (like DISubrangeType) has a record code the
; legacy readers do not know (they crash on it), so it is rejected.
; XFAIL-AS: DIFixedPointType is not supported
define void @f() !dbg !5 {
  ret void, !dbg !9
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug, retainedTypes: !{!11})
!1 = !DIFile(filename: "t.c", directory: "/")
!3 = !{i32 2, !"Dwarf Version", i32 5}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "f", scope: !1, file: !1, line: 1, type: !6, unit: !0, spFlags: DISPFlagDefinition)
!6 = !DISubroutineType(types: !{null})
!9 = !DILocation(line: 1, column: 1, scope: !5)
!11 = !DIFixedPointType(name: "fp", size: 32, align: 32, encoding: DW_ATE_signed_fixed, kind: Binary, factor: -4)
