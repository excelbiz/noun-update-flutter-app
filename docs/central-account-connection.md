# Central account connection: first stage

This change is a sign-in and read-only wallet bridge. It is not a full payment release.

Upload backend/public_html/api/central/index.php to public_html/api/central/index.php on the same host as the existing includes/central-auth.php and includes/central-wallet-bootstrap.php. The bridge uses those installed helpers and their database; it contains no credentials and creates no tables.

The app routes account requests to /api/central/index.php?route=... and public resources to /api/v1. Both APIs must be deployed for the full app to work. HTTPS is required. Preserve the Authorization header in the hosting configuration.

Implemented: existing central account sign-in, hashed website session validation, explicit account-to-wallet ownership, balance, latest 50 ledger entries and sign-out. The website's login rate limits remain active. API cookies are ignored; clients use bearer authentication and a stable User-Agent. Tokens are stored under new secure-storage keys so old Course Summary tokens cannot be reused. No automatic wallet linking by matching email is attempted.

Not implemented here: registration, password reset, profile writes, funding initialization, checkout, purchases, refunds or study-state synchronisation. These central routes return an unavailable response; they must not fall back to legacy identity/balance operations. This release requires an existing central account. Session expiration requires signing in again.

Before deployment, test with a staging central account: successful/incorrect login, expired/revoked session, missing wallet link, correct balance/history, ownership isolation and logout. Never use real customer records in repository fixtures. The PHP bridge has not yet been exercised against the live database.

Funding remains gated pending integration of idempotent requests, gateway checkout navigation, verified receipt polling, central database selection in webhooks, and payment status race fixes. Do not enable funding based on a checkout return URL alone.
