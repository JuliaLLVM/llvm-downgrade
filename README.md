# llvm-downgrade

`llvm-downgrade` rewrites an LLVM module to an older bitcode format, so a consumer
built on an older LLVM can read bitcode that a newer toolchain produced.

```
llvm-downgrade input.bc -o output.bc --bitcode-version=14.0
```

It reads bitcode and writes bitcode, in one of the legacy formats 5.0, 7.0, or
14.0. The input is auto-upgraded to the host LLVM as it loads, and LLVM's bitcode
reader stays compatible back to 3.0, so a tool built on a recent LLVM can
downgrade bitcode from any older one. Build it on the newest LLVM you need to read.

Textual `.ll` is accepted too, since it goes through the same reader, but bitcode
is the format with the compatibility guarantee. `.ll` is really only there for
hand-written tests.

## How it works

`src/` holds forks of LLVM's own `BitcodeWriter` and `ValueEnumerator` from the
5.0, 7.0 and 14.0 releases, adapted to build against the host LLVM's C++ API. That
API moves every release, so the sources are tied to one host LLVM version; this
checkout is LLVM 22 (`LLVMDG_LLVM_MAJOR` in `CMakeLists.txt`). `include/` carries
the handful of LLVM headers the downgrader has to augment: the legacy-writer
declarations in `BitcodeWriter.h`, `ATTR_KIND_INVALID` in `LLVMBitCodes.h`, and
`Metadata{50,70}.def`. These shadow the installed copies. `common/` defines the
two `cl::opt`s the in-tree downgrader de-statics, which is how we avoid needing a
patched libLLVM. The driver is `tools/llvm-downgrade.cpp`.

## Building

Out of tree, against a prebuilt LLVM, with no LLVM rebuild:

```sh
cmake -B build -S . -G Ninja -DLLVM_DIR=/path/to/lib/cmake/llvm
cmake --build build
```

By default it links the LLVM component static libraries, so the tool is
self-contained and has no runtime libLLVM dependency. Pass `-DLLVMDG_LINK_DYLIB=ON`
to link the monolithic `libLLVM` instead, for example against a distro LLVM that
only ships the shared library. It is a normal release build: unsupported IR
constructs are rejected with `report_fatal_error`, so the tool fails loudly
instead of leaning on assertions.

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
  -DLLVMDG_DIS_14_0=/path/to/llvm-14/bin/llvm-dis
```

`test/run-downgrade-test.sh` documents the per-test directives (`VERSIONS`,
`MIN-LLVM`/`MAX-LLVM`, `XFAIL-AS`, `XFAIL-DIS-V*`) and the FileCheck prefixes.

## Licensing

The legacy writers are derived from LLVM, so they are under the Apache License
v2.0 with LLVM Exceptions. See `LICENSE.TXT`.
