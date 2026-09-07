# NOUN Update Student App

This is the first working Flutter foundation for the NOUN Update student operating system. It is a native, API-driven Android/iOS application—not a wrapper around the website.

## Included in this foundation

- Branded five-tab navigation: Home, Explore, Wallet, Saved and Profile.
- Personalised **My NOUN** dashboard with semester progress, next action, weak-course and readiness indicators.
- Unified search across tools, courses and resources.
- Course mini-portals connecting materials, TMA, past questions, summaries, mock tests, AI Tutor and Study Mode.
- Wallet/premium interface with safe server-initiated Paystack integration hooks.
- Alerts centre and OneSignal initialisation hook.
- Local demo repository so every screen works before the production APIs are connected.
- API client with secure bearer-token storage and production fallback behaviour.
- Low-data design: compact screens, no heavy animation, local demo/cache-ready data and graceful offline messaging.
- Transparent NOUN Update brand artwork used in the splash screen, app header and Android launcher icon.

## Run locally

Install Flutter 3.27 or newer, then run:

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter run \
  --dart-define=NOUN_API_BASE_URL=https://nounupdate.com/api/v1 \
  --dart-define=ONESIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
```

`flutter create .` supplies the generated Android/iOS runner folders without replacing `lib/`, `docs/` or this configuration.

## Build an installable Android preview

The GitHub Actions workflow in `.github/workflows/build-android-apk.yml`
generates the Android runner, runs the tests and publishes signed, verified
release-mode APKs. Use `NOUN-Update-Student-App-universal.apk` on any physical
ARM Android phone, or the smaller `NOUN-Update-Student-App-arm64.apk` on most
modern devices. These preview builds enable bundled demo data so the interface
can be tested before the production API is ready.

## Production configuration

Do not place Paystack secret keys, database credentials or private AI keys in the app. The mobile app should call authenticated PHP endpoints on `nounupdate.com`; the server performs payments, AI calls and privileged database work.

Compile-time values:

| Variable | Purpose |
| --- | --- |
| `NOUN_API_BASE_URL` | Versioned PHP API root. Defaults to `https://nounupdate.com/api/v1`. |
| `ONESIGNAL_APP_ID` | Existing NOUN Update OneSignal application ID. Empty by default. |
| `ENABLE_DEMO_FALLBACK` | Use bundled data when the API is not ready. Defaults to `true`. |

## Next integration sequence

1. Implement the endpoints in `docs/api_contract.md` on the existing PHP backend.
2. Add a real authentication gate and issue short-lived access tokens plus rotating refresh tokens.
3. Connect each existing NOUN Update tool to a native API result or an approved authenticated web fallback.
4. Register Android/iOS OneSignal credentials and notification deep links.
5. Configure Paystack funding callbacks and idempotent wallet crediting on the server.
6. Replace the temporary in-app wordmark with the official transparent NOUN Update logo assets.
7. Generate signed Android App Bundle and iOS archive after store identifiers are confirmed.

See `docs/product_blueprint.md` for the full product map.
