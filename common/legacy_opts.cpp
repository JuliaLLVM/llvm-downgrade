#include "llvm/Support/CommandLine.h"
// Defined at global scope to match the legacy writers' `extern cl::opt<...>`
// declarations. The option names are deliberately distinct from libLLVM's own
// "bitcode-mdindex-threshold" / "write-relbf-to-summary" so that registering
// ours does not collide with the copies libLLVM still registers internally.
llvm::cl::opt<unsigned> IndexThreshold("legacy-bitcode-mdindex-threshold",
                                       llvm::cl::Hidden, llvm::cl::init(25));
llvm::cl::opt<bool> WriteRelBFToSummary("legacy-write-relbf-to-summary",
                                        llvm::cl::Hidden, llvm::cl::init(false));
