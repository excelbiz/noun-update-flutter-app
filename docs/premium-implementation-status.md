# NOUN Update mobile companion — v0.13 account + study sync

## Implemented
- One unchanged default theme and ten named Premium skins, each with light/dark variants and reference-inspired artwork/background treatments.
- Free skin previews; applying a Premium skin requires server-verified Premium entitlement.
- Central-wallet Premium checkout with server-side live-price validation, wallet row locking, idempotent order/ledger writes, rollback on failure and separate new-purchase/renewal switches that remain OFF by default.
- Birthday month/day celebration, opt-out/removal, free birthday greeting and branded share card.
- Daily Nigeria-date motivation, same-day offline cache and saved favourites.
- Real Premium Mock e-Exam analytics and POP Exam Practice analytics sourced from completed attempt data. No fabricated scores are introduced.
- Downloadable/shareable Premium analytics PDF reports generated from the same verified analytics payload shown in the app.
- Premium profile cosmetics with five profile frames: Classic, Academic Gold, Campus Green, Future Glow and Editorial Ink.
- Signed-in student workspace synchronisation for academic profile details, registered course codes and pinned tools. The app keeps a local offline copy and uses server revisions to prevent a stale device from silently overwriting newer account data.
- Signed-in Study progress synchronisation for completed course-unit indexes and personal study notes, stored per account and per course. This remains a free academic feature and does not require Premium or a wallet link.
- Central account bootstrap is wallet-optional: a valid signed-in account can load profile, workspace, Premium status/preferences and Study progress even when no central-wallet link exists. Only wallet/payment operations require an established wallet link.
- Automatic academic period calculation: January–June is `{year}_1 / First Semester`; July–December is `{year}_2 / Second Semester`. Students no longer maintain Session/Semester manually.
- Native personalised timetable sourced from the existing `personalized_timetable` content table. It reuses the website course-code, practical-course and POP/CBT exception logic rather than maintaining a second timetable database.
- Native timetable returns the matched schedule, missing registered courses, exam type, parsed Lagos exam date/time and the nearest future examination.
- Home dashboard uses the same timetable snapshot for its free-design **Next examination** card.
- Timetable data includes both the automatic current academic period and the period inferred from imported exam dates. A mismatch is surfaced prominently; older timetable rows are never silently relabelled as the current semester.
- Enabled website-backed services can open inside a restricted in-app NOUN Update browser instead of falling through to a dead-end placeholder. Native screens remain native.
- The in-app website fallback permits only HTTPS `nounupdate.com` and its subdomains for in-app navigation. External HTTPS, mail and telephone links leave the app; HTTP, JavaScript and lookalike domains are rejected. Central auth tokens and wallet credentials are never injected into the WebView.
- The live mobile service directory now excludes `enabled:false` entries and deduplicates repeated service IDs before returning tools to the app.

## Student workspace behaviour
- Signed-in account workspaces synchronise programme, faculty, level, study centre, automatic session/semester, registered course codes and pinned tools.
- Local storage remains the immediate offline copy, so the dashboard and course list continue to work when the API is unavailable.
- Local edits are marked pending until successfully written to the central account workspace.
- Server workspaces carry a monotonically increasing revision. A stale revision is rejected instead of overwriting newer data.
- If the account has no server workspace yet, existing locally saved account data is uploaded on first successful sync.
- Guest and skin-preview workspaces never write account data to the server.
- `/app/bootstrap` returns the signed-in workspace with profile and optional wallet data, avoiding a redundant workspace request on initial dashboard hydration. The standalone `/workspace` endpoint remains available for conflict reconciliation and later syncs.

## Study-progress behaviour
- `GET /study/{course}/state` and `POST /study/{course}/state` use the central account API for signed-in students.
- State is isolated by both account and course and currently stores completed unit indexes plus personal notes.
- Completed indexes are validated, deduplicated and sorted server-side. Notes are bounded to prevent oversized mobile payloads.
- Each server save increments a Study-state revision, giving later mobile work a safe basis for stronger offline reconciliation.
- Guest Study progress remains device-local.
- The existing Study UI already calls these central routes, so deploying the backend activates real cross-device notes/read-state sync without moving Study Hub behind Premium.

## Personalised timetable behaviour
- The mobile route is `GET /timetable?courses=...` on the public v1 content API because timetable access remains a free academic feature.
- Course codes are normalised and validated before querying. Up to 30 registered courses can be checked in one request.
- Timetable rows are read from `personalized_timetable` using `course_code`, `course_title`, `day`, `date` and `time`.
- Exam type follows the established website logic: practical exceptions first, explicit POP/CBT exceptions next, then course-level classification.
- Date/time parsing uses `Africa/Lagos` and supports both the website's human-readable dates and ISO/database-style dates.
- The app never fabricates missing exam dates. Courses absent from the imported timetable remain saved in My Courses and are listed as not found until matching rows are imported.
- If the content database is unavailable or does not contain the timetable table, the app reports timetable unavailability rather than falling back to guessed dates.

