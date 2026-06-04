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

## Feed Integration

The feed is connected to the Laravel posts API through:

- `FeedRepository` for API calls and JSON parsing
- `FeedProvider` for feed state, pagination, creation, and deletion
- `PostModel` for post data
- `PostCard` for reusable social-style post UI

The feed screen calls:

```http
GET http://10.0.2.2:8000/api/posts
```

Requests use the Laravel Sanctum token stored during authentication:

```http
Authorization: Bearer laravel_sanctum_token_here
```

The feed supports initial loading, pull to refresh, empty state, readable error state, a "Load more" button, and owner-only post deletion.

## Likes Integration

Post likes are connected through the Laravel likes endpoints:

```http
POST http://10.0.2.2:8000/api/posts/{post}/like
DELETE http://10.0.2.2:8000/api/posts/{post}/like
```

`LikeRepository` sends the request and returns any updated `likes_count` and `liked_by_me` values from the API. `FeedProvider.toggleLike()` updates the selected post locally, keeps the heart icon in sync, and prevents negative like counts.

To test likes:

1. Log in.
2. Open the feed.
3. Tap the heart icon on a post.
4. Confirm the heart toggles and the like count changes.
5. Tap again to unlike.

## Comments Integration

Comments are connected through:

```http
GET http://10.0.2.2:8000/api/posts/{post}/comments
POST http://10.0.2.2:8000/api/posts/{post}/comments
PUT http://10.0.2.2:8000/api/comments/{comment}
DELETE http://10.0.2.2:8000/api/comments/{comment}
```

The comments feature uses:

- `CommentModel` for comment data
- `CommentRepository` for API requests and response parsing
- `CommentsProvider` for comments list state, pagination, submitting, updates, and deletes
- `CommentsScreen` for the comments list and bottom input
- `CommentTile` for individual comment UI and owner-only edit/delete actions

The comments button on each feed post opens `/posts/{postId}/comments`. Creating a comment inserts it at the top of the comments list and increments the feed comment count. Deleting a comment removes it locally and decrements the feed count safely.

To test comments:

1. Log in.
2. Open a post from the feed.
3. Tap the comments icon.
4. Add a non-empty comment.
5. Edit or delete comments that belong to the logged-in user.
6. Return to the feed and confirm the comment count updated.

## Create Post Flow

Users can create a post from the bottom navigation Create item, the feed floating action button, or the `/create-post` route.

Create post sends text and an optional image to Laravel:

```http
POST http://10.0.2.2:8000/api/posts
Content-Type: multipart/form-data
```

Multipart fields:

- `content`: optional text content
- `image`: optional uploaded image file

The screen validates that at least content or an image is present before submitting. On success, the created post is inserted at the top of the feed and the app returns to `/home`.

## Image Uploads

Images are selected from the gallery with `image_picker` and sent as multipart form data with Dio. Feed images are rendered with `cached_network_image`, including loading and error placeholders.

For Laravel public storage URLs to work, run this in the backend project:

```bash
php artisan storage:link
```

If the API returns local URLs like `http://127.0.0.1:8000/storage/...`, Android emulator devices may not be able to load them directly. Prefer returning URLs reachable from the emulator, such as `http://10.0.2.2:8000/storage/...`, during local Android testing.

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
- Feed models, repository, provider, post cards, create post, image upload, and owner delete connected to Laravel posts endpoints
- Likes and comments connected to Laravel API with local feed count updates

## Analyze

```bash
flutter analyze
```
