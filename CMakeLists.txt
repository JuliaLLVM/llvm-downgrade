cmake_minimum_required(VERSION 3.20)
project(llvm-downgrade C CXX)

# Build out-of-tree against a prebuilt LLVM (find_package(LLVM)). The legacy
# bitcode writers in src/ are forks of LLVM's own BitcodeWriter, adapted to the
# host LLVM's C++ API, so they are version-specific. This checkout targets one
# LLVM major version; bump LLVMDG_LLVM_MAJOR and re-extract src/ + include/ from
# the matching downgrade_release_<major> branch to move to a newer LLVM.
find_package(LLVM REQUIRED CONFIG)

set(LLVMDG_LLVM_MAJOR 22)
if(NOT LLVM_VERSION_MAJOR EQUAL LLVMDG_LLVM_MAJOR)
  message(FATAL_ERROR
    "llvm-downgrade's bundled writers are for LLVM ${LLVMDG_LLVM_MAJOR}, but found "
    "LLVM ${LLVM_VERSION_MAJOR}. Re-extract src/ and include/ from the "
    "downgrade_release_${LLVM_VERSION_MAJOR} branch to target this LLVM.")
endif()
message(STATUS "llvm-downgrade: building against LLVM ${LLVM_PACKAGE_VERSION}")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
include(AddLLVM)

# Our augmented LLVM headers (BitcodeWriter.h with the legacy-writer
# declarations, LLVMBitCodes.h with ATTR_KIND_INVALID, Metadata{50,70}.def) must
# shadow the installed ones; they are version-matched to the LLVM we link.
include_directories(BEFORE ${CMAKE_SOURCE_DIR}/include)
include_directories(${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/common)
include_directories(${LLVM_INCLUDE_DIRS})
# LLVMConfig.cmake provides LLVM_DEFINITIONS as one space-separated string. If
# it is passed to add_definitions() whole and its first flag carries a value
# (e.g. -D_GLIBCXX_USE_CXX11_ABI=1, as on mingw/musl where no -D_GNU_SOURCE
# precedes it), CMake parses the remaining flags as part of that value and the
# compiler gets -D_GLIBCXX_USE_CXX11_ABI="1 -D_FILE_OFFSET_BITS=64 ...".
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND "${LLVM_DEFINITIONS}")
add_definitions(${LLVM_DEFINITIONS_LIST})

if(NOT LLVM_ENABLE_RTTI)
  add_compile_options(-fno-rtti)
endif()

# Make the de-static'd-opt shim (see common/LegacyOpts.h) visible everywhere.
add_compile_options(-include ${CMAKE_SOURCE_DIR}/common/LegacyOpts.h)

file(GLOB WRITER_SRCS CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/src/*.cpp)
if(EXISTS ${CMAKE_SOURCE_DIR}/src/BitcodeWriter140.cpp)
  add_compile_definitions(LLVMDG_HAS_140)
endif()
if(EXISTS ${CMAKE_SOURCE_DIR}/src/BitcodeWriter150.cpp)
  add_compile_definitions(LLVMDG_HAS_150)
endif()
if(EXISTS ${CMAKE_SOURCE_DIR}/src/BitcodeWriter180.cpp)
  add_compile_definitions(LLVMDG_HAS_180)
endif()

add_executable(llvm-downgrade
  tools/llvm-downgrade.cpp
  common/legacy_opts.cpp
  ${WRITER_SRCS})

# Default: link the LLVM component static archives, producing a self-contained
# tool with no runtime libLLVM dependency. Set -DLLVMDG_LINK_DYLIB=ON to link
# the monolithic libLLVM instead (e.g. against a distro LLVM that only ships the
# shared library).
option(LLVMDG_LINK_DYLIB "Link the monolithic libLLVM shared library" OFF)
if(LLVMDG_LINK_DYLIB)
  target_link_libraries(llvm-downgrade PRIVATE LLVM)
else()
  llvm_map_components_to_libnames(_llvm_libs
    AsmParser BitReader BitWriter IRReader Object Analysis Core MC TargetParser
    Support)
  target_link_libraries(llvm-downgrade PRIVATE ${_llvm_libs})
endif()

install(TARGETS llvm-downgrade RUNTIME DESTINATION bin)

# FileCheck-based test suite (see test/). Enabled by default; disable with
# -DLLVMDG_BUILD_TESTS=OFF.
option(LLVMDG_BUILD_TESTS "Build the downgrader test suite" ON)
if(LLVMDG_BUILD_TESTS)
  enable_testing()
  add_subdirectory(test)
endif()
