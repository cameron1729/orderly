<?php

/*
 * SPDX-FileCopyrightText: 2026 Cameron Ball
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

// Small, isolated fixtures. None of the declared infinite-loop functions is called.
$repository = dirname(__DIR__, 3);
$helper = __DIR__;
$work = sys_get_temp_dir() . '/orderly-verifier-' . bin2hex(random_bytes(8));
mkdir($work);
$environment = getenv();
unset($environment['GITHUB_STEP_SUMMARY']);

function run(array $command): array
{
    global $work, $environment;
    $process = proc_open($command, [['pipe', 'r'], ['pipe', 'w'], ['pipe', 'w']], $pipes, $work, $environment);
    if (!is_resource($process)) {
        throw new RuntimeException('Could not start fixture command.');
    }
    fclose($pipes[0]);
    $stdout = stream_get_contents($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    return [proc_close($process), $stdout, $stderr];
}

function check(string $name, array $command, ?string $failure = null): array
{
    [$status, $stdout, $stderr] = run($command);
    if (($failure === null && $status !== 0)
        || ($failure !== null && ($status === 0 || !str_contains($stdout . $stderr, $failure)))) {
        throw new RuntimeException("$name failed (exit $status): $stdout$stderr");
    }
    echo "OK $name\n";
    return [$stdout, $stderr];
}

function copyDirectory(string $source, string $destination): void
{
    mkdir($destination, 0777, true);
    foreach (new DirectoryIterator($source) as $entry) {
        if ($entry->isDot()) {
            continue;
        }
        $target = $destination . '/' . $entry->getFilename();
        if ($entry->isDir()) {
            copyDirectory($entry->getPathname(), $target);
        } else {
            copy($entry->getPathname(), $target);
        }
    }
}

function snapshot(string $source, string $composer): void
{
    global $work;
    file_put_contents($work . '/src/functions.php', $source);
    file_put_contents($work . '/composer.json', $composer);
    foreach ([['git', 'add', 'src', 'composer.json'], ['git', '-c', 'user.name=Cameron Ball',
        '-c', 'user.email=cameron@cameron1729.xyz', '-c', 'commit.gpgsign=false',
        '-c', 'core.hooksPath=/dev/null', 'commit', '--quiet', '--allow-empty', '-m', 'Verifier fixture']] as $command) {
        [$status, $stdout, $stderr] = run($command);
        if ($status !== 0) {
            throw new RuntimeException($stdout . $stderr);
        }
    }
}

try {
    mkdir($work . '/src');
    copyDirectory($helper, $work . '/layers/common/php');
    copy($helper . '/../verify-repository.sh', $work . '/layers/common/verify-repository.sh');
    check('initialise fixture', ['git', 'init', '--quiet', '--initial-branch=main']);
    $source = file_get_contents($repository . '/src/functions.php');
    $composer = file_get_contents($repository . '/composer.json');
    $verify = ['timeout', '15s', 'bash', $work . '/layers/common/verify-repository.sh'];

    snapshot($source, $composer);
    check('intended declaration and complete opcode sequence', $verify);
    snapshot(str_replace('while (true)', "/* still the same loop */\n    while ( true )", $source), $composer);
    check('comments and whitespace', $verify);
    foreach ([
        'effect before loop' => str_replace('while (true)', 'echo "effect"; while (true)', $source),
        'conditional loop' => str_replace('while (true)', 'while ($start > 0)', $source),
        'changed default' => str_replace('$base = 10', '$base = 11', $source),
        'by-reference parameter' => str_replace('int $start', 'int &$start', $source),
        'changed return type' => str_replace(': never', ': array', $source),
        'additional operation' => $source . "\nfunction extra(): void {}\n",
        'old empty body' => str_replace("    while (true) {\n    }\n", '', $source),
    ] as $name => $variant) {
        snapshot($variant, $composer);
        check($name, $verify, 'source does not match');
    }
    snapshot($source, $composer);
    file_put_contents($work . '/src/extra.php', "<?php\n");
    snapshot($source, $composer);
    check('additional committed source file', $verify, 'sole committed source path');
    unlink($work . '/src/extra.php');
    snapshot($source, str_replace('src/functions.php', 'src/other.php', $composer));
    check('changed Composer autoload', $verify, 'Composer does not autoload');
    snapshot($source, $composer);
    file_put_contents($work . '/src/functions.php', "<?php echo 'uncommitted';\n");
    check('checks committed source, not a working-tree experiment', $verify);
    file_put_contents($work . '/src/functions.php', $source);

    $profilePath = $work . '/layers/common/php/profile.json';
    $profileBytes = file_get_contents($profilePath);
    $profile = json_decode($profileBytes, true, 512, JSON_THROW_ON_ERROR);
    $profile['version'] = '0.0.0';
    file_put_contents($profilePath, json_encode($profile));
    check('wrong PHP runtime version', $verify, 'pinned profile');
    file_put_contents($profilePath, $profileBytes);
    $runtimePath = $work . '/layers/common/php/runtime.sh';
    $runtime = file_get_contents($runtimePath);
    file_put_contents($runtimePath, str_replace('-d opcache.enable_cli=1', '-d opcache.enable_cli=0', $runtime));
    check('disabled opcode cache', $verify, 'settings differ');
    file_put_contents($runtimePath, $runtime);

    [$stdout, $dump] = check('compile fixture without calling it', ['bash', '-c',
        'source "$1/runtime.sh"; "${orderly_php[@]}" -d opcache.opt_debug_level=0x20000 "$2"',
        'fixture', $helper, $work . '/src/functions.php']);
    if ($stdout !== '') {
        throw new RuntimeException('Unexpected execution output.');
    }
    $dumpCommand = ['bash', '-c',
        'source "$1/runtime.sh"; "${orderly_php[@]}" "$1/verify-opcodes.php" dump "$1/profile.json" "$2" "$1/expected-opcodes.txt"',
        'fixture', $helper, $work . '/dump.txt'];
    file_put_contents($work . '/dump.txt', $dump);
    check('parse full compiler dump', $dumpCommand);
    foreach ([
        'missing opcode output' => ['', 'missing'],
        'changed jump destination' => [str_replace('0004 JMP 0004', '0004 JMP 0003', $dump), 'differs'],
        'missing argument receipt' => [preg_replace('/^0000 CV0.*\n/m', '', $dump), 'differs'],
        'extra opcode' => [$dump . "0005 ECHO string(\"effect\")\n", 'differs'],
        'duplicate function dump' => [$dump . $dump, 'duplicate'],
        'compiler diagnostic' => ["Warning: fixture\n" . $dump, 'Unexpected'],
        'unoptimised dump' => [str_replace('(after optimizer)', '(before optimizer)', $dump), 'Missing optimised'],
    ] as $name => [$variant, $failure]) {
        file_put_contents($work . '/dump.txt', $variant);
        check($name, $dumpCommand, $failure);
    }
    echo "All opcode-verifier fixtures passed.\n";
} catch (Throwable $error) {
    fwrite(STDERR, $error->getMessage() . "\nFixture retained at $work\n");
    exit(1);
}

// Remove only this test's freshly created, uniquely named fixture directory.
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($work, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST);
foreach ($iterator as $entry) {
    $entry->isDir() ? rmdir($entry->getPathname()) : unlink($entry->getPathname());
}
rmdir($work);
