<?php
// Optional: copy to config.local.php INSIDE this protected directory.
// Wallet credentials default to the EXISTING course/.noun-summary.env settings.
// Never point the wallet connection at a new/empty database.
return [
    'site_url' => 'https://nounupdate.com',
    'content_db' => [
        'host' => getenv('NU_CONTENT_DB_HOST') ?: getenv('DB_HOST'),
        'name' => getenv('NU_CONTENT_DB_NAME') ?: getenv('DB_NAME'),
        'user' => getenv('NU_CONTENT_DB_USER') ?: getenv('DB_USER'),
        'pass' => getenv('NU_CONTENT_DB_PASS') ?: getenv('DB_PASS'),
    ],
    // Retains the existing Exam Summary checkout's 1.5% service charge.
    'exam_fee_basis_points' => 150,
    // Local purchased files may ONLY be streamed from these directories.
    'download_roots' => [dirname(__DIR__) . '/file_storage'],
];
