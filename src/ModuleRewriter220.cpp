//===- ModuleRewriter220.cpp - Rewrite IR for LLVM 22 ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements BitcodeWriter220::prepareModule, which lowers the
// current module to a form the LLVM 22 bitcode writer can emit.
//
//===----------------------------------------------------------------------===//

#include "DowngradeError.h"
#include "HostLowering.h"

#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
using namespace llvm;

// LLVM 23 made llvm.returnaddress and llvm.clear_cache overloaded on their
// pointer type, mangling their names with a pointer suffix (e.g.
// llvm.returnaddress.p0). LLVM 22 only knows the unmangled names, which take
// or return an address-space-0 pointer; rename them back.
static bool renameLegacyIntrinsics(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (!F.isIntrinsic())
      continue;
    StringRef Name;
    switch (F.getIntrinsicID()) {
    case Intrinsic::returnaddress:  Name = "llvm.returnaddress";  break;
    case Intrinsic::clear_cache:    Name = "llvm.clear_cache";    break;
    default: continue;
    }
    auto InDefaultAS = [](Type *Ty) {
      return !Ty->isPointerTy() || Ty->getPointerAddressSpace() == 0;
    };
    if (!InDefaultAS(F.getReturnType()) ||
        !llvm::all_of(F.getFunctionType()->params(), InDefaultAS))
      llvmdg::reportError(Twine(Name) + " on a pointer outside address space "
                          "0 is not supported with LLVM 22");
    if (F.getName() != Name) {
      F.setName(Name);
      Changed = true;
    }
  }
  return Changed;
}

bool BitcodeWriter220::prepareModule(Module &M) {
  // LLVM 22 supports lifetime markers without a size, #dbg_declare_value
  // records and all attribute representations natively. The writer drops
  // attribute kinds that postdate it.
  bool Changed = llvmdg::lowerHostConstructs(M, 22);
  Changed |= renameLegacyIntrinsics(M);
  return Changed;
}
