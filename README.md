# SnapCircle - Flutter and Laravel Social Media Mobile Application

SnapCircle is a full-stack social media mobile application built as an academic assignment project. It uses a Flutter mobile frontend and a Laravel REST API backend to support social authentication, profiles, posts, image uploads, likes, comments, follows, and a personalized social feed.

## Features

- Email/password registration and login
- Forgot password and reset password API flow
- Google and Facebook social login
- Laravel Sanctum API token authentication
- User profiles with avatar and bio
- Create, update, delete, and view posts
- Upload single-image and multiple-image carousel posts
- Like and unlike posts
- Add, edit, and delete comments
- Follow and unfollow users
- Private accounts and follow request approval
- Block and unblock users
- Report posts, comments, users, and messages for moderation review
- Admin report review and moderation status updates
- Search users
- View followers and following lists
- Flutter mobile UI with Provider state management
- Dio API client with secure token storage

See the complete final feature inventory in [Feature List](docs/FEATURE_LIST.md).

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile frontend | Flutter, Dart |
| State management | Provider |
| API client | Dio |
| Secure storage | flutter_secure_storage |
| Routing | go_router |
| Backend | Laravel REST API |
| Database | MySQL |
| API authentication | Laravel Sanctum |
| Social authentication | Laravel Socialite, Google, Facebook |

## Project Structure

```txt
snapcircle/
|-- backend/      Laravel REST API
|-- frontend/     Flutter mobile application
|-- docs/         Documentation and assignment files
|-- README.md
`-- .gitignore
```

## Backend Setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve
```

Configure MySQL in `backend/.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=snapcircle
DB_USERNAME=root
DB_PASSWORD=
```

## Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

The frontend API base URL is configurable with `SNAPCIRCLE_API_BASE_URL`.

Default Android emulator API URL:

```txt
http://10.0.2.2:8000/api
```

Default iOS simulator, desktop, and web API URL:

```txt
http://127.0.0.1:8000/api
```

Real device on the same Wi-Fi:

```bash
flutter run --dart-define=SNAPCIRCLE_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/api
```

## Android Demo Setup

Start Laravel so Android emulators and devices can reach it:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Backend health check:

```txt
http://127.0.0.1:8000/api/health
```

Run on an Android emulator:

```bash
cd frontend
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

Run on a physical Android device on the same Wi-Fi:

```bash
cd frontend
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/api
```

Build a debug APK for local Android testing:

```bash
cd frontend
flutter build apk --debug --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

Expected local APK path:

