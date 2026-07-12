# SMCF: Scope-Mediated Control Flow

SMCF is an MLIR dialect for describing computations in terms of named,
single-assignment bindings instead of manually wiring every function input and
output.

The first prototype is intentionally small:

```text
smcf.scope + smcf.binding + smcf.input + smcf.require + smcf.output
                         +
module-level func.func providers
                         ↓
acyclic dependency resolution
                         ↓
func.func + func.call + explicit SSA values
```

The dialect should reuse ordinary MLIR machinery wherever possible. In
particular, providers are ordinary module-level `func.func` operations annotated
with SMCF binding contracts.

For the step-one implementation plan, see
`mlir/lib/Dialect/SMCF/STEP_ONE_IMPLEMENTATION_PLAN.md`.

---

## Core Model

### Scope

An `smcf.scope` is a named symbol table and resolution unit containing one
single-block Graph region.

```mlir
smcf.scope @payment {
  ...
}
```

The Graph region lets unresolved source IR be represented without relying on
textual operation order or ordinary SSA dominance. The SMCF elaboration pass
defines the actual execution order.

The first prototype restricts a scope body to:

- `smcf.binding` declarations;
- `smcf.input` operation;
- `smcf.require` operations;
- one `smcf.output` operation.

Later versions may allow ordinary structured control flow, nested scopes,
imports, and mixins.

### Binding

An `smcf.binding` declares a named, typed, single-assignment semantic value.

```mlir
smcf.binding @amount : i64
smcf.binding @fee : i64
smcf.binding @total : i64
```

All bindings are declared with `smcf.binding`. Ordered scope inputs are listed
separately:

```mlir
smcf.input @amount, @fee
```

Input bindings become arguments of the generated function in `smcf.input` order.
Derived bindings are produced by providers.

### Requirement

An `smcf.require` materializes a binding as an unresolved SSA value.

```mlir
%total = smcf.require @total : i64
```

During elaboration, each requirement is replaced by the SSA value that provides
the requested binding.

### Output

An `smcf.output` declares the ordered bindings exposed by the scope.

```mlir
smcf.output @total, @fee
```

The first prototype requires exactly one `smcf.output` per scope. Its symbol
order defines the result order of the generated `func.func`. `smcf.input` and
`smcf.output` do not repeat types; `smcf.binding` is the type authority.

---

## Provider Contracts

SMCF does not define its own function operation. Providers are ordinary
module-level `func.func` operations with SMCF attributes.

```mlir
func.func private @compute_total(
    %amount: i64 {smcf.requires = @amount},
    %fee: i64 {smcf.requires = @fee}
) -> (
    i64 {smcf.provides = @total}
) attributes {
    smcf.provider
} {
    %total = arith.addi %amount, %fee : i64
    return %total : i64
}
```

A provider may consume multiple bindings and produce multiple bindings. Binding
references in provider contracts are matched against bindings declared in the
scope being elaborated.

The initial matching rule is deliberately simple:

```text
binding identity = symbol name
compatibility = same binding symbol and same MLIR type
cardinality = one provider for each derived binding
```

The first prototype treats purity and determinism as requirements of provider
functions, but does not attempt to prove them.

---

## Example

Unresolved SMCF:

```mlir
func.func private @compute_total(
    %amount: i64 {smcf.requires = @amount},
    %fee: i64 {smcf.requires = @fee}
) -> (
    i64 {smcf.provides = @total}
) attributes {
    smcf.provider
} {
    %result = arith.addi %amount, %fee : i64
    return %result : i64
}

smcf.scope @payment {
  smcf.binding @amount : i64
  smcf.binding @fee : i64
  smcf.binding @total : i64
  smcf.input @amount, @fee

  %total = smcf.require @total : i64
  smcf.output @total
}
```

Elaborated MLIR:

```mlir
func.func @payment(%amount: i64, %fee: i64) -> i64 {
  %total = func.call @compute_total(%amount, %fee)
      : (i64, i64) -> i64
  return %total : i64
}
```

The provider function may remain in the module after elaboration. Later cleanup
passes can remove unused private providers if desired.

---

## Elaboration

The first elaboration pass is a module pass named:

```text
-smcf-elaborate
```

For each `smcf.scope`, the pass:

1. collects binding declarations;
2. collects module-level providers and their binding contracts;
3. verifies exact binding/type matches;
4. identifies input and output bindings;
5. discovers the providers needed for the requested outputs;
6. rejects dependency cycles;
7. emits a new ordinary `func.func`;
8. emits provider `func.call` operations in topological order;
9. replaces scope outputs with explicit `func.return` values;
10. erases or leaves the original `smcf.scope` according to pass options.

Input arguments are emitted in `smcf.input` symbol order. Function results are
emitted in `smcf.output` symbol order.

---

## Prototype Restrictions

The first prototype is acyclic and intentionally restrictive:

- no `scf.if` inside `smcf.scope`;
- no nested `smcf.scope`;
- no imports or mixins;
- no semantic matching beyond exact binding names;
- no multiple candidate providers for the same derived binding;
- no recursive provider dependencies;
- no indirect calls;
- no proof of provider purity or determinism.

These restrictions keep the first implementation focused on proving the core
named-binding elaboration model.

---

## Future Work

Future versions may add:

- ordinary `scf.if` with branch-local `smcf.require` operations;
- branch-sensitive provider placement;
- SCC and SAT-assisted scheduling for conditionally breakable cycles;
- nested scopes, imports, mixins, and visibility;
- semantic binding resolution beyond exact symbol names;
- provenance attributes on generated operations.

The long-term principle remains:

> SMCF decides which computations and values are required. Standard MLIR
> expresses the resulting explicit computation.
