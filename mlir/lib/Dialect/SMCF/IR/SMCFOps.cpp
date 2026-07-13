//===- SMCFOps.cpp - SMCF dialect operations ------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/SMCF/IR/SMCFOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/STLExtras.h"

#include "mlir/Dialect/SMCF/IR/SMCFOpsDialect.cpp.inc"

using namespace mlir;
using namespace mlir::smcf;

static ParseResult parseBindingList(OpAsmParser &parser, ArrayAttr &bindings) {
  SmallVector<Attribute> bindingAttrs;
  Builder &builder = parser.getBuilder();
  if (parser.parseCommaSeparatedList([&]() -> ParseResult {
        StringAttr bindingName;
        if (parser.parseSymbolName(bindingName))
          return failure();
        bindingAttrs.push_back(SymbolRefAttr::get(bindingName));
        return success();
      }))
    return failure();

  bindings = builder.getArrayAttr(bindingAttrs);
  return success();
}

static void printBindingList(OpAsmPrinter &printer, Operation *op,
                             ArrayAttr bindings) {
  llvm::interleaveComma(bindings, printer, [&](Attribute attr) {
    printer.printSymbolName(cast<FlatSymbolRefAttr>(attr).getValue());
  });
}

void SMCFDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/SMCF/IR/SMCFOps.cpp.inc"
      >();
}

#define GET_OP_CLASSES
#include "mlir/Dialect/SMCF/IR/SMCFOps.cpp.inc"
