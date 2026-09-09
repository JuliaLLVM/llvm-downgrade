#include "llvm-downgrade.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(Condition)                                                       \
  do {                                                                         \
    if (!(Condition)) {                                                        \
      fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, #Condition);          \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

static void checkSuccess(unsigned Major) {
  /* Deliberately exclude the terminating NUL from the input. */
  const char IR[] = "define i32 @f() { ret i32 42 }";
  LLVMDGMemoryBufferRef Out = NULL;
  char *Message = NULL;
  CHECK(!LLVMDGDowngrade(IR, sizeof(IR) - 1, Major, 0, &Out, &Message));
  CHECK(Out && !Message);
  CHECK(LLVMDGGetBufferSize(Out) > 4);
  CHECK(!memcmp(LLVMDGGetBufferStart(Out), "BC\300\336", 4));

  /* The returned bitcode is also accepted as input, with independent ownership.
   */
  LLVMDGMemoryBufferRef Again = NULL;
  CHECK(!LLVMDGDowngrade(LLVMDGGetBufferStart(Out), LLVMDGGetBufferSize(Out),
                         Major, 0, &Again, NULL));
  LLVMDGDisposeMemoryBuffer(Out);
  CHECK(LLVMDGGetBufferSize(Again) > 4);
  LLVMDGDisposeMemoryBuffer(Again);
}

int main(void) {
  size_t Count = 0;
  const char *const *Targets = LLVMDGGetTargets(&Count);
  CHECK(Count >= 2);
  CHECK(Targets == LLVMDGGetTargets(NULL));
  unsigned Major, Minor, Patch;
  LLVMDGGetLLVMVersion(&Major, &Minor, &Patch);
  CHECK(Major == 22);
  LLVMDGGetLLVMVersion(NULL, NULL, NULL);
  LLVMDGDisposeMessage(NULL);
  LLVMDGDisposeMemoryBuffer(NULL);

  for (size_t I = 0; I < Count; ++I) {
    CHECK(sscanf(Targets[I], "%u.%u", &Major, &Minor) == 2);
    checkSuccess(Major);
  }

  const char *Invalid[] = {
      "this is not LLVM IR",
      /* Rejected during writer type enumeration, after parsing succeeded. */
      "declare bfloat @unsupported()",
      /* Rejected during pointer rewriting, before writing. */
      "declare ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()\n"
      "define ptr addrspace(4) @f() {\n"
      "  %p = call ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()\n"
      "  ret ptr addrspace(4) %p\n}"};
  for (size_t I = 0; I < sizeof(Invalid) / sizeof(*Invalid); ++I) {
    for (int Repeat = 0; Repeat < 3; ++Repeat) {
      LLVMDGMemoryBufferRef Out = NULL;
      char *Message = NULL;
      CHECK(LLVMDGDowngrade(Invalid[I], strlen(Invalid[I]), 5, 0, &Out,
                            &Message));
      CHECK(!Out && Message && *Message);
      LLVMDGDisposeMessage(Message);
      checkSuccess(5);
    }
  }
  LLVMDGMemoryBufferRef Out = NULL;
  char *Message = NULL;
  CHECK(LLVMDGDowngrade("", 0, 99, 0, &Out, &Message));
  CHECK(!Out && Message && strstr(Message, "unsupported bitcode version"));
  LLVMDGDisposeMessage(Message);
  CHECK(LLVMDGDowngrade(NULL, 0, 5, 0, &Out, NULL));
  CHECK(LLVMDGDowngrade("", 0, 5, 0, NULL, NULL));
  return 0;
}
