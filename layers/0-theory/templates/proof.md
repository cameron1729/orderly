# Layer 0: Categorical theory

We prove $`\mathrm{Correct}_{0,{{revision.math}}}`$ for revision [{{revision.short}}]({{revision.url}}), in the sense of [Definition](../../CORRECTNESS.md#layer-correctness). Its input–output rules $`\mathcal{R}_{0,{{revision.math}}}`$ are the applicable laws of [the categorical theory](../THEORY.md) at that revision.

Let $`T_{{revision.math}}`$ and $`C_{{revision.math}}`$ be the committed theory and correctness-definition documents, $`H`$ the SHA-256 function, and $`h_T`$ and $`h_C`$ their independently approved digests.

Write $`E_{{revision.math}}`$ for the assertion that no public operation returns normally:

$$
E_{{revision.math}} := \forall f : \mathcal{A}_{{revision.math}},\quad \mathcal{G}_{{revision.math}}(f) = \varnothing.
$$

## Execution model

The proof uses stock PHP {{runtime.version}}, Linux x86-64, a 64-bit non-thread-safe CLI build, OPcache with optimiser mask `{{runtime.optimization_level}}`, and no JIT. The [runtime profile]({{runtime.profile_url}}) fixes the source archive and settings. Optional arguments use literal defaults; array contents are unrestricted and are not inspected.

Within the [execution scope](../../CORRECTNESS.md#execution-scope), argument receipt binds only a local value, and a jump changes only the instruction pointer. We assume these transitions describe the pinned [Zend argument handlers](https://github.com/php/php-src/blob/php-8.4.25/Zend/zend_vm_def.h#L5291-L5363) and [jump machinery](https://github.com/php/php-src/blob/php-8.4.25/Zend/zend_execute.c#L5187-L5199). This is a runtime correspondence assumption, not a formal verification of Zend's C implementation.

Let $`B`$ be the following instruction sequence:

```{.centered}
{{runtime.instructions}}
```

## Purity of the instruction sequence {#instruction-purity .lemma}

On its declared input domain, $`B`$ is pure in this execution model.

## Proof {.proof}

The argument instructions bind local values, and the jump changes only the instruction pointer. Every finite execution prefix is therefore determined by the inputs and has no external effects. This is purity by [Definition](../../CORRECTNESS.md#purity).

## Non-return of the instruction sequence {#instruction-non-return .lemma}

On its declared input domain, $`B`$ executes indefinitely without returning normally.

## Proof {.proof statement-blocks=1}

The first four instructions lead to instruction 4, whose only successor is itself. By induction, every subsequent step remains at instruction 4. Execution can always continue, and no return instruction is reachable.

The [Lean model](../../common/lean/Orderly.lean) formalises both lemmas and their consequence that the input–output graph is empty.

## Purity and non-return {#correctness-from-purity-and-non-return .theorem .keep-together}

$$
\begin{gathered}
\bigl(\mathrm{Pure}_{{revision.math}} \land E_{{revision.math}} \land H(T_{{revision.math}}) = h_T \land H(C_{{revision.math}}) = h_C\bigr) \\
\Longrightarrow \mathrm{Correct}_{0,{{revision.math}}}.
\end{gathered}
$$

## Proof {.proof statement-blocks=1}

An empty graph contains no counterexample, so $`E_{{revision.math}}`$ implies $`\mathrm{IO}_{0,{{revision.math}}}`$. Together with $`\mathrm{Pure}_{{revision.math}}`$, this gives $`\mathrm{Correct}_{0,{{revision.math}}}`$ by [Definition](../../CORRECTNESS.md#layer-correctness). The hash equalities bind the claim to the approved source-document digests.

[Layer0.lean](../lean/Layer0.lean) formalises the theorem and its application, assuming the stated runtime/verifier correspondence and an authenticated check of revision `{{revision.short}}`.

## Application to revision `{{revision.short}}`

The successful [Correct run {{verification.run}} (attempt {{verification.attempt}})]({{verification.url}}), denoted $`w`$, records the [source, opcode and Lean checks]({{verification.layers.0.url}}) for revision [{{revision.short}}]({{revision.url}}).

The repository check identifies `between(): never` as the sole public operation and confirms its parameter signature, the runtime profile and the complete compiled sequence $`B`$. It also matches $`B`$ against the Lean model's serialised instruction listing. The checker compiles but does not call `between`.

By [Lemma](#instruction-purity), the checked sequence establishes $`\mathrm{Pure}_{{revision.math}}`$. By [Lemma](#instruction-non-return), it also establishes $`E_{{revision.math}}`$.

The [publication check]({{publication.url}}) compares SHA-256 of the committed $`T_{{revision.math}}`$ and $`C_{{revision.math}}`$ with the independently approved [theory digest]({{documents.theory.approval_url}}) and [correctness-definition digest]({{documents.correctness.approval_url}}):

**Theory SHA-256 $`h_T`$**\
`{{documents.theory.sha256}}`\
[{{documents.theory.path}}]({{documents.theory.source_url}}) ([raw Markdown]({{documents.theory.raw_url}}))

**Correctness definition SHA-256 $`h_C`$**\
`{{documents.correctness.sha256}}`\
[{{documents.correctness.path}}]({{documents.correctness.source_url}}) ([raw Markdown]({{documents.correctness.raw_url}}))

These hashes identify the source documents, not the templates or rendered PDF. Both comparisons match:

$$
H(T_{{revision.math}}) = h_T, \qquad H(C_{{revision.math}}) = h_C.
$$

Therefore, by [Theorem](#correctness-from-purity-and-non-return), revision [{{revision.short}}]({{revision.url}}) is correct with respect to Layer 0: $`\mathrm{Correct}_{0,{{revision.math}}}`$.
