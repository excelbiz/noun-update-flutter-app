# Premium companion extension — v0.7 wallet checkout

## Implemented
- One unchanged default theme and ten named Premium skins, each with light/dark variants. Shared components, no duplicated app screens.
- Premium skin artwork now includes the reference-inspired background imagery, overlays, gradients, texture and dimensional resource-card treatment while preserving readable foreground surfaces.
- Free skin previews; applying a Premium skin requires the authenticated preference endpoint to validate a current server entitlement.
- Account-specific preferred skin, restored after server verification; expiry falls back to default while preserving preference. Offline verification failure falls back to free access. No locally stored Premium boolean grants access.
- Server plans with integer minor-unit prices, UTC promotion windows, original price and promotional display. No mobile price constants.
- Premium wallet checkout is implemented against the existing central wallet. The server rechecks the live plan, promotion, entitlement and NGN wallet balance before debit; it locks the wallet row, writes an idempotent central order and ledger debit, activates the subscription in the same database transaction, and rolls everything back on failure.
- Purchase retry keys are retained on-device until the server gives a definitive no-debit response or confirms success, reducing duplicate purchases after interrupted responses. Successful retries return the original purchase instead of debiting again.
- New subscriptions and renewals are separate administrator switches and remain OFF by default after migration. Existing free educational features are never moved behind Premium.
- Birthday month/day, opt-out and removal, free birthday greeting and share card.
- Daily Nigerian-date motivation selection, same-day offline cache, free server-saved favourites, PNG cards shared through the native social sharing menu.
- Website administrator page for Premium master enablement, wallet purchase/renewal switches, plan price, promotion timing, quote editing/scheduling, complimentary access and expiry, with audit records. Access requires the central login plus an explicit server-side account ID allowlist.

## Integration files
- `backend/sql/companion.sql`: additive migration in the central account database. Its `new_subscriptions_enabled` and `renewals_enabled` defaults remain `0`.
- `backend/public_html/nu-mobile/companion/service.php`: preference, entitlement, plan, quote and transactional Premium wallet-purchase service.
- `backend/public_html/api/central/index.php`: routes using existing central authentication and the established account-to-wallet link. `POST /premium/purchase` requires an idempotency key and never accepts a client-supplied wallet account or debit amount as authority.
- `backend/public_html/admin/mobile/index.php`: protected website management UI, including explicit switches for opening new Premium purchases and renewals.
- `lib/screens/personalisation.dart`: exact-price confirmation, central-wallet purchase, retry-safe idempotency key handling and access recovery.
- Set server environment `NU_MOBILE_ADMIN_ACCOUNT_IDS` to verified central account IDs, comma-separated. It grants no access when unset. This is separate from legacy administrator IDs.

Requires existing `includes/central-auth.php`, `central-wallet-bootstrap.php`, `central-wallet-auth.php`, the central wallet tables and their existing database configuration. No passwords or provider keys belong in the APK.

## Deployment
Back up the central database. Apply the additive SQL, upload the files to corresponding paths and configure the administrator allowlist. Sign in using the existing website account, then visit `/admin/mobile/`. The service imports the current website quote from `public_html/power-space/quote.json`. Scheduled/featured admin quotes take priority for the next daily selection. No fixture quotes are installed.

The initial three plans are NGN 1000/month, NGN 3500/semester and NGN 6000/year; semester initially means six calendar months in this migration and can be edited by the admin. The launch offer is disabled until the admin sets price and start/end dates.

After deploying v0.7, leave **Allow new Premium purchases** and **Allow Premium renewals/extensions** OFF while validating with a controlled account. Check: correct debit, insufficient balance, changed-price rejection, duplicate retry, entitlement activation, wallet ledger entry, expiry extension and the app's “Check Premium access” action. Only then open the required switch from the website admin page.

## Not complete
- This code has NOT been deployed to nounupdate.com by this repository change. Live hosting must still receive the matching backend files/migration before sales can be enabled.
- Advanced Mock/POP analytics, report downloads, alternate launcher icons, profile cosmetics, seasonal assets and milestone celebrations remain pending and stay disabled in the seeded feature configuration.
- No ad SDK currently exists in this app. `PremiumService` exposes suppression for future ad inventory integration; this release does not introduce ads.
- Appearance mode/font remain local; selected skin and birthday are server preferences. Full cross-device student profile/course sync remains pending.
- Provider-specific reconciliation for a payment made outside the central wallet is not part of this purchase route. Existing central-wallet funding/recovery remains the source of wallet credit.

## Validation
Backend CI covers promotion expiry, account isolation, birthday validation/removal, free-vs-Premium skin authorisation, subscription expiry, daily quote stability, disabled-sale no-debit behaviour, changed-price no-debit behaviour, insufficient balance, exact wallet debit, entitlement activation, successful idempotent retry and renewal-from-existing-expiry. Flutter checks cover palette/default preservation, entitlement fallback, skin/share-card screenshot previews, light/dark navigation, narrow layouts and increased text scale.

A successful build is evidence that the repository version compiles and its automated checks pass; it is not evidence that nounupdate.com has already been deployed or that live payments have been enabled.
