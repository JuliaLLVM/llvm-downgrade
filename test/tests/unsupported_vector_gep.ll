; VERSIONS: 5.0 7.0 14.0
; MIN-LLVM: 15
; A vector-of-pointer GEP would need a vector of typed pointers, which the
; typed-pointer reconstruction cannot express; it must abort loudly instead
; of emitting an invalid cast.
; XFAIL-AS: vector-of-pointer getelementptr is not supported
define <2 x ptr> @f(<2 x ptr> %ps) {
  %g = getelementptr i32, <2 x ptr> %ps, <2 x i64> <i64 1, i64 2>
  ret <2 x ptr> %g
}
