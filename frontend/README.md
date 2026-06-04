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

## Current Status

- Flutter project initialized
- Feature-based folder structure created
- API client foundation created with Dio
- Secure token storage added
- Provider state management added
- GoRouter routing added
- Material 3 theme added
- Placeholder screens added
- Social login buttons are placeholders for the next step

## Analyze

```bash
flutter analyze
```
