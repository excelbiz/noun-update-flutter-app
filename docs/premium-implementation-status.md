# Premium companion extension — v0.6 preview

## Implemented
- One unchanged default theme and ten named Premium skin palettes, each with light/dark variants. Shared components, no duplicated app screens.
- Free skin previews; applying a Premium skin requires the authenticated preference endpoint to validate a current server entitlement.
- Account-specific preferred skin, restored after server verification; expiry falls back to default while preserving preference. Offline verification failure falls back to free access. No locally stored Premium boolean grants access.
- Server plans with integer minor-unit prices, UTC promotion windows, original price and promotional display. No mobile price constants.
- Premium page shows only server-enabled benefits; purchases remain disabled in this build.
- Birthday month/day, opt-out and removal, free birthday greeting and share card.
- Daily Nigerian-date motivation selection, same-day offline cache, free server-saved favourites, PNG cards shared through the native social sharing menu.
- Website administrator page for plan price, promotion timing, quote editing/scheduling, complimentary access and expiry, with audit records. Access requires the central login plus an explicit server-side account ID allowlist.

## Integration files
- `backend/sql/companion.sql`: additive migration in the central account database.
- `backend/public_html/nu-mobile/companion/service.php`: preference, entitlement, plan and quote service.
- `backend/public_html/api/central/index.php`: routes using existing central authentication, before wallet-link checks for non-wallet features.
- `backend/public_html/admin/mobile/index.php`: protected website management UI.
- Set server environment `NU_MOBILE_ADMIN_ACCOUNT_IDS` to verified central account IDs, comma-separated. It grants no access when unset. This is separate from legacy administrator IDs.

Requires existing `includes/central-auth.php`, `central-wallet-bootstrap.php`, `central-wallet-auth.php` and their existing database configuration. No passwords or provider keys belong in the APK.

## Deployment
Back up the central database. Apply the additive SQL, upload the files to corresponding paths and configure the administrator allowlist. Sign in using the existing website account, then visit `/admin/mobile/`. The service imports the current website quote from `public_html/power-space/quote.json` (the source confirmed in your uploaded website files). Scheduled/featured admin quotes take priority for the next daily selection. No fixture quotes are installed.

The initial three plans are NGN 1000/month, NGN 3500/semester and NGN 6000/year; semester initially means six calendar months in this migration and can be edited by the admin. The launch offer is disabled until the admin sets price and start/end dates. New paid subscriptions and renewals remain disabled until verified checkout activation is implemented. Do not enable them directly in SQL as a workaround.

## Not complete
- This code has NOT been deployed to nounupdate.com. Live hosting access remains unavailable.
- Current skins are a theme foundation, not yet exact reproductions of all reference artwork, layouts and glass effects.
- The existing file-backed website quote source is mapped; its live hosting path still needs a deployment check.
- Payment recovery currently refreshes entitlement only. Provider reconciliation and Premium wallet purchasing are not implemented. Existing wallet code is unchanged.
- Advanced Mock/POP analytics, report downloads, alternate launcher icons, profile cosmetics, seasonal assets and milestone celebrations remain pending and are disabled in the seeded feature configuration.
- No ad SDK currently exists in this app. PremiumService exposes suppression for future ad inventory integration; this release does not introduce ads.
- Appearance mode/font remain local; selected skin and birthday are server preferences. Full cross-device student profile/course sync remains pending.

## Validation
Backend CI covers promotion expiry, account isolation, birthday validation/removal, free-vs-Premium skin authorisation, subscription expiry and daily quote stability. Flutter checks include palette/default preservation, entitlement fallback and skin/share-card screenshot previews. A successful build is not evidence of live deployment or payment verification.
