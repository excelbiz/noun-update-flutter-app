<?php
declare(strict_types=1);

/**
 * Paystack wallet funding helpers.
 * config.php must be loaded before this file.
 */

final class PaystackConfigurationException extends RuntimeException
{
}

final class PaystackGatewayException extends RuntimeException
{
}

function paystack_secret_key(): string
{
    $secret = trim((string) (env_value('PAYSTACK_SECRET_KEY', '') ?? ''));

    if ($secret === '') {
        throw new PaystackConfigurationException(
            'Paystack funding is not configured. Add PAYSTACK_SECRET_KEY to .noun-summary.env.'
        );
    }

    if (str_starts_with($secret, 'pk_')) {
        throw new PaystackConfigurationException(
            'PAYSTACK_SECRET_KEY contains a public key. Use the backend secret key beginning sk_test_ or sk_live_.'
        );
    }

    if (!preg_match('/^sk_(?:test|live)_[A-Za-z0-9]+$/', $secret)) {
        throw new PaystackConfigurationException(
            'PAYSTACK_SECRET_KEY is invalid. It must begin with sk_test_ or sk_live_.'
        );
    }

    return $secret;
}

function paystack_public_error(Throwable $error): string
{
    if (
        $error instanceof PaystackConfigurationException
        || $error instanceof PaystackGatewayException
        || $error instanceof InvalidArgumentException
    ) {
        return $error->getMessage();
    }

    if ($error instanceof PDOException) {
        return 'The wallet database setup is incomplete. Run wallet_setup.php, then try again.';
    }

    return 'Payment could not be started. Please try again or contact support.';
}

function paystack_request(string $method, string $path, ?array $payload = null): array
{
    if (!function_exists('curl_init')) {
        throw new PaystackConfigurationException(
            'PHP cURL is not enabled on this hosting account. Enable cURL in your hosting PHP settings.'
        );
    }

    $secret = paystack_secret_key();
    $url = 'https://api.paystack.co' . $path;
    $ch = curl_init($url);

    if ($ch === false) {
        throw new PaystackGatewayException('Could not create a connection to Paystack.');
    }

    $headers = [
        'Accept: application/json',
        'Authorization: Bearer ' . $secret,
        'Content-Type: application/json',
        'Cache-Control: no-cache',
    ];

    $options = [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => strtoupper($method),
        CURLOPT_CONNECTTIMEOUT => 15,
        CURLOPT_TIMEOUT => 45,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ];

    if ($payload !== null) {
        $encoded = json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);

        if ($encoded === false) {
            curl_close($ch);
            throw new RuntimeException('The payment request could not be prepared.');
        }

        $options[CURLOPT_POSTFIELDS] = $encoded;
    }

    curl_setopt_array($ch, $options);

    $raw = curl_exec($ch);
    $curlError = curl_error($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($raw === false || $curlError !== '') {
        error_log('Paystack cURL error: ' . $curlError);
        throw new PaystackGatewayException('Paystack could not be reached from the server. Please try again.');
    }

    $response = json_decode((string) $raw, true);

    if (!is_array($response)) {
        throw new PaystackGatewayException('Paystack returned an unreadable response. Please try again.');
    }

    if ($status < 200 || $status >= 300 || empty($response['status'])) {
        $gatewayMessage = mb_substr((string) ($response['message'] ?? 'Paystack request failed.'), 0, 250);
        error_log('Paystack API error (' . $status . '): ' . $gatewayMessage);

        if ($status === 401 || $status === 403) {
            throw new PaystackConfigurationException(
                'Paystack rejected the secret key. Replace it with the correct active secret key.'
            );
        }

        throw new PaystackGatewayException(
            $gatewayMessage !== ''
                ? 'Paystack: ' . $gatewayMessage
                : 'Paystack could not initialize this payment. Please retry.'
        );
    }

    return $response;
}

function paystack_callback_url(): string
{
    $configured = trim((string) (env_value('NOUN_SUMMARY_PAYSTACK_CALLBACK_URL', '') ?? ''));

    if ($configured === '') {
        throw new PaystackConfigurationException(
            'NOUN_SUMMARY_PAYSTACK_CALLBACK_URL is missing from .noun-summary.env.'
        );
    }

    $parts = parse_url($configured);

    if (!is_array($parts) || ($parts['scheme'] ?? '') !== 'https' || empty($parts['host'])) {
        throw new PaystackConfigurationException(
            'NOUN_SUMMARY_PAYSTACK_CALLBACK_URL must be a full HTTPS URL.'
        );
    }

    return $configured;
}

