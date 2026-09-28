# Premium companion extension — v0.10 profile styles

## Implemented
- One unchanged default theme and ten named Premium skins, each with light/dark variants and reference-inspired artwork/background treatments.
- Free skin previews; applying a Premium skin requires server-verified Premium entitlement.
- Central-wallet Premium checkout with server-side live-price validation, wallet row locking, idempotent order/ledger writes, rollback on failure and separate new-purchase/renewal switches that remain OFF by default.
- Birthday month/day celebration, opt-out/removal, free birthday greeting and branded share card.
- Daily Nigeria-date motivation, same-day offline cache and saved favourites.
- Real Premium Mock e-Exam analytics and POP Exam Practice analytics sourced from completed attempt data. No fabricated scores are introduced.
- Downloadable/shareable Premium analytics PDF reports generated from the same verified analytics payload shown in the app.
- Premium profile cosmetics with five profile frames: Classic, Academic Gold, Campus Green, Future Glow and Editorial Ink.
- Profile frame choice is stored server-side. Non-Classic frames require the server-verified `profile_frames` Premium entitlement. If Premium expires or verification fails, the app displays Classic while retaining the preferred Premium frame for later reactivation.
- The selected frame is used on the real Profile screen, not only in the preview selector.
- Website administration remains responsible for Premium master control, purchase/renewal switches, pricing, promotions, quotes and complimentary access.

## Profile-style behaviour
- Classic remains available to every signed-in user.
- Premium users can preview and apply any Premium frame.
- Free or expired accounts may preview the styles but cannot save a Premium frame.
- Academic details are never changed by profile cosmetics.
- Profile cosmetics use a separate additive preference table so the migration remains repeatable on existing installations.

## Analytics report behaviour
- The report includes aggregate attempts, course count, average/best performance, Mock timing metrics, POP answer coverage, difficulty analytics where available, and course-performance tables.
- It is generated as `noun-update-premium-analytics.pdf` and handed to the phone's native share/save sheet.
- The app never invents missing analytics. If a source is unavailable, not linked or has no completed attempts, the report states that condition instead of fabricating values.

## Deployment
Back up the central database, apply `backend/sql/companion.sql`, then deploy the matching backend and app build. The additive migration enables implemented analytics/report/profile-frame feature flags but does not open Premium sales, alter wallet balances or grant Premium entitlement.

Keep **Allow new Premium purchases** and **Allow Premium renewals/extensions** OFF until a controlled live-account validation confirms debit amount, duplicate retry safety, insufficient-balance handling, entitlement activation, analytics retrieval and PDF report generation.

## Still pending
- Alternate launcher icons.
- Seasonal Premium assets/skins.
- Enhanced milestone celebrations; these should wait for dependable usage/progress data rather than fabricated milestones.
- No ad SDK is introduced by this work; existing Premium ad-suppression logic is retained for future ad inventory.
- Full cross-device student profile/course synchronisation remains incomplete.
- Live deployment to nounupdate.com is outside this repository commit and must be performed separately.

## Validation expectations
- Backend CI covers Premium entitlement, wallet purchase safety, profile-frame authorisation/expiry behaviour and Mock/POP analytics retrieval.
- Flutter validation covers Premium profile-frame fallback and selector behaviour alongside skin previews, `flutter analyze`, tests and Android release builds.
- A successful repository build is not evidence that the corresponding backend is already live on nounupdate.com.
