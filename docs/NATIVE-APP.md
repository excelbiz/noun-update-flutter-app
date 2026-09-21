# Native app revision — 0.3.0

The main app now uses Home, Study, Tools, Notifications and Profile. It follows the supplied references' green header, rounded content sheets, mint cards and glossy green/red/gold icons. Layout changes column counts for narrower screens and larger text. The marketing phone frames are not part of the interface. Branding is downloaded from `/images/logo.webp` at build time.

The running app no longer opens NOUN Update website pages. News is rendered as text, course materials and purchased PDF summaries use an in-app reader, and supported tools call `/api/v1`. The only embedded browser is the payment provider's secure checkout; website return URLs are intercepted and the API verifies payment before crediting the wallet. Some banks may require a separate banking app for authorization; that flow still needs physical-device testing.

## Supported integrations

- Existing shared email/password account; native registration and email reset code.
- One wallet backed by `summary_users.balance`, existing payment verification and transaction ledger.
- Exam Summary catalogue, quoted wallet purchase, purchase history and PDF reader.
- Course Summary unlock/generation through the existing summary engine. The app reviews the server price before debit; cached summaries and existing entitlement are reused.
- Course materials, native module reading, notes and completion state.
- News, guides, scholarships, career and blog feeds from the existing website content tables.
- Academic calendar from the existing calendar core (this component uses the site's calendar storage, which is not necessarily MySQL).
- Fee records from `fee_check`; manual CGPA estimate and focus timer.

Notifications currently show public published updates and calendar deadlines. They are not personal eLearn results or a push-notification delivery system. No fabricated unread counts, balances, subscriptions or course progress are shown. Biometric sign-in is not enabled in this revision. Quizly is excluded.

## Website files still required for complete parity

Only the relevant handlers and a schema-only export are needed, not the whole website:

| Service | Needed files and structure |
| --- | --- |
| Mock e-Exam | `/mock` entry/controller, question selection, attempt submission/scoring handlers; question/options/attempt/answer table definitions |
| Result checker | `/result` entry/controller and the server-side portal lookup handler; request/response examples with student details removed |
| Marketplace | Listing, upload, order and checkout handlers; listing/order/payment table definitions |
| Timetable | `/personalized-timetable` controller and schedule-generation rules; course timetable table definitions |
| Exact fee calculation | `/fee-check` controller and any included calculator file; rules for entry mode, matric year, exclusions and semester charges |
| Calendar | `academic-calendar-core/calendar.php` and its config/storage on the host |
| Course Summary | Existing `course/lib/summary_engine.php`, `course/paystack.php`, course environment configuration and installed Course Summary schema |

Unconnected service tiles open a native unavailable screen; they never open a website. The references contain features for which no backend was provided, so this revision is not a claim of complete service parity or pixel-identical visual matching.

## Added API routes

Public: `POST /auth/register`, `POST /auth/reset-request`, `POST /auth/reset-finish`, `GET /materials`, `GET /materials/{id}/pdf`, `GET /fees/options`, `POST /fees/calculate`, `GET /study/{code}`.

Bearer-authenticated: `GET/POST /profile`, `GET/POST /study/{code}/state`, `/course-summary?action=check_access|get_courses|summarize_init|summarize_section` (generation actions use POST). Existing wallet, purchase and article routes remain.

Apply `backend/sql/install.sql` again to add `nu_app_profiles`, `nu_app_resets` and `nu_app_study_state`; it is additive. These are in the wallet database. Existing content database tables are read rather than duplicated. New code lives in `nu-mobile/native.php`, `course-actions.php`, `course-environment.php` and the API router. `course-actions.php` adapts the supplied course controller to authenticated bearer requests; it does not expose a browser session.

No database password, payment secret or AI key belongs in Flutter. Configure these only on the server. Rotate the credentials previously pasted in chat before deployment. The app and website must use the same shared account identity and wallet routines; legacy independent checkout paths must not continue crediting balances separately.

Deploy first to staging and verify real provider checkout, reset-email delivery, course generation and PDF rendering on a physical phone before production. The API changes are not automatically deployed by an APK build.

## Reference design refinement — 0.3.1

Sign-in now uses a bundled, AI-generated decorative student banner with the actual website logo rendered separately. The banner is illustrative; it is not an official campus photograph. Prompt: smiling Nigerian adult student in a plain emerald hoodie holding a phone and books, campus background, dark green negative space on the left, no text or logos. Generated with the built-in image generation tool; source asset: `assets/images/student-hero.webp`.

Tools now use the reference's three-column card order, captions and bevelled icons. Notifications use All/TMAs/Exams/Results/Fees/General filters and Today/This week/Earlier sections, based on actual published posts. Read state is local to the device/account. This is not personal eLearn data or push delivery. Study uses numbered modules, a five-tab row and a toolkit strip; Quiz offers clearly labelled self-study recall, not an assessed mock exam. Explain and Voice Reader still display unavailable states pending integration. Wallet uses the reference's compact green panel and actual shared balance.

Screenshots generated by widget tests use fixture content and loaded text/icon fonts. They are app renders, not marketing mockups. Pixel-perfect equivalence to the posters is not claimed: device proportions, user text sizes, actual branding and available account data affect the layout. Mock e-Exam, result scraping and marketplace workflows remain dependent on their unsupplied backend controllers.
