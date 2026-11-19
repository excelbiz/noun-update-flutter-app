# Green Glass Lite development branch

This is the first implementation increment. It removes the browser and embedded
NOUN Update website fallback and establishes one live Flutter theme in production.
It is not yet a release candidate: incomplete services remain visible in the
catalogue with a native availability message while their adapters are built.

## App changes

- Green Glass Lite palette, lightweight gradient surfaces, fields, navigation,
  dialogs and page headers. Native app uses the same layout in both colour modes.
- Automatic appearance is light 07:00–18:59 and dark 19:00–06:59 in device time.
  Re-evaluate on resume and at local minute boundaries. Existing manual settings
  and text size/font preferences remain supported.
- Every service is resolved by ID for bundled and server directories. Website
  paths/URLs in service rows are never used for navigation. A new server ID
  does not automatically create a native service.
- Course Summary and Exam Summary continue to use separate native flows.
- Study Hub provides native course, notes, bookmark and timer routes and a
  locally saved revision checklist. AI, webinar and other Study Hub functions
  remain to be integrated.
- Public course-material PDFs can be downloaded to app-private storage, reopened
  offline and removed from Downloads. The reader preserves zoom and adds page
  controls. Paid ticket URLs are excluded from the offline store.
- A student can explicitly save the current verified personal timetable on the
  device. Offline copies are account/course-set scoped and marked with their
  save date; the offline view does not call old entries upcoming. Faculty
  batch mapping and timetable variants remain outstanding.
- The accessible native information reader displays approved structured copy.
  Provision the content below before publishing legal/help pages.
- Existing payment and entitlement endpoints are unchanged. The sole retained
  WebView is the existing Paystack provider authorisation view; it blocks
  NOUN Update page destinations and returns to server-side verification.
  This is distinct from website tool pages. Multi-gateway funding and
  verification still need the hosted central service adapters.
- Premium entitlements and account data remain server authoritative. Old skin
  preferences are retained as data, but do not select the production theme.
- Quizly is not integrated.

See [feature parity](green-glass-parity.md) for the entire bundled catalogue and
runtime policy. Source and previous designs remain on their original branches.

## PHP setup

Add the `/information/{id}` route from `backend/public_html/api/v1/index.php`
and `backend/public_html/nu-mobile/information.php` to a staging server after
comparing the hosted router. Do not overwrite an independently updated router.
No SQL migration is required for this change.

In the existing protected `nu-mobile/config.local.php` set
`native_information_file` to an absolute path outside the public web root.
Use the actual approved text. The backend never scrapes website HTML and does
not serve arbitrary files. Example schema (illustrative text, not a policy):

```json
{
  "privacy-policy": {
    "title": "Privacy Policy",
    "updated_at": "YYYY-MM-DD",
    "sections": [
      {"heading": "Scope", "text": "Replace this with the approved policy text."}
    ]
  }
}
```

Populate the allowed IDs in `information.php` as appropriate.
An unconfigured page returns a clear JSON service-unavailable response.

## Build and checks

Use Flutter 3.50 (as validated on the base branch) and Java 21 for Android CI.
Run `flutter pub get`, `flutter analyze --no-fatal-infos`, and `flutter test`.
The Android workflow generates the runner, refreshes the official logo,
applies splash/icon assets, builds the APK and verifies its signature.
The redesign branch produces a standalone test-signed APK for review.
Use the workflow's APK and screenshots artifacts from the corresponding commit.

For a local build, run `flutter create --platforms=android,ios --org com.nounupdate --project-name noun_update_student_app .` from the repository.
Remove the generated counter-app test (`test/widget_test.dart`) if present.
Run `python tools/prepare_brand_assets.py` (Pillow required), `flutter pub get`,
`dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
Set Android Internet permission as in the workflow. Then use
`flutter build apk --release --target-platform android-arm,android-arm64`.
On macOS with Xcode, configure your own iOS bundle ID, development team,
provisioning and any enabled notification capabilities. Run
`flutter build ios --release --no-codesign` for a compile check, then
`flutter build ipa --release` using your distribution credentials.
An iOS build and physical-device test are separate verification gates.

## Next integration inputs

Use the current hosted mobile routers and the deployed service APIs or PHP
source/contracts for Mock e-Exam attempts and question bank, PAS, result
extraction, the latest authoritative faculty batch mapping, the order/checkout
adapters and the relevant published legal copy. Do not put credentials or
gateway keys in the mobile source. Do not route unimplemented functions to
the website or fabricate sample transactions, exam scores or batch assignments.
