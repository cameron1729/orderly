# Layer 3: Executable Haskell reference

[![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D3)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml)

Layer 3 concerns an executable Haskell reference of the [derived discrete realization](../2-discrete-realization/CORRECTNESS.md). It supplies an executable specification against which the PHP library is verified.

## Claim

This layer must establish [PHP purity](../PURITY.md) and, using the [shared conformance definition](../CORRECTNESS.md#layer-conformance), $`\mathrm{Correct}_{3}(r)`$.

It declares no rules for the PHP library:

$$
\mathcal{R}_{3,r} = \varnothing.
$$

## Proofs

### Purity

At this revision, [functions.php](../../src/functions.php) declares only `between(): never`. Its parameters are passed by value, its defaults are literals, and its body is empty. It reads no ambient state, performs no I/O, and changes no state outside the call.

Reaching the end of the body raises a `TypeError` under PHP's [`never` semantics](https://www.php.net/manual/en/language.types.never.php). This deterministic failure is permitted by the [purity definition](../PURITY.md). Thus $`\mathrm{Pure}(r)`$ holds.

### Conformance

At this revision, the PHP library exposes only `between(): never`. Its [graph](../CORRECTNESS.md#operations-and-results) contains no input–output pairs, so none can violate this layer's rules. This establishes $`\mathrm{Correct}_{3}(r)`$. The empty rule collection would also suffice on its own.

## Verification

### Verifying the premises

[The repository verifier](../common/verify-repository.sh) checks the committed `HEAD`. It requires Composer's production autoloading to consist solely of `src/functions.php` and that file to be the only tracked source path. It compares the file's PHP tokens with the exact `between(): never` declaration, including its literal defaults and empty body, ignoring comments and whitespace and rejecting any additional code. It then confirms the public operation by reflection. These checks establish the source facts used in both proofs.

### Checking the argument

[Layer3.lean](lean/Layer3.lean) defines this layer's rules and proves `phpConforms` directly by eliminating an impossible member of the empty function graph in the [shared PHP model](../common/lean/Orderly.lean).

[The verifier](verify) checks the repository premises for both proofs. [The layer action](action.yml) runs that verifier and checks this layer's Lean conformance proof and the shared PHP definitions. Its successful `Layer 3` check supports this layer's badge.
