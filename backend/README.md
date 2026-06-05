# SnapCircle API

SnapCircle API is the Laravel REST backend for the SnapCircle social media mobile application. It provides authentication, profiles, follows, posts, likes, and comments for the Flutter mobile app.

## Requirements

- PHP 8.3 or newer
- Composer
- MySQL
- Laravel-compatible PHP extensions: OpenSSL, PDO, Mbstring, Fileinfo, Tokenizer, XML, Ctype, JSON

## Tech Stack

- Laravel
- MySQL
- Laravel Sanctum
- Laravel Socialite
- REST JSON API

## Installation

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

## Environment Setup

Configure the app URL and database in `.env`:

```env
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=snapcircle
DB_USERNAME=root
DB_PASSWORD=
```

Create the MySQL database before running migrations:

```sql
CREATE DATABASE snapcircle;
```

## Social Login Setup

Laravel Socialite is configured for Google and Facebook. Add real credentials in `.env` when ready:

```env
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=

FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
FACEBOOK_REDIRECT_URI=
```

Do not commit real credentials.

## Database

Run migrations and seed demo data:

```bash
php artisan migrate:fresh --seed
```

## Public Storage

Post images and avatars use Laravel's public storage disk:

```bash
php artisan storage:link
```

Uploaded files are stored under:

```txt
storage/app/public/posts
storage/app/public/avatars
```

## Run Server

```bash
php artisan serve
```

API base URL:

```txt
http://127.0.0.1:8000
```

Health check:

```txt
GET http://127.0.0.1:8000/api/health
```

## Run Tests

```bash
php artisan test
```

## API Documentation

Full endpoint documentation is available at:

```txt
../docs/API_DOCUMENTATION.md
```

Setup guide:

```txt
../docs/SETUP_GUIDE.md
```

Testing checklist:

```txt
../docs/TESTING_CHECKLIST.md
```

Postman collection:

```txt
../docs/postman/SnapCircle.postman_collection.json
```

## Feed Modes

The protected posts endpoint supports multiple feed modes:

```http
GET /api/posts?mode=all&page=1&per_page=10
GET /api/posts?mode=following&page=1&per_page=10
GET /api/posts?mode=popular&page=1&per_page=10
GET /api/posts?mode=mine&page=1&per_page=10
```

Optional query parameters:

```txt
mode      all | following | popular | mine
search    optional post content keyword
page      optional page number
per_page  optional page size, max 50
```

Post detail:

```http
GET /api/posts/{post}
```

Feed and post detail responses include ownership metadata for Flutter UI actions:

```txt
liked_by_me
is_owner
can_update
can_delete
```

## Save Posts

Authenticated users can save posts for later:

```http
POST /api/posts/{post}/save
DELETE /api/posts/{post}/save
GET /api/saved-posts
```

Saved post responses include:

```txt
saved_by_me
saves_count
```

The saved-posts list is paginated and returns full post resources.

## Notifications

Notifications are generated for social actions:

```txt
post_liked
post_commented
user_followed
```

Protected notification endpoints:

```http
GET /api/notifications
GET /api/notifications/unread-count
PUT /api/notifications/{notification}/read
PUT /api/notifications/read-all
DELETE /api/notifications/{notification}
```

Notification creation is handled by `NotificationService` so likes, comments, and follows can trigger reusable notification logic without duplicating code in controllers.

## Near Real-Time Status Endpoints

Phase 6 adds lightweight polling endpoints for the Flutter app:

```http
GET /api/feed/status
GET /api/posts/{post}/comments/status
```

These routes are protected by Sanctum and return only latest IDs, timestamps, totals, and unread notification counts. They avoid returning full posts or full comments during polling.

This phase uses lightweight polling instead of WebSockets. In future production versions, Laravel Broadcasting, Laravel Reverb, Pusher, or Firebase Cloud Messaging can be used for real-time updates.

## Messaging / Chat MVP

Chat uses REST endpoints protected by Sanctum:

```http
GET /api/conversations
POST /api/conversations
GET /api/conversations/{conversation}
DELETE /api/conversations/{conversation}
GET /api/conversations/{conversation}/messages
POST /api/conversations/{conversation}/messages
PUT /api/messages/{message}/read
```

Database tables:

```txt
conversations
conversation_user
messages
```

The MVP supports one-to-one conversations, participant-only access, latest-message previews, unread counts, sending text messages, and marking received messages as read. Conversation delete/archive is intentionally deferred to a later phase.

## Stories Feature MVP

Stories use Laravel storage and Sanctum-protected REST endpoints:

```http
GET /api/stories
POST /api/stories
GET /api/stories/{story}
DELETE /api/stories/{story}
POST /api/stories/{story}/view
GET /api/users/{user}/stories
```

Database tables:

```txt
stories
story_views
```

Stories are image-based, can include a caption, expire after 24 hours, and track unique views per user. Uploaded story media is stored under:

```txt
storage/app/public/stories
```

Run `php artisan storage:link` so story media URLs resolve through `/storage`.

## Explore and Discovery

Explore endpoints are protected by Sanctum:

```http
GET /api/explore/posts
GET /api/explore/users
GET /api/explore/trending-posts
GET /api/explore/recommended-users
GET /api/explore/search
```

The backend returns discoverable posts with engagement metadata, users with follow/profile counts, trending posts ranked by a simple engagement score, and recommended users excluding people the authenticated user already follows.

## Response Format

Success:

```json
{
  "success": true,
  "message": "Success message",
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "message": "Error message",
  "errors": {}
}
```
## Profile Improvements

Profiles include username, cover image, bio, location, website, private profile placeholder, joined date, last active date, profile completion, and user posts.

Key endpoints:

```http
PUT /api/profile
GET /api/users/username/{username}
GET /api/users/{user}/posts
```

Run `php artisan storage:link` so uploaded avatars and cover images are publicly reachable from `/storage/...`.

## Settings and Account Management

Settings are stored in `user_settings`; account status is stored on `users.account_status`.

```http
GET /api/settings
PUT /api/settings
PUT /api/account/deactivate
DELETE /api/account
```

Deactivation sets `account_status=deactivated` and revokes tokens. The delete endpoint is intentionally safe for the MVP and deactivates instead of hard deleting user data.

## Security Notes

- Keep `.env` private and use `.env.example` placeholders only.
- Use `APP_DEBUG=false` in production.
- Restrict CORS to the real frontend domain before launch.
- Configure production Google/Facebook OAuth credentials and redirect URIs.
- Rate limits are applied to auth and write-heavy endpoints.
- Uploads are restricted to jpg, jpeg, png, and webp with endpoint-specific size limits.
- Public media is stored under intended directories: `avatars`, `covers`, `posts`, and `stories`.
