# Layer 2: Discrete realization

[![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D2)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml)

Layer 2 concerns exact discrete sequences derived from the [continuous realization](../1-continuous-realization/CORRECTNESS.md). It carries the correspondence argument connecting that derivation to the categorical theory.

## Claim

This layer must establish $`\mathrm{Correct}_{2}(r)`$ under the [shared correctness definition](../CORRECTNESS.md#layer-correctness).

It declares no input–output rules for the PHP library:

$$
\mathcal{R}_{2,r} = \varnothing.
$$

## Proof

### Purity

At this revision, [functions.php](../../src/functions.php) declares only `between(): never`. Its parameters are passed by value, its defaults are literals, and its body is empty. It reads no ambient state, performs no external I/O, and changes no state outside the call.

Reaching the end of the body raises a `TypeError` under PHP's [`never` semantics](https://www.php.net/manual/en/language.types.never.php). This deterministic failure is permitted by the [purity definition](../CORRECTNESS.md#purity). Thus $`\mathrm{Pure}(r)`$ holds.

### Input–output requirements

At this revision, the PHP library exposes only `between(): never`. Its [graph](../CORRECTNESS.md#operations-and-results) contains no input–output pairs, so none can violate this layer's rules. This establishes $`\mathrm{IO}_{2}(r)`$; the empty rule collection would also suffice. Together with purity, it proves $`\mathrm{Correct}_{2}(r)`$.

## Verification

### Verifying the premises

[The repository verifier](../common/verify-repository.sh) checks the committed `HEAD`. It requires Composer's production autoloading to consist solely of `src/functions.php` and that file to be the only tracked source path. It compares the file's PHP tokens with the exact `between(): never` declaration, including its literal defaults and empty body, ignoring comments and whitespace and rejecting any additional code. It then confirms the public operation by reflection. These checks establish the source facts used in the proof.

### Checking the argument

[Layer2.lean](lean/Layer2.lean) defines this layer's rules and proves `resultsCorrect` directly by eliminating an impossible member of the empty function graph in the [shared PHP model](../common/lean/Orderly.lean).

[The verifier](verify) checks the source facts establishing purity and the empty function graph. [The layer action](action.yml) runs that verifier and checks this layer's Lean input–output proof and the shared PHP definitions. Together these checks support the correctness claim reported by this layer's badge.
