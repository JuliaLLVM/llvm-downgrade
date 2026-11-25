//===- HostLowering.cpp - Lower host-only IR for every target -------------===//

#include "HostLowering.h"
#include "DowngradeError.h"

#include "llvm/ADT/FloatingPointMode.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

// LLVM 17 added the "dynamic" denormal mode. Earlier releases cannot parse
// it and assume IEEE for code that does not specify a mode, so use that.
DenormalMode legacyDenormalMode(DenormalMode Mode, unsigned TargetMajor) {
  if (TargetMajor < 17) {
    if (Mode.Output == DenormalMode::Dynamic)
      Mode.Output = DenormalMode::IEEE;
    if (Mode.Input == DenormalMode::Dynamic)
      Mode.Input = DenormalMode::IEEE;
  }
  return Mode;
}

std::string denormalModeString(DenormalMode Mode) {
  std::string S;
  raw_string_ostream OS(S);
  // "out,in", or just "out" when both match: the single-component form is
  // the only one LLVM releases before 11 understand.
  Mode.print(OS, /*Legacy=*/true, /*OmitIfSame=*/true);
  return S;
}

// LLVM 23 promoted some string function attributes to first-class attributes
// (and auto-upgrades the old spelling when reading). The legacy writers have
// no encoding for the new kinds and would drop them, which loses semantics:
// the denormal mode changes floating-point results, and AMDGPU reads a
// valueless "uniform-work-group-size" as false. Restore the string forms.
AttributeList lowerFnAttrs(LLVMContext &C, AttributeList AL,
                           unsigned TargetMajor, bool &Changed) {
  AttributeSet FnAttrs = AL.getFnAttrs();
  if (!FnAttrs.hasAttributes())
    return AL;
  AttrBuilder B(C, FnAttrs);
  bool Modified = false;

  if (Attribute A = FnAttrs.getAttribute(Attribute::DenormalFPEnv);
      A.isValid()) {
    DenormalFPEnv Env = A.getDenormalFPEnv();
    DenormalMode Default = legacyDenormalMode(Env.DefaultMode, TargetMajor);
    DenormalMode F32 = legacyDenormalMode(Env.F32Mode, TargetMajor);
    B.removeAttribute(Attribute::DenormalFPEnv);
    // An absent attribute means IEEE, and an absent f32 one means the same as
    // the default mode.
    if (Default != DenormalMode::getIEEE())
      B.addAttribute("denormal-fp-math", denormalModeString(Default));
    if (F32 != Default)
      B.addAttribute("denormal-fp-math-f32", denormalModeString(F32));
    Modified = true;
  }

  if (FnAttrs.hasAttribute(Attribute::NoOutline)) {
    B.removeAttribute(Attribute::NoOutline);
    B.addAttribute("nooutline");
    Modified = true;
  }

  if (Attribute A = FnAttrs.getAttribute("uniform-work-group-size");
      A.isValid() && A.getValueAsString().empty()) {
    B.addAttribute("uniform-work-group-size", "true");
    Modified = true;
  }

  if (!Modified)
    return AL;
  Changed = true;
  return AL.removeFnAttributes(C).addFnAttributes(C, B);
}

// LLVM 23 added the elementwise modifier to atomicrmw, which makes a vector
// operation atomic per element instead of as a whole. Whole-value atomicity
// is strictly stronger, so floating-point operations, which older formats
// already allow on vectors, can drop the modifier. Integer and pointer
// vectors are only valid with it.
bool lowerElementwiseAtomics(Function &F, unsigned TargetMajor) {
  bool Changed = false;
  for (Instruction &I : instructions(F)) {
    auto *RMW = dyn_cast<AtomicRMWInst>(&I);
    if (!RMW || !RMW->isElementwise())
      continue;
    if (!RMW->isFloatingPointOperation())
      llvmdg::reportError(Twine("elementwise atomicrmw ") +
                          AtomicRMWInst::getOperationName(
                              RMW->getOperation()) +
                          " is not supported with LLVM " + Twine(TargetMajor));
    RMW->setElementwise(false);
    Changed = true;
  }
  return Changed;
}

} // namespace

bool llvmdg::lowerHostConstructs(Module &M, unsigned TargetMajor) {
  bool Changed = false;
  LLVMContext &C = M.getContext();
  for (Function &F : M) {
    F.setAttributes(lowerFnAttrs(C, F.getAttributes(), TargetMajor, Changed));
    for (Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        CB->setAttributes(
            lowerFnAttrs(C, CB->getAttributes(), TargetMajor, Changed));
    Changed |= lowerElementwiseAtomics(F, TargetMajor);
  }
  return Changed;
}