```txt
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

Build a physical-device debug APK by replacing the emulator host with your computer LAN IP:

```bash
cd frontend
flutter build apk --debug --dart-define=SNAPCIRCLE_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/api
```

Demo login:

```txt
Email: maya@snapcircle.local
Password: password
```

Android notes:

- `10.0.2.2` is only for Android emulators. Physical devices need your computer's LAN IP.
- Phone and computer must be on the same Wi-Fi for physical-device demos.
- The backend should run with `php artisan serve --host=0.0.0.0 --port=8000`.
- Firewall rules must allow port `8000`.
- Local HTTP is enabled for Android debug/profile builds only; release builds should use HTTPS.
- If image uploads fail, confirm `php artisan storage:link` has run and `APP_URL`/API URL are reachable from the Android device.

Full Android install, APK, and real-device QA details are in [Android Demo Guide](docs/ANDROID_DEMO_GUIDE.md).

## Demo Flow

1. Login with email, demo, or social authentication.
2. View and refresh the home feed.
3. Create a post with text, one image, or multiple images.
4. Like, comment, save, and share posts.
5. Explore/search users and posts.
6. Report or block a user/post, then review blocked users in Settings.
7. Turn on Private account, approve/reject follow requests, and confirm private posts are protected.
8. View and edit profile details.
9. Review notifications.
10. Send a chat message.
11. Review settings and logout.

For the final presentation sequence, use [Final Demo Script](docs/FINAL_DEMO_SCRIPT.md).

## Environment Variable Notes

- Do not commit real `.env` files.
- Use `backend/.env.example` as the template.
- Add real Google and Facebook OAuth credentials only in local `.env` files.
- Production deployment would require production OAuth apps, HTTPS, secure database credentials, cloud file storage, and stricter server configuration.

## Multiple Image Posts Feature Pass

SnapCircle supports Android-first carousel posts without removing single-image compatibility.

- Backend storage uses a `post_media` table with ordered image records.
- Create/update post accepts multipart `images[]`; legacy `image` remains supported.
- Post JSON returns `media` and keeps `image_url` as the first image for older clients.
- Flutter create post supports multi-select, previews, per-image removal, a 10-image limit, and disabled submit while uploading.
- Feed and post detail show swipeable carousels with page indicators.
- Profile and Explore grids show the first image and a multiple-image badge.

Known limitations: image-only media for this pass, no video upload yet, and edit-post media removal is handled through replacement rather than a dedicated clear-all action.

## Private Account and Follow Requests Feature Pass

SnapCircle now supports private-account social behavior:

- Existing `users.is_private` is enforced by backend visibility rules.
- `follows.status` supports `pending` and `accepted`.
- Public accounts accept follows immediately.
- Private accounts create follow requests that owners can approve or reject.
- Feed, Explore, profile posts, stories, post detail, comments, likes, and saves respect private content access.
- Flutter Privacy Settings includes a Private account toggle.
- Flutter includes a Follow Requests screen with approve/reject controls.
- Profile/search/explore UI shows Follow, Requested, Following, Blocked, and private lock states.

Known limitations: follower removal is available in the API but not yet exposed in a dedicated Flutter follower-management screen, and existing followers remain approved when an account turns private.

## Android Push Notifications Feature Pass

SnapCircle now has Android-first Firebase Cloud Messaging support:

- Flutter includes Firebase initialization, FCM token registration, token refresh handling, foreground local notifications, and notification tap routing.
- Laravel stores Android FCM tokens in `device_tokens`.
- New protected routes: `POST /api/device-tokens` and `DELETE /api/device-tokens`.
- Pushes are triggered for likes, comments, follows, follow requests, follow request approvals, and chat messages.
- In-app notification records still use the existing notification system.
- Backend push delivery uses Firebase HTTP v1 and skips safely until Firebase is configured.

Firebase setup required:

1. Create a Firebase Android app with package `com.snapcircle.app`.
2. Download the real `google-services.json`.
3. Place it at `frontend/android/app/google-services.json`.
4. Create a Firebase service account JSON and store it outside git, for example `backend/storage/firebase-service-account.json`.
5. Set `FIREBASE_PROJECT_ID` and `FIREBASE_SERVICE_ACCOUNT_PATH` in `backend/.env`.

Security notes: do not commit `.env`, `google-services.json`, service account JSON, private keys, API keys, tokens, build outputs, or APK files. These paths are ignored by git.

Known limitations: push delivery still requires Firebase configuration outside git.

## Feature Expansion and UI Improvement Pass

SnapCircle now has a more complete Android-first social action surface:

- Post menus include View profile, Copy post text, Save/unsave, Report, Block, Edit, and Delete where allowed.
- Saved Posts supports the same post actions as the feed, including delete confirmation and unsave.
- Post Detail keeps safety actions available after opening a post.
- Existing real Laravel APIs power these actions; no fake client-only backend behavior was added.
- Reposts, mention autocomplete, video posts, and real-time typing indicators remain future enhancements.

## Documentation

- [Backend API Documentation](docs/API_DOCUMENTATION.md)
- [Technical Audit](docs/TECHNICAL_AUDIT.md)
- [Setup Guide](docs/SETUP_GUIDE.md)
- [Demo Guide](docs/DEMO_GUIDE.md)
- [Android Demo Guide](docs/ANDROID_DEMO_GUIDE.md)
- [Final Demo Script](docs/FINAL_DEMO_SCRIPT.md)
- [Feature List](docs/FEATURE_LIST.md)
- [Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md)
- [Screenshot Guide](docs/SCREENSHOT_GUIDE.md)
- [Final Submission Checklist](docs/FINAL_SUBMISSION_CHECKLIST.md)
- [Testing Checklist](docs/TESTING_CHECKLIST.md)
- [Assignment Report Draft](docs/ASSIGNMENT_REPORT.md)
- [Submission Guide](docs/SUBMISSION_GUIDE.md)
- [Screenshots Placeholder Guide](docs/screenshots/README.md)
- [Postman Collection](docs/postman/SnapCircle.postman_collection.json)

## Testing

Backend:

```bash
cd backend
php artisan route:list
php artisan test
```

Frontend:

```bash
cd frontend
flutter pub get
flutter analyze
flutter test --no-pub
```

On Windows, plugin-enabled Flutter projects may require Developer Mode for symlink support during some commands.

## Screenshots

Screenshots should be added before final submission in:

```txt
docs/screenshots/
```

Required screenshot placeholders include login, home feed, create post, comments, profile, edit profile, search, user profile, and followers/following screens.

## Assignment Summary

SnapCircle demonstrates a modern full-stack mobile application architecture. Flutter communicates with Laravel through REST JSON endpoints, Laravel uses Eloquent ORM to manage MySQL data, and Sanctum tokens secure protected API requests after email, demo, Google, or Facebook authentication.

The current Android demo build also includes safety and moderation workflows: user blocking, filtered feed/discovery/chat behavior for blocked users, expanded report reasons, and an admin report detail screen.

This project is for academic assignment purposes. A real production deployment would require stronger security configuration, production OAuth credentials, HTTPS, cloud storage, monitoring, and server deployment hardening.

## Known Limitations

- Debug APKs are for local demo/testing, not Play Store release.
- Release signing is not configured.
- Firebase push delivery requires real Firebase files and backend service account credentials outside git.
- Reposts, mention autocomplete, video posts, and real-time typing indicators are future improvements.
- Local Android demos require Flutter/Android tooling on PATH and a reachable Laravel backend.

## Advanced Features and Functionality Expansion Pass

SnapCircle now includes saved collections, user activity, and granular notification preferences.

- Saved collections keep existing simple saved posts working while adding collection CRUD and collection post membership.
- User activity shows recent posts, comments, likes, saved posts, and follows.
- Notification preferences include likes, comments, follows, follow requests, messages, and mentions, with backend notification creation respecting enabled categories.
- Demo seed data includes saved collections for richer Android demos.

## Author

- GitHub: `johnappleseed-sk`
- Project: SnapCircle
