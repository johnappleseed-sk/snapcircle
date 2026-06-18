# SnapCircle Final Submission Checklist

Use this checklist before handing in the final project package or presenting the Android demo.

## Backend

- [ ] `composer install` completed.
- [ ] `.env` created locally from `.env.example`.
- [ ] App key generated with `php artisan key:generate`.
- [ ] Database configured.
- [ ] `php artisan migrate:fresh --seed` completed.
- [ ] `php artisan storage:link` completed or link already exists.
- [ ] Backend starts with `php artisan serve --host=0.0.0.0 --port=8000`.
- [ ] Health check returns SnapCircle JSON at `http://127.0.0.1:8000/api/health`.

## Frontend And Android

- [ ] Flutter SDK and Android SDK are installed and on PATH.
- [ ] `flutter pub get` completed.
- [ ] `flutter analyze` completed.
- [ ] `flutter test` completed.
- [ ] Android debug APK built with:

```bash
flutter build apk --debug --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

- [ ] APK exists locally at `frontend/build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] APK was not committed to git unless explicitly requested.

## Demo Readiness

- [ ] Demo account works: `maya@snapcircle.local` / `password`.
- [ ] Home feed loads.
- [ ] Create post works.
- [ ] Image or multiple-image post works.
- [ ] Like/comment/save works.
- [ ] Explore/search works.
- [ ] Profile and edit profile work.
- [ ] Follow/following state works.
- [ ] Notifications screen works.
- [ ] Chat list and chat detail work.
- [ ] Settings/logout work.
- [ ] Report/block workflow is ready to show.
- [ ] Admin/report screen is ready if presenting moderation.

## Presentation Assets

- [ ] `docs/FINAL_DEMO_SCRIPT.md` is ready.
- [ ] `docs/SCREENSHOT_GUIDE.md` is ready.
- [ ] `docs/FEATURE_LIST.md` is ready.
- [ ] `docs/TECHNICAL_ARCHITECTURE.md` is ready.
- [ ] Screenshots captured or screenshot plan included.
- [ ] README has setup, demo login, APK build, docs links, and limitations.

## Git And Security

- [ ] Code pushed to GitHub.
- [ ] No `.env` files committed.
- [ ] No API keys or tokens committed.
- [ ] No Firebase private keys or service account JSON committed.
- [ ] No build outputs committed.
- [ ] No cache folders committed.
- [ ] No local IDE files committed.
- [ ] No APK files committed unless explicitly requested.

## Known Local Environment Notes

- [ ] PHP has the required database PDO driver.
- [ ] PHP has `mbstring` enabled for PHPUnit.
- [ ] Port `8000` is free before starting Laravel.
- [ ] Computer firewall allows port `8000` for physical Android devices.
