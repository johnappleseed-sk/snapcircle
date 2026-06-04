# SnapCircle API

SnapCircle API is the Laravel REST backend for the SnapCircle social media mobile application. This backend will provide JSON APIs for authentication, profiles, posts, image uploads, likes, comments, follows, and feed data.

The backend is currently initialized as a clean Laravel API foundation. Full feature implementation will be added later.

## Backend Tech Stack

- Laravel
- MySQL
- Laravel Sanctum
- Laravel Socialite
- REST JSON API

## Current API Endpoints

```http
GET /api/health
```

Response:

```json
{
  "status": "ok",
  "app": "SnapCircle API"
}
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
composer install
```

### 2. Create Environment File

```bash
cp .env.example .env
```

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

### 3. Generate Application Key

```bash
php artisan key:generate
```

### 4. Configure MySQL Database

Create a MySQL database named `snapcircle`, then update these values in `.env` if needed:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=snapcircle
DB_USERNAME=root
DB_PASSWORD=
```

### 5. Run Migrations

```bash
php artisan migrate
```

### 6. Start Development Server

```bash
php artisan serve
```

The API will be available at:

```txt
http://localhost:8000
```

Health check:

```txt
http://localhost:8000/api/health
```

## Authentication Notes

Laravel Sanctum is installed for API token authentication. Laravel Socialite is installed for Google and Facebook authentication. Authentication routes and controllers will be implemented in a later development step.

## Development Status

- Laravel backend initialized
- REST API routing enabled
- Sanctum installed
- Socialite installed
- MySQL environment example configured
- Health check endpoint added

No frontend code or advanced social media features have been implemented yet.
