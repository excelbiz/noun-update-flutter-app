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

require_once __DIR__.'/summary-library.php';

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
} catch (NuFailure $e) {
    throw $e;
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
    $message = 'The request could not be completed. Please try again.';
    json_response(['error' => $message], 500);
}