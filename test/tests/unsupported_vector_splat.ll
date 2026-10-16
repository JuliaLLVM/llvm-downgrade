; VERSIONS: 5.0 7.0 14.0 18.0
; Before LLVM 19, vector splats have to be written as data arrays, which cannot
; hold x86_fp80 elements.
; XFAIL-AS: unsupported vector splat constant
define <2 x x86_fp80> @f(<2 x x86_fp80> %x) {
  %r = fadd <2 x x86_fp80> %x, splat (x86_fp80 0xK3FFF8000000000000000)
  ret <2 x x86_fp80> %r
}
