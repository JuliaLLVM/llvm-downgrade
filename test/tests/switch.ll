; VERSIONS: 5.0 7.0 14.0 15.0 18.0
; Since LLVM 22 switch case values are no longer instruction operands, so the
; enumerators must collect them via SwitchInst::cases() explicitly. Constants
; referenced *only* as case values (all of the ones below) used to be left out
; of the constant table, corrupting every emitted switch record. Cover several
; condition widths and a case constant wider than 32 bits.
define i32 @f(i32 %x) {
entry:
  switch i32 %x, label %default [
    i32 1, label %one
    i32 2, label %two
    i32 -7, label %neg
  ]
one:
  ret i32 10
two:
  ret i32 20
neg:
  ret i32 30
default:
  ret i32 0
}

define i32 @g(i16 %x) {
entry:
  switch i16 %x, label %default [
    i16 7, label %seven
  ]
seven:
  ret i32 1
default:
  ret i32 0
}

define i8 @h(i64 %x) {
entry:
  switch i64 %x, label %default [
    i64 4294967296, label %big
    i64 -1, label %neg
  ]
big:
  ret i8 1
neg:
  ret i8 2
default:
  ret i8 0
}
; CHECK: switch i32 %x, label %default [
; CHECK-NEXT: i32 1, label %one
; CHECK-NEXT: i32 2, label %two
; CHECK-NEXT: i32 -7, label %neg
; CHECK: switch i16 %x, label %default [
; CHECK-NEXT: i16 7, label %seven
; CHECK: switch i64 %x, label %default [
; CHECK-NEXT: i64 4294967296, label %big
; CHECK-NEXT: i64 -1, label %neg