function paystack_cancel_url(): string
{
    return wallet_url();
}

function wallet_db_table_exists(PDO $pdo, string $table): bool
{
    $stmt = $pdo->prepare(
        'SELECT COUNT(*)
         FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?'
    );
    $stmt->execute([$table]);
    return (int) $stmt->fetchColumn() > 0;
}

function wallet_db_table_engine(PDO $pdo, string $table): ?string
{
    $stmt = $pdo->prepare(
        'SELECT ENGINE
         FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
         LIMIT 1'
    );
    $stmt->execute([$table]);
    $engine = $stmt->fetchColumn();
    return $engine === false ? null : strtoupper((string) $engine);
}

function wallet_assert_transactional_storage(PDO $pdo): void
{
    $required = ['summary_users', 'payment_intents', 'wallet_credit_receipts'];
    $bad = [];

    foreach ($required as $table) {
        if (!wallet_db_table_exists($pdo, $table)) {
            $bad[] = $table . ' (missing)';
            continue;
        }

        $engine = wallet_db_table_engine($pdo, $table);
        if ($engine !== 'INNODB') {
            $bad[] = $table . ' (' . ($engine ?: 'unknown engine') . ')';
        }
    }

    if ($bad !== []) {
        throw new PaystackConfigurationException(
            'Wallet database safety upgrade required. Run wallet_setup.php once. Problem: ' . implode(', ', $bad) . '.'
        );
    }
}

function paystack_configuration_diagnostics(PDO $pdo): array
{
    $checks = [];

    $secret = trim((string) (env_value('PAYSTACK_SECRET_KEY', '') ?? ''));
    $keyReady = preg_match('/^sk_(?:test|live)_[A-Za-z0-9]+$/', $secret) === 1;
    $keyMode = str_starts_with($secret, 'sk_live_')
        ? 'Live'
        : (str_starts_with($secret, 'sk_test_') ? 'Test' : 'Invalid');

    $checks[] = [
        'label' => 'Secret key',
        'ok' => $keyReady,
        'message' => $keyReady ? $keyMode . ' Paystack secret key detected.' : 'Valid Paystack secret key required.',
    ];

    $callback = trim((string) (env_value('NOUN_SUMMARY_PAYSTACK_CALLBACK_URL', '') ?? ''));
    $callbackParts = $callback !== '' ? parse_url($callback) : false;
    $callbackReady = is_array($callbackParts)
        && ($callbackParts['scheme'] ?? '') === 'https'
        && !empty($callbackParts['host']);

    $checks[] = [
        'label' => 'Callback URL',
        'ok' => $callbackReady,
        'message' => $callbackReady ? $callback : 'Set NOUN_SUMMARY_PAYSTACK_CALLBACK_URL.',
    ];

    $webhook = trim((string) (env_value('NOUN_SUMMARY_PAYSTACK_WEBHOOK_URL', '') ?? ''));
    $webhookParts = $webhook !== '' ? parse_url($webhook) : false;
    $webhookReady = is_array($webhookParts)
        && ($webhookParts['scheme'] ?? '') === 'https'
        && !empty($webhookParts['host']);

    $checks[] = [
        'label' => 'Webhook URL',
        'ok' => $webhookReady,
        'message' => $webhookReady ? $webhook : 'Set NOUN_SUMMARY_PAYSTACK_WEBHOOK_URL.',
    ];

    $curlReady = function_exists('curl_init');
    $checks[] = [
        'label' => 'Server cURL',
        'ok' => $curlReady,
        'message' => $curlReady ? 'PHP cURL is available.' : 'Enable PHP cURL on the hosting account.',
    ];

    $schemaReady = false;
    try {
        $column = $pdo->query("SHOW COLUMNS FROM payment_intents LIKE 'customer_email'")->fetch();
        $schemaReady = (bool) $column;
    } catch (Throwable $ignored) {
        $schemaReady = false;
    }

    $checks[] = [
        'label' => 'Payment database',
        'ok' => $schemaReady,
        'message' => $schemaReady ? 'payment_intents is present.' : 'Run wallet_setup.php once.',
    ];

    $summaryEngine = wallet_db_table_engine($pdo, 'summary_users');
    $intentEngine = wallet_db_table_engine($pdo, 'payment_intents');
    $receiptEngine = wallet_db_table_engine($pdo, 'wallet_credit_receipts');
    $transactionSafe = $summaryEngine === 'INNODB' && $intentEngine === 'INNODB' && $receiptEngine === 'INNODB';

    $checks[] = [
        'label' => 'Duplicate-credit protection',
        'ok' => $transactionSafe,
        'message' => $transactionSafe
            ? 'Transactional InnoDB credit protection is active.'
            : 'Run the V4 wallet_setup.php. summary_users=' . ($summaryEngine ?: 'missing')
                . ', payment_intents=' . ($intentEngine ?: 'missing')
                . ', wallet_credit_receipts=' . ($receiptEngine ?: 'missing') . '.',
    ];

    return [
        'ready' => $keyReady && $callbackReady && $curlReady && $schemaReady && $transactionSafe,
        'recommended_ready' => $keyReady && $callbackReady && $webhookReady && $curlReady && $schemaReady && $transactionSafe,
        'mode' => $keyMode,
        'schema_ready' => $schemaReady,
        'transaction_safe' => $transactionSafe,
        'checks' => $checks,
    ];
}

