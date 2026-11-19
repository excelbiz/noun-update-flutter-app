# Native feature parity checklist

Bundled: 78 rows, 76 unique IDs. Server baseline: 78 configured rows. Duplicate paths are listed for review; the router dispatches IDs.

“Existing native” means implementation is present, not live-host acceptance. “Content needed” requires operator-approved copy. “Adapter needed” means there is no complete native action in this preview.

| ID | Website path / function | Native screen | API / source | Access | Offline / status |
|---|---|---|---|---|---|
| `noun-student-resource-centre` | `/noun-student-resource-centre` · Resource Centre | Native resource directory | /services plus bundled index | Public | Existing native / partial as noted · Bundled tools; verify website parity |
| `result` | `/result` · Result Checker | Native Result Checker flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `ai-result-analytics` | `/ai-result-analytics.php` · AI Result Analytics | Native AI Result Analytics flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `ai-result-analytics-auto` | `/ai-result-analytics-auto.php` · Auto Result Analytics | Native Auto Result Analytics flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `ai-result-analytics-dashboard` | `/ai-result-analytics-dashboard.php` · Analytics Dashboard | Native Analytics Dashboard flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `cgpa-calculator` | `/cgpa-calculator` · CGPA Calculator | Manual CGPA estimate | Local calculation | Public | Existing native / partial as noted · Offline |
| `graduation` | `/graduation` · Graduation / Convocation Checker | Native Graduation / Convocation Checker flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `graduation-predictor` | `/graduation-predictor.php` · Graduation Predictor | Native Graduation Predictor flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `fees` | `/fees/` · Fee Checker | Fee calculation form | /fees/options, /fees/calculate | Public | Existing native / partial as noted · Online |
| `personalized-timetable` | `/personalized-timetable` · Personalised Timetable | Personal course schedule | /timetable | Public lookup; student scope for save | Existing native / partial as noted · Explicit offline save; server maps 2026_2 faculties; reminders and later period mapping pending |
| `study-planner` | `/study-planner` · Study Planner | Study Hub revision checklist | Local storage | Public; scoped by student | Existing native / partial as noted · Offline; full website planner parity missing |
| `mock` | `/mock` · e-Exam Practice | Native e-Exam Practice flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `exam-practice.html` | `/exam-practice.html` · POP Exam Practice | Native POP Exam Practice flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `past-questions` | `/past-questions` · Past Questions | Native Past Questions flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `tma-archive` | `/tma-archive` · TMA Archive | Native TMA Archive flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `courses` | `/courses/` · Course Materials / Courseware | Course library / PDF / notes | /materials, /study/{code}, /study/{code}/state | Public; sync requires account | Existing native / partial as noted · Public PDFs and local notes |
| `course-summary` | `/course/summary` · Course Summary | Course Summary | /materials, /course-summary | Server-controlled access and pricing | Existing native / partial as noted · No full offline summary |
| `exam-summary` | `/exam-summary` · Exam Summary | Exam Summary catalogue / order | /exam-summaries, central quote/purchase, orders and download tickets | Purchase requires account and wallet | Existing native / partial as noted · No persistent paid PDF |
| `smart-eligibility-finder` | `/smart-eligibility-finder` · Smart Eligibility Finder | Native Smart Eligibility Finder flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `eligibility_checker` | `/eligibility_checker` · Eligibility Checker | Native Eligibility Checker flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `admission-requirements` | `/admission-requirements.php` · Admission Requirements | Native Admission Requirements flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `programmes` | `/programmes/` · NOUN Programmes | Native NOUN Programmes flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `programmes` | `/programmes.php` · Programmes Directory | Native Programmes Directory flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `study-centres` | `/study-centres/` · Study Centres | Native Study Centres flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `ai-course-tutor` | `/ai-course-tutor.php` · AI Course Tutor | Native AI Course Tutor flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `ai-exam-coach` | `/ai-exam-coach.php` · AI Exam Coach | Native AI Exam Coach flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `transcript-analyzer` | `/transcript-analyzer.php` · Transcript Analyzer | Native Transcript Analyzer flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `gpa-rescue` | `/gpa-rescue.php` · GPA Rescue Plan | Native GPA Rescue Plan flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `project-topic-generator` | `/project-topic-generator` · Project Topic Generator | Native Project Topic Generator flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `topic-generator` | `/topic-generator` · Topic Generator | Native Topic Generator flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `generate-project-slip` | `/generate-project-slip` · Generate Project Slip | Native Generate Project Slip flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `generate-seminar-slip` | `/generate-seminar-slip` · Generate Seminar Slip | Native Generate Seminar Slip flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `project-seminar` | `/hire-project-seminar.php` · Project & Seminar Support | Native Project & Seminar Support flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `projects` | `/projects` · Projects Library | Native Projects Library flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `business-plan` | `/business-plan.php` · Premium Business Plan | Native Premium Business Plan flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `turnitin` | `/turnitin` · Turnitin / Plagiarism Checker | Native Turnitin / Plagiarism Checker flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `marketplace` | `/marketplace` · Marketplace | Native Marketplace flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `dashboard` | `/dashboard.php` · Student Dashboard | Native Home | Central bootstrap, published updates, timetable | Account for personal data | Existing native / partial as noted · Local workspace |
| `my-account` | `/course/central-wallet.php` · My Account & Purchases | Native Account | Central bootstrap and settings | Account for remote profile; edit/reset/register adapters pending | Existing native / partial as noted · Local preferences |
| `cart` | `/cart.php` · Cart / Checkout | Native Cart / Checkout flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `student-success-hub` | `/student-success-hub` · Success Hub | Native Success Hub flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `student-advisor` | `/student-advisor` · Academic Advisor | Native Academic Advisor flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `career-hub` | `/career-hub.php` · Career & Internship Hub | Published feed and native article reader | /posts/{category}, /posts/{category}/{id} | Public | Existing native feed · online |
| `career-services` | `/career-services` · Career Services | Native Career Services flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `scholarships` | `/scholarships.php` · Scholarships | Published feed and native article reader | /posts/{category}, /posts/{category}/{id} | Public | Existing native feed · online |
| `fos` | `/fos` · Sciences | Native Sciences flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `foas` | `/foas` · Agricultural Sciences | Native Agricultural Sciences flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `foa` | `/foa` · Arts | Native Arts flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `fol` | `/fol` · Law | Native Law flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `foms` | `/foms` · Management Sciences | Native Management Sciences flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `foss` | `/foss` · Social Sciences | Native Social Sciences flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `foe` | `/foe` · Education | Native Education flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `fohs` | `/fohs` · Health Sciences | Native Health Sciences flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `foc` | `/foc` · Computing | Native Computing flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `search` | `/search.php` · Search NOUN Update | Native tool directory search | /services plus bundled index | Public | Existing native / partial as noted · Bundled tools |
| `glossary` | `/glossary` · Glossary | Native Glossary flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `about-noun` | `/about-noun` · About NOUN | Structured native information reader | /information/about-noun | Public | Content needed · online |
| `faqs` | `/faqs` · FAQs | Structured native information reader | /information/faqs | Public | Content needed · online |
| `file-resizer` | `/file-resizer/` · File Resizer | Native File Resizer flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `support` | `/support.php` · Support | Native Support flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `contact` | `/contact.php` · Contact | Native Contact flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `premium` | `/premium.php` · Premium Access | Premium plans and wallet purchase | Central /premium/config, /premium/status, /premium/purchase | Account and eligible balance | Existing native / partial as noted · No offline entitlement grant |
| `news` | `/news/` · News & Announcements | Published feed and native article reader | /posts/{category}, /posts/{category}/{id} | Public | Existing native feed · online |
| `guides` | `/guides/` · Student Guides | Published feed and native article reader | /posts/{category}, /posts/{category}/{id} | Public | Existing native feed · online |
| `calendar` | `/academic-calendar.php` · Academic Calendar | Academic calendar | /calendar | Public | Existing native / partial as noted · Online |
| `pas-status` | `/pas-status` · PAS Status | Native PAS Status flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `study-hub` | `/study-hub` · Study Hub | Study Hub and revision checklist | Existing native materials, workspace and saved-resources routes | Core tools public; sync requires account | Existing native / partial as noted · Checklist on device; AI/webinar parity missing |
| `wallet` | `/course/central-wallet.php` · Central Wallet | Balance and ledger | Central /app/bootstrap, /wallet | Account; additional funding adapter required | Existing native / partial as noted · Online; never cached balance |
| `tma-service` | `/tma-service` · TMA Support | Native TMA Support flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `gst302` | `/gst302-form` · GST302 Form Assistant | Native GST302 Form Assistant flow required | Match hosted service business logic | Verify hosted access and purchase rules | Adapter needed · offline rules unverified |
| `about` | `/about` · About NOUN Update | Native app information | Bundled verified app description | Public | Existing native / partial as noted · Offline |
| `editorial-policy` | `/editorial-policy` · Editorial Policy | Structured native information reader | /information/editorial-policy | Public | Content needed · online |
| `corrections` | `/corrections` · Corrections | Structured native information reader | /information/corrections | Public | Content needed · online |
| `sources` | `/sources` · Sources | Structured native information reader | /information/sources | Public | Content needed · online |
| `advertising` | `/advertising` · Advertising | Structured native information reader | /information/advertising | Public | Content needed · online |
| `privacy-policy` | `/privacy-policy` · Privacy Policy | Structured native information reader | /information/privacy-policy | Public | Content needed · online |
| `terms-of-use` | `/terms-of-use` · Terms of Use | Structured native information reader | /information/terms-of-use | Public | Content needed · online |

Dynamic rows use the same fixed ID resolver. An API-supplied URL cannot launch a webpage. Unknown IDs are explicitly unresolved. Validate each enabled row against its hosted API in staging before release.

## Release gates

- Exercise authentication, access renewal, purchase recovery and all enabled gateways against staging accounts and test payment intents.
- Match the live Mock data, attempt save/resume, scoring and explanations; verify timed and practice flows.
- Compare faculty/batch mappings and course-code variants against the current authoritative timetable.
- Test downloaded PDFs and timed theme changes on physical devices. Review all secondary pages at small widths and large text.
- Complete each adapter and approved information document before claiming full parity.
