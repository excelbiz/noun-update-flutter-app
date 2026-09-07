# NOUN Update Mobile Product Blueprint

## Product position

The application turns NOUN Update from a collection of useful pages into a connected student operating system. One student identity links programme, level, semester, courses, materials, TMA, practice, results, CGPA, wallet, premium access and graduation progress.

## Primary navigation

| Tab | Student outcome |
| --- | --- |
| Home | See what matters now and continue the next academic task. |
| Explore | Search anything NOUN and browse tools, courses, news and documents. |
| Wallet | Fund once and purchase premium summaries, mock tests, AI credits and services. |
| Saved | Keep downloaded or bookmarked resources grouped by type. |
| Profile | Manage academic identity, alerts, downloads, premium access and support. |

## Connected course journey

Every course is a mini learning portal:

1. Course identity: code, title, units, level, semester, faculty and old/new codes.
2. Learn: official material, summary, audio/video and AI course tutor.
3. Practise: TMA archive, topic quiz, past questions and timed mock.
4. Review: explanations, repeated concepts, weak topics and readiness score.
5. Act: save offline, continue Study Mode and receive course-specific alerts.

## Release roadmap

### Release 0.1 — Foundation

- Native design system and navigation.
- Demo-backed My NOUN dashboard.
- Unified search and course portal.
- Wallet, saved items, profile and alerts.
- Secure API and OneSignal hooks.

### Release 0.2 — Identity and live data

- Login/registration/password recovery.
- Programme, level and course selection.
- Live dashboard bootstrap endpoint.
- Existing wallet and premium balance.
- News, guides, materials and past-question APIs.

### Release 0.3 — Learning engine

- Study Mode sessions.
- Mock test engine and attempt history.
- Weak-topic detection and readiness score.
- AI Tutor restricted to each course material.
- Offline reading and queued progress sync.

### Release 0.4 — Student lifecycle

- Result analysis and CGPA history.
- Fee and registration planning.
- Programme map and graduation tracker.
- Personalised TMA/exam/calendar alerts.

### Release 0.5 — Network effects

- Faculty, level and course communities.
- Moderated student contributions.
- Verified resource submissions.
- Referral and service-booking integration.

## Non-negotiable safeguards

- The server owns prices, entitlements, AI prompts and payment verification.
- Wallet credits are idempotent and come only from verified Paystack callbacks.
- The app never stores database, Paystack-secret or AI-provider credentials.
- Premium status is checked server-side for each protected resource.
- Result and student data are encrypted in transit and excluded from analytics payloads.
- Alerts open an allow-listed in-app route; raw notification URLs are not executed.
