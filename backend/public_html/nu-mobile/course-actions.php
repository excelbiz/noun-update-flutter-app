<?php
declare(strict_types=1);

if(!isset($nuNativeUser,$pdo,$nuConfig)) { http_response_code(404); exit; }
require_once __DIR__.'/course-environment.php';
require_once $nuConfig['root'].'/course/lib/summary_engine.php';

header('Content-Type: application/json; charset=utf-8');

function json_response(array $payload, int $status = 200): never
{
    if($status>=400)throw new NuFailure($status,'SUMMARY_ERROR',(string)($payload['error']??'Summary unavailable.'));
    nu_send($payload,$status);
}

function request_json(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        json_response(['error' => 'Invalid JSON request.'], 400);
    }
    return $data;
}

function require_post_with_csrf(): array
{
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
        json_response(['error' => 'Method not allowed.'], 405);
    }
    return request_json();
}

function require_summary_access(PDO $pdo, int $userId, string $courseCode): void
{
    $stmt = $pdo->prepare(
        'SELECT id FROM user_summaries
         WHERE user_id = ? AND REPLACE(UPPER(course_code), " ", "") = ? LIMIT 1'
    );
    $stmt->execute([$userId, $courseCode]);
    if (!$stmt->fetchColumn()) {
        json_response(['error' => 'Unlock this course before generating its summary.'], 403);
    }
}

function cached_section(PDO $pdo, string $courseCode, string $sourceHash, int $sectionIndex): ?array
{
    $stmt = $pdo->prepare(
        'SELECT summary_json, module_title, unit_title, model, updated_at
         FROM course_summaries_v2
         WHERE course_code = ? AND source_hash = ? AND prompt_version = ? AND section_index = ?
         LIMIT 1'
    );
    $stmt->execute([$courseCode, $sourceHash, SUMMARY_PROMPT_VERSION, $sectionIndex]);
    $row = $stmt->fetch();
    if (!$row || !is_string($row['summary_json'])) {
        return null;
    }
    $summary = json_decode($row['summary_json'], true);
    if (!is_array($summary)) {
        return null;
    }
    return [
        'summary' => $summary,
        'module_title' => $row['module_title'],
        'unit_title' => $row['unit_title'],
        'model' => $row['model'],
        'updated_at' => $row['updated_at'],
    ];
}

