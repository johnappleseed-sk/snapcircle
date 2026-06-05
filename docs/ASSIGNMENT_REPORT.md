# SnapCircle Assignment Report

## Cover Page

**Project Title:** SnapCircle - Flutter and Laravel Social Media Mobile Application  
**Project Type:** Full-stack mobile application  
**Frontend:** Flutter  
**Backend:** Laravel REST API  
**Database:** MySQL  
**Authentication:** Laravel Sanctum, Laravel Socialite, Google, Facebook  

## Abstract

SnapCircle is a social media mobile application developed as an academic assignment project. The application allows users to authenticate using Google or Facebook, create user profiles, publish posts with optional images, like posts, comment on posts, follow other users, and browse a social feed. The project demonstrates full-stack mobile application development using Flutter for the mobile interface and Laravel for the REST API backend.

## Introduction

Modern social applications require secure authentication, structured content management, responsive mobile interfaces, and reliable backend APIs. SnapCircle was created to demonstrate these concepts in a clean and maintainable full-stack project. The Flutter application communicates with the Laravel backend using HTTP requests, and Laravel returns JSON responses that the mobile app can render.

## Problem Statement

Many beginner social media projects are built as isolated frontend or backend systems. This project addresses the challenge of connecting a mobile client to a secure API backend with proper authentication, database relationships, and maintainable project structure.

## Objectives

- Build a Flutter mobile application with a clean feature-based architecture.
- Build a Laravel REST API with structured models, migrations, and controllers.
- Implement social login support using Google and Facebook.
- Use Laravel Sanctum for protected API requests.
- Store relational social media data in MySQL.
- Prepare clear documentation for setup, testing, and submission.

## Scope of the Project

The project includes authentication, profile management, posts, image uploads, likes, comments, following, search, and a social feed. The project is designed for academic demonstration and local development. Production deployment, payment systems, notifications, chat, and advanced moderation are outside the current scope.

## Technology Used

| Area | Technology |
| --- | --- |
| Mobile app | Flutter, Dart |
| State management | Provider |
| HTTP client | Dio |
| Token storage | flutter_secure_storage |
| Image loading | cached_network_image |
| Image picking | image_picker |
| Routing | go_router |
| Backend | Laravel |
| Database | MySQL |
| Authentication | Laravel Sanctum, Laravel Socialite |
| Social providers | Google, Facebook |

## System Architecture

```txt
Flutter Mobile App
        |
        v
REST API JSON
        |
        v
Laravel Backend
        |
        v
Eloquent ORM
        |
        v
MySQL Database
```

Flutter communicates with Laravel using HTTP requests. Laravel processes each request through routes, controllers, validation, models, and services. Laravel then returns JSON responses to Flutter. Database operations are handled through Eloquent ORM, which maps Laravel models to MySQL tables.

## Database Design

### users

Purpose: Stores user accounts and social authentication details.

Important fields:

- `id`
- `name`
- `email`
- `password`
- `avatar`
- `bio`
- `provider`
- `provider_id`

Relationships:

- A user has many posts.
- A user has many comments.
- A user has many likes.
- A user can follow many users.
- A user can be followed by many users.

### posts

Purpose: Stores user-created social feed posts.

Important fields:

- `id`
- `user_id`
- `content`
- `image_path`
- `deleted_at`

Relationships:

- A post belongs to one user.
- A post has many comments.
- A post has many likes.

### comments

Purpose: Stores comments written by users on posts.

Important fields:

- `id`
- `user_id`
- `post_id`
- `comment`
- `deleted_at`

Relationships:

- A comment belongs to one user.
- A comment belongs to one post.

### likes

Purpose: Stores post likes.

Important fields:

- `id`
- `user_id`
- `post_id`

Relationships:

- A like belongs to one user.
- A like belongs to one post.
- A unique constraint prevents duplicate likes by the same user on the same post.

### follows

Purpose: Stores follow relationships between users.

Important fields:

- `id`
- `follower_id`
- `following_id`

Relationships:

- `follower_id` references the user who follows.
- `following_id` references the user being followed.
- A unique constraint prevents duplicate follows.

## API Design

| Feature | Method | Endpoint | Description |
| --- | --- | --- | --- |
| Authentication | POST | `/api/auth/google` | Login with Google access token |
| Authentication | POST | `/api/auth/facebook` | Login with Facebook access token |
| Authentication | POST | `/api/logout` | Revoke current token |
| Profile | GET | `/api/profile` | Get current user profile |
| Profile | PUT | `/api/profile` | Update current user profile |
| Posts | GET | `/api/posts` | List paginated feed posts |
| Posts | POST | `/api/posts` | Create a new post |
| Posts | DELETE | `/api/posts/{post}` | Delete own post |
| Likes | POST | `/api/posts/{post}/like` | Like a post |
| Likes | DELETE | `/api/posts/{post}/like` | Unlike a post |
| Comments | GET | `/api/posts/{post}/comments` | List post comments |
| Comments | POST | `/api/posts/{post}/comments` | Add a comment |
| Follow | POST | `/api/users/{user}/follow` | Follow a user |
| Follow | DELETE | `/api/users/{user}/follow` | Unfollow a user |

## Mobile App Design

The Flutter mobile application uses a feature-based folder structure. Core services such as API client, token storage, theme, constants, and reusable widgets are placed under `lib/core`. Features such as authentication, feed, posts, comments, profile, and search are separated under `lib/features`.

The UI uses Material 3, rounded cards, consistent spacing, reusable buttons, avatar components, loading states, error states, and empty states.

## Authentication Flow

1. User taps Google or Facebook login in Flutter.
2. Flutter receives social access token.
3. Flutter sends access token to Laravel API.
4. Laravel verifies the social token using Socialite.
5. Laravel finds or creates the user.
6. Laravel creates Sanctum API token.
7. Flutter stores token securely.
8. Flutter uses token for protected API requests.

## Main Features

- Social login with Google and Facebook
- Secure API token authentication
- User profile viewing and editing
- Feed listing
- Post creation with optional images
- Like and unlike posts
- Comment creation, editing, and deletion
- Follow and unfollow users
- User search
- Followers and following lists

## Testing

Backend testing uses Laravel feature tests for authentication, posts, comments, likes, profiles, and follows. Frontend testing uses Flutter analysis and widget tests. Manual testing should be completed using the testing checklist before submission.

## Challenges

- Coordinating social authentication between Flutter and Laravel.
- Designing reusable API response formats.
- Managing protected routes with Sanctum tokens.
- Handling image uploads and public storage paths.
- Maintaining clean project structure across frontend and backend.

## Conclusion

SnapCircle demonstrates a complete full-stack mobile application foundation. The project combines Flutter, Laravel, MySQL, Sanctum, and Socialite to provide a maintainable social media application suitable for academic submission and future feature expansion.

## References

- Flutter documentation: https://docs.flutter.dev
- Laravel documentation: https://laravel.com/docs
- Laravel Sanctum documentation: https://laravel.com/docs/sanctum
- Laravel Socialite documentation: https://laravel.com/docs/socialite
- MySQL documentation: https://dev.mysql.com/doc/
