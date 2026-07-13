//===- SMCFOps.h - SMCF dialect operations ----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_SMCF_IR_SMCFOPS_H
#define MLIR_DIALECT_SMCF_IR_SMCFOPS_H

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/IR/SymbolTable.h"

#include "mlir/Dialect/SMCF/IR/SMCFOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/SMCF/IR/SMCFOps.h.inc"

#endif // MLIR_DIALECT_SMCF_IR_SMCFOPS_H
