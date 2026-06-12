# SnapCircle Demo Guide

This guide prepares SnapCircle for a university demo, prototype review, or local product walkthrough.

## 1. Start The Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve --host=0.0.0.0 --port=8000
```

Backend health check:

```txt
http://127.0.0.1:8000/api/health
```

## 2. Start The Frontend

```bash
cd frontend
flutter pub get
flutter run
```

Local API URL defaults:

- Android emulator: `http://10.0.2.2:8000/api`
- iOS simulator, desktop, and web: `http://127.0.0.1:8000/api`
- Real device on same Wi-Fi: use your computer LAN IP, for example `http://192.168.1.25:8000/api`

Override the API base URL without editing source:

```bash
flutter run --dart-define=SNAPCIRCLE_API_BASE_URL=http://192.168.1.25:8000/api
```

## Android Demo Setup

Use this path for the Android emulator or an Android physical device demo.

Backend:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Backend health check:

```txt
http://127.0.0.1:8000/api/health
```

Android emulator frontend:

```bash
cd frontend
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

Physical Android device frontend:

```bash
cd frontend
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/api
```

Debug APK build:

```bash
cd frontend
flutter build apk --debug --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

Demo login credentials:

```txt
Email: maya@snapcircle.local
Password: password
```

Android connection troubleshooting:

- Emulator: use `10.0.2.2`, not `127.0.0.1`, because `127.0.0.1` means the emulator itself.
- Physical device: use your computer's LAN IP, keep both devices on the same Wi-Fi, and allow firewall access to port `8000`.
- Backend: run Laravel with `--host=0.0.0.0` so it accepts connections beyond localhost.
- Images: run `php artisan storage:link`; make sure uploaded image URLs point to a host the Android device can reach.
- Local HTTP: Android debug/profile builds allow cleartext traffic for the local Laravel backend. Production/release demos should use HTTPS.

Full Android APK install and real-device QA details are documented in:

```txt
docs/ANDROID_DEMO_GUIDE.md
```

## 3. Demo Login Options

- Email login/register: uses `POST /api/auth/login` and `POST /api/auth/register`.
- Forgot/reset password: uses `POST /api/auth/forgot-password` and `POST /api/auth/reset-password`; email delivery depends on local mail configuration.
- Demo login: uses `POST /api/auth/demo` and is the fastest route for presentation.
- Google login: requires valid backend OAuth configuration.
- Facebook login: requires valid backend OAuth configuration.

Do not commit real OAuth secrets or local `.env` files.

## 4. Main Demo Flow

1. Register or login with email, or use the demo button for the fastest presentation path.
2. View the home feed and pull to refresh.
3. Create a post with text, one image, or multiple images.
4. Like, comment, save, and share a post.
5. Open Explore, search for people/posts, and use recent searches.
6. Open a user profile from Explore.
7. Report a post or user with a specific reason.
8. Block a user from the profile menu or feed post menu, then confirm their content is hidden.
9. Open Settings > Blocked users and unblock that account.
10. Turn Private account on in Privacy Settings.
11. Login as another user, send a follow request, and confirm the profile shows Requested.
12. Return to the private account and approve or reject the request from Follow Requests.
13. Open your profile and edit profile details/avatar.
14. Open Notifications and mark items read.
15. Open Messages and send a chat message.
16. If using an admin account, open Admin > Reports and review a report detail/status.
17. Open Settings, review privacy/notification/account settings, then logout.

## 5. Known Limitations

- Conversation deletion is intentionally not exposed because the backend route is MVP-limited.
- Password reset email delivery requires mail settings in `backend/.env`.
- Mobile reset deep links are not wired yet; use the reset-token screen for local testing.
- Admin report detail is available; admin user detail and admin content moderation screens remain future UI work.
- Blocking hides and prevents core interactions with blocked users, but it does not delete historical data.
- Local social login needs real OAuth credentials in `backend/.env`.
- Physical Android device QA still requires a connected phone on the same Wi-Fi as the backend host.

