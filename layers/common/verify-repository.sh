#!/usr/bin/env bash
# shellcheck disable=SC2016 # Single-quoted PHP and Markdown are intentional.
# shellcheck source-path=SCRIPTDIR

set -euo pipefail

repository=$(git rev-parse --show-toplevel)
cd "$repository"
helper="$repository/layers/common/php"
# shellcheck source=php/runtime.sh
source "$helper/runtime.sh"
profile=$("${orderly_php[@]}" "$helper/verify-opcodes.php" runtime "$helper/profile.json")
printf '%s\n' "$profile"

source_paths=$(git ls-tree -r --name-only HEAD -- src/)

if [[ "$source_paths" != 'src/functions.php' ]]; then
    echo 'PHP repository witness failed: src/functions.php is not the sole committed source path.' >&2
    exit 1
fi

if ! git show HEAD:composer.json | "${orderly_php[@]}" -r '
    $composer = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
    $expected = array("files" => array("src/functions.php"));
    exit(($composer["autoload"] ?? null) === $expected ? 0 : 1);
'; then
    echo 'PHP repository witness failed: Composer does not autoload only src/functions.php.' >&2
    exit 1
fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
source_file="$scratch/functions.php"
git show HEAD:src/functions.php > "$source_file"

if ! "${orderly_php[@]}" -r '
    $tokens = static function (string $source): array {
        $result = [];
        foreach (token_get_all($source, TOKEN_PARSE) as $token) {
            if (!is_array($token)) {
                $result[] = $token;
            } elseif (!in_array($token[0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) {
                $result[] = [$token[0], $token[0] === T_OPEN_TAG ? trim($token[1]) : $token[1]];
            }
        }
        return $result;
    };

    $expected = "<?php
        declare(strict_types=1);
        namespace Cameron1729\\Orderly;
        function between(int \$start, int \$end, int \$base = 10, ?array \$mantissas = null): never { while (true) {} }
    ";

    exit($tokens(file_get_contents($argv[1])) === $tokens($expected) ? 0 : 1);
' "$source_file"; then
    echo 'PHP repository witness failed: source does not match the between(): never declaration and empty infinite loop.' >&2
    exit 1
fi

if ! "${orderly_php[@]}" -r '
    $beforeFunctions = get_defined_functions()["user"];
    $beforeTypes = array_merge(get_declared_classes(), get_declared_interfaces(), get_declared_traits());

    require $argv[1];

    $functions = array_values(array_diff(get_defined_functions()["user"], $beforeFunctions));
    $types = array_diff(
        array_merge(get_declared_classes(), get_declared_interfaces(), get_declared_traits()),
        $beforeTypes,
    );

    if ($functions !== array("cameron1729\\orderly\\between") || $types !== array()) {
        exit(1);
    }

    $returnType = (new ReflectionFunction($functions[0]))->getReturnType();
    exit(
        $returnType instanceof ReflectionNamedType && $returnType->getName() === "never"
            ? 0
            : 1
    );
' "$source_file"; then
    echo 'PHP repository witness failed: Composer does not expose only between(): never.' >&2
    exit 1
fi

# Loading this exact declaration never calls between. The loop is not executed.
"${orderly_php[@]}" -d opcache.opt_debug_level=0x20000 "$source_file" \
    > "$scratch/stdout" 2> "$scratch/opcodes"
[[ ! -s $scratch/stdout ]] || { echo 'Unexpected output while loading the declaration.' >&2; exit 1; }
"${orderly_php[@]}" "$helper/verify-opcodes.php" dump "$helper/profile.json" \
    "$scratch/opcodes" "$helper/expected-opcodes.txt" > "$scratch/checked-opcodes"
revision=$(git rev-parse HEAD)
printf 'PHP opcode witness holds for revision %s:\n' "$revision"
cat "$scratch/checked-opcodes"
if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
    {
        printf '### PHP opcode witness\n\nRevision: `%s`\n\n%s\n\n```text\n' "$revision" "$profile"
        cat "$scratch/checked-opcodes"
        printf '```\n\nThe complete compiled sequence matches the program used by the Lean proof.\n'
    } >> "$GITHUB_STEP_SUMMARY"
fi
