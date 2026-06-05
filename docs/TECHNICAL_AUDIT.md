# SnapCircle Technical Audit

## Purpose

This audit records the current state of SnapCircle before larger startup-focused improvements. The goal of Phase 1 is to understand the existing architecture, preserve stable behavior, and make only small refactors that reduce duplication without changing the API or mobile app feature set.

## Current Features

- Laravel REST API with Sanctum token authentication.
- Social login foundation for Google and Facebook through Laravel Socialite.
- Demo login endpoint for development and testing.
- Authenticated profile viewing and profile update with avatar upload.
- User search and public user profile API.
- Follow and unfollow users with follower/following lists.
- Post feed with pagination, search, images, counts, and `liked_by_me`.
- Create, view, update, soft delete posts.
- Create, list, update, and soft delete comments.
- Like and unlike posts with duplicate prevention.
- Flutter mobile app using Provider, Dio, GoRouter, and feature-based folders.
- Reusable Flutter theme, constants, buttons, cards, avatars, loading, empty, and error views.
- Backend feature tests for auth, health, posts, comments, likes, follows, and profile APIs.

## Backend Structure Review

The backend is organized around standard Laravel conventions:

- `routes/api.php` contains public and Sanctum-protected API routes.
- `app/Http/Controllers/Api` contains controllers for auth, posts, comments, likes, follows, and profiles.
- `app/Http/Requests` contains reusable validation request classes.
- `app/Http/Resources` contains JSON resource transformers.
- `app/Helpers/ApiResponse.php` centralizes the API success/error response format.
- `app/Models` contains the social domain models and relationships.
- `tests/Feature` covers the main API behavior.

Strengths:

- Existing features are covered by feature tests.
- Controllers use API resources and form requests in important write paths.
- Soft deletes are used for user-generated posts and comments.
- API responses are consistently shaped with `success`, `message`, and `data` or `errors`.
- Eager loading and count loading are already used in feed-style endpoints.

Areas to improve later:

- Authorization checks are currently mostly inline controller checks; policies would scale better.
- Route files are still manageable, but route grouping can be clearer as more features arrive.
- Pagination response metadata was duplicated across several controllers before this phase.
- File upload validation is present, but production hardening should add image scanning and stricter storage notes.
- Some counts are computed with relationship queries after writes; this is safe now but should be reviewed under higher traffic.

## Frontend Structure Review

The Flutter app uses a feature-based layout:

- `lib/core` contains API client, configuration, constants, theme, storage, utilities, and shared widgets.
- `lib/features/auth` contains authentication models, repository, provider, and screens.
- `lib/features/feed` contains feed repository, provider, model, screen, and post card widget.
- `lib/features/comments` contains comment API, provider, model, screen, and comment tile.
- `lib/features/profile` contains profile repository, provider, and profile-related screens.
- `lib/features/search` contains user search provider, screen, and user tile.
- `lib/routes/app_router.dart` centralizes navigation.

Strengths:

- Feature folders keep the app understandable.
- Provider state is separated from repositories and screens.
- Dio errors are normalized in one API client.
- Shared widgets and constants already exist for a design system foundation.
- API endpoints are centralized instead of hardcoded across screens.

Areas to improve later:

- Some widgets still duplicate layout patterns that could move into shared components.
- Feed, comments, and profile flows can use richer loading, empty, and retry states.
- The app currently uses a local development API base URL; future phases should add environment switching for staging and production.
- Large screens should continue being split into smaller widgets as product features grow.
- Widget tests are minimal and should expand around core social interactions.

## Security Concerns

- OAuth secrets must remain in `.env` only and must never be committed.
- Demo authentication is useful for development, but production deployment should disable or strongly protect it.
- Auth, comments, likes, follows, and profile update endpoints should receive rate limiting before real users.
- Inline authorization should be replaced with policies for posts and comments.
- User resources should continue avoiding sensitive fields such as tokens, password hashes, and provider internals.
- Uploads should remain size/type validated, and production deployments should use safe public storage configuration.
- CORS configuration should be reviewed before deployment.

## UI/UX Issues

- The UI foundation is clean, but screens still feel closer to an MVP than a polished social product.
- Feed interactions need pull-to-refresh, infinite loading polish, and stronger visual hierarchy.
- Post cards should eventually include clearer ownership actions, share/save placeholders, and better media treatment.
- Empty and error states exist, but some flows can use more contextual copy and actions.
- Profile screens need richer headers, cover image support, joined date, and follower previews in later phases.

## Performance Issues

- Feed endpoints use eager loading and counts, which is good for the current scope.
- Future growth will require database indexes on high-traffic columns such as `posts.created_at`, `comments.post_id`, `likes.post_id`, and follow columns.
- Pagination exists for core list endpoints, but infinite scroll and caching are not fully developed on mobile.
- Image loading uses caching on the Flutter side, but upload compression and backend media processing are future work.
- Notification, messaging, and story features should be designed with pagination from the beginning.

## Safe Refactors Applied In Phase 1

- Added `ApiResponse::paginated()` to centralize paginated API response formatting.
- Updated post, comment, user search, followers, and following list endpoints to reuse the shared pagination helper.
- Preserved existing response shape:
  - collection key such as `posts`, `comments`, or `users`
  - `meta.current_page`
  - `meta.last_page`
  - `meta.per_page`
  - `meta.total`
  - `links.first`
  - `links.last`
  - `links.prev`
  - `links.next`

No API paths, request bodies, resource fields, or Flutter screens were changed in this phase.

## Recommended Improvements

1. Add backend policies for posts, comments, and future resources.
2. Add rate limiting to auth and high-frequency social actions.
3. Expand Flutter widget tests for shared widgets and social screens.
4. Add frontend environment switching for development, staging, and production API URLs.
5. Improve feed UX with tabs, pull-to-refresh, infinite scroll, and skeleton loading.
6. Add saved posts before notifications because save/share is lower-risk and improves product usefulness.
7. Add database indexes before heavier discovery, notifications, and messaging features.
8. Document production deployment and CORS/storage configuration before hosting.

## Development Roadmap

1. Phase 2: UI/UX redesign system and screen polish.
2. Phase 3: Better feed modes and post detail experience.
3. Phase 4: Save and share posts.
4. Phase 5: Notifications.
5. Phase 6: Near-real-time refresh strategy.
6. Phase 7: Messaging MVP.
7. Phase 8: Stories.
8. Phase 9: Explore and discovery.
9. Phase 10: Profile improvements.
10. Phase 11: Settings and account management.
11. Phase 12: Security hardening.
12. Phase 13: Performance improvements.
13. Phase 14: Admin and moderation foundation.
14. Phase 15: Production deployment preparation.
15. Phase 16: Testing and quality system.
16. Phase 17: Product documentation.
17. Phase 18: Branding and startup polish.

## Phase 1 Status

Phase 1 is intentionally small and stable. The project is ready to proceed to Phase 2 after backend tests and Flutter analysis pass.