function initialize_wallet_payment(PDO $pdo, array $user, int $amountNaira): string
{
    $userId = (int) ($user['id'] ?? 0);
    $email = strtolower(trim((string) ($user['email'] ?? '')));

    if ($userId < 1 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new InvalidArgumentException('Your account email is not valid for payment.');
    }

    $min = max(100, (int) (env_value('PAYSTACK_MIN_TOPUP', '500') ?? '500'));
    $max = max($min, (int) (env_value('PAYSTACK_MAX_TOPUP', '200000') ?? '200000'));

    if ($amountNaira < $min || $amountNaira > $max) {
        throw new InvalidArgumentException(
            'Enter an amount between ₦' . number_format($min) . ' and ₦' . number_format($max) . '.'
        );
    }

    paystack_secret_key();
    $callbackUrl = paystack_callback_url();

    $reference = 'NUW-' . $userId . '-' . strtoupper(bin2hex(random_bytes(10)));
    $amountKobo = $amountNaira * 100;

    $insert = $pdo->prepare(
        'INSERT INTO payment_intents
         (user_id, customer_email, reference, amount_naira, amount_kobo, currency, status, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, "NGN", "pending", NOW(), NOW())'
    );

    $insert->execute([$userId, $email, $reference, $amountNaira, $amountKobo]);

    try {
        $metadata = json_encode([
            'purpose' => 'NOUN UPDATE Comprehensive Summary wallet funding',
            'user_id' => $userId,
            'wallet_reference' => $reference,
            'cancel_action' => paystack_cancel_url(),
        ], JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);

        if ($metadata === false) {
            throw new RuntimeException('Could not prepare payment metadata.');
        }

        $response = paystack_request('POST', '/transaction/initialize', [
            'email' => $email,
            'amount' => (string) $amountKobo,
            'currency' => 'NGN',
            'reference' => $reference,
            'callback_url' => $callbackUrl,
            'metadata' => $metadata,
        ]);

        $data = is_array($response['data'] ?? null) ? $response['data'] : [];
        $authorizationUrl = trim((string) ($data['authorization_url'] ?? ''));
        $accessCode = trim((string) ($data['access_code'] ?? ''));
        $returnedReference = trim((string) ($data['reference'] ?? ''));

        if ($returnedReference !== '' && !hash_equals($reference, $returnedReference)) {
            throw new PaystackGatewayException('Paystack returned an unexpected transaction reference.');
        }

        $parts = parse_url($authorizationUrl);
        $checkoutHost = is_array($parts) ? strtolower((string) ($parts['host'] ?? '')) : '';

        if (
            !is_array($parts)
            || ($parts['scheme'] ?? '') !== 'https'
            || ($checkoutHost !== 'paystack.com' && !str_ends_with($checkoutHost, '.paystack.com'))
        ) {
            throw new PaystackGatewayException('Paystack did not return a safe checkout address.');
        }

        $update = $pdo->prepare(
            'UPDATE payment_intents
             SET status = "initialized", authorization_url = ?, access_code = ?, updated_at = NOW()
             WHERE reference = ?'
        );

        $update->execute([$authorizationUrl, $accessCode, $reference]);

        return $authorizationUrl;
    } catch (Throwable $e) {
        try {
            $update = $pdo->prepare(
                'UPDATE payment_intents
                 SET status = "initialization_failed", updated_at = NOW()
                 WHERE reference = ?'
            );
            $update->execute([$reference]);
        } catch (Throwable $ignored) {
            // Preserve the original payment exception.
        }

        throw $e;
    }
}

