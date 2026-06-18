# SnapCircle Technical Architecture

This document explains SnapCircle in a student-friendly way for final presentation and submission.

## System Overview

SnapCircle has two main parts:

```txt
Android Flutter App
  |
  | HTTPS/HTTP REST JSON API with Bearer token
  v
Laravel Backend API
  |
  | Eloquent ORM
  v
MySQL or local configured database
```

Flutter owns the mobile user experience. Laravel owns authentication, authorization, validation, business rules, data storage, and API responses.

## Flutter Frontend Architecture

The Flutter app is organized by feature modules under `frontend/lib/features`.

Important layers:

- `core/api`: Dio API client and endpoint constants.
- `core/storage`: token and local preference storage.
- `core/theme`: light/dark theme definitions.
- `core/widgets`: reusable UI states and controls.
- `routes`: `go_router` app navigation.
- `features/*/data`: repositories that call the backend.
- `features/*/providers`: Provider state classes.
- `features/*/screens`: visible pages.
- `features/*/widgets`: feature-specific UI pieces.

State management uses Provider. Repositories call the API client, providers hold loading/error/data state, and screens render that state.

## Laravel Backend Architecture

The Laravel backend is organized around REST API routes in `backend/routes/api.php`.

Important layers:

- Controllers in `app/Http/Controllers/Api`.
- Request validation in `app/Http/Requests`.
- API resources in `app/Http/Resources`.
- Eloquent models in `app/Models`.
- Database migrations in `database/migrations`.
- Demo data in `database/seeders`.
- Protected API routes use Laravel Sanctum authentication.
- Admin routes use an admin middleware.

The backend validates requests, checks ownership/privacy/blocking rules, stores data with Eloquent, and returns JSON responses for Flutter.

## API Flow

Example: creating a post.

```txt
CreatePostScreen
  -> FeedProvider.createPost
  -> FeedRepository.createPost
  -> Dio POST /api/posts
  -> Laravel PostController@store
  -> StorePostRequest validation
  -> Post/PostMedia models
  -> PostResource JSON
  -> Flutter updates feed state
```

The same pattern is used for comments, profiles, saved posts, notifications, chat, and reports.

## Auth And Token Flow

```txt
Login/Register/Demo Login
  -> Laravel AuthController
  -> Sanctum token is created
  -> Flutter stores token securely
  -> Dio adds Authorization: Bearer TOKEN
  -> Protected API routes return user data
```

On logout, Flutter asks the backend to revoke the token and removes the local token. If a request returns unauthorized, the app clears stale auth state and sends the user back to login.

## Database Overview

Core tables include:

- `users`: account, profile, privacy, moderation, and role fields.
- `posts`: post content and first-image compatibility field.
- `post_media`: ordered media records for carousel posts.
- `comments`: post comments.
- `likes`: post likes.
- `saved_posts`: saved post relationships.
- `follows`: followers, following, and pending/accepted status.
- `user_blocks`: block relationships.
- `reports`: moderation reports.
- `stories` and `story_views`: story content and view tracking.
- `notifications`: in-app notifications and route metadata.
- `conversations`, `conversation_user`, and `messages`: chat data.
- `device_tokens`: Android FCM token storage.
- `user_settings`: privacy, message, and notification preferences.

## Feature Modules

```txt
auth           login, register, demo auth, reset password
feed           home feed, post detail, saved posts
post           create and edit post
comments       comments experience
profile        own/user profiles, follow lists, follow requests
explore        search, trending, recommended users
stories        create/view stories
notifications  in-app notification list and routing
chat           conversations and messages
settings       account, privacy, notifications, blocked users
reports        report dialog and report submission
admin          moderation dashboards and review screens
```

## Android API URL Explanation

Android emulators cannot use `127.0.0.1` to reach the host computer. In an emulator, `127.0.0.1` points to the emulator itself. Use:

```txt
http://10.0.2.2:8000/api
```

For a real Android phone, use the computer LAN IP:

```txt
http://YOUR_COMPUTER_LAN_IP:8000/api
```

Run Laravel with:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

## Security And Release Notes

- Do not commit `.env`, API keys, tokens, Firebase private keys, service account JSON, build outputs, cache folders, local IDE files, or APK files.
- Debug APKs are for local demos only.
- Production release would need HTTPS, release signing, production OAuth apps, real push configuration, cloud media storage, monitoring, and stronger deployment hardening.

## Text System Diagram

```txt
User
  |
  v
Flutter UI Screens
  |
  v
Provider State
  |
  v
Repositories
  |
  v
Dio ApiClient
  |
  v
Laravel API Routes
  |
  v
Controllers -> Requests -> Resources
  |
  v
Eloquent Models
  |
  v
Database + Storage
```
