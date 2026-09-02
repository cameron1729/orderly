<?php

/*
 * SPDX-FileCopyrightText: 2026 Cameron Ball
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

function fail(string $message): never
{
    fwrite(STDERR, "PHP opcode witness failed: $message\n");
    exit(1);
}

function verifyRuntime(array $profile): void
{
    if (PHP_VERSION !== $profile['version'] || PHP_OS_FAMILY !== $profile['os']
        || php_uname('m') !== $profile['architecture'] || PHP_INT_SIZE !== $profile['integer_size']
        || PHP_SAPI !== $profile['sapi'] || (bool) PHP_ZTS !== $profile['thread_safe']) {
        fail('The PHP version, platform or build mode differs from the pinned profile.');
    }
    if (get_loaded_extensions(true) !== ['Zend OPcache']
        || phpversion('Zend OPcache') !== $profile['version']) {
        fail('Expected only the matching Zend OPcache extension.');
    }
    $allowed = ['Core', 'date', 'hash', 'json', 'pcre', 'random', 'Reflection', 'SPL', 'standard', 'tokenizer', 'Zend OPcache'];
    if (array_diff(get_loaded_extensions(), $allowed) !== []) {
        fail('The process has extensions outside the verification profile.');
    }
    if (!function_exists('token_get_all') || !ini_get('opcache.enable') || !ini_get('opcache.enable_cli')
        || intval(ini_get('opcache.optimization_level'), 0) !== intval($profile['optimization_level'], 0)
        || (int) ini_get('opcache.file_update_protection') !== 0
        || ini_get('opcache.file_cache') !== '' || ini_get('opcache.preload') !== ''
        || (int) ini_get('max_execution_time') !== 0) {
        fail('The interpreter/optimiser settings differ from the verification profile.');
    }
    $status = opcache_get_status(false);
    if ($status === false || ($status['jit']['enabled'] ?? false)
        || ($status['jit']['on'] ?? false)) {
        fail('Expected an active opcode cache without JIT execution.');
    }
}

function instructions(string $dump): array
{
    $result = [];
    foreach (preg_split('/\n\s*\n/', trim($dump)) as $block) {
        $lines = explode("\n", $block);
        $name = array_shift($lines);
        if (!in_array($name, ['$_main:', 'Cameron1729\\Orderly\\between:'], true)
            || isset($result[$name])) {
            fail('Unexpected, missing or duplicate function in the opcode dump.');
        }
        $body = [];
        $optimized = 0;
        foreach ($lines as $line) {
            $line = trim($line);
            if ($line === '; (after optimizer)') {
                $optimized++;
            } elseif (str_starts_with($line, ';')) {
                continue;
            } elseif (preg_match('/^[0-9]{4} \S.*$/D', $line)) {
                $body[] = preg_replace('/[ \t]+/', ' ', $line);
            } else {
                fail('Malformed opcode output or an unexpected compiler diagnostic.');
            }
        }
        if ($optimized !== 1 || $body === []) {
            fail('Missing optimised instructions.');
        }
        $result[$name] = implode("\n", $body) . "\n";
    }
    if (array_keys($result) !== ['$_main:', 'Cameron1729\\Orderly\\between:']
        || $result['$_main:'] !== "0000 RETURN int(1)\n") {
        fail('Unexpected declaration-loading instructions.');
    }
    return $result;
}

try {
    if (!(($argc === 3 && $argv[1] === 'runtime') || ($argc === 5 && $argv[1] === 'dump'))) {
        fail('Expected runtime <profile> or dump <profile> <dump> <expected>.');
    }
    $profile = json_decode(file_get_contents($argv[2]), true, 512, JSON_THROW_ON_ERROR);
    verifyRuntime($profile);
    if ($argv[1] === 'runtime') {
        printf("PHP %s; %s %s; %d-bit %s NTS; OPcache %s; optimiser %s; JIT disabled.\n",
            PHP_VERSION, PHP_OS_FAMILY, php_uname('m'), PHP_INT_SIZE * 8, PHP_SAPI,
            phpversion('Zend OPcache'), $profile['optimization_level']);
    } elseif ($argv[1] === 'dump' && $argc === 5) {
        $actual = instructions(file_get_contents($argv[3]))['Cameron1729\\Orderly\\between:'];
        if ($actual !== file_get_contents($argv[4])) {
            fail('The complete instruction sequence differs from the proved program.');
        }
        echo $actual;
    } else {
        fail('Expected runtime <profile> or dump <profile> <dump> <expected>.');
    }
} catch (Throwable $error) {
    fail($error->getMessage());
}
