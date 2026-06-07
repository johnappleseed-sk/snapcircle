# SnapCircle Frontend / Backend Gaps

Last updated: 2026-06-07

This file records feature gaps and mismatches found while connecting the Flutter frontend to the existing Laravel API. The frontend should only call routes that exist in `backend/routes/api.php`.

## Backend Routes Missing For Requested Product Flows

- Email/password login is not present in `routes/api.php`.
- User registration is not present in `routes/api.php`.
- Forgot password or password reset is not present in `routes/api.php`.
- Refresh-token rotation is not present. Laravel Sanctum bearer tokens are issued by social/demo login and are revoked on logout/account changes.

## Backend Routes Present But Incomplete Or Not Fully Surfaced

- `DELETE /conversations/{conversation}` exists, but `ConversationController::destroy` returns "Conversation delete is not implemented for the MVP". The frontend should not expose conversation deletion as a real feature yet.
- `GET /admin/reports/{report}` exists but is not surfaced in Flutter UI.
- `GET /admin/users/{user}` exists but is not surfaced in Flutter UI.
- `GET /admin/posts`, `DELETE /admin/posts/{post}`, `GET /admin/comments`, and `DELETE /admin/comments/{comment}` exist but are not surfaced in Flutter UI.

## Request / Response Shape Notes

- Laravel wraps most responses as `{ success, message, data }`.
- Some paginated endpoints return list data directly under `data.data`.
- Other paginated endpoints use named keys such as `data.users`, `data.posts`, `data.conversations`, or `data.notifications`, plus `meta` and `links`.
- The frontend needs tolerant pagination parsing that supports both plain list responses and Laravel pagination metadata.
- Multipart uploads are supported for posts, profile avatar/cover image, and stories.

## Frontend Follow-Ups

- Add admin report detail and admin user detail screens if needed.
- Add admin posts/comments moderation screens if needed.
- Improve unauthorized handling so stale tokens are cleared consistently and the router returns users to login.

## Backend Follow-Ups For Future Versions

- Add email/password auth routes if non-social login/register/forgot password are required.
- Implement conversation deletion or remove the route from product expectations.
- Add refresh-token/session introspection if long-lived mobile sessions need token refresh instead of forced re-login.
