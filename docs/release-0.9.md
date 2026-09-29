# NOUN Update 0.9.0 preview — native resource continuity

Extends the latest v0.14 feature handoff on branch codex/mobile-api-central-wallet.
The Android package version advances from 0.8.0+9 to 0.9.0+10.

## Changes
- Individual Course Material and Course Summary bookmarks in the native library
  and reader. These remain free, with local guest storage and account sync.
- Saved material bookmarks resolve current website metadata before opening the
  native study reader. Summary bookmarks open their course directly and never
  purchase access merely by being opened.
- Bookmark updates are serialised per account across controls, preventing delayed
  saves from resurrecting a removed bookmark or replacing a different local item.
- Queued bookmark writes carry an account identity guard. The backend derives
  ownership from central authentication and rejects a mismatched account.
- All ten Premium Home skins show the same verified timetable summary, including
  missing-course and imported-period warnings. No dates are fabricated.
- Birthday and server-controlled daily motivation now appear in every Premium
  Home family. Editorial no longer substitutes a hard-coded motivational quote.
- Existing skin artwork, navigation, authentication and wallet logic are retained.

- Workspace conflicts now pause for an explicit review instead of automatically
  retrying stale data over the newer account copy. Old local lists remain pending.
- Workspace responses serialize empty details as JSON objects so courses-only
  accounts can load successfully.

## Deploy
Deploy both public_html/nu-mobile/saved-resources/service.php and
public_html/nu-mobile/workspace/service.php.
It adds account_id to responses and validates it on new-client writes. Older
clients remain compatible. No new SQL is required beyond the existing
backend/sql/companion.sql. Upload the service before testing account bookmarks.
If the new service is absent, the app preserves local bookmarks and pending writes
instead of accepting an unbound server response.

This repository update is not a live deployment. Keep existing Premium sales
switches at their verified setting; no payment provider configuration was changed.

## Remaining release work
- Complete native API adapters for tools still using the existing website fallback.
- Verify central auth, live wallet gateways and Premium purchase/recovery on hosting.
- Validate workspace conflict resolution with two physical devices before production.
- Alternate launcher icons, seasonal assets and milestone celebrations.
- Exact visual comparison needs the original reference images reattached; older
  chat image paths are unavailable. Current artwork is reference-inspired.

APK is a preview build signed with the workflow's test signing identity, not a
store-release signing key. Automated rendering does not replace physical-device
and live-hosting acceptance tests.
