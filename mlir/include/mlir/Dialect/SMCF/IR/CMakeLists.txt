set(LLVM_TARGET_DEFINITIONS SMCFOps.td)
add_mlir_dialect(SMCFOps smcf)
add_mlir_doc(SMCFOps SMCFOps Dialects/ -gen-dialect-doc)
