/* Command-line driver for the downgrader C API. */

#include "llvm-downgrade.h"

#include <stdint.h>
#include <stdio.h>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif
#include <stdlib.h>
#include <string.h>

static void usage(FILE *Out) {
  size_t Count, I;
  const char *const *Targets = LLVMDGGetTargets(&Count);
  fprintf(
      Out,
      "usage: llvm-downgrade --bitcode-version=<version> [<input>] [-o "
      "<output>]\n"
      "\n"
      "Re-emits an LLVM module (bitcode or textual IR) in an older bitcode\n"
      "format. `-` reads standard input / writes standard output.\n"
      "\n"
      "options:\n"
      "  --bitcode-version=<v>  target bitcode version:");
  for (I = 0; I < Count; ++I)
    fprintf(Out, "%s %s", I ? "," : "", Targets[I]);
  fprintf(Out,
          "\n"
          "  -o <output>            output file (default: standard output)\n"
          "  --version              print the embedded LLVM version and exit\n"
          "  --help                 print this message and exit\n");
}

static char *readAll(FILE *In, size_t *Length) {
  size_t Capacity = 1 << 16, Size = 0;
  char *Data = malloc(Capacity);
  if (!Data)
    return NULL;
  for (;;) {
    size_t N = fread(Data + Size, 1, Capacity - Size, In);
    Size += N;
    if (Size < Capacity)
      break;
    if (Capacity > SIZE_MAX / 2) {
      free(Data);
      return NULL;
    }
    Capacity *= 2;
    char *Grown = realloc(Data, Capacity);
    if (!Grown) {
      free(Data);
      return NULL;
    }
    Data = Grown;
  }
  if (ferror(In)) {
    free(Data);
    return NULL;
  }
  *Length = Size;
  return Data;
}

int main(int argc, char **argv) {
  const char *Version = NULL, *Input = "-", *Output = "-";
  int HaveInput = 0;
  unsigned Major, Minor;

  for (int A = 1; A < argc; ++A) {
    const char *Arg = argv[A];
    if (!strcmp(Arg, "--help") || !strcmp(Arg, "-h")) {
      usage(stdout);
      return 0;
    } else if (!strcmp(Arg, "--version")) {
      LLVMDGGetLLVMVersion(&Major, &Minor, NULL);
      printf("llvm-downgrade (LLVM %u.%u)\n", Major, Minor);
      return 0;
    } else if (!strncmp(Arg, "--bitcode-version=", 18)) {
      Version = Arg + 18;
    } else if (!strcmp(Arg, "--bitcode-version") && A + 1 < argc) {
      Version = argv[++A];
    } else if (!strncmp(Arg, "-o=", 3)) {
      Output = Arg + 3;
    } else if (!strcmp(Arg, "-o") && A + 1 < argc) {
      Output = argv[++A];
    } else if (Arg[0] == '-' && Arg[1] != '\0') {
      fprintf(stderr, "llvm-downgrade: unknown option '%s'\n", Arg);
      usage(stderr);
      return 1;
    } else if (!HaveInput) {
      Input = Arg;
      HaveInput = 1;
    } else {
      fprintf(stderr, "llvm-downgrade: more than one input file\n");
      return 1;
    }
  }
  if (!Version) {
    fprintf(stderr, "llvm-downgrade: --bitcode-version is required\n");
    usage(stderr);
    return 1;
  }
  size_t Count;
  const char *const *Targets = LLVMDGGetTargets(&Count);
  size_t I;
  for (I = 0; I < Count; ++I)
    if (!strcmp(Version, Targets[I]))
      break;
  if (I == Count || sscanf(Version, "%u.%u", &Major, &Minor) != 2) {
    fprintf(stderr, "llvm-downgrade: unsupported bitcode version '%s'\n",
            Version);
    return 1;
  }

#ifdef _WIN32
  if ((!strcmp(Input, "-") && _setmode(_fileno(stdin), _O_BINARY) == -1) ||
      (!strcmp(Output, "-") && _setmode(_fileno(stdout), _O_BINARY) == -1)) {
    perror("binary standard I/O");
    return 1;
  }
#endif

  FILE *In = strcmp(Input, "-") ? fopen(Input, "rb") : stdin;
  if (!In) {
    perror(Input);
    return 1;
  }
  size_t Length;
  char *Data = readAll(In, &Length);
  if (In != stdin)
    fclose(In);
  if (!Data) {
    fprintf(stderr, "llvm-downgrade: cannot read '%s'\n", Input);
    return 1;
  }

  LLVMDGMemoryBufferRef Result;
  char *Message;
  int Status = LLVMDGDowngrade(Data, Length, Major, Minor, &Result, &Message);
  free(Data);
  if (Status) {
    fprintf(stderr, "llvm-downgrade: %s\n",
            Message ? Message : "downgrade failed");
    LLVMDGDisposeMessage(Message);
    return 1;
  }

  FILE *Out = strcmp(Output, "-") ? fopen(Output, "wb") : stdout;
  if (!Out) {
    perror(Output);
    LLVMDGDisposeMemoryBuffer(Result);
    return 1;
  }
  size_t Size = LLVMDGGetBufferSize(Result);
  int Failed = fwrite(LLVMDGGetBufferStart(Result), 1, Size, Out) != Size;
  if (Out == stdout) {
    if (fflush(Out) != 0)
      Failed = 1;
  } else if (fclose(Out) != 0) {
    Failed = 1;
  }
  LLVMDGDisposeMemoryBuffer(Result);
  if (Failed) {
    fprintf(stderr, "llvm-downgrade: cannot write '%s'\n", Output);
    return 1;
  }
  return 0;
}
