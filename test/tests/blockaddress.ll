; VERSIONS: 5.0 7.0 14.0
; blockaddress constants are emitted with the legacy i8* type, and their
; record references the function through its emitted typed pointer type.
; Previously any module with more than one function died with "Type mismatch
; in constant table".
define void @other() {
  ret void
}

define void @g(i8 %idx) {
entry:
  indirectbr ptr blockaddress(@g, %one), [label %one, label %two]
one:
  ret void
two:
  ret void
}

; CHECK: bitcast i8* blockaddress(@g, %one) to {}*
; CHECK: indirectbr {}* %{{.*}}, [label %one, label %two]
