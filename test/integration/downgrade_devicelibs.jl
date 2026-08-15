# Downgrade the ROCm device libraries shipped by the latest
# AMDGPU_LLVM_Backend_jll and check the results with the legacy LLVM binaries
# the build was configured with: llvm-dis proves a real old LLVM reads each
# module, opt runs its full IR verifier. The 5.0/7.0 targets are not
# exercised because LLVM 7 and older cannot parse the AMDGPU datalayout
# string, which the downgrader passes through unmodified.
#
# Exits 77 (the test suite's skip code) when the package cannot be fetched,
# e.g. without network access.
#
# Usage (CI runs this on every push, see .github/workflows/ci.yml; flags
# mirror run-downgrade-test.sh, and empty values are ignored):
#   julia downgrade_devicelibs.jl --tool <llvm-downgrade> \
#       [--dis-14 <llvm-dis>] [--opt-14 <opt>] [--dis-15 ...] ...

using Test, Pkg

const VERSIONS = ["14.0", "15.0", "18.0"]

function parse_args(args)
    iseven(length(args)) || error("flags and values must come in pairs: $args")
    tool = nothing
    checkers = Dict{String,Dict{Symbol,String}}()
    for i in 1:2:length(args)
        flag, value = args[i], args[i + 1]
        if flag == "--tool"
            tool = value
        else
            m = match(r"^--(dis|opt)-(\d+)$", flag)
            m === nothing && error("unknown flag: $flag")
            if !isempty(value)
                entry = get!(Dict{Symbol,String}, checkers, m.captures[2])
                entry[Symbol(m.captures[1])] = value
            end
        end
    end
    tool === nothing && error("--tool is required")
    return tool, checkers
end

# run `cmd`, returning whether it succeeded along with its stderr
function checked_run(cmd)
    err = IOBuffer()
    ok = success(run(pipeline(ignorestatus(cmd); stdout=devnull, stderr=err)))
    return ok, String(take!(err))
end

const tool, checkers = parse_args(ARGS)

Pkg.activate(; temp=true)
try
    Pkg.add("AMDGPU_LLVM_Backend_jll")
catch err
    @error "could not fetch AMDGPU_LLVM_Backend_jll; skipping" exception = err
    exit(77)
end
import AMDGPU_LLVM_Backend_jll

const libdir = joinpath(AMDGPU_LLVM_Backend_jll.artifact_dir, "amdgcn", "bitcode")
isdir(libdir) || error("AMDGPU_LLVM_Backend_jll does not ship amdgcn/bitcode; " *
                       "cannot test device-lib downgrading")
const libs = sort!(filter(endswith(".bc"), readdir(libdir; join=true)))
isempty(libs) && error("no .bc files in $libdir")
@info "downgrading $(length(libs)) device libraries from $libdir"

@testset "device libs to $version" for version in VERSIONS
    entry = get(checkers, first(split(version, '.')), Dict{Symbol,String}())
    haskey(entry, :dis) ||
        @warn "no llvm-dis for $version; only checking that the downgrade succeeds"
    @testset "$(basename(bc))" for bc in libs
        out = tempname() * ".bc"
        try
            ok, log = checked_run(`$tool --bitcode-version=$version $bc -o $out`)
            ok || print(log)
            @test ok
            if ok && haskey(entry, :dis)
                ok, log = checked_run(`$(entry[:dis]) $out -o -`)
                ok || print(log)
                @test ok
            end
            if ok && haskey(entry, :opt)
                # -mtriple: stock opt rejects modules with a triple it does
                # not know; the override only affects TargetMachine setup,
                # not IR verification.
                ok, log = checked_run(
                    `$(entry[:opt]) -passes=verify -disable-output -mtriple=x86_64-unknown-linux-gnu $out`)
                ok || print(log)
                @test ok
            end
        finally
            rm(out; force=true)
        end
    end
end
