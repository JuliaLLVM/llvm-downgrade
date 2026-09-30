//===- ModuleRewriter200.cpp - Rewrite IR for LLVM 20 ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements BitcodeWriter200::prepareModule, which lowers the
// current module to a form the LLVM 20 bitcode writer can emit.
//
//===----------------------------------------------------------------------===//

#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/DebugProgramInstruction.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
using namespace llvm;

// LLVM made some pointer-typed intrinsics overloaded on the pointer type
// after 20, mangling their names with a pointer suffix (thread.pointer in 21;
// e.g. llvm.thread.pointer.p0). LLVM 20 only knows the unmangled names;
// rename them back. (stacksave/stackrestore were mangled in 17 and
// va_start/va_end/va_copy in 19, so they keep their host names.)
static bool renameLegacyIntrinsics(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (!F.isIntrinsic())
      continue;
    StringRef Name;
    switch (F.getIntrinsicID()) {
    case Intrinsic::thread_pointer: Name = "llvm.thread.pointer"; break;
    default: continue;
    }
    if (F.getName() != Name) {
      F.setName(Name);
      Changed = true;
    }
  }
  return Changed;
}

// Remove llvm.lifetime.start/end markers: LLVM 22 dropped their size
// argument, so the modern form cannot be expressed against any legacy
// signature (old readers upgrade the call by name and crash on the missing
// argument). They are pure optimization hints, so dropping them is safe.
static bool dropLifetimeIntrinsics(Module &M) {
  bool Changed = false;
  for (Function &F : llvm::make_early_inc_range(M)) {
    if (F.getIntrinsicID() != Intrinsic::lifetime_start &&
        F.getIntrinsicID() != Intrinsic::lifetime_end)
      continue;
    for (User *U : llvm::make_early_inc_range(F.users()))
      if (auto *CI = dyn_cast<CallInst>(U))
        CI->eraseFromParent();
    if (F.use_empty())
      F.eraseFromParent();
    Changed = true;
  }
  return Changed;
}

// Remove #dbg_declare_value records (LLVM 22). LLVM 20 has no such record
// kind and fails to read the module; like the other debug records the pre-20
// targets drop, losing them only loses variable locations.
static bool dropDeclareValueRecords(Module &M) {
  bool Changed = false;
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      for (DbgVariableRecord &DVR :
           llvm::make_early_inc_range(filterDbgVars(I.getDbgRecordRange())))
        if (DVR.isDbgDeclareValue()) {
          DVR.eraseFromParent();
          Changed = true;
        }
  return Changed;
}

bool BitcodeWriter200::prepareModule(Module &M) {
  // LLVM 20 is opaque-pointer-only and supports target extension types,
  // debug records and all attribute representations natively. The writer
  // drops attribute kinds that postdate it.
  bool Changed = false;
  Changed |= renameLegacyIntrinsics(M);
  Changed |= dropLifetimeIntrinsics(M);
  Changed |= dropDeclareValueRecords(M);
  return Changed;
}
