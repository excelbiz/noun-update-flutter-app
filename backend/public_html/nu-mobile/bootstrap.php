<?php
declare(strict_types=1);

// No user session is trusted by the mobile API. Authentication is by bearer token.
// Read the same environment file as Course Summary without including its HTML
// configuration/error handler or starting a second PHP session.
$nuRoot = dirname(__DIR__);
$nuEnvPaths = [getenv('NOUN_SUMMARY_ENV_FILE') ?: '', $nuRoot . '/course/.noun-summary.env',
    dirname($nuRoot) . '/.noun-summary.env', $nuRoot . '/.noun-summary.env'];
foreach ($nuEnvPaths as $nuEnvPath) {
    if (!$nuEnvPath || !is_readable($nuEnvPath)) continue;
    foreach (file($nuEnvPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$key, $value] = array_map('trim', explode('=', $line, 2));
        if (!preg_match('/^[A-Z_][A-Z0-9_]*$/i', $key) || getenv($key) !== false) continue;
        if (strlen($value) >= 2 && (($value[0] === '"' && substr($value, -1) === '"') ||
            ($value[0] === "'" && substr($value, -1) === "'"))) $value = substr($value, 1, -1);
        putenv($key . '=' . $value);
    }
    break;
}
// Existing course/paystack.php calls env_value(). Keep its established contract.
if (!function_exists('env_value')) {
    function env_value(string $key, ?string $default = null): ?string {
        $value = getenv($key);
        return $value === false ? $default : (string)$value;
    }
}
$nuConfig = [
    'site_url' => 'https://nounupdate.com', 'root' => $nuRoot,
    'wallet_db' => ['host'=>env_value('DB_HOST'), 'name'=>env_value('DB_NAME'),
        'user'=>env_value('DB_USER'), 'pass'=>env_value('DB_PASS')],
    'content_db' => ['host'=>env_value('NU_CONTENT_DB_HOST', env_value('DB_HOST')),
        'name'=>env_value('NU_CONTENT_DB_NAME', env_value('DB_NAME')),
        'user'=>env_value('NU_CONTENT_DB_USER', env_value('DB_USER')),
        'pass'=>env_value('NU_CONTENT_DB_PASS', env_value('DB_PASS'))],
    'exam_fee_basis_points' => 150, 'download_roots' => [$nuRoot . '/file_storage'],
];
if (is_file(__DIR__ . '/config.local.php')) {
    $overrides = require __DIR__ . '/config.local.php';
    if (!is_array($overrides)) throw new RuntimeException('Invalid mobile configuration.');
    $nuConfig = array_replace_recursive($nuConfig, $overrides);
}
require_once __DIR__ . '/core.php';
require_once __DIR__ . '/content.php';

function nu_connect(array $config): PDO {
    foreach (['host','name','user','pass'] as $key) {
        if (!isset($config[$key]) || $config[$key] === '') throw new RuntimeException('Database configuration is incomplete.');
    }
    return new PDO('mysql:host='.$config['host'].';dbname='.$config['name'].';charset=utf8mb4',
        $config['user'], $config['pass'], [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES=>false]);
}
