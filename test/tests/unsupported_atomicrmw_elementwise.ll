; VERSIONS: 5.0 7.0 14.0 18.0 20.0 22.0
; MIN-LLVM: 23
; Integer and pointer vectors are only valid atomicrmw operands with the
; elementwise modifier (LLVM 23), which no older format can express.
; XFAIL-AS: elementwise atomicrmw add is not supported
define <2 x i32> @f(ptr %p, <2 x i32> %v) {
  %r = atomicrmw elementwise add ptr %p, <2 x i32> %v monotonic
  ret <2 x i32> %r
}
