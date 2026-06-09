//===- llvm-downgrade.cpp - Re-emit a module as older LLVM bitcode --------===//
//
// Reads an LLVM module and writes it back out in an older LLVM bitcode format,
// so an LLVM too old to predate the producing toolchain can still read it.
//
//   llvm-downgrade --bitcode-version=14.0 input.bc -o output.bc
//
// The input is bitcode (textual .ll is also accepted for convenience); it is
// auto-upgraded to the host LLVM on load, so bitcode from any LLVM the host can
// read is accepted. The output is always bitcode in the requested legacy format
// (5.0, 7.0, or -- when built against host LLVM >= 15 -- 14.0).
//
//===----------------------------------------------------------------------===//

#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static cl::opt<std::string> InputFilename(cl::Positional,
                                          cl::desc("<input bitcode>"),
                                          cl::init("-"));

static cl::opt<std::string> OutputFilename("o", cl::desc("Output filename"),
                                           cl::value_desc("filename"),
                                           cl::init("-"));

static cl::opt<std::string>
    BitcodeVersion("bitcode-version",
                   cl::desc("Target bitcode version: 5.0, 7.0"
#ifdef LLVMDG_HAS_140
                            ", 14.0"
#endif
                            ),
                   cl::value_desc("version"), cl::Required);

int main(int argc, char **argv) {
  InitLLVM X(argc, argv);
  cl::ParseCommandLineOptions(
      argc, argv, "llvm-downgrade: re-emit a module as older LLVM bitcode\n");

  LLVMContext Context;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseIRFile(InputFilename, Err, Context);
  if (!M) {
    Err.print(argv[0], errs());
    return 1;
  }

  std::error_code EC;
  ToolOutputFile Out(OutputFilename, EC, sys::fs::OF_None);
  if (EC) {
    errs() << argv[0] << ": " << OutputFilename << ": " << EC.message() << '\n';
    return 1;
  }

  StringRef V(BitcodeVersion);
  if (V == "5.0") {
    BitcodeWriter50::prepareModule(*M);
    WriteBitcode50ToFile(*M, Out.os());
  } else if (V == "7.0") {
    BitcodeWriter70::prepareModule(*M);
    WriteBitcode70ToFile(*M, Out.os());
#ifdef LLVMDG_HAS_140
  } else if (V == "14.0") {
    BitcodeWriter140::prepareModule(*M);
    WriteBitcode140ToFile(*M, Out.os());
#endif
  } else {
    errs() << argv[0] << ": unsupported bitcode version '" << V << "'\n";
    return 1;
  }

  Out.keep();
  return 0;
}
