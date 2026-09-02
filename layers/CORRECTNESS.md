# PHP conformance

The PHP library must be [pure](PURITY.md). It conforms to a layer when every normally returned result satisfies that layer's applicable requirements for the inputs that produced it.

## Operations and results

For a committed revision $`r`$, let $`\mathcal{A}_r`$ be the type whose inhabitants are the public PHP operations exposed by the Composer package.

For each operation $`f : \mathcal{A}_r`$, let $`\mathcal{G}_r(f)`$ be its graph: the collection of input–output pairs $`(x,y)`$ for which calling $`f`$ with inputs $`x`$ returns the value $`y`$ normally. Here $`x`$ records the arguments to the call; only $`y`$ is returned. Calls that throw or never finish contribute no pair.

## Layer conformance

Let $`\mathcal{R}_{\ell,r}`$ be the collection of rules declared by layer $`\ell`$ at revision $`r`$. Each rule assigns a proposition to an operation and one of its input–output pairs. We define conformance with a layer as:

$$
\mathrm{Correct}_{\ell}(r)
:=
\forall f : \mathcal{A}_r,\quad
\forall p \in \mathcal{G}_r(f),\quad
\forall P \in \mathcal{R}_{\ell,r},\quad P(f,p).
$$

Each layer's `CORRECTNESS.md` identifies its requirements and proves both purity and conformance. [Overall correctness](../README.md#correctness) requires purity and conformance with every layer.