function ensure_summary_tracking_tables(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS user_summary_progress (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            course_code VARCHAR(20) NOT NULL,
            source_hash CHAR(64) NOT NULL,
            prompt_version VARCHAR(50) NOT NULL,
            last_revealed_section INT NOT NULL DEFAULT -1,
            completed_sections INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_user_summary_progress
                (user_id, course_code, source_hash, prompt_version),
            KEY index_user_summary_progress_updated (user_id, updated_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
    );

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS summary_token_usage (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            course_code VARCHAR(20) NOT NULL,
            source_hash CHAR(64) NOT NULL,
            prompt_version VARCHAR(50) NOT NULL,
            section_index INT NOT NULL,
            model VARCHAR(80) NOT NULL,
            openai_response_id VARCHAR(100) NULL,
            input_tokens INT NOT NULL DEFAULT 0,
            output_tokens INT NOT NULL DEFAULT 0,
            total_tokens INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_generated_section_usage
                (course_code, source_hash, prompt_version, section_index),
            KEY index_summary_usage_user (user_id, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
    );
}

function user_summary_progress(
    PDO $pdo,
    int $userId,
    string $courseCode,
    string $sourceHash
): int {
    $stmt = $pdo->prepare(
        'SELECT last_revealed_section
         FROM user_summary_progress
         WHERE user_id = ? AND course_code = ? AND source_hash = ? AND prompt_version = ?
         LIMIT 1'
    );
    $stmt->execute([$userId, $courseCode, $sourceHash, SUMMARY_PROMPT_VERSION]);
    $value = $stmt->fetchColumn();
    return $value === false ? -1 : max(-1, (int) $value);
}

function save_user_summary_progress(
    PDO $pdo,
    int $userId,
    string $courseCode,
    string $sourceHash,
    int $sectionIndex
): int {
    $stmt = $pdo->prepare(
        'INSERT INTO user_summary_progress
            (user_id, course_code, source_hash, prompt_version,
             last_revealed_section, completed_sections, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
         ON DUPLICATE KEY UPDATE
            last_revealed_section = GREATEST(last_revealed_section, VALUES(last_revealed_section)),
            completed_sections = GREATEST(completed_sections, VALUES(completed_sections)),
            updated_at = NOW()'
    );
    $stmt->execute([
        $userId,
        $courseCode,
        $sourceHash,
        SUMMARY_PROMPT_VERSION,
        $sectionIndex,
        $sectionIndex + 1,
    ]);
    return user_summary_progress($pdo, $userId, $courseCode, $sourceHash);
}

function save_summary_token_usage(
    PDO $pdo,
    int $userId,
    string $courseCode,
    string $sourceHash,
    int $sectionIndex,
    array $generated
): void {
    $usage = is_array($generated['usage'] ?? null) ? $generated['usage'] : [];
    $stmt = $pdo->prepare(
        'INSERT INTO summary_token_usage
            (user_id, course_code, source_hash, prompt_version, section_index,
             model, openai_response_id, input_tokens, output_tokens, total_tokens, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
         ON DUPLICATE KEY UPDATE id = id'
    );
    $stmt->execute([
        $userId,
        $courseCode,
        $sourceHash,
        SUMMARY_PROMPT_VERSION,
        $sectionIndex,
        (string) ($generated['model'] ?? ''),
        (string) ($generated['response_id'] ?? ''),
        max(0, (int) ($usage['input_tokens'] ?? 0)),
        max(0, (int) ($usage['output_tokens'] ?? 0)),
        max(0, (int) ($usage['total_tokens'] ?? 0)),
    ]);
}

/**
 * Use a short-lived filesystem lock while the AI request runs. A MySQL named
 * lock kept the database connection idle for one to four minutes and caused
 * shared-hosting servers to close it before the generated section was saved.
 * File locks survive that idle period without depending on MySQL wait_timeout.
 *
 * @return resource|false
 */
function acquire_summary_generation_lock(string $key)
{
    $directory = rtrim(sys_get_temp_dir(), '/\\') . DIRECTORY_SEPARATOR . 'noun-summary-locks';
    if (!is_dir($directory) && !mkdir($directory, 0700, true) && !is_dir($directory)) {
        throw new RuntimeException('The summary queue is temporarily unavailable. Please retry.');
    }

    $handle = fopen($directory . DIRECTORY_SEPARATOR . hash('sha256', $key) . '.lock', 'c');
    if ($handle === false) {
        throw new RuntimeException('The summary queue is temporarily unavailable. Please retry.');
    }
    if (!flock($handle, LOCK_EX | LOCK_NB)) {
        fclose($handle);
        return false;
    }

    return $handle;
}

/** @param resource $handle */
function release_summary_generation_lock($handle): void
{
    flock($handle, LOCK_UN);
    fclose($handle);
}

/**
 * If the very first section cannot produce usable study content, reverse the
 * unlock atomically. This prevents a customer paying for a course that never
 * produced even one usable section. Later-section failures keep the permanent
 * entitlement so the customer can resume without another charge.
 */
function refund_unstarted_summary(
    PDO &$pdo,
    int $userId,
    string $courseCode,
    string $sourceHash,
    int $price
): array {
    if ($price <= 0) {
        return ['refunded' => false, 'new_balance' => null];
    }

    $pdo = ensure_database_connection($pdo);
    $reference = 'SUM-REFUND-' . strtoupper(substr(hash(
        'sha256',
        $userId . '|' . $courseCode . '|' . $sourceHash . '|' . SUMMARY_PROMPT_VERSION
    ), 0, 60));

    $pdo->beginTransaction();
    try {
        $progress = user_summary_progress($pdo, $userId, $courseCode, $sourceHash);
        if ($progress >= 0) {
            $pdo->commit();
            return ['refunded' => false, 'new_balance' => null];
        }

        $existingRefund = $pdo->prepare(
            'SELECT id FROM summary_transactions WHERE reference = ? LIMIT 1 FOR UPDATE'
        );
        $existingRefund->execute([$reference]);
        if ($existingRefund->fetchColumn()) {
            $pdo->commit();
            return ['refunded' => false, 'new_balance' => null];
        }

        $access = $pdo->prepare(
            'SELECT id FROM user_summaries
             WHERE user_id = ? AND REPLACE(UPPER(course_code), " ", "") = ? LIMIT 1 FOR UPDATE'
        );
        $access->execute([$userId, $courseCode]);
        if (!$access->fetchColumn()) {
            $pdo->commit();
            return ['refunded' => false, 'new_balance' => null];
        }

        $balanceStmt = $pdo->prepare('SELECT balance FROM summary_users WHERE id = ? LIMIT 1 FOR UPDATE');
        $balanceStmt->execute([$userId]);
        $balance = $balanceStmt->fetchColumn();
        if ($balance === false) {
            throw new RuntimeException('User account not found while reversing the summary charge.');
        }

        $pdo->prepare('UPDATE summary_users SET balance = balance + ? WHERE id = ?')
            ->execute([$price, $userId]);
        $pdo->prepare(
            'DELETE FROM user_summaries
             WHERE user_id = ? AND REPLACE(UPPER(course_code), " ", "") = ?'
        )->execute([$userId, $courseCode]);
        $pdo->prepare(
            'INSERT INTO summary_transactions
             (user_id, amount, type, description, reference)
             VALUES (?, ?, "credit", ?, ?)'
        )->execute([
            $userId,
            $price,
            'Automatic refund: no usable summary generated for ' . $courseCode,
            $reference,
        ]);

        $newBalance = (float) $balance + $price;
        $pdo->commit();
        return ['refunded' => true, 'new_balance' => $newBalance];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

function unlock_course(PDO $pdo, int $userId, string $courseCode, int $price): array
{
    $pdo->beginTransaction();
    try {
        $accessStmt = $pdo->prepare(
            'SELECT id FROM user_summaries
             WHERE user_id = ? AND REPLACE(UPPER(course_code), " ", "") = ? LIMIT 1 FOR UPDATE'
        );
        $accessStmt->execute([$userId, $courseCode]);
        if ($accessStmt->fetchColumn()) {
            $balanceStmt = $pdo->prepare('SELECT balance FROM summary_users WHERE id = ? LIMIT 1');
            $balanceStmt->execute([$userId]);
            $balance = (float) $balanceStmt->fetchColumn();
            $pdo->commit();
            return ['deducted' => false, 'new_balance' => $balance];
        }

        $balanceStmt = $pdo->prepare('SELECT balance FROM summary_users WHERE id = ? LIMIT 1 FOR UPDATE');
        $balanceStmt->execute([$userId]);
        $balanceValue = $balanceStmt->fetchColumn();
        if ($balanceValue === false) {
            throw new RuntimeException('User account not found.');
        }
        $balance = (float) $balanceValue;
        if ($balance < $price) {
            $pdo->rollBack();
            json_response(['error' => 'Insufficient balance. You need ₦' . number_format($price) . '.'], 402);
        }

        $update = $pdo->prepare(
            'UPDATE summary_users SET balance = balance - ? WHERE id = ? AND balance >= ?'
        );
        $update->execute([$price, $userId, $price]);
        if ($update->rowCount() !== 1) {
            throw new RuntimeException('Your wallet could not be updated. Please retry.');
        }

        $pdo->prepare(
            'INSERT INTO user_summaries (user_id, course_code) VALUES (?, ?)'
        )->execute([$userId, $courseCode]);

        $reference = 'SUM-' . strtoupper(bin2hex(random_bytes(10)));
        $pdo->prepare(
            'INSERT INTO summary_transactions
             (user_id, amount, type, description, reference)
             VALUES (?, ?, "debit", ?, ?)'
        )->execute([$userId, $price, 'Unlocked course summary: ' . $courseCode, $reference]);

        $newBalance = $balance - $price;
        $pdo->commit();
        return ['deducted' => true, 'new_balance' => $newBalance];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        // If two tabs attempted the same unlock together, the unique
        // entitlement wins and the losing transaction is rolled back in full.
        if ($e instanceof PDOException && (string) $e->getCode() === '23000') {
            $accessStmt = $pdo->prepare(
                'SELECT id FROM user_summaries
                 WHERE user_id = ? AND REPLACE(UPPER(course_code), " ", "") = ? LIMIT 1'
            );
            $accessStmt->execute([$userId, $courseCode]);
            if ($accessStmt->fetchColumn()) {
                $balanceStmt = $pdo->prepare('SELECT balance FROM summary_users WHERE id = ? LIMIT 1');
                $balanceStmt->execute([$userId]);
                return ['deducted' => false, 'new_balance' => (float) $balanceStmt->fetchColumn()];
            }
        }
        throw $e;
    }
}

$userId=(int)$nuNativeUser['id'];
$action = (string) ($_GET['action'] ?? '');

try {
    if ($action === 'get_courses') {
        $stmt = $pdo->query(
            'SELECT DISTINCT REPLACE(UPPER(course_code), " ", "") AS course_code
             FROM extracted_texts
             WHERE extracted_text IS NOT NULL AND CHAR_LENGTH(extracted_text) > 100
             ORDER BY course_code ASC'
        );
        json_response(['courses' => $stmt->fetchAll(PDO::FETCH_COLUMN)]);
    }

    if ($action === 'check_access') {
        $courseCode = normalise_course_code((string) ($_GET['course'] ?? ''));
        $stmt = $pdo->prepare(
            'SELECT id FROM user_summaries
             WHERE user_id = ? AND REPLACE(UPPER(course_code), " ", "") = ? LIMIT 1'
        );
        $stmt->execute([$userId, $courseCode]);
        json_response([
            'has_access' => (bool) $stmt->fetchColumn(),
            'price' => (int) (env_value('SUMMARY_PRICE', '500') ?? '500'),
        ]);
    }

    if ($action === 'summarize_init') {
        $data = require_post_with_csrf();
        $courseCode = normalise_course_code((string) ($data['course_code'] ?? ''));
        $course = get_course_text($pdo, $courseCode);
        if ($course === null) {
            json_response(['error' => 'No usable course material was found for this course.'], 404);
        }

        $sections = split_course_into_sections($course['text']);
        if ($sections === []) {
            json_response([
                'error' => 'This extracted course file contains only an outline or does not contain enough explained lesson text. Replace it with the complete course material before generating a summary.',
            ], 422);
        }

        ensure_summary_tracking_tables($pdo);

        // Validate the material before touching the student's wallet.
        $price = max(0, (int) (env_value('SUMMARY_PRICE', '500') ?? '500'));
        $purchase = unlock_course($pdo, $userId, $courseCode, $price);

        $sectionMeta = array_map(
            static fn(array $section): array => [
                'index' => $section['index'],
                'module_title' => $section['module_title'],
                'unit_title' => $section['unit_title'],
            ],
            $sections
        );

        $cachedStmt = $pdo->prepare(
            'SELECT section_index FROM course_summaries_v2
             WHERE course_code = ? AND source_hash = ? AND prompt_version = ?'
        );
        $cachedStmt->execute([$courseCode, $course['source_hash'], SUMMARY_PROMPT_VERSION]);
        $cachedIndexes = array_map('intval', $cachedStmt->fetchAll(PDO::FETCH_COLUMN));
        $lastRevealedSection = min(
            count($sections) - 1,
            user_summary_progress($pdo, $userId, $courseCode, $course['source_hash'])
        );
        $nextSectionIndex = $lastRevealedSection + 1 < count($sections)
            ? $lastRevealedSection + 1
            : null;

        json_response([
            'course_code' => $courseCode,
            'source_hash' => $course['source_hash'],
            'total_sections' => count($sections),
            'sections' => $sectionMeta,
            'cached_indexes' => $cachedIndexes,
            'last_revealed_section' => $lastRevealedSection,
            'next_section_index' => $nextSectionIndex,
            'deducted' => $purchase['deducted'],
            'new_balance' => $purchase['new_balance'],
            'prompt_version' => SUMMARY_PROMPT_VERSION,
        ]);
    }

    if ($action === 'summarize_section') {
        $data = require_post_with_csrf();
        $courseCode = normalise_course_code((string) ($data['course_code'] ?? ''));
        $sectionIndex = filter_var($data['section_index'] ?? null, FILTER_VALIDATE_INT);
        if ($sectionIndex === false || $sectionIndex < 0) {
            json_response(['error' => 'Invalid section number.'], 422);
        }
        require_summary_access($pdo, $userId, $courseCode);
        ensure_summary_tracking_tables($pdo);

        $course = get_course_text($pdo, $courseCode);
        if ($course === null) {
            json_response(['error' => 'Course material is no longer available.'], 404);
        }
        $sections = split_course_into_sections($course['text']);
        if (!isset($sections[$sectionIndex])) {
            json_response(['error' => 'That study section does not exist.'], 404);
        }

        $lastRevealedSection = user_summary_progress(
            $pdo,
            $userId,
            $courseCode,
            $course['source_hash']
        );
        if ($sectionIndex > $lastRevealedSection + 1) {
            json_response([
                'error' => 'Generate the next available section before opening a later one.',
                'next_section_index' => $lastRevealedSection + 1,
            ], 409);
        }

        $cached = cached_section($pdo, $courseCode, $course['source_hash'], $sectionIndex);
        if ($cached !== null) {
            $lastRevealedSection = save_user_summary_progress(
                $pdo,
                $userId,
                $courseCode,
                $course['source_hash'],
                $sectionIndex
            );
            json_response([
                'section_index' => $sectionIndex,
                'section' => $cached['summary'],
                'source' => 'cache',
                'token_saved' => true,
                'last_revealed_section' => $lastRevealedSection,
                'next_section_index' => $lastRevealedSection + 1 < count($sections)
                    ? $lastRevealedSection + 1
                    : null,
                'updated_at' => $cached['updated_at'],
            ]);
        }

        // Prevent duplicate AI requests without keeping MySQL idle while the
        // remote generation is running.
        $lockKey = 'nounsum:' . hash(
            'sha256',
            $courseCode . '|' . $course['source_hash'] . '|' . SUMMARY_PROMPT_VERSION . '|' . $sectionIndex
        );
        $lockHandle = acquire_summary_generation_lock($lockKey);
        if ($lockHandle === false) {
            json_response([
                'error' => 'This section is already being prepared. Retrying shortly.',
                'retry_after' => 4,
            ], 409);
        }

        $contentFailure = null;
        $refundResult = ['refunded' => false, 'new_balance' => null];
        try {
            $cached = cached_section($pdo, $courseCode, $course['source_hash'], $sectionIndex);
            if ($cached !== null) {
                $lastRevealedSection = save_user_summary_progress(
                    $pdo,
                    $userId,
                    $courseCode,
                    $course['source_hash'],
                    $sectionIndex
                );
                json_response([
                    'section_index' => $sectionIndex,
                    'section' => $cached['summary'],
                    'source' => 'cache',
                    'token_saved' => true,
                    'last_revealed_section' => $lastRevealedSection,
                    'next_section_index' => $lastRevealedSection + 1 < count($sections)
                        ? $lastRevealedSection + 1
                        : null,
                    'updated_at' => $cached['updated_at'],
                ]);
            }

            $openAiTimeout = max(60, (int) (env_value('OPENAI_TIMEOUT_SECONDS', '240') ?? '240'));
            set_time_limit(max(180, ($openAiTimeout * 2) + 45));
            $generated = call_openai_for_summary($courseCode, $sections[$sectionIndex]);

            // The AI call can exceed the database's shared-hosting idle timeout.
            // Refresh the connection before saving, then re-check the cache in
            // case another worker completed the section while this one waited.
            $pdo = ensure_database_connection($pdo);
            $summaryJson = json_encode(
                $generated['summary'],
                JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE
            );
            if ($summaryJson === false) {
                throw new RuntimeException('The generated summary could not be saved.');
            }

            $save = $pdo->prepare(
                'INSERT INTO course_summaries_v2
                 (course_code, source_hash, prompt_version, section_index, module_title, unit_title,
                  summary_json, model, openai_response_id, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
                 ON DUPLICATE KEY UPDATE
                    module_title = VALUES(module_title),
                    unit_title = VALUES(unit_title),
                    summary_json = VALUES(summary_json),
                    model = VALUES(model),
                    openai_response_id = VALUES(openai_response_id),
                    updated_at = NOW()'
            );
            $save->execute([
                $courseCode,
                $course['source_hash'],
                SUMMARY_PROMPT_VERSION,
                $sectionIndex,
                $sections[$sectionIndex]['module_title'],
                $sections[$sectionIndex]['unit_title'],
                $summaryJson,
                $generated['model'],
                $generated['response_id'],
            ]);

            save_summary_token_usage(
                $pdo,
                $userId,
                $courseCode,
                $course['source_hash'],
                $sectionIndex,
                $generated
            );
            $lastRevealedSection = save_user_summary_progress(
                $pdo,
                $userId,
                $courseCode,
                $course['source_hash'],
                $sectionIndex
            );

            json_response([
                'section_index' => $sectionIndex,
                'section' => $generated['summary'],
                'source' => 'openai',
                'token_saved' => false,
                'last_revealed_section' => $lastRevealedSection,
                'next_section_index' => $lastRevealedSection + 1 < count($sections)
                    ? $lastRevealedSection + 1
                    : null,
            ]);
        } catch (SummaryContentException $e) {
            $contentFailure = $e;
            if ($sectionIndex === 0) {
                $price = max(0, (int) (env_value('SUMMARY_PRICE', '500') ?? '500'));
                $refundResult = refund_unstarted_summary(
                    $pdo,
                    $userId,
                    $courseCode,
                    $course['source_hash'],
                    $price
                );
            }
        } finally {
            release_summary_generation_lock($lockHandle);
        }

        if ($contentFailure instanceof SummaryContentException) {
            error_log(
                'NOUN summary content failure for user ' . $userId . ', ' . $courseCode
                . ', section ' . $sectionIndex . ': ' . $contentFailure->getMessage()
            );
            $message = $refundResult['refunded']
                ? 'This course section could not produce a reliable summary. Your course charge was automatically returned to your wallet. Please contact support so the course material can be corrected.'
                : 'This course section could not produce a reliable summary. Your access remains active and you have not been charged again. Please retry or contact support.';
            json_response([
                'error' => $message,
                'refunded' => (bool) $refundResult['refunded'],
                'new_balance' => $refundResult['new_balance'],
            ], 422);
        }
    }

    json_response(['error' => 'Invalid action.'], 404);
} catch (InvalidArgumentException $e) {
    json_response(['error' => $e->getMessage()], 422);
} catch (Throwable $e) {
    $context = 'action=' . $action . ', user=' . $userId;
    if (isset($courseCode) && is_string($courseCode) && $courseCode !== '') {
        $context .= ', course=' . $courseCode;
    }
    if (isset($sectionIndex) && is_int($sectionIndex)) {
        $context .= ', section=' . $sectionIndex;
    }
    error_log('NOUN summary API error (' . $context . '): ' . $e->getMessage());
    $message = $appDebug ? $e->getMessage() : 'The request could not be completed. Please try again.';
    json_response(['error' => $message], 500);
}