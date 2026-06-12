# SnapCircle Frontend API Coverage

Last updated: 2026-06-12

This document tracks Laravel API routes discovered in `backend/routes/api.php` and how the Flutter frontend currently uses them. Email/password login, registration, forgot password, and reset password are now implemented through the Laravel API and surfaced in Flutter.

Status legend:

- Used: A Flutter repository/provider/screen calls the route and exposes the flow.
- Partially used: Code exists but the route is not fully surfaced in UI, or the flow is incomplete.
- Not used: Backend route exists but no meaningful Flutter usage was found.
- Backend missing: Product requirement exists but backend route was not found.

## Public

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/health` | Not used | Endpoint constant exists; no health check UI/service call yet. |
| POST | `/auth/google` | Used | `AuthRepository.signInWithGoogle`, `AuthProvider`, `LoginScreen`. |
| POST | `/auth/facebook` | Used | `AuthRepository.signInWithFacebook`, `AuthProvider`, `LoginScreen`. |
| POST | `/auth/demo` | Used | Debug local demo login in `LoginScreen`. |
| POST | `/auth/login` | Used | Email/password login in `LoginScreen` through `AuthRepository.signInWithEmail`. |
| POST | `/auth/register` | Used | `RegisterScreen` creates an email account and stores the returned Sanctum token. |
| POST | `/auth/forgot-password` | Used | `ForgotPasswordScreen` requests a reset email. |
| POST | `/auth/reset-password` | Used | `ResetPasswordScreen` submits email, token, and new password. |

## Authenticated User And Account

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/user` | Used | Auth bootstrap via `AuthRepository.getCurrentUser`. |
| POST | `/logout` | Used | `AuthRepository.logout`, profile/settings logout flows. |
| GET | `/settings` | Used | `SettingsRepository`, settings screens. |
| PUT | `/settings` | Used | Settings update screens. |
| PUT | `/settings/privacy` | Used | Private account toggle in Privacy Settings. |
| PUT | `/account/deactivate` | Used | Account settings screen. |
| DELETE | `/account` | Used | Account settings screen. |

## Profile, Users, Follow

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/profile` | Used | `ProfileRepository.getProfile`, `ProfileScreen`. |
| PUT | `/profile` | Used | `EditProfileScreen`, avatar and cover upload. |
| GET | `/users` | Used | `ProfileRepository.getUsers`, search/users provider. |
| GET | `/users/username/{username}` | Used | `/u/:username` route and `UserProfileScreen`. |
| GET | `/users/{user}` | Used | User profile screen. |
| GET | `/users/{user}/posts` | Used | Profile posts section. |
| GET | `/users/{user}/stories` | Used | Profile stories section on own and other-user profile screens. |
| POST | `/users/{user}/report` | Used | Report dialog on user profile. |
| GET | `/blocks` | Used | Settings > Blocked users list. |
| POST | `/users/{user}/block` | Used | User profile menu and feed post action sheet. |
| DELETE | `/users/{user}/block` | Used | User profile menu and blocked-users settings screen. |
| GET | `/users/{user}/block-status` | Partially used | Endpoint exists for direct status checks; profile responses already include block state. |
| POST | `/users/{user}/follow` | Used | Profile and explore follow actions. |
| DELETE | `/users/{user}/follow` | Used | Profile and explore unfollow or cancel pending request actions. |
| GET | `/follow-requests` | Used | Follow Requests screen. |
| POST | `/follow-requests/{user}/approve` | Used | Approve follow request action. |
| POST | `/follow-requests/{user}/reject` | Used | Reject follow request action. |
| DELETE | `/followers/{user}` | Partially used | Backend supports safe follower removal; no dedicated Flutter action yet. |
| GET | `/users/{user}/followers` | Used | Follow list screen. |
| GET | `/users/{user}/following` | Used | Follow list screen. |

## Explore And Search

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/explore/posts` | Used | `ExploreRepository`, explore post grid. |
| GET | `/explore/users` | Used | `ExploreRepository`; partially surfaced via search/recommended people. |
| GET | `/explore/trending-posts` | Used | Trending section in explore. |
| GET | `/explore/recommended-users` | Used | Recommended people section. |
| GET | `/explore/search` | Used | Explore search bar and results. |

