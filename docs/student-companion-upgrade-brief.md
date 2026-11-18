Remodel and upgrade the existing NOUN Update mobile application into a polished, premium, modern student application while preserving the parts of the current interface that already look good.

Do not redesign the application from scratch unnecessarily. Improve the existing design system, navigation, responsiveness, animations, information hierarchy and usability.

The app must feel like a true mobile application and not simply a mobile version of nounupdate.com.

The primary objective is to make NOUN Update become a personalised student dashboard and academic companion for National Open University of Nigeria students.

## 1. DESIGN DIRECTION

Preserve the current NOUN Update branding and visual identity.

The UI should feel:

- Modern
- Premium
- Clean
- Spacious
- Fast
- Academic
- Friendly
- Professional
- Native to Android/iOS
- Easy to understand without instructions

Avoid overcrowding screens.

Use cards, spacing, typography, icons, subtle shadows, rounded corners and visual hierarchy carefully.

Maintain consistency across every page.

Do not use excessive gradients, excessive animations or unnecessary decorative elements.

Interactive elements should clearly respond to touch.

Use skeleton loaders instead of ugly loading spinners wherever possible.

Add proper empty states, error states, offline states and retry states.

## 2. THEME SYSTEM

Keep the existing ability for users to change the application's theme.

Add four theme options:

- Auto
- Light
- Dark
- System

AUTO must be the default setting.

When Auto is selected:

- Automatically use Light Theme during daytime.
- Automatically use Dark Theme at night.
- Determine this using the device's local time.
- Theme switching should happen automatically without requiring the application to restart.
- Use a smooth transition when changing themes.

Recommended behaviour:

Light mode:
06:00 AM to 06:59 PM

Dark mode:
07:00 PM to 05:59 AM

Do not hard-code a Nigerian timezone. Use the device's current local timezone.

If the user manually selects Light or Dark, their manual choice must override automatic switching.

If they select System, follow the operating system theme.

Persist the selected theme between application sessions.

Every screen, dialog, bottom sheet, modal, card, icon, input field, navigation bar and loading state must properly support both dark and light mode.

Ensure sufficient colour contrast for accessibility.

## 3. FONT CUSTOMISATION

Preserve and improve the existing font-changing functionality.

Allow users to choose their preferred application font from Settings.

Font selection must apply consistently throughout the application without breaking layouts.

Store the selected font permanently until changed by the user.

Provide a preview before selecting a font.

Also provide text-size settings:

- Small
- Default
- Large
- Extra Large

Course materials and summaries should support separate reading font-size controls.

## 4. MAIN NAVIGATION

Simplify the primary bottom navigation to five tabs:

Home
Study
Tools
Updates
Profile

Do not overcrowd the bottom navigation.

Place Search and Notifications in the Home/App Bar.

Wallet balance may also be accessible from the Home header.

## 5. PERSONALISED HOME DASHBOARD

Transform Home into a personalised academic dashboard.

The dashboard should intelligently use the student's:

- Programme
- Faculty
- Level
- Semester
- Study centre
- Registered courses
- Exam timetable
- Study progress
- Wallet
- Premium status
- Saved resources
- Recent activity

Suggested Home structure:

Greeting

Example:

Good evening, Segun 👋

2026_2 Semester
400 Level
B.Sc. Computer Science

Then show a personalised hero card.

Examples:

NEXT EXAM

CIT411
Tuesday, 13 October
11:00 AM

21 Days Remaining

Or:

TMA Period is Active

Or:

PAS is Open

Or:

Results Have Been Released

The hero card should change automatically depending on the most important academic event affecting the student.

## 6. SMART PRIORITY CARD

Create a smart dynamic card near the top of Home.

The system should determine the most important thing the student needs to know.

Examples:

POP Exams Approaching

You have 6 POP courses.
Your first exam is in 21 days.

Start POP Preparation →

PAS Is Open

You have 2 non-examinable courses.

Check PAS Status →

TMA Period

TMA is currently ongoing.

