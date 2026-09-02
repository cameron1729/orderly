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

end Orderly
