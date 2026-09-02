#!/usr/bin/env bash
set -euo pipefail

readonly repository=cameron1729/orderly
readonly approval_url=https://orderly.cameron1729.xyz/commitment.php
readonly helper=layers/common/pdf
readonly work=${2:?Usage: publish.sh prepare|render|upload <temporary directory>}
readonly pdf_names=(theory-0.pdf orderly.pdf)
mkdir -p "$work"
[[ $work == /* ]] || { printf 'Expected an absolute temporary directory.\n' >&2; exit 1; }

fail() { printf '%s\n' "$*" >&2; exit 1; }
download() { curl --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 120 --retry 3 "$@"; }
api() {
  download --fail --header "Authorization: Bearer ${GH_TOKEN:?}" \
    --header 'Accept: application/vnd.github+json' \
    --header 'X-GitHub-Api-Version: 2022-11-28' \
    "https://api.github.com/repos/$repository/actions/$1"
}
pdf_header() { [[ $(head -c 5 "$1") == '%PDF-' ]]; }
summary() {
  printf '%s: [%s](%s)\n' "$1" "$2" "$3" >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
}
publication_exists() {
  jq -er --arg name "$1" '.publications[$name].exists
    | if type == "boolean" then tostring else error("Missing publication state") end' "$work/evidence.json"
}

case ${1-} in
  prepare)
    [[ ${GITHUB_EVENT_NAME-} == workflow_run ]] || fail 'Expected a workflow_run event.'
    jq -e '.workflow_run | (.id | type == "number") and (.run_attempt | type == "number")
      and (.id > 0) and (.run_attempt > 0) and (.head_sha | test("^[0-9a-f]{40}$"))' \
      "${GITHUB_EVENT_PATH:?}" > /dev/null
    run_id=$(jq -r '.workflow_run.id' "$GITHUB_EVENT_PATH")
    attempt=$(jq -r '.workflow_run.run_attempt' "$GITHUB_EVENT_PATH")
    revision=$(git rev-parse HEAD)
    git diff --quiet HEAD -- layers .github src composer.json || fail 'Source checkout has local changes.'
    api "runs/$run_id/attempts/$attempt" > "$work/run.json"
    page=1
    pages=()
    while :; do
      api "runs/$run_id/jobs?filter=all&per_page=100&page=$page" > "$work/page-$page.json"
      pages+=("$work/page-$page.json")
      jq -e '.jobs | type == "array"' "$work/page-$page.json" > /dev/null
      [[ $(jq '.jobs | length' "$work/page-$page.json") -eq 100 ]] || break
      page=$((page + 1))
    done
    jq -s '[.[].jobs[]]' "${pages[@]}" > "$work/jobs.json"
    jq -n --slurpfile event "$GITHUB_EVENT_PATH" --slurpfile run "$work/run.json" \
      --slurpfile jobs "$work/jobs.json" --arg revision "$revision" \
      --arg repository "${GITHUB_REPOSITORY:?}" \
      --arg publication_url "https://github.com/$repository/actions/runs/${GITHUB_RUN_ID:?}/attempts/${GITHUB_RUN_ATTEMPT:?}" \
      --arg publication_attempt "$GITHUB_RUN_ATTEMPT" \
      --arg publication_workflow_revision "${GITHUB_WORKFLOW_SHA:?}" \
      -f "$helper/evidence.jq" > "$work/verification.json"

    # Definitions and presentation templates both come from the verified tree.
    : > "$work/snapshot-digests.jsonl"
    for path in layers/CORRECTNESS.md layers/0-theory/THEORY.md \
      layers/common/templates/correctness.md layers/common/templates/theory-source.md \
      layers/0-theory/templates/proof.md; do
      mkdir -p "$work/sources/$(dirname "$path")"
      git show "$revision:$path" > "$work/sources/$path"
      digest=$(sha256sum "$work/sources/$path" | cut -d ' ' -f 1)
      jq -n --arg path "$path" --arg digest "$digest" '{key: $path, value: $digest}' \
        >> "$work/snapshot-digests.jsonl"
    done
    jq -s 'from_entries' "$work/snapshot-digests.jsonl" > "$work/snapshot-digests.json"

    : > "$work/document-approvals.jsonl"
    for document in correctness theory; do
      case $document in
        correctness) path=layers/CORRECTNESS.md; url="$approval_url?document=correctness" ;;
        theory) path=layers/0-theory/THEORY.md; url=$approval_url ;;
      esac
      digest=$(jq -r --arg path "$path" '.[$path]' "$work/snapshot-digests.json")
      download --fail "$url" > "$work/$document-approved.sha256"
      approved=$(< "$work/$document-approved.sha256")
      [[ $approved =~ ^[0-9a-f]{64}$ ]] || fail "Invalid independent $document approval."
      [[ $digest == "$approved" ]] || fail "The committed $document document does not match its independent approval."
      approval_time=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
      jq -n --arg document "$document" --arg path "$path" --arg digest "$digest" \
        --arg approved "$approved" --arg url "$url" --arg time "$approval_time" \
        '{key: $document, value: {path: $path, digest: $digest, approved_digest: $approved,
          approval_url: $url, approval_time: $time}}' >> "$work/document-approvals.jsonl"
      printf 'SHA-256 match: %s = %s\n' "$path" "$digest"
      # Keep both sides of each comparison inspectable from the PDF's run link.
      # shellcheck disable=SC2016
      printf '### SHA-256: `%s`\n\nSource at `%s`: [committed file](%s), [raw Markdown](%s).\n\nComputed: `%s`\n\nRequired: `%s` ([independent approval](%s), retrieved %s).\n\nResult: **match**.\n\n' \
        "$path" "$revision" "https://github.com/$repository/blob/$revision/$path" \
        "https://raw.githubusercontent.com/$repository/$revision/$path" \
        "$digest" "$approved" "$url" "$approval_time" >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
    done
    jq -s 'from_entries' "$work/document-approvals.jsonl" > "$work/documents.json"

    : > "$work/publications.jsonl"
    all_exist=true
    for filename in "${pdf_names[@]}"; do
      pdf_url="https://orderly.cameron1729.xyz/proofs/$revision/$filename"
      status=$(download --output "$work/existing-$filename" --write-out '%{http_code}' "$pdf_url")
      case $status in
        200)
          pdf_header "$work/existing-$filename" || fail "The existing $filename is not a PDF."
          exists=true
          summary 'Already published; leaving unchanged' "$filename" "$pdf_url"
          ;;
        404) exists=false; all_exist=false ;;
        *) fail "Could not check $filename (HTTP $status)." ;;
      esac
      jq -n --arg filename "$filename" --arg url "$pdf_url" --argjson exists "$exists" \
        '{key: $filename, value: {exists: $exists, url: $url}}' >> "$work/publications.jsonl"
    done
    jq -s 'from_entries' "$work/publications.jsonl" > "$work/publications.json"
    jq --slurpfile documents "$work/documents.json" --slurpfile publications "$work/publications.json" \
      --slurpfile digests "$work/snapshot-digests.json" --arg snapshot "$work/sources" \
      '. + {documents: $documents[0], publications: $publications[0],
        snapshot_root: $snapshot, snapshot_digests: $digests[0]}' \
      "$work/verification.json" > "$work/evidence.json"
    printf 'exists=%s\n' "$all_exist" >> "${GITHUB_OUTPUT:-/dev/stdout}"
    ;;

  render)
    # Detect an altered snapshot before passing its bytes to the renderer.
    jq -er '.snapshot_digests | to_entries[] | [.key, .value] | @tsv' \
      "$work/evidence.json" > "$work/snapshot-digests.tsv"
    while IFS=$'\t' read -r path expected; do
      digest=$(sha256sum "$work/sources/$path" | cut -d ' ' -f 1)
      [[ $digest == "$expected" ]] || fail "The source snapshot changed: $path"
    done < "$work/snapshot-digests.tsv"
    for filename in "${pdf_names[@]}"; do
      exists=$(publication_exists "$filename")
      [[ $exists == false ]] || continue
      case $filename in
        theory-0.pdf) manifest=layers/0-theory/pdf.yaml ;;
        orderly.pdf) manifest=layers/pdf.yaml ;;
      esac
      if ! pandoc --defaults "$manifest" --metadata-file "$work/evidence.json" \
        --output "$work/$filename" /dev/null 2> "$work/render-$filename.log"; then
        message=$(< "$work/render-$filename.log")
        message=${message//%/%25}
        message=${message//$'\r'/%0D}
        message=${message//$'\n'/%0A}
        printf '::error title=PDF rendering failed::%s\n' "$message"
        exit 1
      fi
      cat "$work/render-$filename.log"
      pdf_header "$work/$filename" || fail 'The renderer did not produce a PDF.'
      pdfinfo "$work/$filename"
      [[ $(wc -c < "$work/$filename") -le $((20 * 1024 * 1024)) ]] || fail 'PDF exceeds the receiver limit.'
    done
    ;;

  upload)
    revision=$(jq -er '.revision' "$work/evidence.json")
    [[ $revision =~ ^[0-9a-f]{40}$ ]] || fail 'Expected a full commit SHA.'
    umask 077
    ssh_directory=$(mktemp -d)
    trap 'rm -f "$ssh_directory/key" "$ssh_directory/known_hosts"; rmdir "$ssh_directory"' EXIT
    printf '%s\n' "${PDF_DEPLOY_KEY:?}" > "$ssh_directory/key"
    unset PDF_DEPLOY_KEY
    printf '%s\n' '[cameron1729.xyz]:728 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLkZR7QKmlqGicXQbpPDVPNHOMEtQlE6HuY2dlTwv3cbhf+mu0q+FvKjXpjJiB699pNzPNYQs6QdftMQJ0+VLq4=' > "$ssh_directory/known_hosts"
    ssh-keygen -l -f "$ssh_directory/known_hosts"
    # Publish the companion first. A retry skips each immutable file independently.
    for filename in "${pdf_names[@]}"; do
      exists=$(publication_exists "$filename")
      [[ $exists == false ]] || continue
      pdf_url="https://orderly.cameron1729.xyz/proofs/$revision/$filename"
      digest=$(sha256sum "$work/$filename" | cut -d ' ' -f 1)
      ssh -F /dev/null -p 728 -i "$ssh_directory/key" \
        -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
        -o "UserKnownHostsFile=$ssh_directory/known_hosts" -o GlobalKnownHostsFile=/dev/null \
        -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
        orderly-pdf@cameron1729.xyz "upload $revision $filename $digest" < "$work/$filename"
      download --fail "$pdf_url" > "$work/published-$filename"
      cmp --silent "$work/$filename" "$work/published-$filename" || fail "The public $filename differs from the uploaded bytes."
      summary 'Published and checked byte-for-byte' "$filename" "$pdf_url"
      # shellcheck disable=SC2016
      printf 'PDF SHA-256: `%s`\n' "$digest" >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
    done
    ;;

  *) fail 'Usage: publish.sh prepare|render|upload <temporary directory>' ;;
esac
