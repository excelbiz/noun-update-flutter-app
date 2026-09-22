# Student companion upgrade status

The full user brief is in student-companion-upgrade-brief.md. This is a staged implementation, not a completed release.

## Implemented in the first increment
- Auto, Light, Dark and System appearance controls; Auto defaults on new installs.
- Device-local light hours 06:00–18:59, dark hours 19:00–05:59.
- Re-evaluation at each minute and immediately after resuming; timer stops in background.
- Existing explicit appearance choices remain intact on upgrade.
- Small, Default, Large and Extra Large app text sizes with persistent storage.
- Device accessibility text scaling remains active; reduced-motion disables theme animation.
- Existing bundled fonts, accents and brand design retained.

## Remaining client work
- Five tabs Home / Study / Tools / Updates / Profile, separate notification inbox, real grouped global search.
- Optional student onboarding, My Courses and course hubs, personal dashboard and priority cards.
- Reading progress, reading-specific text controls, bookmarks, downloads and data saver.
- Timetable reminders, clashes, calendar integration and notification preferences.
- Persistent focus timer, optional study activity, dashboard layout controls and pinned tools.
- Deep links, share actions, launcher shortcuts, premium presentation and meaningful release notes.
- Broader skeleton/error/offline components and accessibility coverage.

## Backend and release dependencies
- New central-wallet integration is not implemented or deployed. Existing API targets the legacy wallet.
- Central account and wallet_payment_intents structure-only schemas remain outstanding.
- Supplied funding/webhook code needs central database selection and guarded payment state transitions.
- Account synchronisation, server entitlements and validated payment status must precede cross-device promises.
- Real academic alerts must come from dated source data; brief examples are not fixtures for production.
- Do not advertise premium benefits or enable ads until actual entitlements and provider setup support them.
- Hosted API deployment remains blocked by hosting access; no live deployment has occurred.
- Quizly and the future assistant remain outside the initial release.
