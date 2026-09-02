# PHP purity

An operation is pure when its behaviour depends only on its inputs and it performs no I/O or changes to state outside the call. It must not depend on ambient state such as a clock, a random generator, or mutable global variables.

Deterministic exceptions are permitted as failure outcomes; purity does not require normal termination. These requirements apply to calls whether or not they return normally.

For a committed revision $`r`$, we write $`\mathrm{Pure}(r)`$ when every [public operation](CORRECTNESS.md#operations-and-results) at that revision is pure.

Each layer's `CORRECTNESS.md` proves purity alongside [conformance with that layer](CORRECTNESS.md#layer-conformance).