View Your Courses →

New Result Update

Check your latest result information.

The card should change according to academic events and student data.

## 7. MY COURSES

Create a central "My Courses" system.

Students should be able to add their registered semester courses.

Each course should become its own Course Hub.

Example:

CIT411

Inside CIT411 show:

- Course Material
- Course Summary
- Exam Summary
- Past Questions
- POP Practice
- Mock Examination
- TMA information
- Exam date
- Personal notes
- Bookmarks
- Downloaded resources
- Study progress

Students should not need to search different sections of the app every time they need something related to the same course.

## 8. CONTINUE STUDYING

Create a Continue Studying section.

Remember exactly where the student stopped.

Example:

Continue Studying

CIT411 Course Summary
Chapter 6
Page 31
78% Complete

Continue →

Store progress for:

- Course Material
- Course Summary
- Exam Summary
- Past Questions
- POP Practice
- Study Hub content
- Mock examinations where appropriate

Synchronise reading progress to the user's account when internet is available.

## 9. GLOBAL SEARCH

Add a powerful global search.

The search icon should be visible from major screens.

Searching:

CIT411

should return:

Course Material
Course Summary
Exam Summary
Past Questions
Mock Examination
POP Practice
Exam Date
Related News

Search should also understand queries such as:

GST302 presentation
300 level fees
POP timetable
CIT425 past questions
PAS status
academic calendar

Group search results by category.

Include recent searches and allow users to clear their history.

## 10. STUDY TAB

Design Study as the main academic learning area.

Recommended sections:

Continue Studying

My Courses

Course Materials

Course Summary

Exam Summary

Past Questions

POP Practice

Mock E-Exam

Study Hub

Saved Resources

Downloaded Resources

Use horizontally scrollable cards where appropriate, but avoid excessive horizontal scrolling.

## 11. TOOLS TAB

Include:

Fee Checker

Personalised Timetable

Academic Calendar

CGPA Calculator

Result Checker

PAS Status

Project Topic Generator

Seminar Topic Generator

Project Slip Generator

Seminar Slip Generator

GST302 tools

Marketplace

Recover Premium Payment

Any future academic utilities should fit naturally within this page.

Allow users to pin favourite tools.

Pinned tools should appear first.

## 12. SMART PERSONALISED TIMETABLE

Upgrade the timetable into a complete exam companion.

Show:

Course Code
Course Title
Exam Type
Date
Time
Venue where available
Days remaining

Include:

- POP filter
- E-Exam filter
- Exam countdown
- Clash detection
- Calendar view
- List view
- Add to device calendar
- Automatic exam reminders

Notify students:

7 days before
3 days before
1 day before
Morning of the exam

Allow students to configure reminder timing.

## 13. NOTIFICATION CENTRE

Build a proper notification inbox.

Categories:

Academic
Examinations
TMA
PAS
Results
Timetable
Payments
Wallet
Study reminders
Scholarships
NOUN news
App updates

Notifications should support deep linking.

Example:

If a timetable notification mentions CIT411, tapping it should open CIT411's timetable entry directly.

Allow notification preferences to be configured.

Important alerts should be visually distinguished but not aggressively styled.

## 14. WALLET

Design the universal wallet like a polished fintech interface.

Show:

Current Balance

Fund Wallet

Transactions

Receipts

Payment History

Pending Transactions

Failed Transactions

Refunds

Every transaction should display:

Amount
Date
Reference
Service
Status

When sufficient wallet balance exists, enable one-tap purchases.

Example:

Course Summary
₦500

Wallet Balance
₦4,650

Pay ₦500

Avoid unnecessary redirection to external payment pages when wallet balance is enough.

Use biometric authentication or device PIN confirmation for sensitive wallet operations where appropriate.

## 15. PREMIUM EXPERIENCE

Create a proper NOUN Update Premium page.

Show premium benefits clearly.

Potential benefits:

No advertisements

Premium study tools

Advanced mock examination features

Discounted resources

Offline study resources

