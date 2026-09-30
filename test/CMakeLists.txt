# Exercise the C ABI in library-only builds too.
add_executable(llvm-downgrade-api-test api.c)
set_property(TARGET llvm-downgrade-api-test PROPERTY C_STANDARD 99)
target_compile_definitions(llvm-downgrade-api-test PRIVATE LLVMDG_LLVM_MAJOR=${LLVMDG_LLVM_MAJOR})
if(LLVMDG_BUILD_LIBRARY)
  target_link_libraries(llvm-downgrade-api-test PRIVATE llvm_downgrade)
else()
  target_sources(llvm-downgrade-api-test PRIVATE $<TARGET_OBJECTS:llvm_downgrade_core>)
  target_compile_definitions(llvm-downgrade-api-test PRIVATE LLVMDG_STATIC)
  target_link_libraries(llvm-downgrade-api-test PRIVATE ${_llvm_libs})
endif()
add_test(NAME api COMMAND llvm-downgrade-api-test)

if(NOT LLVMDG_BUILD_TOOL)
  return()
endif()

add_test(NAME cli COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/cli.sh $<TARGET_FILE:llvm-downgrade>)

# FileCheck-based downgrader tests. Each tests/<name>.ll is downgraded to its
# target bitcode version(s), disassembled with the matching *legacy* llvm-dis,
# and checked with FileCheck (see run-downgrade-test.sh).
#
# FileCheck is taken from the LLVM install. The legacy disassemblers are not part
# of any modern LLVM, so they must be supplied; a version whose disassembler is
# absent is reported as skipped rather than failed:
#
#   -DLLVMDG_DIS_5_0=/path/to/llvm-5/bin/llvm-dis
#   -DLLVMDG_DIS_7_0=/path/to/llvm-7/bin/llvm-dis
#   -DLLVMDG_DIS_14_0=/path/to/llvm-14/bin/llvm-dis
#   -DLLVMDG_DIS_18_0=/path/to/llvm-18/bin/llvm-dis
#
# llvm-dis does not run the IR verifier, so it misses semantically invalid
# output (mismatched attribute types, bad intrinsic signatures, ...). If the
# matching legacy opt is also supplied, each downgraded module is additionally
# run through its full verifier:
#
#   -DLLVMDG_OPT_5_0=/path/to/llvm-5/bin/opt   (etc.)

find_program(LLVMDG_FILECHECK NAMES FileCheck HINTS ${LLVM_TOOLS_BINARY_DIR}
             DOC "FileCheck used by the downgrader test suite")
if(NOT LLVMDG_FILECHECK)
  message(WARNING "FileCheck not found; downgrader tests will report as skipped")
endif()

set(LLVMDG_DIS_5_0  "" CACHE FILEPATH "legacy LLVM 5.0 llvm-dis (for 5.0 tests)")
set(LLVMDG_DIS_7_0  "" CACHE FILEPATH "legacy LLVM 7.0 llvm-dis (for 7.0 tests)")
set(LLVMDG_DIS_14_0 "" CACHE FILEPATH "legacy LLVM 14.0 llvm-dis (for 14.0 tests)")
set(LLVMDG_DIS_18_0 "" CACHE FILEPATH "legacy LLVM 18.0 llvm-dis (for 18.0 tests)")

set(LLVMDG_OPT_5_0  "" CACHE FILEPATH "legacy LLVM 5.0 opt (verifies 5.0 tests)")
set(LLVMDG_OPT_7_0  "" CACHE FILEPATH "legacy LLVM 7.0 opt (verifies 7.0 tests)")
set(LLVMDG_OPT_14_0 "" CACHE FILEPATH "legacy LLVM 14.0 opt (verifies 14.0 tests)")
set(LLVMDG_OPT_18_0 "" CACHE FILEPATH "legacy LLVM 18.0 opt (verifies 18.0 tests)")

set(_runner ${CMAKE_CURRENT_SOURCE_DIR}/run-downgrade-test.sh)
file(GLOB _tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.ll)
foreach(_t ${_tests})
  get_filename_component(_name ${_t} NAME_WE)
  add_test(NAME downgrade/${_name}
    COMMAND ${_runner}
      --tool       $<TARGET_FILE:llvm-downgrade>
      --filecheck  "${LLVMDG_FILECHECK}"
      --host-major ${LLVM_VERSION_MAJOR}
      --dis-5      "${LLVMDG_DIS_5_0}"
      --dis-7      "${LLVMDG_DIS_7_0}"
      --dis-14     "${LLVMDG_DIS_14_0}"
      --dis-18     "${LLVMDG_DIS_18_0}"
      --opt-5      "${LLVMDG_OPT_5_0}"
      --opt-7      "${LLVMDG_OPT_7_0}"
      --opt-14     "${LLVMDG_OPT_14_0}"
      --opt-18     "${LLVMDG_OPT_18_0}"
      ${_t})
  set_tests_properties(downgrade/${_name} PROPERTIES SKIP_RETURN_CODE 77)
endforeach()
