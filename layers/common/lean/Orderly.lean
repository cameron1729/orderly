namespace Orderly

/-- The public PHP operations exposed by the committed Composer package. -/
inductive PublicOperation : Type where
  | between : PublicOperation

/-- Input–output pairs in the graph of each public operation. -/
def Graph : PublicOperation → Type
  | .between => Empty

/-- A rule assigns a proposition to each input–output pair of each operation. -/
def Rule := (operation : PublicOperation) → Graph operation → Prop

/-- The input–output component of PHP correctness with respect to a layer. -/
def ResultsCorrect (rules : List Rule) : Prop :=
  ∀ operation : PublicOperation,
    ∀ pair : Graph operation,
      ∀ rule ∈ rules, rule operation pair

/-- A revision-indexed contract model. Purity is an explicit semantic premise;
this model does not implement PHP's execution semantics. -/
structure Contract (Revision : Type) where
  Operation : Revision → Type
  Graph : (r : Revision) → Operation r → Type
  Pure : Revision → Prop

namespace Contract

variable {Revision : Type}

def Rule (m : Contract Revision) (r : Revision) :=
  (operation : m.Operation r) → m.Graph r operation → Prop

def EmptyGraphs (m : Contract Revision) (r : Revision) : Prop :=
  ∀ operation : m.Operation r, m.Graph r operation → False

def IO (m : Contract Revision) (r : Revision) (rules : List (m.Rule r)) : Prop :=
  ∀ operation : m.Operation r,
    ∀ pair : m.Graph r operation,
      ∀ rule ∈ rules, rule operation pair

def Correct (m : Contract Revision) (r : Revision) (rules : List (m.Rule r)) : Prop :=
  m.Pure r ∧ m.IO r rules

def OverallCorrect (m : Contract Revision) (r : Revision)
    (layers : List Nat) (rules : Nat → List (m.Rule r)) : Prop :=
  ∀ layer ∈ layers, m.Correct r (rules layer)

theorem ioOfEmpty (m : Contract Revision) (r : Revision) (rules : List (m.Rule r))
    (empty : m.EmptyGraphs r) : m.IO r rules := by
  intro operation pair
  exact False.elim (empty operation pair)

theorem correctOfPureAndEmpty (m : Contract Revision) (r : Revision)
    (rules : List (m.Rule r)) (pure : m.Pure r) (empty : m.EmptyGraphs r) :
    m.Correct r rules :=
  ⟨pure, m.ioOfEmpty r rules empty⟩

end Contract

/-- An abstract run record. Its authenticity is supplied by the external run
checks, not established by constructing this record in Lean. -/
structure VerificationRun (Revision Check : Type) where
  revision : Revision
  check : Check
  succeeded : Bool

/-- Recorded identifies authenticated evidence. A freely constructed run record
does not, by itself, establish that a check was executed. -/
def Verified {Revision Check : Type} (recorded : VerificationRun Revision Check → Prop)
    (w : VerificationRun Revision Check)
    (r : Revision) (designated : Check) : Prop :=
  recorded w ∧ w.revision = r ∧ w.check = designated ∧ w.succeeded = true

/-- The trusted bridge from the designated source checker to PHP premises. -/
def VerifierSound {Revision Check : Type} (m : Contract Revision)
    (recorded : VerificationRun Revision Check → Prop) (designated : Check) : Prop :=
  ∀ (w : VerificationRun Revision Check) (r : Revision),
    Verified recorded w r designated → m.Pure r ∧ m.EmptyGraphs r

/-- Exact source identity, deliberately independent of any hashing function. -/
def Bound {Document : Type} (used committed : Document) : Prop := used = committed

/-- Digest equality with a separately supplied approved digest. H denotes
SHA-256 in the publication integration; Lean neither computes it nor treats it
as injective. The external approval's provenance is checked by the publisher. -/
def Approved {Document Digest : Type} (H : Document → Digest)
    (committed : Document) (approved : Digest) : Prop :=
  H committed = approved

theorem requirementsOfBinding {Document : Type} {used committed : Document}
    (requirements : Document → Prop) (binding : Bound used committed)
    (satisfied : requirements used) : requirements committed := by
  cases binding
  exact satisfied

end Orderly
