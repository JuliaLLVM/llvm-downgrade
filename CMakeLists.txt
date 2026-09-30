cmake_minimum_required(VERSION 3.20)
project(llvm-downgrade C CXX)

# Build out-of-tree against a prebuilt LLVM (find_package(LLVM)). The legacy
# bitcode writers in src/ are forks of LLVM's own BitcodeWriter, adapted to the
# host LLVM's C++ API, so they are version-specific. This checkout targets one
# LLVM major version; bump LLVMDG_LLVM_MAJOR and re-extract src/ + include/ from
# the matching downgrade_release_<major> branch to move to a newer LLVM.
find_package(LLVM REQUIRED CONFIG)

set(LLVMDG_LLVM_MAJOR 23)
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
include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/common)
include_directories(${LLVM_INCLUDE_DIRS})
# LLVMConfig.cmake provides LLVM_DEFINITIONS as one space-separated string. If
# it is passed to add_definitions() whole and its first flag carries a value
# (e.g. -D_GLIBCXX_USE_CXX11_ABI=1, as on mingw/musl where no -D_GNU_SOURCE
# precedes it), CMake parses the remaining flags as part of that value and the
# compiler gets -D_GLIBCXX_USE_CXX11_ABI="1 -D_FILE_OFFSET_BITS=64 ...".
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND "${LLVM_DEFINITIONS}")
add_definitions(${LLVM_DEFINITIONS_LIST})

file(GLOB WRITER_SRCS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/BitcodeWriter140.cpp)
  add_compile_definitions(LLVMDG_HAS_140)
endif()
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/BitcodeWriter180.cpp)
  add_compile_definitions(LLVMDG_HAS_180)
endif()

# The tool links the shared library when enabled, or embeds the writers.
option(LLVMDG_BUILD_LIBRARY "Build the libllvm_downgrade shared library" ON)
option(LLVMDG_BUILD_TOOL "Build the llvm-downgrade tool" ON)
if(NOT LLVMDG_BUILD_LIBRARY AND NOT LLVMDG_BUILD_TOOL)
  message(FATAL_ERROR "Nothing to build: enable LLVMDG_BUILD_LIBRARY and/or LLVMDG_BUILD_TOOL")
endif()

# Default: link the LLVM component static archives, producing self-contained
# binaries with no runtime libLLVM dependency. Set -DLLVMDG_LINK_DYLIB=ON to link
# the monolithic libLLVM instead (e.g. against a distro LLVM that only ships the
# shared library).
option(LLVMDG_LINK_DYLIB "Link the monolithic libLLVM shared library" OFF)
if(LLVMDG_LINK_DYLIB)
  set(_llvm_libs LLVM)
else()
  llvm_map_components_to_libnames(_llvm_libs
    AsmParser BitReader BitWriter IRReader Object Analysis Core MC TargetParser
    Support)
endif()

# Keep the embedded LLVM private to the library.
add_library(llvm_downgrade_core OBJECT
  lib/llvm-downgrade.cpp
  common/legacy_opts.cpp
  ${WRITER_SRCS})
set_target_properties(llvm_downgrade_core PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
  POSITION_INDEPENDENT_CODE ON)