## Feed, Posts, Comments, Likes, Saves

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/feed/status` | Used | `RealtimeRepository`, feed polling banner. |
| GET | `/posts` | Used | Home feed, pagination, search/modes. |
| POST | `/posts` | Used | Create post screen with multipart text, single-image, and multiple-image carousel support. |
| GET | `/posts/{post}` | Used | Post detail screen. |
| PUT | `/posts/{post}` | Used | Owner-only edit action opens edit post UI and updates feed/detail state. |
| DELETE | `/posts/{post}` | Used | Owner delete actions in feed/detail. |
| POST | `/posts/{post}/report` | Used | Report dialog from post UI. |
| GET | `/posts/{post}/comments/status` | Used | Comments polling for new-comment banner. |
| GET | `/posts/{post}/comments` | Used | Comments screen. |
| POST | `/posts/{post}/comments` | Used | Comment composer. |
| PUT | `/comments/{comment}` | Used | Comment edit UI. |
| DELETE | `/comments/{comment}` | Used | Comment delete UI. |
| POST | `/comments/{comment}/report` | Used | Report dialog from comment UI. |
| POST | `/reports` | Used | Generic report endpoint supports post, comment, user, and message targets; current dialog continues to use target-specific routes where available. |
| POST | `/posts/{post}/like` | Used | Post card like action. |
| DELETE | `/posts/{post}/like` | Used | Post card unlike action. |
| POST | `/posts/{post}/save` | Used | Save/bookmark action. |
| DELETE | `/posts/{post}/save` | Used | Unsave action. |
| GET | `/saved-posts` | Used | Saved posts screen. |

## Stories

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/stories` | Used | Home stories row. |
| POST | `/stories` | Used | Create story screen. |
| GET | `/stories/{story}` | Used | Story viewer. |
| DELETE | `/stories/{story}` | Used | Story provider delete support. |
| POST | `/stories/{story}/view` | Used | Story viewer marks viewed. |

## Notifications

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/notifications` | Used | Notifications screen. |
| GET | `/notifications/unread-count` | Used | Home app bar badge and notification screen. |
| PUT | `/notifications/read-all` | Used | Notifications screen. |
| PUT | `/notifications/{notification}/read` | Used | Notification tap flow. |
| DELETE | `/notifications/{notification}` | Used | Notification delete action. |

## Chat

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/conversations` | Used | Conversations screen. |
| POST | `/conversations` | Used | Start chat from user profile. |
| GET | `/conversations/{conversation}` | Used | Chat detail refreshes conversation metadata. |
| DELETE | `/conversations/{conversation}` | Partially used | Backend route exists but returns MVP not implemented. Do not expose as a delete feature. |
| GET | `/conversations/{conversation}/messages` | Used | Chat detail screen. |
| POST | `/conversations/{conversation}/messages` | Used | Chat composer. |
| PUT | `/messages/{message}/read` | Used | Message read support. |

## Reports And Admin

| Method | Route | Status | Flutter usage |
| --- | --- | --- | --- |
| GET | `/admin/dashboard` | Used | Admin dashboard screen. |
| GET | `/admin/reports` | Used | Admin reports screen. |
| GET | `/admin/reports/{report}` | Used | Admin report detail screen. |
| PUT | `/admin/reports/{report}/status` | Used | Admin report status update. |
| GET | `/admin/users` | Used | Admin users screen. |
| GET | `/admin/users/{user}` | Not used | No admin user detail repository/screen call found. |
| PUT | `/admin/users/{user}/ban` | Used | Admin users moderation flow. |
| PUT | `/admin/users/{user}/unban` | Used | Admin users moderation flow. |
| PUT | `/admin/users/{user}/role` | Used | Admin users screen role update menu. |
| GET | `/admin/posts` | Not used | No admin content repository/screen call found. |
| DELETE | `/admin/posts/{post}` | Not used | No admin content delete flow found. |
| GET | `/admin/comments` | Not used | No admin content repository/screen call found. |
| DELETE | `/admin/comments/{comment}` | Not used | No admin content delete flow found. |

## QA and Release Readiness Pass

Date: 2026-06-07

Reviewed Flutter repository calls against `backend/routes/api.php` and targeted controllers/requests for posts, comments, saved posts, notifications, stories, profile, chat, settings, reports, and admin users.

Findings:

- Endpoint paths and HTTP methods used by Flutter match Laravel routes for the reviewed user-facing flows.
- Multipart field names match backend requests: post `image`, profile `avatar` and `cover_image`, story `media`.
- Social auth uses the backend-supported `access_token` payload. Email/password auth now uses Laravel validation requests and standard `{ success, message, data }` responses.
- Pagination response parsing now supports both direct Laravel list payloads and `ApiResponse::paginated` named-list payloads.
- Conversation deletion remains intentionally not surfaced because the backend MVP route returns a not-implemented message.

Verification notes:

- `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` could not run because `flutter` is not available on PATH in the current shell.
- Static API contract review found no new frontend/backend route mismatch.

## Startup Product Polish Pass

Date: 2026-06-07

API coverage review:

- No new backend API routes were invented or called during this polish pass.
- Onboarding completion and Explore recent searches are stored locally with `flutter_secure_storage`.
- Existing auth, feed, post, profile, explore, notification, chat, settings, and admin route usage remains unchanged from the QA pass.
- Logout/delete confirmations and profile completion prompts are frontend UX improvements around already-integrated flows.

Result:

