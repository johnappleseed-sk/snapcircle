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

### Better Feed Experience

The feed supports four modes from the same API endpoint:

| UI label | API mode | Purpose |
| --- | --- | --- |
| For You | `all` | Latest posts from everyone |
| Following | `following` | Posts from followed users plus your own posts |
| Popular | `popular` | Posts ordered by likes and comments |
| Mine | `mine` | Authenticated user's posts |

Example request:

```http
GET http://10.0.2.2:8000/api/posts?mode=following&page=1&per_page=10
```

The feed screen now includes horizontal mode chips, post search, skeleton loading cards, mode-specific empty states, and a post detail route:

```txt
/posts/{postId}
```

Tapping a post card opens the post detail screen. Tapping the comments action still opens:

```txt
/posts/{postId}/comments
```

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

## Save And Share Posts

Saved posts are connected through:

```http
POST http://10.0.2.2:8000/api/posts/{post}/save
DELETE http://10.0.2.2:8000/api/posts/{post}/save
GET http://10.0.2.2:8000/api/saved-posts
```

Flutter files:

- `SavedPostRepository` handles save, unsave, and saved-post list API calls.
- `SavedPostsProvider` owns saved-post list state and pagination.
- `SavedPostsScreen` shows saved posts with pull to refresh and load more.
- `PostCard` includes Save and Share actions.

Sharing is client-side through `share_plus`. The shared text includes the post content when available and a SnapCircle post-link placeholder.

Saved posts can be opened from the feed app bar or the Profile screen.

## Notifications

Notifications are connected through:

```http
GET http://10.0.2.2:8000/api/notifications
GET http://10.0.2.2:8000/api/notifications/unread-count
PUT http://10.0.2.2:8000/api/notifications/{notification}/read
PUT http://10.0.2.2:8000/api/notifications/read-all
DELETE http://10.0.2.2:8000/api/notifications/{notification}
```

Flutter files:

- `NotificationModel` parses notification data from Laravel.
- `NotificationRepository` handles notification API calls.
- `NotificationsProvider` owns notification list state, filters, unread count, read actions, and delete actions.
- `NotificationsScreen` displays notifications with filters, pull to refresh, mark-all-read, and load more.
- `NotificationTile` renders actor avatar, message, time, unread indicator, preview, and delete menu.

The feed app bar shows a notification icon with an unread badge. Tapping a notification marks it as read and opens the related post or user profile when available.

## Near Real-Time Updates

Phase 6 adds lightweight polling so the app feels more current without requiring WebSockets.

Polling intervals are centralized in:

```txt
lib/core/constants/realtime_config.dart
```

Current intervals:

```txt
notificationPollInterval: 30 seconds
feedStatusPollInterval: 45 seconds
commentsStatusPollInterval: 30 seconds
```

The app calls:

```http
GET http://10.0.2.2:8000/api/feed/status
GET http://10.0.2.2:8000/api/posts/{post}/comments/status
```

UI behavior:

- The feed shows a "New posts available" banner instead of auto-refreshing.
- The notification badge uses the lightweight feed status unread count and stays compatible with `NotificationsProvider`.
- The comments screen starts polling only while open and shows a "New comments available" banner.
- Polling stops on logout and pauses while the app is inactive or in the background.

This phase uses lightweight polling instead of WebSockets. In future production versions, Laravel Broadcasting, Laravel Reverb, Pusher, or Firebase Cloud Messaging can be used for real-time updates.

## Messaging / Chat MVP

Chat is connected through:

```http
GET http://10.0.2.2:8000/api/conversations
POST http://10.0.2.2:8000/api/conversations
GET http://10.0.2.2:8000/api/conversations/{conversation}
GET http://10.0.2.2:8000/api/conversations/{conversation}/messages
POST http://10.0.2.2:8000/api/conversations/{conversation}/messages
PUT http://10.0.2.2:8000/api/messages/{message}/read
```

Flutter files:

- `ConversationModel` and `MessageModel` parse chat data from Laravel.
- `ConversationRepository` and `MessageRepository` handle chat API calls.
- `ConversationsProvider` owns conversation list state, pagination, and start-chat actions.
- `MessagesProvider` owns message list state, pagination, sending, and read receipts.
- `ConversationsScreen` shows the messages inbox at `/messages`.
- `ChatDetailScreen` shows messages and the composer at `/messages/{conversationId}`.

Users can open Messages from the feed app bar or start a new conversation from another user's profile. This MVP uses REST and manual refresh rather than WebSockets. Future phases can add live message delivery with Laravel Broadcasting, Laravel Reverb, Pusher, or Firebase Cloud Messaging.

## Stories Feature MVP

Stories are connected through:

```http
GET http://10.0.2.2:8000/api/stories
POST http://10.0.2.2:8000/api/stories
GET http://10.0.2.2:8000/api/stories/{story}
DELETE http://10.0.2.2:8000/api/stories/{story}
POST http://10.0.2.2:8000/api/stories/{story}/view
GET http://10.0.2.2:8000/api/users/{user}/stories
```

Flutter files:

- `StoryModel` parses story data from Laravel.
- `StoryRepository` handles story API calls and multipart uploads.
- `StoriesProvider` owns story list state, creation, deletion, and view updates.
- `StoriesRow` and `StoryCircle` show active stories above the feed.
- `CreateStoryScreen` lets users select an image and caption.
- `StoryViewerScreen` displays a full-screen story and owner delete action.

