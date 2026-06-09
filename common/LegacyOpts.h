#pragma once
// The in-tree downgrader de-statics two cl::opt globals in
// lib/Bitcode/Writer/BitcodeWriter.cpp (global namespace) so the legacy writers
// can reuse them. When building out-of-tree against a prebuilt libLLVM those
// symbols stay `static` (internal), so we declare them here -- matching the
// writers' own global-scope `extern cl::opt<...>` declarations -- and define our
// own copies in common/legacy_opts.cpp. This header is force-included into every
// translation unit (see CMakeLists.txt) so even the writers that use the globals
// without re-declaring them (e.g. BitcodeWriter50.cpp) compile.
#include "llvm/Support/CommandLine.h"
extern llvm::cl::opt<unsigned> IndexThreshold;
extern llvm::cl::opt<bool> WriteRelBFToSummary;
