; MIN-LLVM: 22  (errnomem is LLVM 21+, target_mem0/1 LLVM 22+)
; VERSIONS: 18.0 20.0
; memory(...) packs two bits per location. LLVM 21 and 22 added locations that
; LLVM 18 and 20 do not know, which changes the layout of the encoded value; they
; have to be folded back into the location that covered them before (errnomem
; into other memory, target_mem into inaccessible memory) instead of being
; misread as a different location.
declare void @read_not_errno() memory(read, errnomem: none)
declare void @errno_only() memory(errnomem: write)
declare void @target_mem() memory(target_mem0: read)
declare void @readwrite_not_errno() memory(readwrite, errnomem: none)
declare void @target_mems() memory(argmem: read, target_mem0: read, target_mem1: write)

; CHECK: declare void @read_not_errno() [[READ:#[0-9]+]]
; CHECK: declare void @errno_only() [[WRITE:#[0-9]+]]
; CHECK: declare void @target_mem() [[INACC:#[0-9]+]]
; CHECK: declare void @readwrite_not_errno() [[RW:#[0-9]+]]
; CHECK: declare void @target_mems() [[TARGET:#[0-9]+]]
; CHECK-DAG: attributes [[READ]] = { memory(read) }
; CHECK-DAG: attributes [[WRITE]] = { memory(write, argmem: none, inaccessiblemem: none) }
; CHECK-DAG: attributes [[INACC]] = { memory(inaccessiblemem: read) }
; CHECK-DAG: attributes [[RW]] = { memory(readwrite) }
; CHECK-DAG: attributes [[TARGET]] = { memory(argmem: read, inaccessiblemem: readwrite) }
