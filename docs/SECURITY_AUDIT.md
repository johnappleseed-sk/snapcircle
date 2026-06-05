# SnapCircle Security Audit

## Current Security Features

- Laravel Sanctum API authentication.
- Social login through Google/Facebook.
- Protected routes using `auth:sanctum`.
- Ownership checks for posts, comments, stories, conversations, and notifications.
- File upload validation for profile, post, and story images.
- Secure token storage on Flutter side with `flutter_secure_storage`.
- `.env` ignored by Git.
- Safe account deactivation instead of hard deletion.
- Email visibility controlled by user settings.

## Security Risks Found

| Priority | Area | Risk | Recommended Fix |
|---|---|---|---|
| High | Authentication | Login endpoints could be spammed. | Add route throttling to social auth. |
| High | Authorization | Ownership checks were repeated inline. | Add policies for posts, comments, stories, conversations, and notifications. |
| High | Account status | Deactivated users could reach some protected actions. | Add active-account middleware for protected app actions. |
| Medium | API validation | Default framework errors could vary by exception type. | Normalize API JSON errors for validation, auth, forbidden, not found, and throttling. |
| Medium | Rate limiting | Write-heavy actions could be abused. | Add throttles to posts, comments, likes, follows, stories, messages, and destructive account routes. |
| Medium | File uploads | Unsafe filenames or oversized uploads can become storage risk. | Keep image-only validation, size caps, and framework-generated unique stored names. |
| Medium | CORS | Local defaults are permissive during development. | Restrict CORS to production frontend domains before deployment. |
| Medium | Public storage | Public media URLs can expose uploaded media. | Keep uploads in intended public directories and plan moderation/scanning. |
| Medium | User privacy | Public user resources can leak email. | Hide email unless current user or `show_email` is enabled. |
| Medium | Sensitive response fields | Provider IDs and tokens must never leak. | Use resources and hidden model fields; test sensitive field absence. |
| Low | Chat privacy | Messaging privacy is partially enforced in UI. | Enforce `allow_messages` server-side in conversation creation later. |
| Low | Story privacy | Stories are visible to authenticated users. | Add audience controls in a future privacy phase. |
| Low | Notifications privacy | Notifications are owner-scoped. | Keep policy checks and owner queries. |

## Improvements Applied

- Added route throttles for auth and write-heavy routes.
- Added authorization policies for posts, comments, stories, conversations, and notifications.
- Added `EnsureAccountIsActive` middleware and applied it to protected app actions.
- Normalized API error responses for 401, 403, 404, 422, and 429 cases.
- Confirmed upload validation and local-only deletion safety comments.
- Added security-focused tests for authorization, uploads, throttling, and sensitive resources.
- Added `.env.example` placeholders for frontend and OAuth configuration.
- Improved Flutter API error messages for expired sessions, forbidden actions, rate limits, and upload size problems.

## Future Security Roadmap

- Two-factor authentication.
- Blocked users.
- Report/moderation system.
- Production OAuth credentials and redirect URI hardening.
- Audit logging for sensitive actions.
- Server-side malware scanning for uploads.
- Advanced rate limiting by user/IP/action.
- Security headers and HTTPS-only cookies where applicable.
- Privacy policy and data retention policy.
