# SnapCircle Setup Guide

This guide explains how to run the Laravel backend and Flutter frontend locally.

## Backend Setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

Configure MySQL in `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=snapcircle
DB_USERNAME=root
DB_PASSWORD=
```

Create the database:

```sql
CREATE DATABASE snapcircle;
```

Run migrations and seeders:

```bash
php artisan migrate --seed
```

Create the public storage link:

```bash
php artisan storage:link
```

Start the Laravel server:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

## Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

Check the API base URL in:

```txt
frontend/lib/core/constants/app_config.dart
```

Android emulator:

```txt
http://10.0.2.2:8000/api
```

iOS simulator:

```txt
http://127.0.0.1:8000/api
```

Real device on the same Wi-Fi:

```txt
http://YOUR_COMPUTER_LAN_IP:8000/api
```

You can override the API URL at runtime without editing source:

```bash
flutter run --dart-define=SNAPCIRCLE_API_BASE_URL=http://192.168.1.25:8000/api
```

## Test Commands

Backend:

```bash
cd backend
php artisan route:list
php artisan test
```

Frontend:

```bash
cd frontend
flutter analyze
flutter test --no-pub
```
