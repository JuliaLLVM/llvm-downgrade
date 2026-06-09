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

find_program(LLVMDG_FILECHECK NAMES FileCheck HINTS ${LLVM_TOOLS_BINARY_DIR}
             DOC "FileCheck used by the downgrader test suite")
if(NOT LLVMDG_FILECHECK)
  message(WARNING "FileCheck not found; downgrader tests will report as skipped")
endif()

set(LLVMDG_DIS_5_0  "" CACHE FILEPATH "legacy LLVM 5.0 llvm-dis (for 5.0 tests)")
set(LLVMDG_DIS_7_0  "" CACHE FILEPATH "legacy LLVM 7.0 llvm-dis (for 7.0 tests)")
set(LLVMDG_DIS_14_0 "" CACHE FILEPATH "legacy LLVM 14.0 llvm-dis (for 14.0 tests)")

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
      ${_t})
  set_tests_properties(downgrade/${_name} PROPERTIES SKIP_RETURN_CODE 77)
endforeach()
