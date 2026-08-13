; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 20
; Poison-generating flags that postdate a target (disjoint, nneg, samesign,
; trunc/GEP nuw+nusw) are dropped -- that is always sound -- while nuw/nsw/
; exact/inbounds survive on every target.
define i64 @f(i32 %x, i32 %y, ptr %p) {
  %a = add nuw nsw i32 %x, %y
  %d = sdiv exact i32 %a, %y
  %o = or disjoint i32 %d, %y
  %z = zext nneg i32 %o to i64
  %g = getelementptr inbounds i8, ptr %p, i64 8
  %h = getelementptr nuw nusw i8, ptr %p, i64 16
  %t = trunc nuw i64 %z to i32
  %c = icmp samesign ult i32 %t, %x
  %s = select i1 %c, i64 %z, i64 0
  ret i64 %s
}
; CHECK: add nuw nsw i32
; CHECK: sdiv exact i32
; CHECK-NOT: disjoint
; CHECK-NOT: nneg
; CHECK: getelementptr inbounds i8
; CHECK-NOT: getelementptr nuw
; CHECK-NOT: samesign
