# Layer 0: Categorical theory

## Claim

The claim is that revision [{{revision.full}}]({{revision.url}}) is correct with respect to Layer 0 in the sense of [Definition](../../CORRECTNESS.md#layer-correctness): $`\mathrm{Correct}_{0,{{revision.math}}}`$.

Its input–output rules $`\mathcal{R}_{0,{{revision.math}}}`$ are the applicable laws of [the categorical theory](../THEORY.md) at that revision.

Let $`T_{{revision.math}}`$ and $`C_{{revision.math}}`$ be the exact committed source documents of the theory and shared correctness definition. Let $`H`$ denote SHA-256, and let $`h_T`$ and $`h_C`$ be their independently approved target digests.

Write $`E_{{revision.math}}`$ for the assertion that no public operation returns normally:

$$
E_{{revision.math}} := \forall f : \mathcal{A}_{{revision.math}},\quad \mathcal{G}_{{revision.math}}(f) = \varnothing.
$$

## Purity and non-return {#correctness-from-purity-and-non-return .theorem .keep-together}

Purity, non-return and the two matching document hashes establish correctness with respect to Layer 0:

$$
\begin{aligned}
&\bigl(\mathrm{Pure}_{{revision.math}} \land E_{{revision.math}} \land H(T_{{revision.math}}) = h_T \\
&\quad{}\land H(C_{{revision.math}}) = h_C\bigr) \Longrightarrow \mathrm{Correct}_{0,{{revision.math}}}.
\end{aligned}
$$

## Proof {.proof}

An input–output counterexample would require a pair in an empty graph. No such pair exists, so $`E_{{revision.math}}`$ implies $`\mathrm{IO}_{0,{{revision.math}}}`$. Together with $`\mathrm{Pure}_{{revision.math}}`$, this gives $`\mathrm{Correct}_{0,{{revision.math}}}`$ by [Definition](../../CORRECTNESS.md#layer-correctness). The hash equalities identify the digests of the committed documents to which the claim applies.

[Layer0.lean](../lean/Layer0.lean) formalises this theorem and its application to a verified revision. Its revision parameter is instantiated here as `{{revision.short}}`. The source verifier's soundness and the authenticated run record are explicit premises; Lean checks the deduction from them.

## Application to revision `{{revision.short}}`

Let [$`w`$]({{verification.url}}) identify [Correct run {{verification.run}}, attempt {{verification.attempt}}]({{verification.url}}). Its [Layer 0 source and Lean checks]({{verification.layers.0.url}}) (job {{verification.layers.0.id}}, attempt {{verification.layers.0.attempt}}) succeeded for revision [{{revision.full}}]({{revision.url}}).

### Purity

Run [$`w`$]({{verification.layers.0.url}}) checks that `between(): never` is the sole public operation, with by-value parameters, literal defaults and an empty body. That body reads no ambient state, performs no external I/O and changes no state outside the call. Reaching its end raises a deterministic `TypeError`, which the shared purity definition permits. Thus $`\mathrm{Pure}_{{revision.math}}`$ holds.

### No normal returns

Run [$`w`$]({{verification.layers.0.url}}) also confirms the declaration's native [`never` return type](https://www.php.net/manual/en/language.types.never.php) by reflection. No call can return normally, so the operation's graph is empty. Thus $`E_{{revision.math}}`$ holds.

### Document hashes

The [publication check]({{publication.url}}) calculates SHA-256 from the exact committed bytes of $`T_{{revision.math}}`$ and $`C_{{revision.math}}`$. It compares them with the independently approved [theory digest]({{documents.theory.approval_url}}) and [correctness-definition digest]({{documents.correctness.approval_url}}).

**Theory SHA-256 $`h_T`$**\
`{{documents.theory.sha256}}`\
[{{documents.theory.path}}]({{documents.theory.source_url}}) ([raw Markdown]({{documents.theory.raw_url}}))

**Correctness definition SHA-256 $`h_C`$**\
`{{documents.correctness.sha256}}`\
[{{documents.correctness.path}}]({{documents.correctness.source_url}}) ([raw Markdown]({{documents.correctness.raw_url}}))

These are hashes of the source definitions, not the publication templates or rendered PDFs. The templates present those definitions and this argument for revision `{{revision.short}}`. The publication check records both computed and required hashes; both comparisons match:

$$
H(T_{{revision.math}}) = h_T, \qquad H(C_{{revision.math}}) = h_C.
$$

### Conclusion

Therefore, by [Theorem](#correctness-from-purity-and-non-return), revision [{{revision.full}}]({{revision.url}}) is correct with respect to Layer 0: $`\mathrm{Correct}_{0,{{revision.math}}}`$.