target_include_directories(llvm_downgrade_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
if(LLVMDG_BUILD_LIBRARY)
  target_compile_definitions(llvm_downgrade_core PRIVATE LLVMDG_EXPORTS)
else()
  target_compile_definitions(llvm_downgrade_core PRIVATE LLVMDG_STATIC)
endif()
# Writer errors unwind through our code, even when LLVM was built without EH.
if(MSVC)
  target_compile_options(llvm_downgrade_core PRIVATE /EHsc)
else()
  target_compile_options(llvm_downgrade_core PRIVATE -fexceptions)
endif()
if(NOT LLVM_ENABLE_RTTI)
  if(MSVC)
    target_compile_options(llvm_downgrade_core PRIVATE /GR-)
  else()
    target_compile_options(llvm_downgrade_core PRIVATE -fno-rtti)
  endif()
endif()
# Make the de-static'd-opt shim (see common/LegacyOpts.h) visible in every
# writer translation unit.
if(MSVC)
  target_compile_options(llvm_downgrade_core PRIVATE /FI${CMAKE_CURRENT_SOURCE_DIR}/common/LegacyOpts.h)
else()
  target_compile_options(llvm_downgrade_core PRIVATE -include ${CMAKE_CURRENT_SOURCE_DIR}/common/LegacyOpts.h)
endif()
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND NOT WIN32)
  # glibc treats STB_GNU_UNIQUE symbols as process-unique regardless of
  # visibility, which would defeat the isolation.
  target_compile_options(llvm_downgrade_core PRIVATE -fno-gnu-unique)
endif()

if(LLVMDG_BUILD_LIBRARY)
  add_library(llvm_downgrade SHARED $<TARGET_OBJECTS:llvm_downgrade_core>)
  set_property(TARGET llvm_downgrade PROPERTY WINDOWS_EXPORT_ALL_SYMBOLS OFF)
  target_include_directories(llvm_downgrade PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_link_libraries(llvm_downgrade PRIVATE ${_llvm_libs})
  if(APPLE)
    target_link_options(llvm_downgrade PRIVATE
      -Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/lib/llvm-downgrade.exports
      -Wl,-dead_strip)
  elseif(MINGW)
    # Export only the dllexport'd API: auto-export would overflow the 64K PE
    # export limit with the static LLVM.
    target_link_options(llvm_downgrade PRIVATE -Wl,--exclude-all-symbols)
  elseif(UNIX)
    target_link_options(llvm_downgrade PRIVATE
      -Wl,--exclude-libs,ALL -Wl,-Bsymbolic -Wl,--gc-sections
      -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/lib/llvm-downgrade.map)
  endif()
  if(APPLE)
    set_property(TARGET llvm_downgrade APPEND PROPERTY LINK_DEPENDS
      ${CMAKE_CURRENT_SOURCE_DIR}/lib/llvm-downgrade.exports)
  elseif(UNIX)
    set_property(TARGET llvm_downgrade APPEND PROPERTY LINK_DEPENDS
      ${CMAKE_CURRENT_SOURCE_DIR}/lib/llvm-downgrade.map)
  endif()
  install(TARGETS llvm_downgrade
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
  install(FILES include/llvm-downgrade.h DESTINATION include)
endif()

if(LLVMDG_BUILD_TOOL)
  if(LLVMDG_BUILD_LIBRARY)
    add_executable(llvm-downgrade tools/llvm-downgrade.c)
    target_link_libraries(llvm-downgrade PRIVATE llvm_downgrade)
    if(APPLE)
      set_property(TARGET llvm-downgrade PROPERTY INSTALL_RPATH "@loader_path/../lib")
    elseif(UNIX)
      set_property(TARGET llvm-downgrade PROPERTY INSTALL_RPATH "$ORIGIN/../lib")
    endif()
  else()
    add_executable(llvm-downgrade tools/llvm-downgrade.c
      $<TARGET_OBJECTS:llvm_downgrade_core>)
    target_include_directories(llvm-downgrade PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_compile_definitions(llvm-downgrade PRIVATE LLVMDG_STATIC)
    target_link_libraries(llvm-downgrade PRIVATE ${_llvm_libs})
  endif()
  set_property(TARGET llvm-downgrade PROPERTY C_STANDARD 99)
  install(TARGETS llvm-downgrade RUNTIME DESTINATION bin)
endif()

# FileCheck-based test suite (see test/). Enabled by default; disable with
# -DLLVMDG_BUILD_TESTS=OFF.
option(LLVMDG_BUILD_TESTS "Build the downgrader test suite" ON)
if(LLVMDG_BUILD_TESTS)
  enable_testing()
  add_subdirectory(test)
endif()
