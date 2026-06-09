//===- llvm-downgrade.cpp - Emit legacy-version LLVM bitcode --------------===//
//
// Reads LLVM IR (textual .ll or current-version .bc) and writes it back out in
// an older LLVM bitcode format, so that an LLVM old enough to predate the
// producing toolchain can still read it.
//
// Usage:
//   llvm-downgrade <input.ll|input.bc> -o <output.bc> --bitcode-version=14.0
//
// With no --bitcode-version it behaves like `llvm-as` and writes native bitcode.
// The set of supported legacy versions depends on the host LLVM the tool was
// built against (5.0 and 7.0 always; 14.0 for host LLVM >= 15).
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
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static cl::opt<std::string> InputFilename(cl::Positional,
                                          cl::desc("<input .ll/.bc file>"),
                                          cl::init("-"));

static cl::opt<std::string> OutputFilename("o", cl::desc("Override output filename"),
                                           cl::value_desc("filename"));

static cl::opt<std::string>
    BitcodeVersion("bitcode-version",
                   cl::desc("Target bitcode version: 5.0, 7.0"
#ifdef LLVMDG_HAS_140
                            ", 14.0"
#endif
                            " (default: native)"),
                   cl::value_desc("version"), cl::init(""));

static cl::opt<bool> Force("f", cl::desc("Enable binary output on terminals"));

// NB: we deliberately do not expose a `preserve-ll-uselistorder` flag -- the
// prebuilt libLLVM we link already registers that cl::opt, and registering it
// again aborts at startup. Use-list order is not preserved (the default).
static const bool PreserveUseListOrder = false;

int main(int argc, char **argv) {
  InitLLVM X(argc, argv);
  cl::ParseCommandLineOptions(
      argc, argv, "llvm-downgrade: emit legacy-version LLVM bitcode\n");

  LLVMContext Context;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseIRFile(InputFilename, Err, Context);
  if (!M) {
    Err.print(argv[0], errs());
    return 1;
  }

  if (OutputFilename.empty()) {
    if (InputFilename == "-") {
      OutputFilename = "-";
    } else {
      StringRef IFN = InputFilename;
      OutputFilename = (IFN.ends_with(".ll") ? IFN.drop_back(3) : IFN).str();
      OutputFilename += ".bc";
    }
  }

  std::error_code EC;
  ToolOutputFile Out(OutputFilename, EC, sys::fs::OF_None);
  if (EC) {
    errs() << argv[0] << ": " << OutputFilename << ": " << EC.message() << '\n';
    return 1;
  }

  // Refuse to splatter binary bitcode onto a terminal (matches llvm-as).
  if (Force || !CheckBitcodeOutputToConsole(Out.os())) {
    StringRef V = BitcodeVersion;
    if (V.empty()) {
      WriteBitcodeToFile(*M, Out.os(), PreserveUseListOrder);
    } else if (V == "5.0") {
      BitcodeWriter50::prepareModule(*M);
      WriteBitcode50ToFile(*M, Out.os(), PreserveUseListOrder);
    } else if (V == "7.0") {
      BitcodeWriter70::prepareModule(*M);
      WriteBitcode70ToFile(*M, Out.os(), PreserveUseListOrder);
#ifdef LLVMDG_HAS_140
    } else if (V == "14.0") {
      BitcodeWriter140::prepareModule(*M);
      WriteBitcode140ToFile(*M, Out.os(), PreserveUseListOrder);
#endif
    } else {
      errs() << argv[0] << ": unsupported bitcode version '" << V
             << "' for this host LLVM\n";
      return 1;
    }
    Out.keep();
  }

  return 0;
}
