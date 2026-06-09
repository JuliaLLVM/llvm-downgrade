; MIN-LLVM: 15  (uses opaque `ptr`; opaque pointers are LLVM 15+)
; A pointer-typed constant expression (here a vector-of-pointers GEP) cannot be
; reconstructed to a typed pointer; the downgrader aborts.
; XFAIL-AS: pointers in constant expressions are not supported

@z = global <2 x ptr> getelementptr ([3 x {i32, i32}], <2 x ptr> zeroinitializer, <2 x i32> <i32 1, i32 2>, <2 x i32> <i32 2, i32 3>, <2 x i32> <i32 1, i32 1>)