-- Run in the EXISTING Course Summary database. No balances/accounts are copied.
-- Existing summary_users, summary_transactions and user_summaries are retained.
CREATE TABLE IF NOT EXISTS nu_app_sessions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 access_hash CHAR(64) NOT NULL UNIQUE,
 refresh_hash CHAR(64) NOT NULL UNIQUE,
 password_fingerprint CHAR(64) NOT NULL,
 access_expires DATETIME NOT NULL,
 refresh_expires DATETIME NOT NULL,
 revoked TINYINT NOT NULL DEFAULT 0,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 KEY user_sessions(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_app_rate_limits (
 bucket CHAR(64) PRIMARY KEY,
 hits INT UNSIGNED NOT NULL,
 expires_at DATETIME NOT NULL,
 KEY expiry(expires_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS nu_app_quotes (
 id CHAR(32) PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 items_json LONGTEXT NOT NULL,
 subtotal_kobo BIGINT UNSIGNED NOT NULL,
 fee_kobo BIGINT UNSIGNED NOT NULL,
 total_kobo BIGINT UNSIGNED NOT NULL,
 expires_at DATETIME NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 KEY user_quotes(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_app_orders (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 quote_id CHAR(32) NOT NULL UNIQUE,
 request_key VARCHAR(96) NOT NULL,
 reference VARCHAR(100) NOT NULL UNIQUE,
 subtotal_kobo BIGINT UNSIGNED NOT NULL,
 fee_kobo BIGINT UNSIGNED NOT NULL,
 total_kobo BIGINT UNSIGNED NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY user_request(user_id, request_key), KEY user_orders(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_app_order_items (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 order_id BIGINT UNSIGNED NOT NULL,
 file_id BIGINT UNSIGNED NOT NULL,
 name VARCHAR(500) NOT NULL,
 file_path TEXT NOT NULL,
 price_kobo BIGINT UNSIGNED NOT NULL,
 UNIQUE KEY order_file(order_id,file_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_app_downloads (
 token_hash CHAR(64) PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 item_id BIGINT UNSIGNED NOT NULL,
 expires_at DATETIME NOT NULL,
 used_at DATETIME NULL,
 KEY expiry(expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