function try_write_legacy_wallet_ledger(PDO $pdo, int $userId, float $amountNaira, string $reference): void
{
    // The Comprehensive Summary site may already have a summary_transactions
    // table from an older version. A schema mismatch here must NEVER roll back
    // a genuine Paystack wallet credit. This write is therefore best-effort.
    try {
        $table = $pdo->query("SHOW TABLES LIKE 'summary_transactions'")->fetchColumn();
        if (!$table) {
            return;
        }

        // Avoid duplicate legacy ledger rows when callback/webhook/recovery repeat.
        try {
            $check = $pdo->prepare(
                'SELECT id FROM summary_transactions WHERE reference = ? LIMIT 1'
            );
            $check->execute([$reference]);
            if ($check->fetch()) {
                return;
            }
        } catch (Throwable $ignored) {
            // Continue with a best-effort insert. Some old schemas may differ.
        }

        $transaction = $pdo->prepare(
            'INSERT INTO summary_transactions
             (user_id, amount, type, description, reference, created_at)
             VALUES (?, ?, "credit", "Wallet top-up (Paystack)", ?, NOW())'
        );
        $transaction->execute([$userId, $amountNaira, $reference]);
    } catch (Throwable $e) {
        // IMPORTANT: the wallet has already been credited at this point.
        // Log the legacy ledger incompatibility without taking value away.
        error_log(
            'Wallet credited but legacy summary_transactions insert failed for '
            . $reference . ': ' . $e->getMessage()
        );
    }
}

function update_payment_intent_gateway_status(PDO $pdo, string $reference, string $status): void
{
    try {
        $safeStatus = mb_substr($status !== '' ? $status : 'pending', 0, 30);
        $stmt = $pdo->prepare(
            'UPDATE payment_intents
             SET status = ?, updated_at = NOW()
             WHERE reference = ? AND status <> "credited"'
        );
        $stmt->execute([$safeStatus, $reference]);
    } catch (Throwable $ignored) {
        // Verification result remains authoritative even if this cosmetic status update fails.
    }
}

