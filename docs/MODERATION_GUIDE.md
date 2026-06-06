# SnapCircle Moderation Guide

## User Roles

SnapCircle supports three roles:

- `user`: normal social app member.
- `moderator`: can access admin moderation APIs.
- `admin`: can access moderation APIs and assign roles.

Admin and moderator routes require a Sanctum token and the `admin` middleware.

## Report System

Authenticated active users can report posts, comments, and users:

```http
POST /api/posts/{post}/report
POST /api/comments/{comment}/report
POST /api/users/{user}/report
```

Request body:

```json
{
  "reason": "spam",
  "description": "Optional context"
}
```

Allowed reasons:

```text
spam
harassment
inappropriate_content
fake_account
violence
other
```

Duplicate pending reports from the same user for the same item are blocked.

## Admin Dashboard

Admins and moderators can view platform-level counts:

```http
GET /api/admin/dashboard
```

The dashboard includes users, active users, banned users, posts, comments, reports, pending reports, stories, messages, and daily activity counts.

## Moderation Workflow

1. User submits a report.
2. Report is stored with `pending` status.
3. Admin or moderator reviews the report.
4. Reviewer updates status to `reviewed`, `dismissed`, or `action_taken`.
5. If needed, admin/moderator deletes the content or bans the user.

Report management endpoints:

```http
GET /api/admin/reports
GET /api/admin/reports/{report}
PUT /api/admin/reports/{report}/status
```

## Ban And Unban Behavior

Admin user endpoints:

```http
GET /api/admin/users
GET /api/admin/users/{user}
PUT /api/admin/users/{user}/ban
PUT /api/admin/users/{user}/unban
PUT /api/admin/users/{user}/role
```

Banning a user sets:

```text
account_status = banned
banned_at = current timestamp
ban_reason = supplied reason
```

The backend also revokes the banned user's tokens. Admins cannot ban themselves.

Unbanning a user restores:

```text
account_status = active
banned_at = null
ban_reason = null
```

## Content Deletion Behavior

Admin content endpoints:

```http
GET /api/admin/posts
DELETE /api/admin/posts/{post}
GET /api/admin/comments
DELETE /api/admin/comments/{comment}
```

Posts and comments use soft deletes, so moderation removal does not hard-delete content from the database.

## Flutter Moderation UI

Normal users can report posts, comments, and profiles from existing menus. Admin and moderator users see an Admin Panel entry in Settings with dashboard, reports, and user management screens.

## Future Moderation Improvements

- Moderator audit logs.
- Report assignment queues.
- Automated spam detection.
- User warning system.
- Appeal workflow.
- Media review queues.
- Admin activity notifications.
- More granular permissions.
