# llvm-downgrade

`llvm-downgrade` rewrites an LLVM module to an older bitcode format, so a consumer
built on an older LLVM can read bitcode that a newer toolchain produced.

```
llvm-downgrade input.bc -o output.bc --bitcode-version=14.0
```

It reads bitcode and writes bitcode, in one of the legacy formats 5.0, 7.0,
14.0, 18.0 or 20.0. The input is auto-upgraded to the host LLVM as it loads, and LLVM's bitcode
reader stays compatible back to 3.0, so a tool built on a recent LLVM can
downgrade bitcode from any older one. Build it on the newest LLVM you need to read.

Textual `.ll` is accepted too, since it goes through the same reader, but bitcode
is the format with the compatibility guarantee. `.ll` is really only there for
hand-written tests.

## How it works

`src/` holds forks of LLVM's own `BitcodeWriter` and `ValueEnumerator` from the
5.0, 7.0, 14.0, 18.1 and 20.1 releases, adapted to build against the host LLVM's
C++ API. That
API moves every release, so the sources are tied to one host LLVM version; this
checkout is LLVM 23 (`LLVMDG_LLVM_MAJOR` in `CMakeLists.txt`). `include/` carries
the handful of LLVM headers the downgrader has to augment: the legacy-writer
declarations in `BitcodeWriter.h`, `ATTR_KIND_INVALID` in `LLVMBitCodes.h`, and
`Metadata{50,70}.def`. These shadow the installed copies. `common/` defines the
two `cl::opt`s the in-tree downgrader de-statics, which is how we avoid needing a
patched libLLVM. The driver is `tools/llvm-downgrade.c`.

## Building

Out of tree, against a prebuilt LLVM, with no LLVM rebuild:

```sh
cmake -B build -S . -G Ninja -DLLVM_DIR=/path/to/lib/cmake/llvm
cmake --build build
```

This builds the `libllvm_downgrade` shared library and the `llvm-downgrade`
command-line tool. Set `-DLLVMDG_BUILD_LIBRARY=OFF` to embed the writers in the
tool, or `-DLLVMDG_BUILD_TOOL=OFF` to build only the library. Install with
`cmake --install build --prefix /path/to/install`.

By default, LLVM's static component libraries are linked into the downgrader.
Their symbols are hidden in the shared library so it can coexist with another
LLVM in the same process. This requires LLVM archives built with position
independent code. Set `-DLLVMDG_LINK_DYLIB=ON` to link the shared `libLLVM`
instead; that configuration uses the process's LLVM and does not isolate it.

## Library

`include/llvm-downgrade.h` follows the `llvm-c` conventions: bitcode in,
bitcode out, status as return value, message on failure.

```c
#include <llvm-downgrade.h>
#include <stdio.h>

LLVMDGMemoryBufferRef Out;
char *Message;
if (LLVMDGDowngrade(Data, Length, 14, 0, &Out, &Message)) {
  fprintf(stderr, "%s\n", Message ? Message : "downgrade failed");
  LLVMDGDisposeMessage(Message);
} else {
  fwrite(LLVMDGGetBufferStart(Out), 1, LLVMDGGetBufferSize(Out), File);
  LLVMDGDisposeMemoryBuffer(Out);
}
```

`LLVMDGGetTargets` lists the formats the build can emit and `LLVMDGGetLLVMVersion`
the LLVM it was built on. Downgrade calls are serialized; returned buffers are
independent and owned by the caller. Parsing errors and unsupported constructs
return an error status. Internal LLVM fatal errors and assertions remain fatal.
Link C clients with `-lllvm_downgrade`.

## Testing

```sh
ctest --test-dir build
```

`test/tests/*.ll` are FileCheck tests. Each one is downgraded to its target
version, disassembled with the matching legacy `llvm-dis`, and checked. Those old
disassemblers are not part of any modern LLVM, so you point the build at them; a
version whose disassembler is missing is skipped rather than failed:

```sh
cmake -B build -S . -DLLVM_DIR=... \
  -DLLVMDG_DIS_5_0=/path/to/llvm-5/bin/llvm-dis \
  -DLLVMDG_DIS_7_0=/path/to/llvm-7/bin/llvm-dis \
  -DLLVMDG_DIS_14_0=/path/to/llvm-14/bin/llvm-dis \
  -DLLVMDG_DIS_18_0=/path/to/llvm-18/bin/llvm-dis \
  -DLLVMDG_DIS_20_0=/path/to/llvm-20/bin/llvm-dis
```

`llvm-dis` does not run the IR verifier, so it misses semantically invalid
output (attribute type mismatches, bad intrinsic signatures, ...). Point the
build at the matching legacy `opt` binaries as well and every downgraded module
is additionally run through the real old verifier:

```sh
  -DLLVMDG_OPT_5_0=/path/to/llvm-5/bin/opt   # etc.
```

CI obtains LLVM 14 and newer tools from `LLVM_full_jll`. For LLVM 5 and 7,
`ci/legacy-llvm/build.sh <5|7> <prefix>` builds `llvm-dis`, `opt`, and `llc`
from pinned release sources without Julia. The build enables X86, AMDGPU, and
NVPTX code generation and applies the compatibility patches in
`ci/legacy-llvm/patches/`. CI caches the tools. Set
`CMAKE_BUILD_PARALLEL_LEVEL` to limit build concurrency.

The C API tests also run in library-only builds and cover buffer ownership,
invalid input, unsupported formats, and reuse after writer errors.

`test/run-downgrade-test.sh` documents the per-test directives (`VERSIONS`,
`MIN-LLVM`/`MAX-LLVM`, `XFAIL-AS`, `XFAIL-DIS-V*`) and the FileCheck prefixes.

`test/integration/downgrade_devicelibs.jl` is a Julia integration test that
fetches the ROCm device libraries shipped by the latest
`AMDGPU_LLVM_Backend_jll` and downgrades all of them to the LLVM versions we
care about (14, 18, and 20). See `.github/workflows/ci.yml` for how to invoke
it.

## Limitations

Constructs with no reasonable legacy representation return an error: exception handling (`invoke`, 5.0/7.0
targets), `callbr`, atomicrmw operations newer than the target format,
vector-of-pointer GEPs, unwinding inline asm (5.0/7.0), scalable vectors /
bfloat / AMX (5.0/7.0), target extension types, pointer-typed intrinsics
without a known typed signature (5.0/7.0), `DIEnumerator` values wider than 64
bits (5.0/7.0), and `DIAssignID`/`DIFixedPointType`/`DISubrangeType` (14.0).

Some information is dropped, always soundly: attribute kinds that postdate the
target (`nofpclass`, `range`, partial `captures`, ...), poison-generating
instruction flags (`disjoint`, `nneg`, `samesign`, `nuw`/`nusw` on GEP and
`trunc`), `llvm.lifetime` markers (their modern form has no legacy signature),
and, on the pre-20 targets, `#dbg_value`/`#dbg_declare` variable-location
records (those writers predate debug records, and modern LLVM has no intrinsic
form left to lower them to; the 20.0 target keeps them). Line-table debug info
survives everywhere. The datalayout and triple strings are passed through
unmodified; a datalayout with specifiers the target LLVM cannot parse is the
front-end's responsibility.

## Licensing

The legacy writers are derived from LLVM, so they are under the Apache License
v2.0 with LLVM Exceptions. See `LICENSE.TXT`.
