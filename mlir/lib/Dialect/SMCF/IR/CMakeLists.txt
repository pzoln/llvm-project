add_mlir_dialect_library(MLIRSMCFDialect
  SMCFOps.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/SMCF

  DEPENDS
  MLIRSMCFOpsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  )
