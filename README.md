# NOUN Update Student App

Flutter student app with live Power Space feeds, a shared Course Summary wallet,
separate Exam Summary checkout, and native student screens.
Quizly is excluded from this release.

See **backend/DEPLOY.md** for the website upload and SQL installation steps.
See **docs/mobile_api_v1.md** for the original API and **docs/NATIVE-APP.md** for the native revision, added routes and remaining backend requirements.

## Build

```sh
flutter create --platforms=android,ios --org com.nounupdate .
python -m pip install Pillow
python tools/prepare_brand_assets.py
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run --dart-define=NOUN_API_BASE_URL=https://nounupdate.com/api/v1
```

The GitHub APK workflow downloads the current `https://nounupdate.com/images/logo.webp`,
prepares the app header/launcher/splash assets, checks the code and builds Android
preview APKs. It fails if the current logo cannot be fetched; it does not silently
substitute the old logo. A stable private signing key is needed before production
store publication and subsequent production updates.

The UI uses glossy rounded icon tiles inspired by the supplied references. News and wallet screens read
real API responses; no demo financial or academic data is shown. Services without
native adapters display an in-app unavailable state; the app does not open website pages. The existing foundation screens
remain in the repository for later development but are not the active app shell.

The server package keeps secrets on the server, preserves existing `/api/` endpoints,
and adds `/api/v1/`. The central wallet shares the existing Course Summary account
and balance, rather than copying or merging money from unverified legacy accounts.
Other service wallets require separate adapters before joining the central balance.
