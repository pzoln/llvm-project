//===- SMCFOps.td - SMCF operation definitions ------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_SMCF_IR_SMCFOPS_TD
#define MLIR_DIALECT_SMCF_IR_SMCFOPS_TD

include "mlir/IR/OpBase.td"
include "mlir/IR/RegionKindInterface.td"
include "mlir/IR/SymbolInterfaces.td"

def SMCF_Dialect : Dialect {
  let name = "smcf";
  let cppNamespace = "::mlir::smcf";
  let summary = "Scope-mediated control-flow dialect";
  let description = [{
    SMCF represents computations in terms of named, single-assignment bindings
    that are later elaborated into ordinary explicit SSA values and calls.
  }];
}

class SMCF_Op<string mnemonic, list<Trait> traits = []>
    : Op<SMCF_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// ScopeOp
//===----------------------------------------------------------------------===//

def SMCF_ScopeOp : SMCF_Op<"scope", [
    IsolatedFromAbove, NoRegionArguments, Symbol, SymbolTable
  ] # GraphRegionNoTerminator.traits> {
  let summary = "SMCF named binding resolution scope";
  let description = [{
    An `smcf.scope` declares named bindings and unresolved requirements that
    will be elaborated into ordinary explicit MLIR.
  }];

  let arguments = (ins SymbolNameAttr:$sym_name);
  let regions = (region SizedRegion<1>:$body);

  let assemblyFormat = "$sym_name attr-dict-with-keyword $body";
}

//===----------------------------------------------------------------------===//
// BindingOp
//===----------------------------------------------------------------------===//

def SMCF_BindingOp : SMCF_Op<"binding", [Symbol]> {
  let summary = "SMCF named typed binding";
  let description = [{
    An `smcf.binding` declares a named, typed, single-assignment semantic value.
  }];

  let arguments = (ins SymbolNameAttr:$sym_name, TypeAttr:$type);

  let assemblyFormat = "$sym_name `:` $type attr-dict";
}

//===----------------------------------------------------------------------===//
// InputOp
//===----------------------------------------------------------------------===//

def SMCF_InputOp : SMCF_Op<"input"> {
  let summary = "SMCF ordered input binding list";
  let description = [{
    An `smcf.input` declares which scope bindings become generated function
    arguments and in what order.
  }];

  let arguments = (ins FlatSymbolRefArrayAttr:$bindings);

  let assemblyFormat = "custom<BindingList>($bindings) attr-dict";
}

//===----------------------------------------------------------------------===//
// RequireOp
//===----------------------------------------------------------------------===//

def SMCF_RequireOp : SMCF_Op<"require"> {
  let summary = "SMCF binding requirement";
  let description = [{
    An `smcf.require` materializes a binding as an unresolved SSA value.
  }];

  let arguments = (ins SymbolRefAttr:$binding);
  let results = (outs AnyType:$result);

  let assemblyFormat = "$binding attr-dict `:` type($result)";
}

//===----------------------------------------------------------------------===//
// OutputOp
//===----------------------------------------------------------------------===//

def SMCF_OutputOp : SMCF_Op<"output"> {
  let summary = "SMCF ordered output binding list";
  let description = [{
    An `smcf.output` declares which scope bindings become generated function
    results and in what order.
  }];

  let arguments = (ins FlatSymbolRefArrayAttr:$bindings);

  let assemblyFormat = "custom<BindingList>($bindings) attr-dict";
}

#endif // MLIR_DIALECT_SMCF_IR_SMCFOPS_TD
