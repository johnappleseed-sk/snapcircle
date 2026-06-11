# SnapCircle - Flutter and Laravel Social Media Mobile Application

SnapCircle is a full-stack social media mobile application built as an academic assignment project. It uses a Flutter mobile frontend and a Laravel REST API backend to support social authentication, profiles, posts, image uploads, likes, comments, follows, and a personalized social feed.

## Features

- Email/password registration and login
- Forgot password and reset password API flow
- Google and Facebook social login
- Laravel Sanctum API token authentication
- User profiles with avatar and bio
- Create, update, delete, and view posts
- Upload post images
- Like and unlike posts
- Add, edit, and delete comments
- Follow and unfollow users
- Block and unblock users
- Report posts, comments, users, and messages for moderation review
- Admin report review and moderation status updates
- Search users
- View followers and following lists
- Flutter mobile UI with Provider state management
- Dio API client with secure token storage

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

Demo login:

```txt
Email: maya@snapcircle.local
Password: password
```

Android notes:

- `10.0.2.2` is only for Android emulators. Physical devices need your computer's LAN IP.
- Local HTTP is enabled for Android debug/profile builds only; release builds should use HTTPS.
- If image uploads fail, confirm `php artisan storage:link` has run and `APP_URL`/API URL are reachable from the Android device.

Full Android install, APK, and real-device QA details are in [Android Demo Guide](docs/ANDROID_DEMO_GUIDE.md).

## Demo Flow

1. Login with email, demo, or social authentication.
2. View and refresh the home feed.
3. Create a post with text and optional image.
4. Like, comment, save, and share posts.
5. Explore/search users and posts.
6. Report or block a user/post, then review blocked users in Settings.
7. View and edit profile details.
8. Review notifications.
9. Send a chat message.
10. Review settings and logout.

## Environment Variable Notes

- Do not commit real `.env` files.
- Use `backend/.env.example` as the template.
- Add real Google and Facebook OAuth credentials only in local `.env` files.
- Production deployment would require production OAuth apps, HTTPS, secure database credentials, cloud file storage, and stricter server configuration.

## Documentation

- [Backend API Documentation](docs/API_DOCUMENTATION.md)
- [Technical Audit](docs/TECHNICAL_AUDIT.md)
- [Setup Guide](docs/SETUP_GUIDE.md)
- [Demo Guide](docs/DEMO_GUIDE.md)
- [Android Demo Guide](docs/ANDROID_DEMO_GUIDE.md)
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

## Author

- GitHub: `johnappleseed-sk`
- Project: SnapCircle
