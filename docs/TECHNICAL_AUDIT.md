# SnapCircle Technical Audit

## 1. Current Project Overview

SnapCircle is a Flutter and Laravel social media mobile application. The Flutter app provides the mobile experience, while the Laravel REST API handles authentication, profiles, posts, image uploads, likes, comments, follows, and user search. The project is still suitable for an academic assignment, but it now has enough structure to begin evolving into a maintainable startup-style product.

The current architecture is a monorepo:

- `backend/` contains the Laravel API.
- `frontend/` contains the Flutter mobile app.
- `docs/` contains setup, testing, API, assignment, submission, Postman, screenshot, and audit documentation.

## 2. Current Features

- Social authentication with Google and Facebook through Laravel Socialite.
- Laravel Sanctum API token authentication.
- Development/demo authentication endpoint.
- Authenticated feed with paginated posts.
- Create, view, update, and soft delete posts.
- Image upload support for posts.
- Like and unlike posts with duplicate prevention.
- Create, list, update, and soft delete comments.
- User profiles with avatar and bio.
- Profile update with avatar upload.
- Search users.
- Follow and unfollow users.
- Followers and following lists.
- API documentation, setup guide, testing checklist, assignment report, submission guide, and Postman collection.

## 3. Backend Review

| Area | Review |
|---|---|
| Route organization | `backend/routes/api.php` separates public routes from Sanctum-protected routes. The file is readable at the current size, but future features should use clearer grouped sections or route files if it grows. |
| Controllers | API controllers are organized by feature: auth, posts, comments, likes, follows, and profile. They are mostly small and readable. Inline authorization exists and should later move to policies. |
| Validation | Create/update post, comment, and profile flows use form request classes. This is a good foundation. Future complex features should continue this pattern. |
| Resources | `PostResource`, `CommentResource`, and `UserResource` keep API output consistent and prevent exposing raw model internals. |
| Models | Models define relationships for users, posts, comments, likes, and follows. Fillable fields and soft deletes are used where appropriate. |
| Migrations | Core social tables exist: users, posts, comments, likes, follows, Sanctum tokens, jobs, cache. Unique constraints exist for likes and follows. |
| Authentication | Sanctum protects private API routes. Socialite supports Google and Facebook token-based login. |
| Authorization | Users are blocked from editing or deleting posts/comments they do not own. Policies are not yet implemented, which is acceptable for MVP but less scalable. |
| Testing | Feature tests cover health, auth, posts, comments, likes, follows, and profile behavior. |
| Response consistency | `ApiResponse` standardizes success/error responses. Phase 1 now also centralizes paginated responses. |

## 4. Frontend Review

| Area | Review |
|---|---|
| Folder structure | `frontend/lib` is organized into `core`, `features`, and `routes`, which is a good feature-based structure. |
| Routing | `go_router` centralizes navigation in `lib/routes/app_router.dart`. |
| Providers | Provider classes manage state for auth, feed, comments, profile, and users. This keeps business state out of widgets. |
| Repositories | API calls live in repositories, keeping network code separate from UI screens. |
| Models | Dart models parse API responses for auth, posts, comments, and users. |
| Reusable widgets | Core widgets exist for buttons, text fields, cards, avatars, empty states, error states, loading states, and section headers. |
| Theme | The app has centralized theme and color constants. This is a good base for Phase 2 UI work. |
| Error handling | Dio errors are normalized in `ApiClient`, and UI flows show readable messages. |
| Loading/empty states | Reusable views exist, but some screens can still use more contextual empty and retry states. |
| UI consistency | The app is clean for an MVP, but spacing, card hierarchy, feed polish, and profile presentation should be improved in the next phase. |

## 5. Security Review

| Check | Status |
|---|---|
| `.env` ignored | Root `.gitignore` ignores `.env`, `.env.*`, `backend/.env`, and `backend/.env.*`, while allowing `.env.example`. |
| Tokens stored securely | Flutter uses secure token storage through `flutter_secure_storage`. |
| Protected routes | Private API routes are wrapped in `auth:sanctum`. |
| Ownership checks | Users cannot edit or delete posts/comments owned by other users. |
| Social login secrets | OAuth placeholders are in `.env.example`; real credentials should stay in local `.env` files only. |
| Upload validation | Post and profile image uploads are validated by request classes. |

Security concerns to address later:

- Disable or protect demo login before production.
- Add rate limiting for auth, comments, likes, follows, and future chat endpoints.
- Move inline authorization into Laravel policies.
- Review CORS and production session/cookie settings before deployment.

## 6. Performance Review

| Area | Status |
|---|---|
| Pagination | Posts, comments, users, followers, and following lists are paginated. |
| Eager loading | Feed-style endpoints use eager loading and counts to reduce N+1 risk. |
| Image loading/caching | Flutter uses `cached_network_image` for network images. |
| Indexes | Unique constraints exist for likes and follows. More performance indexes should be added later for feed and discovery queries. |
| Repeated API calls | Current flows are acceptable for MVP. Future infinite scroll, polling, and notifications need careful throttling. |
| Provider rebuild risks | Provider usage is clean enough for the current scope. Later UI polish should watch for large widgets rebuilding unnecessarily. |

Recommended future indexes:

- `posts.user_id`
- `posts.created_at`
- `comments.post_id`
- `comments.created_at`
- `likes.post_id`
- `follows.follower_id`
- `follows.following_id`

## 7. UI/UX Review

- Design consistency is improving through shared colors, theme, and core widgets.
- Navigation is understandable and centralized.
- Empty, loading, and error views exist but can become more contextual.
- Feed and profile screens need stronger visual hierarchy and more polished social app patterns.
- Login and social authentication screens should feel more branded.
- Post cards should eventually support richer actions such as save, share, and post detail navigation.
- Profile screens should later include cover image, username, joined date, website, location, and profile post layout.

## 8. Testing Review

Current strengths:

- Backend feature tests cover major API flows.
- `php artisan route:list` verifies route registration.
- `php artisan test` verifies backend behavior.
- `flutter analyze` verifies frontend static analysis.
- `docs/TESTING_CHECKLIST.md` supports manual assignment testing.

Missing or future test areas:

- More negative auth tests for social token failures.
- Rate limit tests after rate limiting is added.
- Backend policy tests after policies are introduced.
- Flutter widget tests for login, post card, profile, empty/error/loading views, and comments.
- Provider tests for feed, comments, profile, and auth state transitions.

## 9. Issues Found

| Priority | Area | Issue | Recommended Fix |
|---|---|---|---|
| High | Security | Demo login exists and is useful for testing, but unsafe for production if left public. | Disable in production or protect behind an environment flag before deployment. |
| High | Security | Auth and high-frequency social endpoints do not yet have explicit rate limiting. | Add route rate limiters for auth, comments, likes, follows, and future messaging. |
| Medium | Authorization | Post/comment ownership checks are inline in controllers. | Add `PostPolicy` and `CommentPolicy` in a security hardening phase. |
| Medium | Performance | Additional feed and relationship indexes are not fully defined yet. | Add safe indexes before advanced feed, explore, notifications, and chat features. |
| Medium | Frontend | API base URL is local-development focused. | Add environment switching for development, staging, and production. |
| Medium | Testing | Flutter widget/provider test coverage is still minimal. | Add focused widget/provider tests for core screens and state flows. |
| Low | UI/UX | MVP screens need stronger polish, empty states, and profile/feed hierarchy. | Continue with Phase 2 UI/UX redesign system. |
| Low | Documentation | Production deployment guidance is not complete yet. | Add a deployment guide in a later production-preparation phase. |

## 10. Safe Refactoring Plan

Safe improvements completed or appropriate for Phase 1:

- Keep the existing route names and API paths unchanged.
- Keep current authentication flow unchanged.
- Centralize duplicated paginated response formatting in `ApiResponse::paginated()`.
- Preserve the existing paginated JSON shape with collection data, `meta`, and `links`.
- Verify `.gitignore` protects environment files, dependencies, build outputs, IDE files, OS files, and generated caches.
- Add this technical audit as startup-quality documentation.
- Link the audit from the root README.

Safe improvements deferred to later phases:

- Route grouping refinements after more APIs are added.
- Policies for post/comment authorization.
- Rate limiting.
- More indexes.
- More widget/provider tests.
- Frontend environment switching.

## 11. Long-Term Roadmap

Recommended next phases:

1. UI/UX redesign system.
2. Better feed experience.
3. Save posts.
4. Notifications.
5. Chat.
6. Stories.
7. Explore.
8. Settings.
9. Security hardening.
10. Performance optimization.
11. Deployment preparation.

Phase 1 status: complete. The project has been audited, the documentation has been updated, and only a safe backend pagination-response refactor was applied.