function finalize_wallet_payment(PDO $pdo, array $paystackData): array
{
    $reference = trim((string) ($paystackData['reference'] ?? ''));
    $gatewayStatus = strtolower(trim((string) ($paystackData['status'] ?? '')));
    $currency = strtoupper(trim((string) ($paystackData['currency'] ?? '')));
    $amountKobo = (int) ($paystackData['amount'] ?? 0);
    $requestedAmountRaw = $paystackData['requested_amount'] ?? null;
    $requestedAmountKobo = is_numeric($requestedAmountRaw) ? (int) $requestedAmountRaw : 0;
    $gatewayEmail = strtolower(trim((string) ($paystackData['customer']['email'] ?? '')));

    if ($reference === '' || $gatewayStatus !== 'success' || $currency !== 'NGN' || $amountKobo < 1) {
        throw new RuntimeException('The payment has not been confirmed as successful.');
    }

    if (!preg_match('/^NUW-[0-9]+-[A-F0-9]{20}$/', $reference)) {
        throw new RuntimeException('This transaction is not a NOUN Summary wallet payment.');
    }

    // V4 safety requirement. We refuse to touch a wallet balance if the tables
    // cannot participate in one real database transaction. This prevents the
    // old MyISAM/partial-rollback duplicate-credit failure completely.
    wallet_assert_transactional_storage($pdo);

    $pdo->beginTransaction();

    try {
        $intentStmt = $pdo->prepare(
            'SELECT id, user_id, customer_email, amount_naira, amount_kobo, currency, status
             FROM payment_intents
             WHERE reference = ?
             LIMIT 1
             FOR UPDATE'
        );
        $intentStmt->execute([$reference]);
        $intent = $intentStmt->fetch();

        if (!$intent) {
            throw new RuntimeException('This payment does not match a wallet funding request.');
        }

        $userStmt = $pdo->prepare(
            'SELECT id, email, balance
             FROM summary_users
             WHERE id = ?
             LIMIT 1
             FOR UPDATE'
        );
        $userStmt->execute([(int) $intent['user_id']]);
        $user = $userStmt->fetch();

        if (!$user) {
            throw new RuntimeException('The wallet account could not be found.');
        }

        // A dedicated receipt with a UNIQUE reference is the authoritative
        // idempotency guard. Even if a callback, webhook and Recheck all arrive,
        // only one committed receipt can ever exist for this Paystack reference.
        $receiptStmt = $pdo->prepare(
            'SELECT id, amount_naira
             FROM wallet_credit_receipts
             WHERE reference = ?
             LIMIT 1
             FOR UPDATE'
        );
        $receiptStmt->execute([$reference]);
        $receipt = $receiptStmt->fetch();

        if ((string) $intent['status'] === 'credited' || $receipt) {
            // Repair the cosmetic status if an existing V4 receipt is present.
            $repairStatus = $pdo->prepare(
                'UPDATE payment_intents
                 SET status = "credited",
                     paid_at = COALESCE(paid_at, NOW()),
                     updated_at = NOW()
                 WHERE id = ?'
            );
            $repairStatus->execute([(int) $intent['id']]);
            $pdo->commit();

            return [
                'credited' => false,
                'already_credited' => true,
                'user_id' => (int) $user['id'],
                'balance' => (float) $user['balance'],
                'amount' => (float) ($receipt['amount_naira'] ?? $intent['amount_naira']),
                'reference' => $reference,
            ];
        }

        if (strtoupper((string) ($intent['currency'] ?? 'NGN')) !== 'NGN') {
            throw new RuntimeException('The wallet request currency is invalid.');
        }

        $expectedAmountKobo = (int) $intent['amount_kobo'];

        if ($requestedAmountKobo > 0 && $requestedAmountKobo !== $expectedAmountKobo) {
            error_log(
                'Wallet amount mismatch for ' . $reference
                . ': expected=' . $expectedAmountKobo
                . ', requested_amount=' . $requestedAmountKobo
                . ', charged_amount=' . $amountKobo
            );
            throw new RuntimeException('The requested Paystack amount does not match the wallet funding request.');
        }

        if ($amountKobo < $expectedAmountKobo) {
            error_log(
                'Wallet underpayment for ' . $reference
                . ': expected=' . $expectedAmountKobo
                . ', requested_amount=' . ($requestedAmountKobo > 0 ? $requestedAmountKobo : 'missing')
                . ', charged_amount=' . $amountKobo
            );
            throw new RuntimeException('The amount actually paid is less than the requested wallet amount.');
        }

        $expectedEmail = strtolower(trim((string) $intent['customer_email']));
        if ($gatewayEmail !== '' && $expectedEmail !== '' && !hash_equals($expectedEmail, $gatewayEmail)) {
            throw new RuntimeException('The payment email does not match the wallet account.');
        }

        $amountNaira = (float) $intent['amount_naira'];
        if ($amountNaira <= 0 || abs(($amountNaira * 100) - $expectedAmountKobo) > 0.001) {
            throw new RuntimeException('The stored wallet amount is inconsistent with the wallet funding request.');
        }

        $gatewayId = isset($paystackData['id']) ? (string) $paystackData['id'] : null;

        // Insert the unique receipt FIRST inside the same InnoDB transaction.
        // A duplicate reference can never pass this point twice.
        $insertReceipt = $pdo->prepare(
            'INSERT INTO wallet_credit_receipts
             (reference, payment_intent_id, user_id, amount_naira, amount_kobo, paystack_transaction_id, created_at)
             VALUES (?, ?, ?, ?, ?, ?, NOW())'
        );
        $insertReceipt->execute([
            $reference,
            (int) $intent['id'],
            (int) $user['id'],
            $amountNaira,
            $expectedAmountKobo,
            $gatewayId,
        ]);

        // Keep the mandatory payment-intent update deliberately simple. It only
        // touches columns that wallet_setup.php guarantees. Optional gateway
        // metadata is written later and can never cancel the wallet credit.
        $markIntent = $pdo->prepare(
            'UPDATE payment_intents
             SET status = "credited",
                 paid_at = COALESCE(paid_at, NOW()),
                 updated_at = NOW()
             WHERE id = ?'
        );
        $markIntent->execute([(int) $intent['id']]);

        $statusCheck = $pdo->prepare('SELECT status FROM payment_intents WHERE id = ? LIMIT 1');
        $statusCheck->execute([(int) $intent['id']]);
        if ((string) $statusCheck->fetchColumn() !== 'credited') {
            throw new RuntimeException('The payment record could not be marked as credited.');
        }

        $credit = $pdo->prepare(
            'UPDATE summary_users
             SET balance = balance + ?
             WHERE id = ?'
        );
        $credit->execute([$amountNaira, (int) $user['id']]);

        if ($credit->rowCount() !== 1) {
            throw new RuntimeException('The wallet balance could not be updated.');
        }

        $newBalanceStmt = $pdo->prepare('SELECT balance FROM summary_users WHERE id = ? LIMIT 1');
        $newBalanceStmt->execute([(int) $user['id']]);
        $newBalance = (float) $newBalanceStmt->fetchColumn();

        $pdo->commit();

        // Optional metadata must not affect the committed credit.
        try {
            $channel = mb_substr((string) ($paystackData['channel'] ?? ''), 0, 40);
            $gatewayResponse = mb_substr((string) ($paystackData['gateway_response'] ?? ''), 0, 250);
            $optional = $pdo->prepare(
                'UPDATE payment_intents
                 SET paystack_transaction_id = ?, channel = ?, gateway_response = ?, updated_at = NOW()
                 WHERE id = ?'
            );
            $optional->execute([$gatewayId, $channel, $gatewayResponse, (int) $intent['id']]);
        } catch (Throwable $e) {
            error_log('Optional Paystack metadata update failed for ' . $reference . ': ' . $e->getMessage());
        }

        try_write_legacy_wallet_ledger(
            $pdo,
            (int) $user['id'],
            $amountNaira,
            $reference
        );

        return [
            'credited' => true,
            'already_credited' => false,
            'user_id' => (int) $user['id'],
            'balance' => $newBalance,
            'amount' => $amountNaira,
            'reference' => $reference,
        ];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        throw $e;
    }
}

