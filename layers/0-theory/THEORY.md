# A categorical theory of anchored selection across scale

This document states the mathematical meaning of Orderly before choosing a formal language or a concrete realization. A semantic change begins here: it must first make sense as a change to the theory before it is propagated through formal models, executable references, conformance data, and production code.

The definitions below constitute $\mathbb{T}_{\mathrm{Orderly}}$ in human-readable form. Every subsequent layer may add structure, but it must preserve the meaning established here.

## 1. Categorical starting point

Orderly is a theory of anchored selection across scale.

Its mathematical source is a category $\mathbf{AnchoredScale}$, whose objects present selected positions across grades in an ordered space and whose morphisms preserve that presentation. Its distinguished observation is a functor

$$
\mathsf{Between}
:
\mathbf{AnchoredScale}
\longrightarrow
\mathbf{FinOrd}.
$$

The functor assigns each anchored scale system its least finite ordered observation. This universal characterization is primary. Integer sequences, radix surfaces, and programs are realizations of it.

## 2. Anchored scale systems

An object $S$ of $\mathbf{AnchoredScale}$ consists of the following data:

- a totally ordered set $X_S$ of positions;
- an anchor $a_S\in X_S$ and terminal boundary $z_S\in X_S$, with $a_S\le z_S$;
- a totally ordered set $I_S$ of scale grades;
- a set $P_S$ of selected tokens;
- a grade map $\gamma_S:P_S\to I_S$; and
- an evaluation map $\varepsilon_S:P_S\to X_S$.

A token records provenance before observation: $\gamma_S$ says at which grade it was selected, while $\varepsilon_S$ says where it is observed. Different tokens may evaluate to the same position. Evaluation may also place a token on a boundary or outside the bounded interval.

The selected strict-interior image must be finite:

$$
C_S
=
\left\{
\varepsilon_S(p)
\mid
p\in P_S,
\quad
a_S<\varepsilon_S(p)<z_S
\right\}.
$$

This is the sole finiteness condition required by the general theory. The sets of positions, grades, and tokens may otherwise be infinite.

## 3. Structure-preserving morphisms

A morphism $F:S\to T$ in $\mathbf{AnchoredScale}$ consists of three maps:

$$
u_F:X_S\to X_T,
\qquad
v_F:I_S\to I_T,
\qquad
w_F:P_S\to P_T.
$$

The maps $u_F$ and $v_F$ are monotone. The position map preserves both exact boundaries:

$$
u_F(a_S)=a_T,
\qquad
u_F(z_S)=z_T.
$$

The token map preserves grading and evaluation:

$$
\gamma_T\circ w_F
=
v_F\circ\gamma_S,
$$

$$
\varepsilon_T\circ w_F
=
u_F\circ\varepsilon_S.
$$

Identity morphisms use identity maps. Composition is componentwise. The displayed preservation laws are stable under both operations, and therefore define the category $\mathbf{AnchoredScale}$.

This choice of morphism makes translations, regradings, and enlargements of a selection expressible whenever a realization supplies them as structure-preserving maps. Their observable effects must then be governed by functoriality rather than implementation convention.

## 4. Finite ordered observations

The category $\mathbf{FinOrd}$ has finite totally ordered sets as objects and monotone maps as morphisms.

For a fixed anchored scale system $S$, an admissible observation is a finite subset $O\subseteq X_S$ such that

$$
\{a_S,z_S\}\cup C_S
\subseteq
O
\subseteq
\{x\in X_S\mid a_S\le x\le z_S\}.
$$

It carries the order inherited from $X_S$. Admissible observations form a category $\mathbf{Obs}(S)$ whose morphisms are inclusions.

## 5. The universal property of Between

The object $\mathsf{Between}(S)$ is the initial object of $\mathbf{Obs}(S)$. Equivalently, it is the unique least admissible observation:

$$
\mathsf{Between}(S)
=
\{a_S,z_S\}\cup C_S.
$$

For every admissible observation $O$, there is a unique inclusion

