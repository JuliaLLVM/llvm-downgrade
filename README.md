# llvm-downgrade

`llvm-downgrade` rewrites an LLVM module into an **older LLVM bitcode format**, so
a consumer built on an older LLVM can read bitcode produced by a newer toolchain.
It is the tool behind Julia's [`LLVMDowngrader_jll`](https://github.com/JuliaPackaging/Yggdrasil/tree/master/L/LLVMDowngrader).

```
llvm-downgrade input.bc -o output.bc --bitcode-version=14.0
```

It ingests bitcode (textual `.ll` is also accepted) and produces bitcode in the
requested legacy format: **5.0**, **7.0**, or **14.0**. The input is auto-upgraded
to the host LLVM on load, so — because LLVM's bitcode reader is backwards
compatible to 3.0 — a tool built on a recent LLVM can downgrade bitcode produced
by any older LLVM. Build it on the newest LLVM you need to ingest.

## How it works

`src/` holds forks of LLVM's own `BitcodeWriter` / `ValueEnumerator` from the 5.0,
7.0 and 14.0 releases, adapted to compile against the host LLVM's C++ API. Because
that API changes every release, the sources are specific to one host LLVM version
(this checkout targets **LLVM 21**, see `LLVMDG_LLVM_MAJOR` in `CMakeLists.txt`).
`include/` carries the few LLVM headers the downgrader augments (the legacy-writer
declarations in `BitcodeWriter.h`, `ATTR_KIND_INVALID` in `LLVMBitCodes.h`, and
`Metadata{50,70}.def`); they shadow the installed copies. `common/` defines the
two `cl::opt`s the in-tree downgrader de-statics, so we don't need a modified
libLLVM. `tools/llvm-downgrade.cpp` is the driver.

The sources were extracted from the `downgrade_release_<major>` branches of the
[JuliaLLVM/llvm-downgrade](https://github.com/JuliaLLVM/llvm-downgrade) LLVM fork.
Only the downgrader files are kept (not that fork's unrelated patches). To target
a different LLVM, bump `LLVMDG_LLVM_MAJOR` and re-extract `src/` + `include/` from
the matching branch; earlier LLVM versions remain in this repository's git history.

## Building

Out-of-tree against a prebuilt LLVM — no LLVM rebuild required:

```sh
cmake -B build -S . -G Ninja -DLLVM_DIR=/path/to/lib/cmake/llvm
cmake --build build
```

By default the LLVM component **static** libraries are linked, producing a
self-contained tool with no runtime libLLVM dependency. Pass
`-DLLVMDG_LINK_DYLIB=ON` to link the monolithic `libLLVM` instead (e.g. against a
distro LLVM that ships only the shared library). The build is a normal release
build; unsupported IR constructs are rejected with a clean `report_fatal_error`,
so the tool fails loudly rather than relying on assertions.

## Testing

```sh
ctest --test-dir build
```

`test/tests/*.ll` are FileCheck tests: each is downgraded to its target
version(s), disassembled with the matching **legacy** `llvm-dis`, and checked.
The legacy disassemblers are not part of any modern LLVM, so supply them (a
version whose disassembler is absent is reported as *skipped*, not failed):

```sh
cmake -B build -S . -DLLVM_DIR=... \
  -DLLVMDG_DIS_5_0=/path/to/llvm-5/bin/llvm-dis \
  -DLLVMDG_DIS_7_0=/path/to/llvm-7/bin/llvm-dis \
  -DLLVMDG_DIS_14_0=/path/to/llvm-14/bin/llvm-dis
```

See `test/run-downgrade-test.sh` for the per-test directives (`VERSIONS`,
`MIN-LLVM`/`MAX-LLVM`, `XFAIL-AS`, `XFAIL-DIS-V*`, and the FileCheck prefixes).

## Licensing

The legacy writers are derived from LLVM and are licensed under the Apache
License v2.0 with LLVM Exceptions (see `LICENSE.TXT`).
