import Orderly

namespace Layer0

open Orderly

/-- Every input–output pair in the PHP function graph satisfies any collection of theory rules. -/
theorem resultsCorrect (rules : List Rule) : ResultsCorrect rules := by
  intro operation pair
  cases operation
  exact Empty.elim pair

end Layer0