## Multiple Image Posts Feature Pass

SnapCircle now supports carousel-style image posts for Android-first demos.

Backend/API:

- Run `php artisan migrate` so the `post_media` table exists.
- Create/update posts can send multipart files as `images[]`; old clients can still send `image`.
- Post responses include `media: [{ id, url, type, sort_order }]` and still include `image_url` for the first image.

Flutter demo behavior:

- Create Post lets users select up to 10 images, preview the selected set, and remove individual images before posting.
- Feed and post detail show swipeable image carousels with page dots.
- Profile and Explore grids show the first image with a small multiple-image indicator.

Android test notes:

- Use `10.0.2.2` for emulator API calls and a LAN IP for a physical phone.
- Run `php artisan storage:link` and make sure `APP_URL` or the served host is reachable from Android so returned media URLs load.
- Test text-only, single-image, and multiple-image posts before the demo.

## Private Account and Follow Requests Feature Pass

Backend/API:

- `users.is_private` controls account privacy.
- `follows.status` stores `pending` or `accepted`.
- Public accounts accept follows immediately.
- Private accounts create pending follow requests.
- `GET /follow-requests` lists pending requests for the authenticated user.
- `POST /follow-requests/{user}/approve` accepts a request.
- `POST /follow-requests/{user}/reject` rejects a request.
- `PUT /settings/privacy` updates the private account toggle.

Visibility rules:

- Owners and accepted followers can see private posts and stories.
- Non-followers and blocked users cannot see private posts or stories.
- Profile basics can still appear for discovery and search.

Android demo steps:

1. Login as Maya and enable Private account in Settings > Privacy Settings.
2. Login as Dara and open Maya's profile.
3. Tap Follow and confirm the button changes to Requested.
4. Login as Maya, open Follow Requests, and approve Dara.
5. Login as Dara again and confirm Maya's posts and stories are visible.
6. Repeat with another request and reject it.
7. Cancel a pending request by tapping Requested.

## Android Push Notifications Feature Pass

Backend/API:

- Run `php artisan migrate` so `device_tokens` exists.
- Configure `FIREBASE_PROJECT_ID` and `FIREBASE_SERVICE_ACCOUNT_PATH` in `backend/.env`.
- Keep the Firebase service account JSON outside git.
- `POST /device-tokens` registers the Android token.
- `DELETE /device-tokens` removes the Android token.

Flutter demo behavior:

- On login or session restore, Flutter requests notification permission and registers the FCM token.
- Foreground pushes display as local notifications.
- Taps route to post detail, Follow Requests, user profile, chat conversation, or Notifications.

Android test notes:

- Add the real `frontend/android/app/google-services.json` before building.
- Use two accounts so self-actions do not generate pushes.
- Test like, comment, follow, follow request, approval, and message notifications.
- Logout should remove the token when the device can reach the API.

Security notes:

- Do not commit `.env`, `google-services.json`, Firebase service account JSON, private keys, API keys, tokens, build outputs, or APK files.

## 6. Troubleshooting

- Android emulator cannot connect: make sure the backend is running with `--host=0.0.0.0` and use `10.0.2.2`.
- Real phone cannot connect: use the host computer LAN IP and ensure firewall access to port `8000`.
- Images fail on Android: ensure backend `APP_URL` is reachable from the device, not only `127.0.0.1`.
- Blocked user still visible: pull to refresh the current screen, then confirm both accounts are using the same backend database.
- Report submission fails: choose one of the supported reasons and avoid sending duplicate pending reports for the same target.
- Session expired: log in again; the Flutter app clears stale local tokens on `401`.
- Database errors: confirm MySQL is running and `backend/.env` database values are correct.
- `php artisan test` reports missing PHP extensions: enable/install the listed extensions, especially `mbstring`, then rerun the command.
