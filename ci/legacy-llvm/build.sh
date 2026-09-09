#!/usr/bin/env bash
# Build LLVM 5/7 llvm-dis, opt and llc for testing downgraded bitcode.
# Usage: ci/legacy-llvm/build.sh <5|7> <install prefix>
# LLVMDG_SOURCE_TARBALL selects a local archive; CC/CXX select the compiler.
# CMAKE_BUILD_PARALLEL_LEVEL limits build concurrency.
set -euo pipefail

major=${1:?usage: $0 <5|7> <install prefix>}
prefix=$(realpath -m "${2:?usage: $0 <5|7> <install prefix>}")
here=$(cd "$(dirname "$0")" && pwd)

case "$major" in
  5) version=5.0.2
     url="https://releases.llvm.org/5.0.2/llvm-5.0.2.src.tar.xz"
     sha256=d522eda97835a9c75f0b88ddc81437e5edbb87dc2740686cb8647763855c2b3c ;;
  7) version=7.1.0
     url="https://github.com/llvm/llvm-project/releases/download/llvmorg-7.1.0/llvm-7.1.0.src.tar.xz"
     sha256=1bcc9b285074ded87b88faaedddb88e6b5d6c331dfcfb57d7f3393dd622b3764 ;;
  *) echo "unsupported legacy LLVM major '$major' (5 or 7)" >&2; exit 1 ;;
esac

work=$(mktemp -d "${TMPDIR:-/tmp}/legacy-llvm-$major.XXXXXX")
trap 'rm -rf "$work"' EXIT

tarball=${LLVMDG_SOURCE_TARBALL:-$work/llvm-$version.src.tar.xz}
if [[ ! -f $tarball ]]; then
  echo "downloading $url"
  curl -fsSL -o "$tarball" "$url"
fi
echo "$sha256  $tarball" | sha256sum -c -

echo "extracting"
tar -xJf "$tarball" -C "$work"
src=$work/llvm-$version.src
patch -d "$src" -p1 < "$here/patches/llvm$major-cmake-policy-and-regex-guard.patch"

echo "building llvm-dis, opt and llc $version"
cmake -S "$src" -B "$work/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DLLVM_TARGETS_TO_BUILD="X86;AMDGPU;NVPTX" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_WARNINGS=OFF
cmake --build "$work/build" --target llvm-dis opt llc
mkdir -p "$prefix/bin"
cp "$work/build/bin/llvm-dis" "$work/build/bin/opt" "$work/build/bin/llc" "$prefix/bin/"
"$prefix/bin/llvm-dis" --version
"$prefix/bin/opt" --version
"$prefix/bin/llc" --version
