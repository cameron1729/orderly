# Orderly

[![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml)

Orderly is a PHP library for the very serious task of correctly generating ordered integer sequences, with fine-grained control over magnitude jumps and exact endpoints. The PHP library is derived from a categorical theory of anchored selection across scale.

## Usage

```php
<?php

use function Cameron1729\Orderly\between;

between(1, 100); // Never returns.
```

## Why Orderly?

### The importance of correct integers

Orderly comes with a strict [correctness guarantee](#correctness). Every certified revision carries a proof that the PHP library satisfies its declared requirements.

This is critical when generating ascending or descending integer sequences. To see why, imagine a hypothetical library that promises `1, 2, 3, 5, 8, 13` but, following a regression, produces:

```text
1, 2, 3, 5, 2, 8, 13
            ^
       CATASTROPHE
```

Orderly promises, and proves, that its returned results satisfy the specification. "Mostly ascending" is not ascending.

### Comparison with other libraries

| Library | Covered by Orderly's proof of correctness | Regressions |
| :--- | :--- | :--- |
| Orderly | Yes | probably not |
| Not Orderly | No | possibly |

## Layers

Orderly's layers trace a progression from categorical theory, through continuous and discrete realizations, to an executable Haskell reference. Each successive layer gives the construction a more concrete form.

The PHP library is verified against every layer.

Each numbered directory under [`layers/`](layers/) is a self-contained layer, keeping its definitions, Lean arguments and proof templates together. Lean establishes the general argument; the templates present that argument and the checked premises for a particular revision. The published PDF is the human-readable proof for that revision.

The layer badge reports verification of its correctness claim. The overall badge requires every layer's verification to pass against the same revision. All badges additionally require [independent approval of the shared correctness definition and that revision's theory](layers/0-theory/templates/proof.md#document-hashes).

| Layer | Subject | PHP library |
| :--- | :--- | :--- |
| $0$ | [Categorical theory](layers/0-theory/) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D0)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |
| $1$ | [Continuous realization](layers/1-continuous-realization/) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D1)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |
| $2$ | [Discrete realization](layers/2-discrete-realization/) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D2)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |
| $3$ | [Executable Haskell reference](layers/3-haskell-reference/) | [![Correct](https://img.shields.io/endpoint?url=https%3A%2F%2Forderly.cameron1729.xyz%2F%3Flayer%3D3)](https://github.com/cameron1729/orderly/actions/workflows/layers.yml) |

## Commitment

Every commit in Orderly is a commitment to [correctness](#correctness). Each layer must preserve the meaning established above it, and the PHP library must satisfy every layer's specification.

A change begins at the earliest layer it affects and must either propagate through every dependent layer or explicitly withdraw those layers' claims. No green badge survives a changed premise.

Every step towards practicality incurs a proof obligation.

## Correctness

A revision is correct when its PHP library is correct with respect to every layer. The [shared correctness definition](layers/CORRECTNESS.md#overall-correctness) states this claim precisely. The [publication templates](layers/0-theory/templates/) turn the general argument and revision-specific checks into a proof for the verified revision.
