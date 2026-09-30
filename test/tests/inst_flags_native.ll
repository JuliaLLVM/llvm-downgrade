; VERSIONS: 20.0
; MIN-LLVM: 20
; The poison-generating flags introduced up to LLVM 20 (disjoint, nneg,
; uitofp nneg, samesign, trunc/GEP nuw+nusw) encode natively on the 20.0 target (compare
; inst_flags.ll, where the older targets drop them).
define i64 @f(i32 %x, i32 %y, ptr %p, ptr %q) {
  %a = add nuw nsw i32 %x, %y
  %d = sdiv exact i32 %a, %y
  %o = or disjoint i32 %d, %y
  %z = zext nneg i32 %o to i64
  %u = uitofp nneg i32 %o to float
  store float %u, ptr %q
  %g = getelementptr inbounds i8, ptr %p, i64 8
  %h = getelementptr nuw nusw i8, ptr %p, i64 16
  %t = trunc nuw i64 %z to i32
  %c = icmp samesign ult i32 %t, %x
  %s = select i1 %c, i64 %z, i64 0
  ret i64 %s
}
; CHECK: add nuw nsw i32
; CHECK: sdiv exact i32
; CHECK: or disjoint i32
; CHECK: zext nneg i32
; CHECK: uitofp nneg i32
; CHECK: getelementptr inbounds i8
; CHECK: getelementptr nusw nuw i8
; CHECK: trunc nuw i64
; CHECK: icmp samesign ult i32
