# Layer 3: Executable Haskell reference

Layer 3 concerns an executable Haskell reference of the [derived discrete realization](../../2-discrete-realization/). It supplies an executable specification against which the PHP library is verified.

## Claim

This layer must establish $`\mathrm{Correct}_{3,{{revision.math}}}`$ under the [shared correctness definition](../../CORRECTNESS.md#layer-correctness), for revision [{{revision.full}}]({{revision.url}}).

It declares no input–output rules for the PHP library:

$$
\mathcal{R}_{3,{{revision.math}}} = \varnothing.
$$

## Proof

### Purity

At revision `{{revision.short}}`, [functions.php](../../../src/functions.php) declares only `between(): never`. Its parameters are passed by value, its defaults are literals, and its body is empty. It reads no ambient state, performs no external I/O, and changes no state outside the call.

Reaching the end of the body raises a `TypeError` under PHP's [`never` semantics](https://www.php.net/manual/en/language.types.never.php). This deterministic failure is permitted by the [purity definition](../../CORRECTNESS.md#purity). Thus $`\mathrm{Pure}_{{revision.math}}`$ holds.

### Input–output requirements

At revision `{{revision.short}}`, the PHP library exposes only `between(): never`. Its [graph](../../CORRECTNESS.md#operations-and-results) contains no input–output pairs, so none can violate this layer's rules. This establishes $`\mathrm{IO}_{3,{{revision.math}}}`$; the empty rule collection would also suffice. Together with purity, it proves $`\mathrm{Correct}_{3,{{revision.math}}}`$.

## Verification

### Verifying the premises

[The repository verifier](../../common/verify-repository.sh) checks the committed revision. It requires Composer's production autoloading to consist solely of `src/functions.php` and that file to be the only tracked source path. It compares the file's PHP tokens with the exact `between(): never` declaration, including its literal defaults and empty body, ignoring comments and whitespace and rejecting any additional code. It then confirms the public operation by reflection. These checks establish the source facts used in the proof.

### Checking the argument

[Layer3.lean](../lean/Layer3.lean) defines this layer's rules and proves `resultsCorrect` directly by eliminating an impossible member of the empty function graph in the [shared PHP model](../../common/lean/Orderly.lean).

[The layer check]({{verification.layers.3.url}}) runs the source verifier and checks this layer's Lean input–output proof and the shared PHP definitions. These checks succeeded in [Correct run {{verification.run}}, attempt {{verification.attempt}}]({{verification.url}}) for revision [{{revision.full}}]({{revision.url}}).