Advanced exam reminders

Priority support

Premium badges should be subtle.

Do not bombard free users with upgrade popups.

Show upgrade messages contextually.

## 16. OFFLINE MODE

Allow students to download supported resources.

Examples:

Course Materials

Course Summaries

Exam Summaries

Past Questions

Downloaded resources should remain available without internet.

Create a Download Manager showing:

Downloaded files
Download progress
File size
Storage usage
Remove download

Show an Offline indicator when internet is unavailable.

Example:

You're offline.

Your downloaded study resources are still available.

Automatically retry failed network operations when connectivity returns where appropriate.

## 17. DATA SAVER

Add a Data Saver setting.

When enabled:

Reduce image quality
Avoid unnecessary background refreshes
Do not autoplay media
Prefer cached content
Delay non-critical downloads

This is particularly important for users on limited mobile data.

## 18. BOOKMARKS AND SAVED ITEMS

Allow users to bookmark:

Articles
Courses
Resources
Questions
Study materials
Important notices

Profile → Saved should show everything organised by category.

## 19. STUDY TIMER

Add a small persistent Study Timer.

Students should be able to start:

25-minute focus session
50-minute session
Custom session

When the timer is running, minimise it into a small persistent element rather than forcing the timer page to remain open.

Connect it to the Study Hub where appropriate.

## 20. STUDY STREAKS

Track optional study activity.

Example:

7 Day Study Streak 🔥

Do not make the experience childish.

Use subtle progress tracking.

Possible metrics:

Days studied
Minutes studied
Courses studied
Practice questions completed
Mock exams completed

Achievements should encourage studying without creating pressure.

## 21. SEMESTER PROGRESS

Create a visual semester tracker.

Example:

2026_2 Semester

Registration ✓

TMA ✓

POP Preparation ●

POP Examination ○

E-Exam ○

Results ○

Display overall semester progress visually.

## 22. RECENT ACTIVITY

Show a Recent Activity section.

Example:

Opened CIT411 Summary

Completed 15 POP questions

Downloaded GST302 material

Funded wallet ₦5,000

Checked PAS status

Allow users to clear activity history.

## 23. HOME WIDGET CUSTOMISATION

Allow students to personalise their Home dashboard.

Users should be able to:

Reorder sections

Hide sections

Pin tools

Choose preferred Quick Actions

Possible widgets:

Next Exam

Wallet

Continue Studying

Semester Progress

Study Streak

Latest Updates

PAS Status

TMA Status

Quick Actions

My Courses

Use sensible default ordering for new users.

## 24. ONBOARDING

First-time users should complete a short onboarding flow.

Ask for:

Programme
Level
Study Centre
Semester
Registered Courses
Notification Preferences

Explain briefly why each selection improves personalisation.

After setup:

Your Dashboard Is Ready 🎉

Do not make onboarding too long.

Allow users to skip optional fields and complete them later.

## 25. PROFILE

Profile should contain:

Student information

Programme

Level

Study Centre

Registered Courses

Wallet

Premium

Downloads

Saved Items

Recent Activity

Transactions

Notification Preferences

Appearance

Theme

Fonts

Text Size

Data Saver

Security

Support

About NOUN Update

Logout

Keep settings logically grouped.

## 26. SMART QUICK ACTIONS

Quick Actions on Home should change according to current academic activities.

During examination period:

Timetable
POP Practice
Exam Summary
Past Questions

During TMA:

My Courses
TMA-related tools
Course Material

When PAS is open:

PAS Status should become more prominent.

The app should adapt to the academic calendar.

## 27. DEEP LINKS

Every major resource should support deep linking.

Notifications, website links and shared links should be able to open the relevant app screen directly.

Examples:

nounupdate.com/.../CIT411

should open CIT411 inside the app where applicable.

## 28. SHARE FUNCTIONALITY

Allow students to share:

News articles
Scholarships
Timetable information
Resources
Important notices

Shared links should use proper NOUN Update previews and branding.

