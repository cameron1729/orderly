# PHP correctness

The PHP library is correct with respect to a layer when its operations are pure and every normally returned result satisfies that layer's applicable requirements for the inputs that produced it.

## Operations and results

For a committed revision $`r`$, let $`\mathcal{A}_r`$ be the type whose inhabitants are the public PHP operations exposed by the Composer package.

For each operation $`f : \mathcal{A}_r`$, let $`\mathcal{G}_r(f)`$ be its graph: the collection of input–output pairs $`(x,y)`$ for which calling $`f`$ with inputs $`x`$ returns the value $`y`$ normally. Here $`x`$ records the arguments to the call; only $`y`$ is returned. Calls that throw or never finish contribute no pair.

## Purity

An operation is pure when its behaviour depends only on its inputs and it neither performs external I/O nor changes state outside the call. It must not depend on ambient state such as a clock, a random generator, or mutable global variables.

Deterministic exceptions are permitted as failure outcomes; purity does not require normal termination. These requirements apply to calls whether or not they return normally.

We write $`\mathrm{Pure}(r)`$ when every public operation at revision $`r`$ is pure.

## Input–output requirements

Let $`\mathcal{R}_{\ell,r}`$ be the collection of rules declared by layer $`\ell`$ at revision $`r`$.

For a rule $`P`$, an operation $`f`$, and an input–output pair $`p`$ in that operation's graph, we write $`P(f,p)`$ to mean that the pair satisfies rule $`P`$ for operation $`f`$.

We write $`\mathrm{IO}_{\ell}(r)`$ when every input–output pair satisfies the layer's applicable rules:

$$
\mathrm{IO}_{\ell}(r)
:=
\forall f : \mathcal{A}_r,\quad
\forall p \in \mathcal{G}_r(f),\quad
\forall P \in \mathcal{R}_{\ell,r},\quad P(f,p).
$$

## Layer correctness

Correctness with respect to a layer requires both purity and satisfaction of its input–output requirements:

$$
\mathrm{Correct}_{\ell}(r) := \mathrm{Pure}(r) \land \mathrm{IO}_{\ell}(r).
$$

Each layer's `CORRECTNESS.md` identifies its requirements and proves this claim. [Overall correctness](../README.md#correctness) requires correctness with respect to every layer.
