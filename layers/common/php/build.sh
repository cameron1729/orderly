#!/usr/bin/env bash
set -euo pipefail

helper=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
prefix=${1:?Usage: build.sh <absolute installation directory>}
[[ $prefix == /* && $prefix != / ]] || { echo 'Expected a private absolute installation directory.' >&2; exit 1; }
fingerprint=$(sha256sum "$helper/profile.json" "$helper/build.sh" | cut -d ' ' -f 1 | sha256sum | cut -d ' ' -f 1)
if [[ -f $prefix/build-fingerprint && $(< "$prefix/build-fingerprint") == "$fingerprint" && -x $prefix/bin/php ]]; then
    echo 'Using the cached PHP verification runtime.'
    exit 0
fi
[[ ! -e $prefix/bin/php ]] || { echo 'The cached runtime does not match this build profile.' >&2; exit 1; }

version=$(jq -er '.version' "$helper/profile.json")
url=$(jq -er '.source_url' "$helper/profile.json")
digest=$(jq -er '.source_sha256' "$helper/profile.json")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
archive=${ORDERLY_PHP_ARCHIVE:-$work/php.tar.xz}
if [[ ! -f $archive ]]; then
    curl --fail --location --proto '=https' --proto-redir '=https' --silent --show-error \
        --connect-timeout 15 --max-time 180 --retry 3 --output "$archive" "$url"
fi
[[ $(sha256sum "$archive" | cut -d ' ' -f 1) == "$digest" ]] || { echo 'PHP source checksum mismatch.' >&2; exit 1; }
tar -xJf "$archive" -C "$work"
cd "$work/php-$version"
mkdir -p "$prefix"
if ! (
    ./configure --prefix="$prefix" --disable-all --enable-cli --disable-cgi \
        --disable-phpdbg --without-pear --enable-tokenizer --enable-opcache --disable-opcache-jit || exit 1
    make -j2 || exit 1
    make install || exit 1
) > "$prefix/build.log" 2>&1; then
    tail -n 80 "$prefix/build.log" >&2
    exit 1
fi
printf '%s\n' "$fingerprint" > "$prefix/build-fingerprint"
"$prefix/bin/php" -n --version
echo "Built stock PHP $version from SHA-256 $digest."
