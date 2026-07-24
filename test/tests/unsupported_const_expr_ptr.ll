; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; XFAIL-AS: pointers in constant expressions are not supported

@z = global <2 x ptr> getelementptr ([3 x {i32, i32}], <2 x ptr> zeroinitializer, <2 x i32> <i32 1, i32 2>, <2 x i32> <i32 2, i32 3>, <2 x i32> <i32 1, i32 1>)
