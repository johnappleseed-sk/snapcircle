# SnapCircle Frontend / Backend Gaps

Last updated: 2026-06-11

This file records feature gaps and mismatches found while connecting the Flutter frontend to the existing Laravel API. The frontend should only call routes that exist in `backend/routes/api.php`.

## Backend Routes Missing For Requested Product Flows

- None for core email authentication after the 2026-06-11 completion pass.
- Refresh-token rotation is not present. Laravel Sanctum bearer tokens are issued by social/demo login and are revoked on logout/account changes.

## Backend Routes Present But Incomplete Or Not Fully Surfaced

- `DELETE /conversations/{conversation}` exists, but `ConversationController::destroy` returns "Conversation delete is not implemented for the MVP". The frontend should not expose conversation deletion as a real feature yet.
- `GET /admin/users/{user}` exists but is not surfaced in Flutter UI.
- `GET /admin/posts`, `DELETE /admin/posts/{post}`, `GET /admin/comments`, and `DELETE /admin/comments/{comment}` exist but are not surfaced in Flutter UI.

## Request / Response Shape Notes

- Laravel wraps most responses as `{ success, message, data }`.
- Some paginated endpoints return list data directly under `data.data`.
- Other paginated endpoints use named keys such as `data.users`, `data.posts`, `data.conversations`, or `data.notifications`, plus `meta` and `links`.
- The frontend needs tolerant pagination parsing that supports both plain list responses and Laravel pagination metadata.
- Multipart uploads are supported for posts, profile avatar/cover image, and stories.

## Frontend Follow-Ups

- Add admin user detail screens if needed.
- Add admin posts/comments moderation screens if needed.
- Improve unauthorized handling so stale tokens are cleared consistently and the router returns users to login.

## Backend Follow-Ups For Future Versions

- Implement conversation deletion or remove the route from product expectations.
- Add refresh-token/session introspection if long-lived mobile sessions need token refresh instead of forced re-login.

## QA and Release Readiness Pass

Date: 2026-06-07

Bugs or gaps found during QA:

- Flutter SDK is not available on PATH in this environment, so analyzer, tests, formatter, and APK build remain environment-blocked.
- Custom cards and skeleton loaders were still hard-coded to light surfaces, which weakened dark theme contrast.

Bugs fixed during QA:

- Made `AppCard` use `Theme.cardTheme.color` and `Theme.dividerColor`.
- Made `SkeletonBox` use a darker-mode-aware shimmer placeholder color.
- Removed a hard-coded dark text override from post content so post text follows the active theme.

Remaining backend/frontend gaps:

- Conversation deletion remains backend-not-implemented for MVP.
- Admin report detail, admin user detail, and admin post/comment moderation screens are still future UI work.

## Startup Product Polish Pass

Date: 2026-06-07

New findings:

- No new backend gaps were introduced by the product-polish pass.
- First-launch onboarding and Explore recent searches are intentionally local-only and do not require Laravel routes.
- Profile completion prompts use the existing `profile_completion` and user profile fields already returned by backend user/profile responses.

Remaining limitations:

- Conversation deletion remains unavailable because the existing backend route reports the MVP limitation.
- Admin report detail, admin user detail, and admin post/comment moderation UI are still not exposed in Flutter.

## Instagram and Threads Inspired UI Polish Pass

Date: 2026-06-07

New findings:

- No new frontend/backend gaps were introduced.
- The visual polish pass did not require new Laravel routes.
- Profile grid previews, story rings, post actions, comments, notifications, and chat polish all use existing data already returned by the backend.

Features not implemented because backend support is still missing:

- Real conversation deletion.
- Admin report detail, admin user detail, and admin post/comment moderation screens.

## Micro-Interactions and Premium UX Pass

Date: 2026-06-11

New findings:

- No new frontend/backend gaps were introduced.
- Micro-interactions, route transitions, skeleton loading, empty-state copy, accessibility labels, and keyboard behavior are frontend-only.
- Existing providers already guard duplicate like/save/follow/pagination requests, so no backend throttling route changes were required.

Remaining backend limitations:

- Conversation deletion remains unavailable because the current backend route reports the MVP limitation.
- Deeper admin detail/moderation screens remain future UI work.

## Full Product Feature Completion Pass

Date: 2026-06-11

Bugs/gaps resolved:

- Email/password login is now available at `POST /auth/login`.
- User registration is now available at `POST /auth/register`.
- Forgot password is now available at `POST /auth/forgot-password`.
- Password reset is now available at `POST /auth/reset-password`.
- Flutter now surfaces email login, registration, forgot password, and reset password without replacing Google, Facebook, or demo login.

Remaining gaps:

- Refresh-token rotation is still not implemented; the app continues to use Sanctum bearer tokens and session-expired handling.
- `DELETE /conversations/{conversation}` remains an MVP limitation until the backend implements real deletion.
- Multiple-image posts and video uploads are not implemented; the current post flow supports text plus one image.
- Admin user detail and admin post/comment moderation screens remain future Flutter work.

## Safety And Moderation Pass

Date: 2026-06-11

Bugs/gaps resolved:

- Added real block/unblock backend APIs and a `user_blocks` table.
- Added Flutter block/unblock actions on user profiles and feed post menus.
- Added Settings > Blocked users so users can review and unblock accounts.
- Added block-state fields to user responses so the profile UI can hide posts/stories and disable follow/message actions when either side has blocked the other.
- Added backend blocking checks to feed, explore, profile discovery, follow lists, notifications, comments, follow actions, conversation start, and message authorization.
- Expanded report reasons to include hate, nudity, scam, and misinformation while preserving existing reasons for old clients/data.
- Added admin report detail UI using the existing `GET /admin/reports/{report}` route.

Remaining gaps:

- `DELETE /conversations/{conversation}` remains an MVP limitation until the backend implements real deletion.
- Admin user detail and admin post/comment moderation screens are still future UI work.
- Blocked users are filtered from the core surfaces, but existing historical conversations are hidden rather than deleted.
