# SnapCircle Performance Audit

## Current Performance Strengths

- Paginated APIs for feed, comments, profile posts, saved posts, notifications, conversations, messages, stories, and explore lists.
- API resources keep response formatting consistent between endpoints.
- Eager loading is already used on core relationships such as post users, notification actors, conversation participants, latest messages, and story users.
- Cached network images are used in Flutter for feed images, avatars, profile covers, stories, explore grids, notifications, and conversations.
- Secure token storage avoids repeated login state work and keeps authenticated API calls centralized through `ApiClient`.
- Feature-based frontend structure keeps screens, providers, repositories, widgets, and models separated.

## Performance Risks Found

| Priority | Area | Risk | Recommended Fix |
|---|---|---|---|
| High | Database indexes | Timeline, notification, message, and profile queries can slow down as tables grow. | Add missing created/read/user composite indexes and keep future query plans monitored. |
| High | Pagination | Some endpoints used local hardcoded page sizes and rejected large `per_page` values instead of clamping. | Centralize pagination defaults and cap all large requests at the configured maximum. |
| High | API resources | Resource fallback counts and follow checks can create extra queries when a controller forgets `withCount` or `withExists`. | Preload counts/existence flags in controllers and keep resource fallbacks only for single-record safety. |
| Medium | N+1 query risks | User settings and nested user data can be queried repeatedly in list resources. | Eager load `setting` on user lists and nested actor/sender/participant resources. |
| Medium | Media file size | Full-size images can be uploaded from mobile devices. | Compress avatar, cover, post, and story images before upload with safe fallback. |
| Medium | Repeated API calls | Search and feed refresh flows can repeat quickly. | Keep debounce for search and ensure fetch calls live in `initState` or explicit actions. |
| Medium | Notification/feed polling | Polling can waste requests if multiple timers run or if the app is logged out. | Keep one timer per provider, stop timers on dispose/logout, and document intervals. |
| Medium | Provider rebuilds | Large screens can rebuild when broad provider watches change. | Use smaller Consumers/Selectors when screens grow; avoid API calls inside `build()`. |
| Low | Image loading | Network image failures can cause blank UI or layout shift. | Continue using cached images with placeholders, fixed aspect ratios, and friendly error states. |
| Low | Large widget trees | Feed and profile screens can grow as features expand. | Keep reusable widgets small and use skeletons for initial loading only. |

## Improvements Applied

- Added `config/snapcircle.php` with default and maximum pagination limits.
- Added `App\Support\Pagination` to clamp `per_page` consistently.
- Added a reversible performance index migration for timeline, notification, story, conversation, and message queries.
- Updated feed, comments, profile, follow, saved posts, notifications, conversations, messages, stories, and explore endpoints to use shared pagination limits.
- Added eager loading for user settings and nested user resources where list responses include users.
- Kept response shapes backward compatible while reducing avoidable resource queries.
- Added query-safety tests for paginated feed, explore posts, profile posts, notifications, messages, and stories.
- Documented caching as future work for auth-sensitive feeds where user-specific flags require careful cache keys.

## Future Performance Roadmap

- Redis cache for low-risk public metadata and carefully keyed user-specific counters.
- Queues for notifications, media processing, emails, and push notifications.
- CDN/object storage for media files instead of local public storage.
- WebSockets for real-time feed, notifications, and chat instead of polling.
- Image thumbnails and responsive variants for feed, profile, and story media.
- Database query monitoring for slow queries and missing index detection.
- Laravel Telescope in local development for request, query, and job inspection.
- Production logs/metrics for latency, error rates, queue depth, and database health.
