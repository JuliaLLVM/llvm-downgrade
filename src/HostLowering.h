//===- HostLowering.h - Lower host-only IR for every target -----*- C++ -*-===//
//
// Constructs the host LLVM introduced in a form that no target format can
// represent as is. Every target's prepareModule runs this first.
//
//===----------------------------------------------------------------------===//

#pragma once

namespace llvm {
class Module;
}

namespace llvmdg {

// Rewrite LLVM 23 constructs into their pre-23 form, or reject them with a
// DowngradeError naming TargetMajor. Returns whether the module changed.
bool lowerHostConstructs(llvm::Module &M, unsigned TargetMajor);

} // namespace llvmdg
