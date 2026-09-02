import Orderly

namespace Layer2

open Orderly

/-- Rules declared by this layer in this revision. -/
def rules (ArrayValue : Type) : List (Rule ArrayValue) := []

/-- Every input–output pair in the PHP function graph satisfies this layer's declared rules. -/
theorem resultsCorrect (ArrayValue : Type) : ResultsCorrect (rules ArrayValue) := by
  intro operation pair
  exact False.elim (graphEmpty operation pair)

theorem pure : Machine.Pure Machine.program := Machine.pure

theorem correct (ArrayValue : Type) :
    (executionContract ArrayValue (fun _ : Unit => Machine.program)).Correct () (rules ArrayValue) :=
  ⟨pure, resultsCorrect ArrayValue⟩

end Layer2
