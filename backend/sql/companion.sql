-- Additive central-account extension. Run against the database used by nu_auth_pdo().
-- Never changes existing accounts, wallet balances, payment tables or educational access.
CREATE TABLE IF NOT EXISTS nu_mobile_configuration (
 id TINYINT UNSIGNED PRIMARY KEY,
 premium_enabled TINYINT NOT NULL DEFAULT 1,
 new_subscriptions_enabled TINYINT NOT NULL DEFAULT 0,
 renewals_enabled TINYINT NOT NULL DEFAULT 0,
 features_json JSON NOT NULL,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO nu_mobile_configuration(id,features_json) VALUES(1,'{"ad_free":true,"premium_skins":true,"mock_analytics":true,"pop_analytics":true,"reports":true,"custom_icons":false,"profile_frames":false,"seasonal_skins":false,"milestone_celebrations":false}');
-- Re-running this additive migration enables only implemented Premium benefits.
-- It does not open sales, change balances or grant Premium access.
UPDATE nu_mobile_configuration SET features_json=JSON_SET(features_json,'$.mock_analytics',CAST('true' AS JSON),'$.pop_analytics',CAST('true' AS JSON),'$.reports',CAST('true' AS JSON)) WHERE id=1;
CREATE TABLE IF NOT EXISTS nu_mobile_premium_plans (
 id VARCHAR(50) PRIMARY KEY, name VARCHAR(100) NOT NULL, enabled TINYINT NOT NULL DEFAULT 1,
 currency CHAR(3) NOT NULL DEFAULT 'NGN', regular_price_minor BIGINT UNSIGNED NOT NULL,
 duration_months INT UNSIGNED NOT NULL, billing_period VARCHAR(50) NOT NULL,
 badge VARCHAR(100) NULL, sort_order INT NOT NULL DEFAULT 0,
 promo_enabled TINYINT NOT NULL DEFAULT 0, promo_price_minor BIGINT UNSIGNED NULL,
 promo_starts_at DATETIME NULL, promo_ends_at DATETIME NULL,
 promo_name VARCHAR(100) NULL, promo_text VARCHAR(250) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO nu_mobile_premium_plans(id,name,regular_price_minor,duration_months,billing_period,badge,sort_order) VALUES
 ('monthly','Monthly',100000,1,'month',NULL,10),
 ('semester','Semester',350000,6,'semester','MOST POPULAR',20),
 ('annual','Annual',600000,12,'year','BEST SAVINGS',30);
CREATE TABLE IF NOT EXISTS nu_mobile_premium_subscriptions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, account_id BIGINT UNSIGNED NOT NULL,
 plan_id VARCHAR(50) NOT NULL, status VARCHAR(30) NOT NULL,
 started_at DATETIME NOT NULL, expires_at DATETIME NOT NULL,
 regular_price_minor BIGINT UNSIGNED NOT NULL, amount_paid_minor BIGINT UNSIGNED NOT NULL,
 currency CHAR(3) NOT NULL DEFAULT 'NGN', payment_provider VARCHAR(40) NULL,
 payment_reference VARCHAR(191) NULL, promotion_id VARCHAR(100) NULL,
 auto_renew TINYINT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY provider_reference(payment_provider,payment_reference),
 KEY account_access(account_id,status,expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_mobile_preferences (
 account_id BIGINT UNSIGNED PRIMARY KEY,
 preferred_skin VARCHAR(50) NOT NULL DEFAULT 'defaultNoun',
 birthday_month TINYINT UNSIGNED NULL, birthday_day TINYINT UNSIGNED NULL,
 birthday_celebration_enabled TINYINT NOT NULL DEFAULT 1,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_mobile_motivation (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, source_hash CHAR(64) NULL UNIQUE, quote TEXT NOT NULL,
 author VARCHAR(150) NOT NULL DEFAULT 'NOUN Update', category VARCHAR(50) NOT NULL DEFAULT 'general',
 active TINYINT NOT NULL DEFAULT 1, featured TINYINT NOT NULL DEFAULT 0,
 schedule_date DATE NULL, starts_at DATETIME NULL, ends_at DATETIME NULL,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_mobile_daily_motivation (
 quote_date DATE PRIMARY KEY, quote_id BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_mobile_saved_motivation (
 account_id BIGINT UNSIGNED NOT NULL, quote_id BIGINT UNSIGNED NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(account_id,quote_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS nu_mobile_admin_audit (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, admin_id VARCHAR(100) NOT NULL,
 account_id BIGINT UNSIGNED NULL, action VARCHAR(80) NOT NULL,
 old_value JSON NULL,new_value JSON NULL,reason VARCHAR(500) NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
