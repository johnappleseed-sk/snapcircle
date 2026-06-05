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
