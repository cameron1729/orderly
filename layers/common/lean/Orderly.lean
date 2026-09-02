import Std

namespace Orderly

/- A deliberately small, deterministic, labelled instruction model. PHP arrays
are opaque input values: the proofs are parametric in their representation.
Events record external writes AND reads. Zend's correspondence with these
semantics is an explicit runtime assumption, not a theorem about its C code. -/
namespace Machine

inductive Value (ArrayValue : Type) where
  | integer : Int → Value ArrayValue
  | array : ArrayValue → Value ArrayValue
  | null : Value ArrayValue
  deriving DecidableEq

inductive Literal where
  | integer : Int → Literal
  | null : Literal
  deriving DecidableEq

def Literal.value {ArrayValue : Type} : Literal → Value ArrayValue
  | .integer n => .integer n
  | .null => .null

/-- Independent optional arguments also cover named calls which omit base but
provide mantissas. No positivity or array-content restriction is imposed. -/
structure Inputs (ArrayValue : Type) where
  start : Int
  finish : Int
  base : Option Int
  mantissas : Option (Option ArrayValue)

def Inputs.argument {ArrayValue : Type} (inputs : Inputs ArrayValue) : Nat → Option (Value ArrayValue)
  | 1 => some (.integer inputs.start)
  | 2 => some (.integer inputs.finish)
  | 3 => inputs.base.map Value.integer
  | 4 => inputs.mantissas.map (fun value => value.elim Value.null Value.array)
  | _ => none

inductive Instruction where
  | receive (argument slot : Nat)
  | receiveDefault (argument slot : Nat) (value : Literal)
  | jump (target : Nat)
  | returnValue (value : Literal)
  | emit
  | readExternal (slot : Nat)
  deriving DecidableEq

inductive Event where
  | externalWrite
  | externalRead
  deriving DecidableEq

inductive Outcome (ArrayValue : Type) where
  | running
  | returned (value : Value ArrayValue)
  | failed
  deriving DecidableEq

structure State (ArrayValue : Type) where
  pc : Nat := 0
  locals : Nat → Option (Value ArrayValue) := fun _ => none
  events : List Event := []
  outcome : Outcome ArrayValue := .running

def State.bind {ArrayValue : Type} (state : State ArrayValue) (slot : Nat)
    (value : Value ArrayValue) : State ArrayValue :=
  { state with
    pc := state.pc + 1
    locals := fun index => if index = slot then some value else state.locals index }

/-- An external action produces a label; it is never silently modelled as a
pure instruction. The external value is available only via readExternal. -/
def step {ArrayValue : Type} (program : List Instruction) (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) (state : State ArrayValue) : State ArrayValue :=
  match state.outcome with
  | .returned _ | .failed => state
  | .running =>
    match program[state.pc]? with
    | some (.receive argument slot) =>
      match inputs.argument argument with
      | some value => state.bind slot value
      | none => { state with outcome := .failed }
    | some (.receiveDefault argument slot value) =>
      state.bind slot ((inputs.argument argument).getD value.value)
    | some (.jump target) => { state with pc := target }
    | some (.returnValue value) => { state with outcome := .returned value.value }
    | some .emit =>
      { state with pc := state.pc + 1, events := state.events ++ [.externalWrite] }
    | some (.readExternal slot) =>
      { state.bind slot external with events := state.events ++ [.externalRead] }
    | none => { state with outcome := .failed }

def execute {ArrayValue : Type} (program : List Instruction) (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) : Nat → State ArrayValue
  | 0 => {}
  | n + 1 => step program inputs external (execute program inputs external n)

/-- No externally visible actions or ambient reads at any finite prefix, and
the entire computation is independent of external state. Nontermination is
permitted. A timeout or host callback is not a transition in this model. -/
def Pure (program : List Instruction) : Prop :=
  (∀ (ArrayValue : Type) (inputs : Inputs ArrayValue) (external : Value ArrayValue) (n : Nat),
    (execute program inputs external n).events = []) ∧
  (∀ (ArrayValue : Type) (inputs : Inputs ArrayValue)
      (external other : Value ArrayValue) (n : Nat),
    execute program inputs external n = execute program inputs other n)

