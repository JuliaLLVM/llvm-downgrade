cmake_minimum_required(VERSION 3.20)
project(llvm-downgrade C CXX)

# Build out-of-tree against a prebuilt LLVM (find_package(LLVM)). The legacy
# bitcode writers are version-matched to the host LLVM, so we pick the bundled
# sources for whatever LLVM major version was found.
find_package(LLVM REQUIRED CONFIG)

set(_V ${LLVM_VERSION_MAJOR})
set(_VDIR ${CMAKE_CURRENT_SOURCE_DIR}/versions/${_V})
if(NOT IS_DIRECTORY ${_VDIR})
  message(FATAL_ERROR
    "llvm-downgrade: no legacy bitcode writers bundled for LLVM ${_V} "
    "(have versions/13 .. versions/22)")
endif()
message(STATUS "llvm-downgrade: LLVM ${LLVM_PACKAGE_VERSION}; using versions/${_V}")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
include(AddLLVM)

# Our augmented LLVM headers (BitcodeWriter.h with the legacy writer
# declarations, LLVMBitCodes.h with ATTR_KIND_INVALID, Metadata{50,70}.def) must
# shadow the installed ones; they are version-matched to the LLVM we link.
include_directories(BEFORE ${_VDIR}/include)
include_directories(${_VDIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/common)
include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

if(NOT LLVM_ENABLE_RTTI)
  add_compile_options(-fno-rtti)
endif()

# Make the de-static'd-opt shim (see common/LegacyOpts.h) visible everywhere.
add_compile_options(-include ${CMAKE_CURRENT_SOURCE_DIR}/common/LegacyOpts.h)

file(GLOB WRITER_SRCS CONFIGURE_DEPENDS ${_VDIR}/src/*.cpp)
if(EXISTS ${_VDIR}/src/BitcodeWriter140.cpp)
  add_compile_definitions(LLVMDG_HAS_140)
endif()

add_executable(llvm-downgrade
  tools/llvm-downgrade.cpp
  common/legacy_opts.cpp
  ${WRITER_SRCS})

# Default: link the LLVM component static archives, producing a self-contained
# tool with no runtime libLLVM dependency (matches the historical llvm-as
# artifact). Set -DLLVMDG_LINK_DYLIB=ON to link the monolithic libLLVM instead
# (e.g. for local dev against a distro LLVM that only ships the shared lib).
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