$$
\mathsf{Between}(S)
\longrightarrow
O.
$$

Thus $\mathsf{Between}(S)$ contains every point required by the boundaries and selected tokens, while containing no additional point. In particular, no value can be introduced merely to bridge a gap.

The initial object is unique up to unique order isomorphism. The displayed subset is the canonical representative inherited from $X_S$.

## 6. Functoriality

For a morphism $F:S\to T$, define $\mathsf{Between}(F)$ by restricting the position map:

$$
\mathsf{Between}(F)(x)=u_F(x).
$$

This restriction is well defined. Boundaries map to boundaries. If $x\in C_S$, then $x=\varepsilon_S(p)$ for some selected token $p$, and

$$
u_F(x)
=
\varepsilon_T\bigl(w_F(p)\bigr).
$$

Monotonicity and preservation of the boundaries ensure that this image is either a boundary of $T$ or a selected strict-interior point of $T$. Hence it belongs to $\mathsf{Between}(T)$.

The restricted map is monotone, preserves identity morphisms, and preserves composition. Consequently $\mathsf{Between}$ is a functor from $\mathbf{AnchoredScale}$ to $\mathbf{FinOrd}$.

## 7. Consequences

The universal property and functoriality entail the following laws for every anchored scale system.

### Exact-boundary law

The anchor and terminal boundary occur in the observation independently of token evaluation. When they differ, each occurs exactly once.

### Equal-boundary law

When $a_S=z_S$, the observation is the singleton set $\{a_S\}$.

### Strict-interior law

Every observed point other than the boundaries lies strictly between them.

### Provenance law

Every strict-interior observed point is the evaluation of at least one selected token. The general theory does not require that provenance to be unique.

### Minimality law

No point lacking either boundary status or selected-token provenance occurs in the observation. In particular, no bridge point is invented.

### Order law

The observation is a finite totally ordered set. Its increasing enumeration is strictly increasing and duplicate-free.

### Selection law

If one system differs from another only by including additional selected tokens, the token inclusion defines a morphism and $\mathsf{Between}$ maps it to inclusion of the corresponding observations. Adding selections may add observed points but cannot remove existing ones.

### Naturality law

Every structure-preserving transformation commutes with observation. Transforming a system and then applying $\mathsf{Between}$ agrees with applying $\mathsf{Between}$ and then using the induced monotone map.

## 8. Realizations

The theory deliberately does not prescribe how grades or evaluated positions are constructed.

The exact integer realization supplies a functor

$$
\mathsf{IntegerRadix}
:
\mathbf{IntegerParameters}
\longrightarrow
\mathbf{AnchoredScale}.
$$

That realization may use ordered affine spaces, filtered lattices, quotient representatives, powers of a radix, and mantissas to construct the abstract grade and evaluation maps. Those structures explain the concrete behaviour but do not define the general theory.

A continuous realization supplies geometric structure over a full subcategory $\mathbf{C}\subseteq\mathbf{AnchoredScale}$ of systems admitting that structure:

$$
\mathsf{Realise}
:
\mathbf{C}
\longrightarrow
\mathbf{Surface}.
$$

Where exact sampling is defined, the continuous and discrete observations must agree naturally:

$$
\mathsf{Sample}\circ\mathsf{Realise}
\cong
\mathsf{Between}\vert_{\mathbf{C}}.
$$

The exact domain of the continuous realization and the construction of this natural isomorphism belong to later layers.

Executable reference models and language implementations descend from the exact integer realization. Their governing composition is

$$
\mathsf{between}
=
\mathsf{enumerate}
\circ
\mathsf{Between}
\circ
\mathsf{IntegerRadix}.
$$

## 9. Deliberate generality

Layer 0 chooses no ambient number system, origin, metric, topology, constant radix, initial scale, mantissa representation, interpolation, programming language, or machine-integer behaviour. It does not require different tokens to have distinct evaluations, and it does not prescribe a default selection.

Those choices belong to later realizations. They may add structure and stronger laws, but they may not alter the category, universal property, functoriality, or consequences stated here.
