//===-- Bitcode/LegacyWriter/PointerRewriter.h - Rewrite pointers -*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class supports writing opaque pointers in typed IR.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_BITCODE_LEGACYWRITER_POINTERREWRITER_H
#define LLVM_LIB_BITCODE_LEGACYWRITER_POINTERREWRITER_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {

class Constant;
class Value;
class Module;
class TypedPointerType;

using PointerTypeMap = DenseMap<const Value *, TypedPointerType *>;

class PointerRewriter {
public:
  PointerRewriter(Module &M) : M(M) {}

  bool run();

  static PointerTypeMap buildPointerMap(const Module &M);
  static bool requiresPointerRewriting(const Constant *C);

  // Return the typed pointer types in `PointerMap` in a deterministic module
  // order. Iterating the DenseMap directly orders types by `Value *` address,
  // which makes the emitted type table — and thus the whole bitcode — depend on
  // allocation addresses and so non-reproducible across runs. May repeat types;
  // the ValueEnumerator dedups them.
  static SmallVector<TypedPointerType *, 16>
  orderedPointerTypes(const Module &M, const PointerTypeMap &PointerMap);

private:
  Module &M;
};


} // End llvm namespace

#endif
