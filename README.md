# SnapCircle

SnapCircle is a full-stack social media mobile application created as an assignment project. The app will allow users to sign in with Google or Facebook, create profiles, share posts, upload images, like and comment on posts, and follow other users.

This repository is currently initialized as a clean monorepo structure only. Flutter and Laravel application code will be added later.

## Project Purpose

The purpose of SnapCircle is to demonstrate the design and development of a modern social media mobile application using a Flutter frontend and a Laravel REST API backend. The project is planned to include secure authentication, user profile management, post creation, image uploads, social interactions, and a personalized feed.

## Tech Stack

- Flutter for the mobile frontend
- Laravel for the backend REST API
- MySQL for the database
- Laravel Sanctum for API authentication
- Laravel Socialite for Google and Facebook authentication
- Google Authentication
- Facebook Authentication

## Planned Features

- Sign in with Google
- Sign in with Facebook
- User registration and authentication
- User profiles
- Create, edit, and delete posts
- Upload images for posts
- Like and unlike posts
- Comment on posts
- Follow and unfollow users
- Social media feed
- REST API for mobile app communication

## Folder Structure

```txt
snapcircle/
|-- frontend/       # Flutter mobile app will be created here later
|-- backend/        # Laravel backend API will be created here later
|-- docs/           # Documentation, diagrams, screenshots
|-- README.md
`-- .gitignore
```

## Setup Instructions

### Backend Setup

Backend setup instructions will be added after the Laravel REST API is created in the `backend/` directory.

Planned backend setup steps:

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

### Frontend Setup

Frontend setup instructions will be added after the Flutter mobile application is created in the `frontend/` directory.

Planned frontend setup steps:

```bash
cd frontend
flutter pub get
flutter run
```

## Current Status

The project currently contains only the initial monorepo folder structure and documentation. No Laravel or Flutter application code has been added yet.