## 29. APP ICON QUICK ACTIONS

Where the operating system supports it, long-pressing the NOUN Update app icon should provide shortcuts such as:

My Timetable

Fee Checker

PAS Status

Study

Wallet

## 30. PERFORMANCE

The app must feel extremely fast.

Optimise:

Image loading

Caching

API calls

State management

Page transitions

Database requests

Do not reload unchanged content unnecessarily.

Use local caching and refresh in the background.

Frequently used pages should open almost instantly after the first load.

## 31. ACCESSIBILITY

Support:

Large text

Screen readers

Proper colour contrast

Logical focus order

Large enough touch targets

Accessible form labels

Do not rely only on colour to communicate status.

## 32. ANIMATIONS

Use subtle animations.

Examples:

Card press animation

Smooth bottom navigation transitions

Animated progress bars

Wallet balance transition

Success check mark after payment

Smooth exam countdown

Page fade/slide transition

Pull-to-refresh animation using the NOUN Update / NU identity

Animations must remain fast and should never delay user actions.

Respect the device's reduced-motion accessibility setting.

## 33. ERROR HANDLING

Never expose raw API errors or developer messages to users.

Provide helpful human-readable errors.

Examples:

Instead of:

HTTP 500

show:

We couldn't load this information right now.

Try Again

Instead of:

NetworkException

show:

You're currently offline.

Downloaded resources are still available.

## 34. PAYMENT UX

Payment screens must clearly show:

Item being purchased

Price

Wallet balance

Payment method

Transaction state

Never allow accidental duplicate payments.

Disable the payment button while processing.

Provide clear states:

Processing

Successful

Pending

Failed

Cancelled

Include a receipt after successful payment.

## 35. SECURITY

Protect:

Wallet actions

Account information

Premium purchases

Sensitive profile information

Support biometric authentication where available.

Never store sensitive credentials in plain text.

Use secure token storage.

## 36. APP UPDATE EXPERIENCE

Add a What's New page after meaningful application updates.

Example:

What's New in NOUN Update

✓ Improved personalised timetable

✓ New offline materials

✓ Automatic dark mode

✓ Faster Study Hub

Do not show this after minor bug fixes unless necessary.

## 37. SMART ASSISTANT PREPARATION

Structure the application so that a future "Ask NOUN Update" assistant can easily be added.

Eventually students should be able to ask:

When is my next exam?

Which courses am I writing POP?

Explain CIT411 Chapter 4.

Show my PAS courses.

Calculate my CGPA.

Where can I get CIT425 past questions?

Do not make this assistant mandatory for the first release, but design the architecture so it can be introduced later.

## 38. ADVERTISEMENT UX

Advertisements must be minimal and non-intrusive.

Never interrupt:

Mock examination questions

Payments

Exam timetable

Critical notices

Course reading sessions

Premium users should see no advertising.

Free users can see ads between natural content sections.

Avoid full-screen ads unless absolutely necessary.

## 39. VISUAL CONSISTENCY

Create reusable design components for:

Cards

Buttons

Inputs

Bottom sheets

Dialogs

Headers

Empty states

Error states

Loading states

Course cards

Wallet cards

Notification cards

Exam cards

Use one consistent spacing scale and corner-radius system.

Do not create slightly different versions of the same component on different pages.

## 40. FINAL OBJECTIVE

The application should feel significantly more valuable than simply visiting nounupdate.com in a mobile browser.

The website should remain NOUN Update's broad information and resource platform.

The mobile application should become the student's personalised NOUN academic operating system.

A student opening the app should immediately know:

What requires my attention?

When is my next exam?

What should I study?

What has changed?

What courses am I taking?

What resources are available?

What have I already completed?

What is my wallet balance?

The design should reduce the number of taps required to accomplish common tasks.

Prioritise personalisation, speed, simplicity and usefulness over adding unnecessary visual elements.

Preserve the existing parts of the NOUN Update app that already look good, particularly the current theme and font customisation features, and improve them rather than replacing them.