# Introduction

We consider the Orderly Composer package at revision $`r`$. Correctness requires purity and satisfaction of the applicable input–output rules.

## Operations and results

Let $`\mathcal{A}_r`$ denote the public PHP operations at revision $`r`$. For $`f : \mathcal{A}_r`$, let $`\mathcal{G}_r(f)`$ be its input–output graph for normal returns.

## Layer rules

Let $`\mathcal{L}`$ be [Orderly's layers](../README.md#layers), and $`\mathcal{R}_{\ell,r}`$ the rules declared by layer $`\ell`$ at revision $`r`$. We write $`P(f,p)`$ when the input–output pair $`p`$ satisfies rule $`P`$ for operation $`f`$.

## Purity

An operation is pure if its behaviour depends only on its inputs and it neither performs external I/O nor changes state outside the call. Write $`\mathrm{Pure}_r`$ when every $`f : \mathcal{A}_r`$ is pure.

Deterministic exceptions are permitted; normal termination is not required.

## Input–output requirements

For a layer $`\ell`$, define:

$$
\mathrm{IO}_{\ell,r}
:=
\forall f : \mathcal{A}_r,\quad
\forall p \in \mathcal{G}_r(f),\quad
\forall P \in \mathcal{R}_{\ell,r},\quad P(f,p).
$$

## Layer correctness

Correctness with respect to layer $`\ell`$ is defined by:

$$
\mathrm{Correct}_{\ell,r} := \mathrm{Pure}_r \land \mathrm{IO}_{\ell,r}.
$$

## Overall correctness

Overall correctness is defined by:

$$
\mathrm{Correct}_r
:=
\forall \ell \in \mathcal{L},\quad
\mathrm{Correct}_{\ell,r}.
$$

## Execution scope

The claims use the execution model stated in the proof and arguments matching the declared parameter types, including declared defaults for omitted arguments. Caller-side argument evaluation, coercion and error handling are excluded.

Effects are measured at the program level. Interpreter bookkeeping and resource consumption are internal computation; external interruption and instrumentation are excluded.
