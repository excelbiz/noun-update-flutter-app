<?php
declare(strict_types=1);
function env_bool(string $key, bool $default = false): bool
{
    $value = env_value($key);

    if ($value === null) {
        return $default;
    }

    return filter_var($value, FILTER_VALIDATE_BOOL, FILTER_NULL_ON_FAILURE) ?? $default;
}

function required_env(string $key): string
{
    $value = env_value($key);

    if ($value === null || trim($value) === '') {
        throw new RuntimeException('Missing required environment setting: ' . $key);
    }

    return trim($value);
}

function create_database_connection(): PDO
{
    $dbHost = required_env('DB_HOST');
    $dbName = required_env('DB_NAME');
    $dbUser = required_env('DB_USER');
    $dbPass = required_env('DB_PASS');

    return new PDO(
        "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4",
        $dbUser,
        $dbPass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_STRINGIFY_FETCHES => false,
        ]
    );
}

/**
 * Long AI requests can outlive a shared host's MySQL wait_timeout. Always use
 * this helper after a remote call before attempting to save its result.
 */
function ensure_database_connection(PDO $connection): PDO
{
    try {
        $connection->query('SELECT 1')->fetchColumn();
        return $connection;
    } catch (Throwable $e) {
        error_log('NOUN summary database connection was refreshed after an idle timeout.');
        return create_database_connection();
    }
}
