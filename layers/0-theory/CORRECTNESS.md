# Layer 0: Categorical theory

[![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D0)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml)

## Claim

This layer must establish both [PHP purity](../PURITY.md) and conformance with its theory.

This layer's requirements are the applicable laws of [THEORY.md](THEORY.md), denoted $`\mathbb{T}_{\mathrm{Orderly}}`$.

Using the [shared conformance definition](../CORRECTNESS.md), we write $`p \models \mathbb{T}_{\mathrm{Orderly}}`$ when the output in an input–output pair $`p`$ satisfies those laws for its inputs.

This layer's conformance obligation is:

$$
\mathrm{Correct}_{0}(r)
\quad\Longleftrightarrow\quad
\forall f : \mathcal{A}_r,\quad
\forall p \in \mathcal{G}_r(f),\quad
p \models \mathbb{T}_{\mathrm{Orderly}}.
$$

## Proofs

### Purity

At this revision, [functions.php](../../src/functions.php) declares only `between(): never`. Its parameters are passed by value, its defaults are literals, and its body is empty. It reads no ambient state, performs no I/O, and changes no state outside the call.

Reaching the end of the body raises a `TypeError` under PHP's [`never` semantics](https://www.php.net/manual/en/language.types.never.php). This deterministic failure is permitted by the [purity definition](../PURITY.md). Thus $`\mathrm{Pure}(r)`$ holds.

### Conformance

At this revision, the PHP library exposes exactly one operation:

$$
\mathcal{A}_r = \lbrace\mathsf{between}\rbrace.
$$

Its native return type is `never`, so it cannot terminate normally with a value. Its [graph](../CORRECTNESS.md#operations-and-results) therefore contains no input–output pairs:

$$
\mathcal{G}_r(\mathsf{between}) = \varnothing.
$$

Every input–output pair in an empty graph satisfies any predicate:

$$
\mathcal{G}_r(\mathsf{between}) = \varnothing
\quad\Longrightarrow\quad
\forall P : \mathcal{G}_r(\mathsf{between}) \to \mathsf{Prop},\quad
\forall p \in \mathcal{G}_r(\mathsf{between}),\quad P(p).
$$

A counterexample would require an input–output pair $`p \in \varnothing`$. No such pair exists, so no returned value is a counterexample to the theory. This establishes $`\mathrm{Correct}_{0}(r)`$.

## Verification

### Verifying the premises

[The repository verifier](../common/verify-repository.sh) checks the committed `HEAD`. It requires Composer's production autoloading to consist solely of `src/functions.php` and that file to be the only tracked source path. It compares the file's PHP tokens with the exact `between(): never` declaration, including its literal defaults and empty body, ignoring comments and whitespace and rejecting any additional code. It then confirms the public operation by reflection. These checks establish the source facts used in both proofs.

### Checking the argument

[Layer0.lean](lean/Layer0.lean) imports the [PHP model](../common/lean/Orderly.lean) and proves `phpConforms` directly by eliminating an impossible member of the empty function graph. The theorem accepts any collection of rules, so it applies to the theory's requirements.

[The verifier](verify) checks the theory's [SHA-256 checksum](THEORY.sha256) and the repository premises. [The layer action](action.yml), run by the [shared workflow](../../.github/workflows/layers.yml), also verifies the Lean proof. The checksum binds the check to the accepted theory text; the repository verifier checks the premises of both proofs; Lean establishes the general conformance argument. Together these checks support this layer's purity and conformance claims.
