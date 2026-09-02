# Layer 0: Categorical theory

[![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D0)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml)

## Claim

This layer must establish $`\mathrm{Correct}_{0}(r)`$ under the [shared correctness definition](../CORRECTNESS.md#layer-correctness).

Its input–output rules $`\mathcal{R}_{0,r}`$ are the applicable laws of [THEORY.md](THEORY.md) at revision $`r`$.

## Proof

### Purity

At this revision, [functions.php](../../src/functions.php) declares only `between(): never`. Its parameters are passed by value, its defaults are literals, and its body is empty. It reads no ambient state, performs no external I/O, and changes no state outside the call.

Reaching the end of the body raises a `TypeError` under PHP's [`never` semantics](https://www.php.net/manual/en/language.types.never.php). This deterministic failure is permitted by the [purity definition](../CORRECTNESS.md#purity). Thus $`\mathrm{Pure}(r)`$ holds.

### Input–output requirements

At this revision, the PHP library exposes exactly one operation:

$$
\mathcal{A}_r = \lbrace\mathsf{between}\rbrace.
$$

Denote this layer's theory at revision $`r`$ by $`\mathbb{T}_{0,r}`$. For an input–output pair $`p`$ in the graph of `between`, we write $`p \models \mathbb{T}_{0,r}`$ when its output satisfies that theory's applicable laws for its inputs.

The native return type of `between` is `never`, so no call can terminate normally with a value. Its [graph](../CORRECTNESS.md#operations-and-results) therefore contains no input–output pairs:

$$
\mathcal{G}_r(\mathsf{between}) = \varnothing.
$$

Since the graph is empty, every pair in it satisfies those laws:

$$
\forall p \in \mathcal{G}_r(\mathsf{between}),\quad p \models \mathbb{T}_{0,r}.
$$

A counterexample to the input–output requirements would require a pair $`p \in \varnothing`$. No such pair exists, so no returned value is a counterexample to this layer's theory. This establishes $`\mathrm{IO}_{0}(r)`$. Together with purity, it proves $`\mathrm{Correct}_{0}(r)`$.

## Verification

### Verifying the premises

[The repository verifier](../common/verify-repository.sh) checks the committed `HEAD`. It requires Composer's production autoloading to consist solely of `src/functions.php` and that file to be the only tracked source path. It compares the file's PHP tokens with the exact `between(): never` declaration, including its literal defaults and empty body, ignoring comments and whitespace and rejecting any additional code. It then confirms the public operation by reflection. These checks establish the source facts used in the proof.

### Checking the argument

[Layer0.lean](lean/Layer0.lean) imports the [PHP model](../common/lean/Orderly.lean) and proves `resultsCorrect` directly by eliminating an impossible member of the empty function graph. The theorem accepts any collection of rules, so it applies to the theory's input–output requirements.

[The verifier](verify) checks the theory's [SHA-256 checksum](THEORY.sha256) and the repository premises. [The layer action](action.yml), run by the [shared workflow](../../.github/workflows/layers.yml), also verifies the Lean proof. The checksum binds the check to the accepted theory text; the repository verifier checks the source facts establishing purity; Lean establishes the input–output argument using the verified empty graph. Together these checks support this layer's correctness claim.
