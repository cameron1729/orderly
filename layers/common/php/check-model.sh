#!/usr/bin/env bash
set -euo pipefail

helper=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
listing=$(mktemp)
trap 'rm -f "$listing"' EXIT
cd "$helper/../lean"
lake env lean --run DumpOpcodes.lean > "$listing"
if ! diff -u "$helper/expected-opcodes.txt" "$listing"; then
    echo 'The Lean instruction model differs from the checked and published listing.' >&2
    exit 1
fi
echo 'The Lean model, compiler witness and publication listing agree.'
