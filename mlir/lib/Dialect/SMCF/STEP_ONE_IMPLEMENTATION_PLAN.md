# SMCF Step One Implementation Plan

## Goal

Implement the first working SMCF prototype: an acyclic named-binding elaborator
that lowers one `smcf.scope` into an ordinary `func.func` with explicit
`func.call` operations.

This step should prove the central model before adding structured control flow,
SCC scheduling, nesting, imports, or semantic binding matching.

## IR Surface

Add an `smcf` dialect with these operations:

- `smcf.scope @name { ... }`
  - symbol and symbol-table operation;
  - one single-block Graph region;
  - contains `smcf.binding`, `smcf.input`, `smcf.require`, and one
    `smcf.output`.
- `smcf.binding @name : type`
  - symbol operation;
  - stores one MLIR type.
- `smcf.input @bindings...`
  - references bindings by `FlatSymbolRefAttr`;
  - symbol order defines generated function argument order.
- `%value = smcf.require @binding : type`
  - references a binding by `SymbolRefAttr`;
  - has one result whose type must match the binding type.
- `smcf.output @bindings...`
  - references bindings by `FlatSymbolRefAttr`;
  - exactly one per scope;
  - symbol order defines generated function result order.

Use module-level `func.func` providers. A provider is a normal function with:

- function attribute `smcf.provider`;
- one `smcf.requires = @binding` attribute on each argument;
- one `smcf.provides = @binding` attribute on each result.

## Verification Rules

Implement verifier coverage for:

- duplicate binding names within a scope;
- missing or duplicate `smcf.input`;
- missing or duplicate `smcf.output`;
- `smcf.input` or `smcf.output` referencing a missing binding;
- `smcf.require` referencing a missing binding;
- `smcf.require` result type not matching the binding type;
- input binding also produced by a provider;
- derived binding with no provider when required by an output dependency;
- more than one provider for the same derived binding;
- provider argument missing `smcf.requires`;
- provider result missing `smcf.provides`;
- provider contract referencing a missing binding for the scope being elaborated;
- provider argument/result type mismatch against the referenced binding.

Cycle rejection may live in the elaboration pass rather than the operation
verifier, because it depends on provider dependency graph construction.

## Elaboration Pass

Add a module pass named `-smcf-elaborate`.

For each `smcf.scope`:

1. collect binding declarations and input/output binding lists;
2. collect all module-level provider functions marked `smcf.provider`;
3. build maps from provided binding to provider result and provider dependencies;
4. start from the symbols listed by `smcf.output`;
5. look up each output symbol's binding declaration;
6. recursively mark needed providers for non-input bindings;
7. reject missing providers and dependency cycles;
8. topologically sort needed providers;
9. create `func.func @scope_name`;
10. create function arguments for input bindings in `smcf.input` order;
11. emit `func.call` operations for providers in topological order;
12. map provider results to their provided bindings;
13. return values corresponding to `smcf.output` symbol order.

Provider functions remain module-level after elaboration. Dead private providers
can be cleaned up by later passes.

## Tests

Add parser/printer tests for:

- minimal scope with one input binding and one output;
- input and derived binding declarations;
- `smcf.input`;
- `smcf.require`;
- variadic symbolic `smcf.output`;
- module-level provider attributes.

Add verifier tests for each rule above.

Add elaboration tests for:

- one provider, two inputs, one output;
- dependency chain across multiple providers;
- one provider with multiple results;
- multiple ordered scope outputs;
- unused provider not emitted;
- missing provider diagnostic;
- duplicate provider diagnostic;
- cycle rejection diagnostic.

## Non-Goals

Do not implement these in step one:

- `scf.if` inside `smcf.scope`;
- branch-local requirements;
- SCC or SAT scheduling;
- nested scopes;
- imports, mixins, or visibility;
- semantic matching beyond exact binding names;
- provider purity analysis;
- custom provenance attributes.

## Acceptance Criteria

Step one is complete when:

- `mlir-opt` can parse, verify, and print the new SMCF IR;
- `-smcf-elaborate` lowers the acyclic examples to ordinary `func.func` IR;
- invalid IR produces focused diagnostics;
- all SMCF parser, verifier, and elaboration lit tests pass.
