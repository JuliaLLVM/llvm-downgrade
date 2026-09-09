#!/usr/bin/env bash
set -euo pipefail
tool=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf 'define i32 @f() { ret i32 42 }\n' > "$work/input.ll"
"$tool" --bitcode-version=5.0 "$work/input.ll" -o "$work/output.bc"
"$tool" --bitcode-version 5.0 < "$work/input.ll" > "$work/stdout.bc"
cmp "$work/output.bc" "$work/stdout.bc"
for version in 5.0junk 5.0.1 +5.0 4294967301.0; do
  if "$tool" --bitcode-version="$version" "$work/input.ll" -o "$work/bad.bc" 2> "$work/error"; then
    echo "accepted invalid version: $version" >&2
    exit 1
  fi
  test ! -e "$work/bad.bc"
  grep -q 'unsupported bitcode version' "$work/error"
done
if [[ -e /dev/full ]]; then
  for output in file stdout; do
    if [[ $output == file ]]; then
      args=(-o /dev/full)
    else
      args=()
    fi
    if "$tool" --bitcode-version=5.0 "$work/input.ll" "${args[@]}" > /dev/full 2> "$work/error"; then
      echo "ignored output error: $output" >&2
      exit 1
    fi
    grep -q 'cannot write' "$work/error"
  done
fi
