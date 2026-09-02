# Layer 2: Discrete realization

Layer 2 concerns exact discrete sequences derived from the [continuous realization](../../1-continuous-realization/). It carries the correspondence argument connecting that derivation to the categorical theory.

## Claim

This layer must establish $`\mathrm{Correct}_{2,{{revision.math}}}`$ under the [shared correctness definition](../../CORRECTNESS.md#layer-correctness), for revision [{{revision.short}}]({{revision.url}}).

It declares no input–output rules for the PHP library:

$$
\mathcal{R}_{2,{{revision.math}}} = \varnothing.
$$

## Proof

### Purity

At revision `{{revision.short}}`, [functions.php](../../../src/functions.php) declares only `between(): never`. Its parameters are passed by value, its defaults are literals, and its body is `while (true) {}`.

Under the [pinned runtime profile](../../common/php/profile.json), the complete [optimised instruction sequence](../../common/php/expected-opcodes.txt) receives four correctly typed arguments or their defaults, then jumps unconditionally to itself. Argument receipt only binds local values; the loop neither reads nor changes external state. Every finite execution prefix is effect-free and determined by its inputs. Thus $`\mathrm{Pure}_{{revision.math}}`$ holds under the [shared execution scope](../../CORRECTNESS.md#execution-scope) and [purity definition](../../CORRECTNESS.md#purity).

### Input–output requirements

At revision `{{revision.short}}`, the PHP library exposes only `between(): never`. Its [graph](../../CORRECTNESS.md#operations-and-results) contains no input–output pairs, so none can violate this layer's rules. This establishes $`\mathrm{IO}_{2,{{revision.math}}}`$; the empty rule collection would also suffice. Together with purity, it proves $`\mathrm{Correct}_{2,{{revision.math}}}`$.

## Verification

### Verifying the premises

[The repository verifier](../../common/verify-repository.sh) checks the committed revision. It requires Composer's production autoloading to consist solely of `src/functions.php` and that file to be the only tracked source path. It compares the file's PHP tokens with the exact `between(): never` declaration and its empty infinite loop, ignoring comments and whitespace and rejecting any additional code. It confirms the declaration by reflection, verifies the runtime profile, and compares the complete compiled instruction sequence with the proved program. The function is never called during verification.

### Checking the argument

[Layer2.lean](../lean/Layer2.lean) defines this layer's rules and proves `correct` using the [shared execution model](../../common/lean/Orderly.lean). That model proves purity and indefinite looping, then derives graph emptiness from the absence of any finite execution returning a value. The correspondence between the pinned Zend handlers and these model transitions is a runtime assumption.

[The layer check]({{verification.layers.2.url}}) runs the source and opcode verifier, checks this layer's Lean proof, and confirms that Lean's instruction model serialises to the same listing checked against the compiler. These checks succeeded in [Correct run {{verification.run}}, attempt {{verification.attempt}}]({{verification.url}}) for revision [{{revision.short}}]({{revision.url}}).
