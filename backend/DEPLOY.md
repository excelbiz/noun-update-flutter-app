# NOUN Update app API and central wallet

This package connects the existing Flutter app to Power Space content and the existing Course Summary wallet. **Exam Summary and Course Summary remain separate services. Quizly is excluded.**

## What is connected

- Power Space news (`news_upload`), guides (`guides_upload`), scholarships (`scholarship_upload`), careers and blog feeds. Publishing/editing/deleting a row changes what the app reads on refresh; no duplicated posts or second admin workflow.
- Course Summary remains in `/course/summary` with its existing generation, pricing and access rules.
- The app and website Exam Summary checkout spend the **existing `summary_users.balance`**, with the existing account password and transaction ledger. Existing Course Summary balances need no copying or migration.
- Exam Summary catalogue reads the existing `files` table. New wallet orders and their file snapshots are recorded in `nu_app_orders` and `nu_app_order_items` in the wallet database. Downloads require ownership and short-lived single-use tickets.
- Native article reading, account login, wallet funding/status, Exam Summary selection, order confirmation and downloads. Other tools open their website pages through labelled Website links.
- 78 directory entries, including currently unavailable entries labelled Coming soon. Native sculpted icons and branding generated from `/images/logo.webp`.

## Before upload

1. Back up the affected PHP files and databases.
2. Rotate the database password and Paystack key exposed in the pasted code. Update the existing server configuration and legacy scripts with the new values; never commit them.
3. Use PHP **8.2+**, HTTPS, PDO MySQL, MySQLi, mbstring and cURL.
4. Keep the existing `/course/` service, including `config.php`, `paystack.php`, `paystack_webhook.php`, its protected `.noun-summary.env`, and its working wallet setup.
5. Identify the database used by Power Space and the `files` catalogue. It may be the same as, or different from, the Course Summary database.

## Install in this order

1. In phpMyAdmin select the **existing Course Summary database**, then import `sql/install.sql`. It creates only new `nu_app_*` tables. It does not change existing balances, accounts or orders. No ALTER or destructive migration runs automatically.
2. Upload `public_html/nu-mobile/`, `public_html/api/v1/`, the new `public_html/course/central-*.php` files, `course/exam-checkout.php` and `course/central-wallet.css`. Upload `central-wallet.php` at the site root. **Preserve your other api/ files and course/ files.**
3. If Power Space uses a different database, copy `nu-mobile/config.example.php` to `nu-mobile/config.local.php` and set the content database values there. `nu-mobile/.htaccess` denies HTTP access to this entire directory. For Nginx, add the equivalent deny rule. Wallet settings must match the existing Course Summary database.
4. Keep the **same existing Paystack webhook** at `https://nounupdate.com/course/paystack_webhook.php`. App top-ups use the existing NUW references, payment intents and unique credit receipts, so the existing signed webhook handles both app and web funding. Do not replace the merchant-wide webhook if other integrations already use a dispatcher; retain that dispatcher and route NUW references to the existing course handler.
5. Visit `https://nounupdate.com/api/v1/health`, `/api/v1/services`, `/api/v1/posts/news`, and `/api/v1/exam-summaries`. Health should return `data.status = ok`. A successful `/services` response alone does not prove the database is ready. If rewrites are unavailable, `api/v1/index.php?route=/health` is supported; configure equivalent rewrites before releasing the app.
6. Where terminal access exists, run `php preflight.php /absolute/path/to/public_html`. This checks InnoDB and the table/column mappings without exposing credentials.
7. Test with Paystack test credentials and a test account first: login, top-up, repeat callback, Course Summary balance, Exam Summary quote, purchase, download and refresh in the app. Do not switch an active production account between test/live keys while live payments are in flight; use a staging copy for this check.
8. **Only after those checks pass**, upload the supplied root `cart.php` and `paystack.php` replacements. They preserve the old cart and route new Exam Summary checkout to the central wallet. Keep old `callback.php` temporarily available for already-in-flight legacy transactions; new checkout no longer starts that legacy payment path.
9. Build/install the APK from the GitHub PR. No APK rebuild is needed for later website posts, prices or API service-directory changes.

## Existing balances and purchases

The shared wallet deliberately reuses Course Summary's account and balance. It does not create a second money ledger or add together unrelated accounts based only on matching emails. Any other existing wallets (Study Hub, mock exams, AI tools, etc.) are **not automatically merged**. Those systems need verified account linking and service-specific charging adapters after their backend is available. Their pages remain accessible in this app release.

Old Exam Summary email orders keep their current download links. They are not automatically imported into an account: the uploaded legacy My Account page accepts an email without verifying ownership. Importing those orders into mobile access requires ownership verification. New central-wallet orders are available in the app and `/course/central-wallet.php`.

The existing `file_storage` files may still have public URLs used by old emailed purchases. The new download API checks ownership, but cannot revoke those historical public URLs. Move paid assets outside the web root only with an explicit migration plan that preserves legitimate old access.

## Behaviour and limits

- Existing Course Summary web funding and generation use the same balance. Exam Summary wallet checkout retains the supplied 1.5% service charge, shown before confirmation. Configure `exam_fee_basis_points` to change it.
- Prices and paths are snapshotted in a 10-minute quote. The confirmed quote price is honoured for that period. Repeat requests for the same quote cannot charge again. Different intentional orders are separate purchases.
- Payments are credited only by the existing verified server payment handler. The app never supplies a balance or a successful payment flag.
- Local paid files must exist under the configured download roots; missing files and remote/unmapped file paths fail before debit.
- All wallet/order writes require InnoDB. If old tables are MyISAM, preflight refuses. Use the existing reviewed wallet upgrade procedure after backup; no silent conversion.
- App tokens expire after 15 minutes; refresh tokens rotate and last up to 30 days. Password changes invalidate them. Signing out revokes that device session. Other website tools keep their own login sessions; complete cross-service SSO is not claimed.
- Existing OneSignal publishing remains unchanged. Native push delivery still needs mobile Firebase/APNs setup and notification handling; content feeds work without push.
- Calendar API delegates to your existing `academic-calendar-core/calendar.php`; that file was not uploaded but is expected on the live site.
- GitHub builds are installable **preview APKs** using the generated runner's debug signing key in release mode. Production updates need a stable private release keystore/signing setup before Play Store publication. iOS store signing is separate.

## Rollback

Restore the original `cart.php` and `paystack.php` to resume legacy checkout. Remove the new app routes from navigation if needed. **Do not restore an old balance backup over live transactions or delete new wallet orders.** The old Course Summary code already understands the same balance, so no reverse balance migration is required.

## Retention

Run a daily CLI cleanup of expired `nu_app_downloads`, expired/revoked `nu_app_sessions`, expired `nu_app_rate_limits`, and unpurchased quotes older than seven days. Keep orders, ledger rows and payment receipts for accounting. Never delete a quote referenced by `nu_app_orders`.
