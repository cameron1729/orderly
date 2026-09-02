#!/usr/bin/env bash
# Sourced by the repository check so every PHP process has the same profile.
php_helper=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
optimization_level=$(jq -er '.optimization_level' "$php_helper/profile.json")
# shellcheck disable=SC2034 # Exported to the sourcing verifier as a shell array.
orderly_php=("${ORDERLY_PHP_BIN:-php}" -n
    -d "zend_extension=${ORDERLY_PHP_OPCACHE:-opcache}"
    -d opcache.enable=1 -d opcache.enable_cli=1
    -d "opcache.optimization_level=$optimization_level"
    -d opcache.file_update_protection=0 -d opcache.file_cache=
    -d opcache.jit=disable -d opcache.jit_buffer_size=0 -d max_execution_time=0)
