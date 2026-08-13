; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; fence and atomic load/store with the various orderings and syncscopes.
define i32 @f(ptr %p, i32 %v) {
  fence acquire
  fence syncscope("singlethread") seq_cst
  %l = load atomic i32, ptr %p acquire, align 4
  store atomic i32 %v, ptr %p release, align 4
  ret i32 %l
}
; CHECK: fence acquire
; CHECK: fence syncscope("singlethread") seq_cst
; CHECK: load atomic i32, i32* %{{.*}} acquire, align 4
; CHECK: store atomic i32 %v, i32* %{{.*}} release, align 4
