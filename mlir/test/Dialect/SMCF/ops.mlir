// RUN: mlir-opt %s | FileCheck %s

// CHECK-LABEL: smcf.scope @payment
smcf.scope @payment {
  // CHECK: smcf.binding @amount : i64
  smcf.binding @amount : i64
  // CHECK: smcf.binding @fee : i64
  smcf.binding @fee : i64
  // CHECK: smcf.binding @total : i64
  smcf.binding @total : i64
  // CHECK: smcf.input @amount, @fee
  smcf.input @amount, @fee
  // CHECK: %{{.*}} = smcf.require @total : i64
  %total = smcf.require @total : i64
  // CHECK: smcf.output @total
  smcf.output @total
}

// CHECK-LABEL: smcf.scope @ordered_outputs
smcf.scope @ordered_outputs {
  // CHECK: smcf.output @total, @fee
  smcf.output @total, @fee
}
