#!/usr/bin/env bash
# Run one downgrader FileCheck test across its target bitcode versions.
#
# For each target version the test exercises, the input is downgraded with
# `llvm-downgrade --bitcode-version=<v>`, disassembled with the matching *legacy*
# llvm-dis (so we verify a real old LLVM accepts the bitcode), and the result is
# checked with FileCheck. Per-test directives (in `;` comments):
#
#   ; VERSIONS: 5.0 7.0       versions to exercise (default: 5.0 7.0)
#   ; MIN-LLVM: 15            require host (producer) LLVM >= N
#   ; MAX-LLVM: 16            require host LLVM <= N
#   ; XFAIL-AS: <substr>      llvm-downgrade is expected to abort with this message
#   ; XFAIL-DIS-V5: <substr>  the legacy llvm-dis is expected to fail with this
#   ; XFAIL-DIS-V7/V14: ...
# FileCheck prefixes: CHECK (common), CHECK-V5 / CHECK-V7 / CHECK-V14.
#
# Exit codes (for ctest SKIP_RETURN_CODE=77): 0 pass, 1 fail, 77 skipped.
set -u

TOOL= FILECHECK= HOST_MAJOR= DIS_5= DIS_7= DIS_14= TEST=
while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)       TOOL=$2;       shift 2;;
    --filecheck)  FILECHECK=$2;  shift 2;;
    --host-major) HOST_MAJOR=$2; shift 2;;
    --dis-5)      DIS_5=$2;      shift 2;;
    --dis-7)      DIS_7=$2;      shift 2;;
    --dis-14)     DIS_14=$2;     shift 2;;
    *)            TEST=$1;       shift;;
  esac
done

[[ -x $TOOL ]] || { echo "tool not executable: $TOOL"; exit 1; }
[[ -f $TEST ]] || { echo "test not found: $TEST"; exit 1; }
name=$(basename "$TEST")

getdir() { sed -n "s/^; *$1: *//p" "$TEST" | head -1; }
firstnum() { grep -oE '^[0-9]+' <<<"${1:-}" | head -1; }

min=$(firstnum "$(getdir MIN-LLVM)")
max=$(firstnum "$(getdir MAX-LLVM)")
if [[ -n $min && $HOST_MAJOR -lt $min ]]; then echo "SKIP $name (needs LLVM >= $min)"; exit 77; fi
if [[ -n $max && $HOST_MAJOR -gt $max ]]; then echo "SKIP $name (needs LLVM <= $max)"; exit 77; fi

versions=$(getdir VERSIONS); versions=${versions:-"5.0 7.0"}
xfail_as=$(getdir XFAIL-AS)

dis_for() { case $1 in 5.0) echo "$DIS_5";; 7.0) echo "$DIS_7";; 14.0) echo "$DIS_14";; esac; }

pass=0 fail=0
for ver in $versions; do
  n=${ver%%.*}
  tmp=$(mktemp); out=$(mktemp); err=$(mktemp)
  trap 'rm -f "$tmp" "$out" "$err"' RETURN

  if ! "$TOOL" --bitcode-version="$ver" "$TEST" -o "$tmp" 2>"$err"; then
    if grep -qi "unsupported bitcode version" "$err"; then
      echo "SKIP  $name v$ver (target not built)"
    elif [[ -n $xfail_as ]] && grep -qF "$xfail_as" "$err"; then
      echo "XFAIL $name v$ver (tool aborts: $xfail_as)"; pass=$((pass+1))
    else
      echo "FAIL  $name v$ver (llvm-downgrade): $(head -1 "$err")"; fail=$((fail+1))
    fi
    rm -f "$tmp" "$out" "$err"; continue
  fi
  if [[ -n $xfail_as ]]; then
    echo "FAIL  $name v$ver (expected llvm-downgrade to abort: $xfail_as)"; fail=$((fail+1))
    rm -f "$tmp" "$out" "$err"; continue
  fi

  dis=$(dis_for "$ver")
  if [[ ! -x $dis ]]; then
    echo "SKIP  $name v$ver (no legacy llvm-dis for $ver)"; rm -f "$tmp" "$out" "$err"; continue
  fi
  xfail_dis=$(getdir "XFAIL-DIS-V$n")
  if ! "$dis" "$tmp" -o "$out" 2>"$err"; then
    if [[ -n $xfail_dis ]] && grep -qF "$xfail_dis" "$err"; then
      echo "XFAIL $name v$ver (llvm-dis: $xfail_dis)"; pass=$((pass+1))
    else
      echo "FAIL  $name v$ver (llvm-dis $ver): $(head -1 "$err")"; fail=$((fail+1))
    fi
    rm -f "$tmp" "$out" "$err"; continue
  fi
  if [[ -n $xfail_dis ]]; then
    echo "FAIL  $name v$ver (expected llvm-dis to fail: $xfail_dis)"; fail=$((fail+1))
    rm -f "$tmp" "$out" "$err"; continue
  fi

  if [[ ! -x $FILECHECK ]]; then
    echo "SKIP  $name v$ver (FileCheck not available)"; rm -f "$tmp" "$out" "$err"; continue
  fi
  prefixes=CHECK
  grep -q "CHECK-V$n:" "$TEST" && prefixes="CHECK,CHECK-V$n"
  if "$FILECHECK" --check-prefixes="$prefixes" "$TEST" <"$out" 2>"$err"; then
    echo "PASS  $name v$ver"; pass=$((pass+1))
  else
    echo "FAIL  $name v$ver (FileCheck): $(grep -m1 'error:' "$err")"; fail=$((fail+1))
  fi
  rm -f "$tmp" "$out" "$err"
done

[[ $fail -gt 0 ]] && exit 1
[[ $pass -gt 0 ]] && exit 0
exit 77   # every version skipped
