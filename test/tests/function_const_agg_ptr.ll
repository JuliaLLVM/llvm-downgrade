; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15

@box = private unnamed_addr addrspace(2) constant { i64, [8 x i8] } { i64 256, [8 x i8] zeroinitializer }, align 16

define { ptr, i8 } @produce(i1 %cond) noinline {
entry:
  br i1 %cond, label %boxed, label %inline

boxed:
  br label %exit

inline:
  br label %exit

exit:
  %value = phi { ptr, i8 } [ { ptr getelementptr inbounds ({ i64, [8 x i8] }, ptr addrspacecast (ptr addrspace(2) @box to ptr), i64 0, i32 1), i8 -126 }, %boxed ], [ { ptr null, i8 1 }, %inline ]
  ret { ptr, i8 } %value
}

; CHECK: @box = private unnamed_addr addrspace(2) constant
; CHECK-LABEL: define { {}*, i8 } @produce
; CHECK: boxed:
; CHECK: [[BOX:%.*]] = bitcast { i64, [8 x i8] } addrspace(2)* @box to {} addrspace(2)*
; CHECK: [[CAST:%.*]] = addrspacecast {} addrspace(2)* [[BOX]] to {}*
; CHECK: [[TYPED:%.*]] = bitcast {}* [[CAST]] to { i64, [8 x i8] }*
; CHECK: [[FIELD:%.*]] = getelementptr inbounds { i64, [8 x i8] }, { i64, [8 x i8] }* [[TYPED]], i64 0, i32 1
; CHECK: [[OPAQUE:%.*]] = bitcast [8 x i8]* [[FIELD]] to {}*
; CHECK: [[PTR:%.*]] = insertvalue { {}*, i8 } {{(undef|poison)}}, {}* [[OPAQUE]], 0
; CHECK: [[VALUE:%.*]] = insertvalue { {}*, i8 } [[PTR]], i8 -126, 1
; CHECK: %value = phi { {}*, i8 } [ [[VALUE]], %boxed ], [ { {}* null, i8 1 }, %inline ]
; CHECK: attributes #0 = { noinline }