## Website-backed service behaviour
- The service directory remains authoritative for which website tools are enabled.
- Existing native implementations take precedence over `mode: web`, including Course Materials, Course Summary, Exam Summary, Personalised Timetable, Academic Calendar, Fee Checker and CGPA Calculator.
- Other enabled website-backed tools can use the restricted in-app browser, including Result Checker, e-Exam Practice, POP Exam Practice, Past Questions, TMA Archive, admission tools, AI tools, project/seminar tools, Marketplace, faculty pages and support utilities.
- Disabled tools are omitted by the live service API and are not intentionally exposed as active mobile features.
- The fallback is not a replacement for future native screens; it prevents working website services from appearing broken while native migration proceeds incrementally.

## Premium/profile behaviour
- Classic profile appearance remains available to every signed-in user.
- Premium users can preview and apply any Premium frame or Premium skin.
- Free or expired accounts may preview Premium appearance options but cannot save gated cosmetics.
- If Premium expires or verification fails, the app displays the free fallback while retaining the preferred Premium choice for later reactivation.
- Academic details and free academic tools are never moved behind Premium.

## Analytics report behaviour
- The report includes aggregate attempts, course count, average/best performance, Mock timing metrics, POP answer coverage, difficulty analytics where available, and course-performance tables.
- It is generated as `noun-update-premium-analytics.pdf` and handed to the phone's native share/save sheet.
- The app never invents missing analytics. If a source is unavailable, not linked or has no completed attempts, the report states that condition instead of fabricating values.

## Deployment
Back up the central database, apply `backend/sql/companion.sql`, then deploy the matching backend and app build. The additive migration creates the Premium/personalisation tables, account workspace table and Study-state table; it does not open Premium sales, alter wallet balances or grant Premium entitlement.

Confirm the mobile API content database (`NU_CONTENT_DB_*`, or its configured fallback) points to the same database containing the live `personalized_timetable` table before enabling the native timetable in production.

Keep **Allow new Premium purchases** and **Allow Premium renewals/extensions** OFF until a controlled live-account validation confirms debit amount, duplicate retry safety, insufficient-balance handling, entitlement activation, analytics retrieval and PDF report generation.

For workspace rollout, validate one existing account with locally saved details/courses, confirm first sync creates the server workspace, then sign into a second device and confirm the same details/courses/pins are restored. For Study rollout, mark a unit complete and save notes on device A, then open the same course on device B and confirm the server state appears. For timetable rollout, test the same account's registered courses against the website generator and confirm course/date/time/type and missing-course results agree.

For accounts without a wallet link, confirm `/app/bootstrap`, `/workspace` and `/study/{course}/state` still work while `/wallet` and Premium purchase correctly return wallet-link errors. This is an intentional boundary, not a degraded account state.

## Still pending
- Stronger signed-in Study offline reconciliation: the server sync is implemented, but the current signed-in Study screen should gain the same local pending/offline cache strategy already used by the student workspace.
- Alternate launcher icons.
- Seasonal Premium assets/skins.
- Enhanced milestone celebrations; these should wait for dependable usage/progress data rather than fabricated milestones.
- No ad SDK is introduced by this work; existing Premium ad-suppression logic is retained for future ad inventory.
- Saved-resource/download state is still device-specific. Workspace sync covers student details, registered courses and pinned tools; Study sync covers notes/read progress.
- Premium Home layout families still use their existing generic internal timetable captions; the timetable page itself and navigation use the verified native data. The next isolated skin-layout pass can surface the verified summary inside each Premium design without touching entitlement logic.
- Website-backed tools should continue migrating to native screens only where a native implementation materially improves the student experience or offline behaviour.
- Live deployment to nounupdate.com is outside this repository commit and must be performed separately.

## Validation expectations
- Backend CI covers Premium entitlement, wallet purchase safety, profile-frame authorisation/expiry behaviour, Mock/POP analytics retrieval, account-workspace revision/isolation checks, Study-state isolation/validation, personalised timetable query/classification handling and enabled service-directory filtering.
- Flutter validation covers Premium appearance fallback, skin previews, workspace sync/bootstrap hydration, central Study-state routing, automatic academic-period boundaries, native timetable parsing/rendering, safe NOUN Update destination validation, responsive/accessibility rendering, `flutter analyze`, tests and Android release builds.
- A successful repository build is not evidence that the corresponding backend is already live on nounupdate.com.
