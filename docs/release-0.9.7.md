# NOUN Update 0.9.7 review build

This update preserves the 0.9.6 skins and navigation and concentrates on account connection reliability. It is not a declaration that Release 1 or live deployment is complete.

## Changes

- Account and workspace routes use the existing central authentication database directly. Wallet validation is deferred to wallet operations.
- Bootstrap can return profile, workspace and settings during a wallet outage. It returns a null wallet and a warning instead of an invented zero balance.
- Mobile token renewal uses the central API route. Public content failures do not attempt renewal or receive account bearer tokens.
- Delayed renewal cannot restore credentials after logout or erase a newer login. Protected request retries preserve the original idempotency key and body.
- Native sign-in saves credentials through the same injected session store used by the API client.
- Local sign-out works even when server revocation cannot be confirmed. The app reports that distinction and switches to the guest workspace.
- Obsolete bootstrap/workspace responses are discarded after a session change.

## Verification

The Android workflow runs analysis, Flutter regression and screenshot tests, browser theme fixtures, APK builds, signature verification and package metadata checks. The backend workflow runs existing MySQL integration tests plus an isolated HTTP router test for wallet failure and bearer-only authentication.

The HTTP fixture checks routing and response contracts; it does not certify the production central-auth implementation or live payment providers.

## Deployment boundary

The only server file changed by this update is `backend/public_html/api/central/index.php`. There is no new SQL migration and no wallet balance migration.

Before installing that file, compare it with the actual hosted router and back up the hosted copy. Apply the wallet-isolation change to the hosted version if it has additional routes. Do not replace a newer Power Space router with this file wholesale.

This repository's router still does not implement registration, password-reset, token-refresh or provider funding adapters. Moving refresh to the correct central URL does not create server support. Existing login returns an empty refresh token; when no refresh token is available the app requires sign-in again. The recovered Power Space package contains additional routes but is not yet reconciled with the current workspace schema and hosted central-auth contracts.

Required next: obtain the currently hosted `api/central/index.php`, `includes/central-auth.php`, `includes/central-wallet-service.php` and `includes/wallet-funding-service.php` with secrets removed; compare their contracts; merge compatible adapters; deploy and verify using a test account and provider test mode. Keep gateway secrets and database credentials on the server.

The preview APK uses test signing and a version-specific application ID. It can be installed alongside previous previews; those previews do not share local app data. Production release signing and live-host testing remain separate gates.
