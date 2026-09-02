# Definitions

Revision $`r`$ is correct with respect to a layer when every public PHP operation exposed by the Composer package at that revision is pure, and every normally returned result satisfies that layer's applicable requirements for its inputs.

## Operations and results

Let $`\mathcal{A}_r`$ be the type whose inhabitants are the public PHP operations exposed by the Composer package at revision $`r`$.

For each operation $`f : \mathcal{A}_r`$, let $`\mathcal{G}_r(f)`$ be its graph: the collection of input–output pairs $`(x,y)`$ for which calling $`f`$ with inputs $`x`$ returns the value $`y`$ normally. Here $`x`$ records the arguments to the call; only $`y`$ is returned. Calls that throw or never finish contribute no pair.

## Purity

An operation is pure when its behaviour depends only on its inputs and it neither performs external I/O nor changes state outside the call. It must not depend on ambient state such as a clock, a random generator, or mutable global variables.

Deterministic exceptions are permitted as failure outcomes; purity does not require normal termination. These requirements apply to calls whether or not they return normally.

We write $`\mathrm{Pure}_r`$ when every public operation at revision $`r`$ is pure.

## Input–output requirements

Let $`\mathcal{R}_{\ell,r}`$ be the collection of rules declared by layer $`\ell`$ at revision $`r`$.

For a rule $`P`$, an operation $`f`$, and an input–output pair $`p`$ in that operation's graph, we write $`P(f,p)`$ to mean that the pair satisfies rule $`P`$ for operation $`f`$.

We write $`\mathrm{IO}_{\ell,r}`$ when every input–output pair satisfies the layer's applicable rules:

$$
\mathrm{IO}_{\ell,r}
:=
\forall f : \mathcal{A}_r,\quad
\forall p \in \mathcal{G}_r(f),\quad
\forall P \in \mathcal{R}_{\ell,r},\quad P(f,p).
$$

## Layer correctness

Correctness with respect to a layer requires both purity and satisfaction of its input–output requirements:

$$
\mathrm{Correct}_{\ell,r} := \mathrm{Pure}_r \land \mathrm{IO}_{\ell,r}.
$$

Each layer identifies its requirements and supplies an argument and revision-specific checks establishing this claim.

## Overall correctness

A revision is correct when its PHP library is correct with respect to every layer. Let $`\mathcal{L}`$ be the collection of [Orderly's layers](../README.md#layers). We define correctness of a revision as:

$$
\mathrm{Correct}_r
:=
\forall \ell \in \mathcal{L},\quad
\mathrm{Correct}_{\ell,r}.
$$

A proof of correctness with respect to one layer establishes $`\mathrm{Correct}_{\ell,r}`$. A proof of overall correctness must establish it for every layer in $`\mathcal{L}`$.