- Backend API coverage status is unchanged.
- No additional unused Laravel routes were surfaced in Flutter during this pass.
- Existing documented gaps remain valid.

## Instagram and Threads Inspired UI Polish Pass

Date: 2026-06-07

API coverage review:

- This pass was UI-only and did not add new API calls.
- Feed, post, comments, stories, profile, explore, notifications, chat, settings, and auth screens continue to use the same documented Laravel endpoints.
- UI-only changes include theme, bottom navigation, post cards, story rings, profile grid previews, comment composer behavior, notification styling, chat bubbles, and settings grouping.

Result:

- Backend API coverage status is unchanged.
- No backend routes were invented.
- Existing backend gaps remain documented in `FRONTEND_BACKEND_GAPS.md`.

## Micro-Interactions and Premium UX Pass

Date: 2026-06-11

API coverage review:

- This pass did not add, remove, or rename any backend API calls.
- Like, unlike, save, unsave, follow, unfollow, delete post, report, comments, notifications, chat, and profile flows continue using the previously documented endpoints.
- Route transitions, skeleton loading, bottom-sheet menus, semantic labels, and keyboard behavior are frontend-only changes.

Result:

- Backend API coverage status is unchanged.
- No backend routes were invented.

## Full Product Feature Completion Pass

Date: 2026-06-11

API coverage update:

- Added backend routes for `POST /auth/register`, `POST /auth/login`, `POST /auth/forgot-password`, and `POST /auth/reset-password`.
- Added Flutter endpoint constants, repository calls, provider methods, and public auth routes for email login, registration, forgot password, and reset password.
- Existing Google, Facebook, demo login, Sanctum token persistence, `/user`, and `/logout` flows remain unchanged.
- `php artisan route:list` passed and listed 84 routes after the auth additions.

Remaining API coverage gaps:

- Conversation deletion remains partially used because the backend MVP route still reports delete as not implemented.
- Admin report detail, admin user detail, and admin post/comment moderation routes still need deeper Flutter screens if required for a complete moderator workflow.

## Safety And Moderation Pass

Date: 2026-06-11

API coverage update:

- Added and surfaced block routes: `GET /blocks`, `POST /users/{user}/block`, `DELETE /users/{user}/block`, and `GET /users/{user}/block-status`.
- Backend feed, explore, profile lists, follow lists, notifications, comments, and chat queries now suppress blocked or blocking users where relevant.
- Follow, conversation start, message sending, and commenting on blocked-owner content are blocked server-side.
- Report reasons now include spam, harassment, hate, violence, nudity, scam, misinformation, and other, while keeping older backend reasons for compatibility.
- Added generic `POST /reports` support for post, comment, user, and message targets.
- Flutter now surfaces block/unblock from user profiles, feed post menus, and Settings > Blocked users.
- Admin report detail is now fully surfaced through `GET /admin/reports/{report}`.

Remaining API coverage gaps:

- Conversation deletion remains partially used because the backend MVP route still reports delete as not implemented.
- Admin user detail and admin post/comment moderation screens are still not surfaced in Flutter.

## Multiple Image Posts Feature Pass

Date: 2026-06-12

API coverage update:

- `POST /posts` now accepts legacy `image` and new `images[]` multipart fields.
- `PUT /posts/{post}` also accepts replacement media through `image` or `images[]` when editing a post.
- Post responses now include a `media` array with `id`, `url`, `path`, `type`, and `sort_order`.
- `image_url` remains present and points to the first media item so older single-image UI remains compatible.
- Feed, saved posts, explore, profile posts, admin posts, and post detail responses eager-load media records.

Flutter coverage update:

- Create post uses `image_picker.pickMultiImage` on Android and sends multiple files as `images[]`.
- Feed and post detail render the returned `media` array through a swipeable carousel.
- Profile and explore grids use the first media item as the thumbnail and show a multiple-image indicator.

Known limitations:

- Multiple image upload supports images only; video posts are still a future feature.
- Existing edit flow can replace media but does not expose a separate "remove all existing images" action.

## Private Account and Follow Requests Feature Pass

Date: 2026-06-12

API coverage update:

- `users.is_private` is now enforced beyond profile editing.
- `follows.status` supports `pending` and `accepted`.
- Public-account follows return `follow_status: following`.
- Private-account follows return `follow_status: requested` until approved.
- Added follow request list, approve, reject, and follower removal backend routes.
- Added `PUT /settings/privacy` for the Privacy Settings private-account toggle.

Flutter coverage update:

- `UserModel` parses `follow_status` and `has_requested_follow`.
- Privacy Settings surfaces the private account toggle with confirmation.
- Profile UI shows Follow, Requested, Following, and Blocked states.
- Follow Requests screen lists pending requests with approve/reject actions.
- Notifications can open the follow request screen for follow-request notifications.

Visibility:

- Feed, Explore posts, profile posts, stories, direct post detail, comments, likes, and saves now rely on backend private-content checks.
