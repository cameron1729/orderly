# Use the triggering attempt, not the run's mutable latest-attempt summary.
def require($condition; $message):
  if $condition then . else error($message) end;

$event[0].workflow_run as $trigger
| $run[0] as $verified
| require($repository == "cameron1729/orderly"
    and $event[0].repository.full_name == $repository;
    "Unexpected publishing repository")
| require($trigger.id == $verified.id
    and $trigger.run_attempt == $verified.run_attempt
    and $trigger.head_sha == $verified.head_sha
    and $verified.head_sha == $revision
    and ($revision | test("^[0-9a-f]{40}$"));
    "Verification run, attempt and checked-out revision must agree")
| require(all([$trigger, $verified][];
    .name == "Correct"
    and .path == ".github/workflows/layers.yml"
    and .head_repository.full_name == $repository
    and .head_branch == "main"
    and (.event == "push" or .event == "workflow_dispatch")
    and .status == "completed"
    and .conclusion == "success");
    "Only successful, trusted main-branch Correct runs may publish")
| ["Layer 0", "Layer 1", "Layer 2", "Layer 3"] as $names
| [$names[] as $name
    | [$jobs[0][]
        | select(.name == $name
            and .run_attempt >= 1
            and .run_attempt <= $verified.run_attempt)]
    | sort_by(.run_attempt, .id) | last
    | require(. != null and .run_id == $verified.id and .head_sha == $revision
        and .status == "completed" and .conclusion == "success";
        "Missing or unsuccessful verification job: \($name)")
    | {name, id: (.id | tostring), run_attempt: (.run_attempt | tostring), html_url, conclusion}] as $selected
| {
    revision: $revision,
    short_revision: $revision[0:8],
    repository: $repository,
    verification_run: ($verified.id | tostring),
    verification_attempt: ($verified.run_attempt | tostring),
    verification_url: "https://github.com/\($repository)/actions/runs/\($verified.id)/attempts/\($verified.run_attempt)",
    jobs: $selected,
    publication_url: $publication_url,
    publication_attempt: $publication_attempt,
    publication_workflow_revision: $publication_workflow_revision
  }
