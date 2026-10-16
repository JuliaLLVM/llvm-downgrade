; VERSIONS: 5.0 7.0 14.0 18.0 20.0
; Since LLVM 23, every FP vector splat is a ConstantFP of vector type. Readers
; before LLVM 19 do not accept that in a FLOAT record, so it has to be written
; as a data array; LLVM 20 reads the splat natively.
@gv = global <4 x float> splat (float 3.0)
@agg = global { <2 x double>, i32 } { <2 x double> splat (double 7.0), i32 1 }

define <2 x float> @f(<2 x float> %x) {
  %r = fdiv <2 x float> splat (float 1.0), %x
  ret <2 x float> %r
}

define <3 x half> @h(<3 x half> %x) {
  %r = fadd <3 x half> %x, <half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <3 x half> %r
}

; LLVM 20's disassembler prints the splat syntax; older ones list every element.
; CHECK: @gv = global <4 x float> {{splat \(float 3.000000e\+00\)|<float 3.000000e\+00, float 3.000000e\+00, float 3.000000e\+00, float 3.000000e\+00>}}
; CHECK: @agg = global { <2 x double>, i32 } { <2 x double> {{splat \(double 7.000000e\+00\)|<double 7.000000e\+00, double 7.000000e\+00>}}, i32 1 }
; CHECK: fdiv <2 x float> {{splat \(float 1.000000e\+00\)|<float 1.000000e\+00, float 1.000000e\+00>}}, %x
; CHECK: fadd <3 x half> %x, {{splat \(half 0xH3C00\)|<half 0xH3C00, half 0xH3C00, half 0xH3C00>}}