def program : List Instruction :=
  [.receive 1 0, .receive 2 1, .receiveDefault 3 2 (.integer 10),
    .receiveDefault 4 3 .null, .jump 4]

private def Invariant {ArrayValue : Type} (state : State ArrayValue) : Prop :=
  state.pc ≤ 4 ∧ state.outcome = .running ∧ state.events = []

private theorem invariant_step {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) (state : State ArrayValue) (h : Invariant state) :
    Invariant (step program inputs external state) := by
  obtain ⟨bound, running, events⟩ := h
  have positions : state.pc = 0 ∨ state.pc = 1 ∨ state.pc = 2 ∨
      state.pc = 3 ∨ state.pc = 4 := by omega
  rcases positions with h | h | h | h | h <;>
    simp [Invariant, step, program, h, running, events, Inputs.argument, State.bind]

private theorem invariant {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) (n : Nat) :
    Invariant (execute program inputs external n) := by
  induction n with
  | zero => simp [execute, Invariant]
  | succ n ih => exact invariant_step inputs external _ ih

private theorem step_independent {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external other : Value ArrayValue) (state : State ArrayValue) (h : Invariant state) :
    step program inputs external state = step program inputs other state := by
  obtain ⟨bound, running, _⟩ := h
  have positions : state.pc = 0 ∨ state.pc = 1 ∨ state.pc = 2 ∨
      state.pc = 3 ∨ state.pc = 4 := by omega
  rcases positions with h | h | h | h | h <;> simp [step, program, h, running]

theorem pure : Pure program := by
  constructor
  · intro ArrayValue inputs external n
    exact (invariant inputs external n).2.2
  · intro ArrayValue inputs external other n
    induction n with
    | zero => rfl
    | succ n ih =>
      simp only [execute, ih]
      exact step_independent inputs external other _ (invariant inputs other n)

theorem entersLoop {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) :
    (execute program inputs external 4).pc = 4 ∧
    (execute program inputs external 4).outcome = .running := by
  simp [execute, step, program, Inputs.argument, State.bind]

theorem loopStep {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) (state : State ArrayValue)
    (pc : state.pc = 4) (running : state.outcome = .running) :
    step program inputs external state = state := by
  simp [step, program, pc, running]
  cases state
  simp_all

theorem loopsForever {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) (n : Nat) :
    execute program inputs external (4 + n) = execute program inputs external 4 := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [Nat.add_succ, execute, ih]
    exact loopStep inputs external _ (entersLoop inputs external).1
      (entersLoop inputs external).2

theorem noNormalReturn {ArrayValue : Type} (inputs : Inputs ArrayValue)
    (external : Value ArrayValue) (n : Nat) (value : Value ArrayValue) :
    (execute program inputs external n).outcome ≠ .returned value := by
  rw [(invariant inputs external n).2.1]
  intro impossible
  cases impossible

/-- A graph member must carry a finite execution returning its output. -/
structure Graph (code : List Instruction) (ArrayValue : Type) where
  inputs : Inputs ArrayValue
  output : Value ArrayValue
  returns : ∃ (external : Value ArrayValue) (steps : Nat),
    (execute code inputs external steps).outcome = .returned output

theorem graphEmpty {ArrayValue : Type} (pair : Graph program ArrayValue) : False := by
  obtain ⟨external, steps, returned⟩ := pair.returns
  exact noNormalReturn pair.inputs external steps pair.output returned

/-- Render the actual model, for comparison with the compiler and PDF listing. -/
private def address (n : Nat) : String :=
  let digits := toString n
  String.ofList (List.replicate (4 - digits.length) '0') ++ digits

private def localName (slot : Nat) : String :=
  let name := match slot with
    | 0 => "start" | 1 => "end" | 2 => "base" | 3 => "mantissas" | _ => "unknown"
  s!"CV{slot}(${name})"

private def Literal.render : Literal → String
  | .integer n => s!"int({n})"
  | .null => "null"