function verify_and_finalize_wallet_payment(PDO $pdo, string $reference, ?int $attempts = null): array
{
    $reference = trim($reference);

    if (!preg_match('/^NUW-[0-9]+-[A-F0-9]{20}$/', $reference)) {
        throw new InvalidArgumentException('The payment reference is invalid.');
    }

    if ($attempts === null) {
        $attempts = (int) (env_value('PAYSTACK_VERIFY_RETRIES', '3') ?? '3');
    }
    $attempts = max(1, min(5, $attempts));

    $lastStatus = 'pending';
    $lastMessage = '';

    for ($try = 1; $try <= $attempts; $try++) {
        $response = paystack_request('GET', '/transaction/verify/' . rawurlencode($reference));
        $data = is_array($response['data'] ?? null) ? $response['data'] : [];
        $lastStatus = strtolower(trim((string) ($data['status'] ?? 'pending')));
        $lastMessage = trim((string) ($data['gateway_response'] ?? $data['message'] ?? ''));

        if ($lastStatus === 'success') {
            return finalize_wallet_payment($pdo, $data);
        }

        update_payment_intent_gateway_status($pdo, $reference, $lastStatus);

        // Final failure states should not be retried during this request.
        if (in_array($lastStatus, ['failed', 'abandoned', 'reversed'], true)) {
            break;
        }

        if ($try < $attempts) {
            sleep(2);
        }
    }

    $detail = $lastStatus !== '' ? ucfirst($lastStatus) : 'Pending';
    if ($lastMessage !== '') {
        $detail .= ' - ' . mb_substr($lastMessage, 0, 120);
    }

    throw new PaystackGatewayException(
        'Paystack has not confirmed this payment as successful yet. Current status: ' . $detail . '.'
    );
}