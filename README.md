# Orderly

Orderly is a PHP library for generating magnitude-aware integer sequences with exact endpoints. It is anchored in abstract human thought: a theory of anchored selection across scale carried, layer by layer, through formal models and executable references into production code.

[![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml)

## Usage

```php
<?php

use function Cameron1729\Orderly\between;

between(1, 100); // Never returns.
```

## Layers

Orderly's layers trace a progression from categorical theory, through continuous and discrete realizations, to an executable Haskell reference. Each successive layer gives the construction a more concrete form.

The PHP library is verified against every layer.

Each numbered directory under [`layers/`](layers/) is a self-contained layer. Its `CORRECTNESS.md` states and proves PHP correctness with respect to that layer. The layer badge reports verification of that claim. The overall badge requires every layer's verification to pass against the same revision.

| Layer | Subject | PHP library |
| :--- | :--- | :--- |
| $0$ | [Categorical theory](layers/0-theory/CORRECTNESS.md) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D0)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |
| $1$ | [Continuous realization](layers/1-continuous-realization/CORRECTNESS.md) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D1)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |
| $2$ | [Discrete realization](layers/2-discrete-realization/CORRECTNESS.md) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D2)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |
| $3$ | [Executable Haskell reference](layers/3-haskell-reference/CORRECTNESS.md) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D3)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |

## Commitment

Every commit in Orderly is a commitment to [correctness](#correctness). Each layer must preserve the meaning established above it, and the PHP library must satisfy every layer's specification.

A change begins at the earliest layer it affects and must either propagate through every dependent layer or explicitly withdraw those layers' claims. No green badge survives a changed premise.

Every step towards practicality incurs a proof obligation.

## Correctness

A revision is correct when its PHP library is correct with respect to every layer.

For a committed revision $`r`$ and a layer $`\ell`$, we write $`\mathrm{Correct}_{\ell}(r)`$ for [PHP correctness with respect to that layer](layers/CORRECTNESS.md#layer-correctness). Let $`\mathcal{L}`$ be the collection of [layers](#layers). We define correctness of a revision as:

$$
\mathrm{Correct}(r)
:=
\forall \ell \in \mathcal{L},\quad
\mathrm{Correct}_{\ell}(r).
$$

Each layer's `CORRECTNESS.md` identifies its requirements and proves its correctness claim.
