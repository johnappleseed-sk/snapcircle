# SnapCircle Frontend

SnapCircle frontend is the Flutter mobile application for the SnapCircle social media project. This setup prepares the app for integration with the Laravel REST API backend.

## Requirements

- Flutter SDK 3.x or newer
- Dart SDK included with Flutter
- Android Studio or VS Code with Flutter tooling
- Running Laravel backend API

## Installed Packages

- `dio`
- `provider`
- `flutter_secure_storage`
- `google_sign_in`
- `flutter_facebook_auth`
- `image_picker`
- `cached_network_image`
- `intl`
- `go_router`

## Install Packages

```bash
flutter pub get
```

## Run App

```bash
flutter run
```

## Backend API Base URL

The app is configured in:

```txt
lib/core/constants/app_config.dart
```

Default API URL:

```txt
http://10.0.2.2:8000/api
```

Use this for Android emulator because `10.0.2.2` points to the host machine.

For iOS simulator, use:

```txt
http://127.0.0.1:8000/api
```

The Laravel backend must be running before social login can complete:

```bash
cd ../backend
php artisan serve --host=0.0.0.0 --port=8000
```

## Authentication

SnapCircle uses social login in Flutter and exchanges the social provider access token for a Laravel Sanctum API token.

Flow:

1. User taps "Continue with Google" or "Continue with Facebook".
2. Flutter opens the native provider login flow.
3. Flutter sends the provider `access_token` to Laravel:

```http
POST http://10.0.2.2:8000/api/auth/google
POST http://10.0.2.2:8000/api/auth/facebook
```

Example request body:

```json
{
  "access_token": "provider_access_token_here"
}
```

Expected Laravel response:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {},
    "token": "laravel_sanctum_token_here",
    "token_type": "Bearer"
  }
}
```

The app stores the Laravel token in `flutter_secure_storage`. Every API request made through `ApiClient` reads that token and sends:

```http
Authorization: Bearer laravel_sanctum_token_here
```

On app start, `AuthProvider.checkAuthStatus()` checks secure storage. If a token exists, it calls `GET /api/user`. A valid token opens `/home`; an invalid token is deleted and the app returns to `/login`.

Logout calls `POST /api/logout`, clears secure storage, signs out from Google, and logs out from Facebook.

## Android Social Login Setup

Google login requires Android OAuth configuration in Google Cloud/Firebase:

- Add the Android package name from `android/app/build.gradle.kts`.
- Add the app SHA-1/SHA-256 fingerprints.
- Add the generated `google-services.json` only if your chosen Google setup requires it.
- Do not commit client secrets.

Facebook login requires Facebook developer configuration:

- Add a Facebook app ID placeholder in Android resources or manifest setup required by `flutter_facebook_auth`.
- Configure the Android package name and key hashes in the Facebook developer console.
- Add required intent queries and callback activity entries following the package documentation.
- Do not commit a Facebook app secret.

## iOS Social Login Setup

iOS setup is project-specific and should be completed before testing on iPhone or iOS Simulator:

- Add Google reversed client ID URL scheme if Google login is enabled for iOS.
- Add Facebook app ID, display name, URL schemes, and LSApplicationQueriesSchemes placeholders as required by `flutter_facebook_auth`.
- Do not commit client secrets or app secrets.

## Current Status

- Flutter project initialized
- Feature-based folder structure created
- API client foundation created with Dio
- Secure token storage added
- Provider state management added
- GoRouter routing added
- Material 3 theme added
- Authentication models, repository, provider, splash flow, and login screen connected to Laravel auth endpoints

## Analyze

```bash
flutter analyze
```