Stories expire after 24 hours. Opening a story marks it as viewed; the API prevents duplicate view records for the same user and story.

## Explore And Discovery

Explore is connected through:

```http
GET http://10.0.2.2:8000/api/explore/posts
GET http://10.0.2.2:8000/api/explore/users
GET http://10.0.2.2:8000/api/explore/trending-posts
GET http://10.0.2.2:8000/api/explore/recommended-users
GET http://10.0.2.2:8000/api/explore/search
```

Flutter files:

- `ExploreRepository` handles Explore API calls.
- `ExploreProvider` owns Explore posts, trending posts, recommended users, search, sorting, and follow state.
- `ExploreScreen` replaces the old Search tab in bottom navigation.
- `ExploreSearchBar` debounces global search input.
- `RecommendedUserCard` displays people to follow.
- `ExplorePostGridItem` displays discoverable posts.

The old `/search` route remains available and opens the Explore screen.

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

## Profile Integration

The profile area is connected through:

```http
GET http://127.0.0.1:8000/api/profile
PUT http://127.0.0.1:8000/api/profile
GET http://127.0.0.1:8000/api/users/{user}
```

`ProfileRepository` handles current profile, profile updates, user detail loading, and follow API calls. `ProfileProvider` owns current profile state, selected user state, edit loading, follow loading, and readable API errors.

The current profile screen shows avatar, name, email, bio, post count, follower count, following count, edit profile, logout, and a placeholder for user posts.

## Edit Profile Flow

The edit profile screen lets the authenticated user update:

- `name`
- `bio`
- `avatar`

Avatar updates use `image_picker` and multipart form data. After a successful update, `ProfileProvider.profile` and `AuthProvider.user` are both refreshed locally so the rest of the app sees the updated user.

## Search Users Flow

Search is connected to:

```http
GET http://127.0.0.1:8000/api/users?search=query
```

The search screen includes a debounced search field, pull to refresh, load more, empty state, error state, and `UserTile` results. Tapping a user opens `/users/{userId}`.

## Follow System

Follow endpoints:

```http
POST http://127.0.0.1:8000/api/users/{user}/follow
DELETE http://127.0.0.1:8000/api/users/{user}/follow
GET http://127.0.0.1:8000/api/users/{user}/followers
GET http://127.0.0.1:8000/api/users/{user}/following
```

`UserProfileScreen` shows a Follow or Unfollow button for other users only. Followers and following counts update locally after follow actions. Followers and Following stats open paginated list screens.

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
- Profile, edit profile, user search, user profiles, follow/unfollow, followers, and following screens connected to Laravel API

## UI/UX Redesign Summary

Phase 2 improves the Flutter app with a cleaner startup-style social interface while keeping the existing Provider state, GoRouter routes, and Laravel API integrations intact.

Design system files:

- `lib/core/constants/app_colors.dart`
- `lib/core/constants/app_sizes.dart`
- `lib/core/constants/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`

Reusable widgets:

- `AppButton`
- `AppTextField`
- `AppAvatar`
- `AppCard`
- `EmptyView`
- `ErrorView`
- `LoadingView`
- `SectionHeader`

Screens polished:

- Splash screen
- Login screen
- Home feed screen
- Post cards
- Create post screen
- Comments screen
- Profile screen
- Edit profile screen
- Search/Explore screen
- User profile screen
- Followers and following lists

The redesign adds consistent spacing, rounded cards, clearer buttons, improved avatars, friendly loading/empty/error states, and consistent snackbar feedback.

## App Screens

- Splash screen
- Login screen
- Home feed
- Create post
- Comments
- Profile
- Edit profile
- Search users
- User profile
- Followers and following lists

## Package Usage

| Package | Usage |
| --- | --- |
| `provider` | State management for auth, feed, comments, profile, and search |
| `dio` | REST API requests to Laravel |
| `flutter_secure_storage` | Stores Laravel Sanctum token securely |
| `go_router` | App routing |
| `google_sign_in` | Google login flow |
| `flutter_facebook_auth` | Facebook login flow |
| `image_picker` | Avatar and post image selection |
| `cached_network_image` | Remote image loading and caching |
| `intl` | Date/time formatting helpers |

## Assignment Documentation

See the root documentation folder:

```txt
../docs/SETUP_GUIDE.md
../docs/TESTING_CHECKLIST.md
../docs/API_DOCUMENTATION.md
../docs/ASSIGNMENT_REPORT.md
```

## Analyze

```bash
flutter analyze
```

## Run And Verify UI

```bash
flutter pub get
flutter analyze
flutter run
```

Manual UI verification checklist:

- Open the splash and login screens.
- Log in with the configured provider or local demo account.
- Refresh the feed and create a text post.
- Open comments, add a comment, and return to the feed.
- Open profile, edit profile, and view another user profile.
- Search users and open followers/following lists.
## Profile Improvements

The Flutter profile experience supports usernames, cover images, avatars, bio, location, website, joined date, private profile placeholder, profile completion, latest/popular profile posts, and username routes with `/u/{username}`.

The Android emulator should call the Laravel API at:

```text
http://10.0.2.2:8000/api
```

Chrome, macOS, and iOS simulator can use:

```text
http://127.0.0.1:8000/api
```
