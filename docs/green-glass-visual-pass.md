# Green Glass Lite visual pass · v0.10.1

This pass uses the supplied light and dark reference sheets for page structure,
colour, typography, spacing, icon treatment and navigation. Reference names,
scores, transactions and course records are not installed as student data.

| Reference area | Flutter implementation |
|---|---|
| Splash and onboarding | First-run campus welcome, official logo, book-stack art, Next and Skip |
| Sign-in | Branded header, wave footer, native fields and green action, with existing account requests |
| Dashboard | Smaller course/tool grid, reference shortcut order, green book-stack banner and student identity |
| My Courses | Registered, All Courses and Favourites, with real catalogue search and local course management |
| Course | Native Overview, Materials, Summary and Past Questions routes |
| PDF | Framed native viewer, previous/next navigation, page slider and permitted offline downloads |
| Timetable and calendar | Compact exam and date rows, timetable filters and existing offline/account scope |
| Study Hub | Compact reference-style hero and study actions, with the native revision planner |
| Wallet, notifications and account | Balance hero, native transactions, filters, preferences sheet and profile actions |

Automatic appearance is light from 07:00 to 18:59 and dark from 19:00 through
06:59, with manual options preserved. Both modes use the same route structure.
No backend files or payment protocols are changed by this visual pass.

Mock setup, questions, question navigator, results and review, and other
unconnected services still need their proper backend adapters. This pass does
not populate them with example exams or pretend they are live. See the existing
[feature parity checklist](green-glass-parity.md) for outstanding service work.

Preview captures are rendered by Flutter widget tests with fixture data.
