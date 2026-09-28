# NOUN Update mobile companion — v0.12 native timetable

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
- Automatic academic period calculation: January–June is `{year}_1 / First Semester`; July–December is `{year}_2 / Second Semester`. Students no longer maintain Session/Semester manually.
- Native personalised timetable sourced from the existing `personalized_timetable` content table. It reuses the website course-code, practical-course and POP/CBT exception logic rather than maintaining a second timetable database.
- Native timetable returns the matched schedule, missing registered courses, exam type, parsed Lagos exam date/time and the nearest future examination.
- Home dashboard now uses the same timetable snapshot for its free-design **Next examination** card.
- Timetable data includes both the automatic current academic period and the period inferred from imported exam dates. A mismatch is surfaced prominently; older timetable rows are never silently relabelled as the current semester.
- Existing guest/unsigned-in workspaces remain device-local; account sync and the timetable do not require Premium.

## Student workspace behaviour
- Signed-in account workspaces synchronise programme, faculty, level, study centre, automatic session/semester, registered course codes and pinned tools.
- Local storage remains the immediate offline copy, so the dashboard and course list continue to work when the API is unavailable.
- Local edits are marked pending until successfully written to the central account workspace.
- Server workspaces carry a monotonically increasing revision. A stale revision is rejected instead of overwriting newer data.
- If the account has no server workspace yet, existing locally saved account data is uploaded on first successful sync.
- Guest and skin-preview workspaces never write account data to the server.
- `/app/bootstrap` returns the signed-in workspace with profile/wallet data, avoiding a redundant workspace request on initial dashboard hydration. The standalone `/workspace` endpoint remains available for conflict reconciliation and later syncs.

## Personalised timetable behaviour
- The mobile route is `GET /timetable?courses=...` on the public v1 content API because timetable access remains a free academic feature.
- Course codes are normalised and validated before querying. Up to 30 registered courses can be checked in one request.
- Timetable rows are read from `personalized_timetable` using `course_code`, `course_title`, `day`, `date` and `time`.
- Exam type follows the established website logic: practical exceptions first, explicit POP/CBT exceptions next, then course-level classification.
- Date/time parsing uses `Africa/Lagos` and supports both the website's human-readable dates and ISO/database-style dates.
- The app never fabricates missing exam dates. Courses absent from the imported timetable remain saved in My Courses and are listed as not found until matching rows are imported.
- If the content database is unavailable or does not contain the timetable table, the app reports timetable unavailability rather than falling back to guessed dates.

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
Back up the central database, apply `backend/sql/companion.sql`, then deploy the matching backend and app build. The additive migration creates the Premium/personalisation tables and the account workspace table; it does not open Premium sales, alter wallet balances or grant Premium entitlement.

Confirm the mobile API content database (`NU_CONTENT_DB_*`, or its configured fallback) points to the same database containing the live `personalized_timetable` table before enabling the native timetable in production.

Keep **Allow new Premium purchases** and **Allow Premium renewals/extensions** OFF until a controlled live-account validation confirms debit amount, duplicate retry safety, insufficient-balance handling, entitlement activation, analytics retrieval and PDF report generation.

For workspace rollout, validate one existing account with locally saved details/courses, confirm first sync creates the server workspace, then sign into a second device and confirm the same details/courses/pins are restored. For timetable rollout, test the same account's registered courses against the website generator and confirm course/date/time/type and missing-course results agree.

## Still pending
- Alternate launcher icons.
- Seasonal Premium assets/skins.
- Enhanced milestone celebrations; these should wait for dependable usage/progress data rather than fabricated milestones.
- No ad SDK is introduced by this work; existing Premium ad-suppression logic is retained for future ad inventory.
- Saved-resource/download/progress state is still device-specific; workspace sync currently covers student details, registered courses and pinned tools only.
- Premium Home layout families still use their existing generic internal timetable captions; the timetable page itself and navigation use the verified native data. The next isolated skin-layout pass can surface the verified summary inside each Premium design without touching entitlement logic.
- Live deployment to nounupdate.com is outside this repository commit and must be performed separately.

## Validation expectations
- Backend CI covers Premium entitlement, wallet purchase safety, profile-frame authorisation/expiry behaviour, Mock/POP analytics retrieval, account-workspace revision/isolation checks and personalised timetable query/classification handling.
- Flutter validation covers Premium appearance fallback, skin previews, workspace sync/bootstrap hydration, automatic academic-period boundaries, native timetable parsing/rendering, responsive/accessibility rendering, `flutter analyze`, tests and Android release builds.
- A successful repository build is not evidence that the corresponding backend is already live on nounupdate.com.
