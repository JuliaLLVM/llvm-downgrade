# llvm-downgrade

`llvm-downgrade` rewrites LLVM IR into an **older LLVM bitcode format**, so a
consumer built on an older LLVM can read bitcode produced by a newer toolchain.
It is the tool behind Julia's [`LLVMDowngrader_jll`](https://github.com/JuliaPackaging/Yggdrasil/tree/master/L/LLVMDowngrader).

```
llvm-downgrade input.ll -o output.bc --bitcode-version=14.0
```

Supported target bitcode versions: **5.0**, **7.0**, and **14.0** (14.0 requires
a host LLVM >= 15). With no `--bitcode-version` it writes native bitcode, like
`llvm-as`.

## How it works

The legacy writers under `versions/<MAJOR>/src/` are forks of LLVM's own
`BitcodeWriter`/`ValueEnumerator` from the 5.0 / 7.0 / 14.0 releases, *adapted to
compile against each newer host LLVM's C++ API*. Because that API changes every
release, the sources are necessarily **per host LLVM version**. Keeping them in
one repository (rather than on a branch per LLVM release of a full LLVM fork)
means a fix — e.g. handling a new attribute — can be made across versions in a
single commit.

```
versions/<MAJOR>/
  src/        legacy writers + their private headers (ValueEnumerator*, etc.)
  include/    the few LLVM headers the downgrader augments, shadowing the
              installed ones (BitcodeWriter.h with the legacy-writer
              declarations, LLVMBitCodes.h with ATTR_KIND_INVALID,
              Metadata{50,70}.def)
common/       version-independent driver support (the de-static'd-opt shim)
tools/        the llvm-downgrade driver
```

These were extracted from the `downgrade_release_<MAJOR>` branches of
<https://github.com/JuliaLLVM/llvm-downgrade> (a full LLVM fork); only the
downgrader files are kept, not that fork's unrelated patches.

## Building

Out-of-tree against a prebuilt LLVM — no LLVM rebuild required:

```sh
cmake -B build -S . -G Ninja -DLLVM_DIR=/path/to/lib/cmake/llvm
cmake --build build
```

The bundled sources for `versions/<LLVM_VERSION_MAJOR>` are selected
automatically. By default the LLVM component **static** libraries are linked,
producing a self-contained tool. Pass `-DLLVMDG_LINK_DYLIB=ON` to link the
monolithic `libLLVM` shared library instead (handy against a distro LLVM that
ships only the shared lib).

## Versions

`versions/13` … `versions/22`, matching LLVM 13 … 22. Versions 13–14 support
bitcode 5.0/7.0 only; 15+ add 14.0.

## Licensing

The legacy writers are derived from LLVM and are licensed under the Apache
License v2.0 with LLVM Exceptions (see `LICENSE.TXT`).
