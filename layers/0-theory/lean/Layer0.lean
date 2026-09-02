import Orderly

namespace Layer0

open Orderly

/-- Every input–output pair in the PHP function graph satisfies any collection of theory rules. -/
theorem resultsCorrect (rules : List Rule) : ResultsCorrect rules := by
  intro operation pair
  cases operation
  exact Empty.elim pair

/-- Correctness from purity and non-return: the premises and two matching source
digests establish correctness for the committed theory. The conclusion also
retains the digests identifying the documents used in the claim. -/
theorem correctnessOfPremises
    {Revision Path Document Digest : Type}
    (m : Contract Revision) (r : Revision)
    (sourceAt : Revision → Path → Document) (definitionPath theoryPath : Path)
    (H : Document → Digest) (definitionDigest theoryDigest : Digest)
    (rules : Document → List (m.Rule r))
    (pure : m.Pure r)
    (empty : m.EmptyGraphs r)
    (theoryHash : H (sourceAt r theoryPath) = theoryDigest)
    (definitionHash : H (sourceAt r definitionPath) = definitionDigest) :
    m.Correct r (rules (sourceAt r theoryPath)) ∧
      H (sourceAt r theoryPath) = theoryDigest ∧
      H (sourceAt r definitionPath) = definitionDigest :=
  ⟨m.correctOfPureAndEmpty r (rules (sourceAt r theoryPath)) pure empty,
    theoryHash, definitionHash⟩

/-- Apply the theorem to the premises supplied by the designated source check and the
two document-hash comparisons. Hash equality is not used to infer equality
between different documents: the rules come directly from the committed source. -/
theorem correctnessOfVerification
    {Revision Check Path Document Digest : Type}
    (m : Contract Revision) (r : Revision)
    (recorded : VerificationRun Revision Check → Prop)
    (w : VerificationRun Revision Check) (designated : Check)
    (sourceAt : Revision → Path → Document) (definitionPath theoryPath : Path)
    (H : Document → Digest)
    (definitionDigest theoryDigest : Digest)
    (rules : Document → List (m.Rule r))
    (sound : VerifierSound m recorded designated)
    (verified : Verified recorded w r designated)
    (theoryHash : H (sourceAt r theoryPath) = theoryDigest)
    (definitionHash : H (sourceAt r definitionPath) = definitionDigest) :
    m.Correct r (rules (sourceAt r theoryPath)) ∧
      H (sourceAt r theoryPath) = theoryDigest ∧
      H (sourceAt r definitionPath) = definitionDigest := by
  obtain ⟨pure, empty⟩ := sound w r verified
  exact correctnessOfPremises m r sourceAt definitionPath theoryPath H
    definitionDigest theoryDigest rules pure empty theoryHash definitionHash

/-- An empty graph alone cannot establish purity. -/
private def impureEmpty : Contract Unit where
  Operation := fun _ => Unit
  Graph := fun _ _ => Empty
  Pure := fun _ => False

example : impureEmpty.EmptyGraphs () := by
  intro _ pair
  exact Empty.elim pair

example : ¬ impureEmpty.Correct () [] := by
  intro claim
  exact claim.1

/-- A pure operation may still have a result that violates a rule. -/
private def pureNonempty : Contract Unit where
  Operation := fun _ => Unit
  Graph := fun _ _ => Unit
  Pure := fun _ => True

example : pureNonempty.Pure () := True.intro

example : ¬ pureNonempty.Correct () [fun _ _ => False] := by
  intro claim
  exact claim.2 () () (fun _ _ => False) (List.Mem.head [])

/-- Even equal digests do not imply that two documents are identical. -/
example : Approved (fun (_ : Bool) => ()) false () ∧
    Approved (fun (_ : Bool) => ()) true () ∧ ¬ Bound false true := by
  refine ⟨rfl, rfl, ?_⟩
  unfold Bound
  decide

/-- Success for another revision or another check does not supply this witness. -/
example : ¬ Verified (fun _ => True) (⟨false, (), true⟩ : VerificationRun Bool Unit) true () := by
  unfold Verified
  decide

example : ¬ Verified (fun _ => True) (⟨(), false, true⟩ : VerificationRun Unit Bool) () true := by
  unfold Verified
  decide

/-- A successful-looking record is insufficient without authenticated evidence. -/
example : ¬ Verified (fun _ => False) (⟨(), (), true⟩ : VerificationRun Unit Unit) () () := by
  unfold Verified
  decide

example : ¬ Approved (fun b : Bool => b) false true := by
  unfold Approved
  decide

end Layer0