private def Instruction.render : Instruction → String
  | .receive argument slot => s!"{localName slot} = RECV {argument}"
  | .receiveDefault argument slot value =>
    s!"{localName slot} = RECV_INIT {argument} {value.render}"
  | .jump target => s!"JMP {address target}"
  | .returnValue value => s!"RETURN {value.render}"
  | .emit => "EFFECT"
  | .readExternal slot => s!"{localName slot} = EXTERNAL_READ"

def renderedProgram : String :=
  String.intercalate "\n" (program.zipIdx.map fun (instruction, index) =>
    s!"{address index} {instruction.render}") ++ "\n"

/-- Non-return does not excuse an external effect. -/
example : ¬ Pure [.emit, .jump 1] := by
  intro h
  have empty := h.1 Unit ⟨0, 0, none, none⟩ .null 1
  simp [execute, step] at empty

/-- A normal return can exist in the model: graph emptiness is not baked in. -/
example : (execute [.returnValue (.integer 7)]
    (⟨0, 0, none, none⟩ : Inputs Unit) .null 1).outcome = .returned (.integer 7) := rfl

/-- Reading ambient state also fails purity, even without an external write. -/
example : ¬ Pure [.readExternal 0, .jump 1] := by
  intro h
  have empty := h.1 Unit ⟨0, 0, none, none⟩ .null 1
  simp [execute, step, State.bind] at empty

end Machine

/-- The public PHP operations exposed by the committed Composer package. -/
inductive PublicOperation : Type where
  | between : PublicOperation

/-- Input–output pairs in the graph of each public operation. -/
def ExecutionGraph (program : List Machine.Instruction) (ArrayValue : Type) : PublicOperation → Type
  | .between => Machine.Graph program ArrayValue

def Graph (ArrayValue : Type) := ExecutionGraph Machine.program ArrayValue

theorem graphEmpty {ArrayValue : Type} (operation : PublicOperation)
    (pair : Graph ArrayValue operation) : False := by
  cases operation
  exact Machine.graphEmpty pair

/-- A rule assigns a proposition to each input–output pair of each operation. -/
def Rule (ArrayValue : Type) := (operation : PublicOperation) → Graph ArrayValue operation → Prop

/-- The input–output component of PHP correctness with respect to a layer. -/
def ResultsCorrect {ArrayValue : Type} (rules : List (Rule ArrayValue)) : Prop :=
  ∀ operation : PublicOperation,
    ∀ pair : Graph ArrayValue operation,
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

/-- A contract whose graph and purity come from execution semantics. The
runtime correspondence identifies programAt with the compiled PHP program. -/
def executionContract {Revision : Type} (ArrayValue : Type)
    (programAt : Revision → List Machine.Instruction) : Contract Revision where
  Operation := fun _ => PublicOperation
  Graph := fun r => ExecutionGraph (programAt r) ArrayValue
  Pure := fun r => Machine.Pure (programAt r)

theorem premisesOfProgram {Revision : Type} (ArrayValue : Type)
    (programAt : Revision → List Machine.Instruction) (r : Revision)
    (program_eq : programAt r = Machine.program) :
    (executionContract ArrayValue programAt).Pure r ∧
      (executionContract ArrayValue programAt).EmptyGraphs r := by
  constructor
  · simpa [executionContract, program_eq] using Machine.pure
  · intro operation pair
    cases operation
    change Machine.Graph (programAt r) ArrayValue at pair
    rw [program_eq] at pair
    exact Machine.graphEmpty pair

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

/-- The trusted correspondence of the pinned runtime and opcode extractor with
the model. A successful check supplies the instruction sequence, not purity or
an empty graph; those are derived by the machine theorems. -/
def VerifierSound {Revision Check : Type} (programAt : Revision → List Machine.Instruction)
    (recorded : VerificationRun Revision Check → Prop) (designated : Check) : Prop :=
  ∀ (w : VerificationRun Revision Check) (r : Revision),
    Verified recorded w r designated → programAt r = Machine.program

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
