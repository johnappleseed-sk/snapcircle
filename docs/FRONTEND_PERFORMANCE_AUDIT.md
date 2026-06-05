# SnapCircle Frontend Performance Audit

## Current Loading Strategy

- Providers own screen data and expose loading, loading-more, error, empty, and pagination state.
- Main screens fetch once from `initState` using post-frame callbacks and refresh from user actions.
- Pull-to-refresh is available on feed, notifications, conversations, saved posts, explore, and profile-related lists.

## Image Caching Usage

- Remote images use `cached_network_image` in feed cards, avatars, profile covers, story UI, explore grid items, recommended user cards, conversations, and notifications.
- Existing widgets use fixed avatar sizes and aspect ratios for post/story/profile media to reduce layout shift.

## Provider Rebuild Risks

- Some large screens still watch broad providers at the screen level.
- Current code avoids API calls directly in `build()`, which prevents repeated network calls during rebuilds.
- Future work should use `Selector` or small `Consumer` sections around badges, loading buttons, and list content when screens become heavier.

## Pagination Usage

- Feed, comments, saved posts, notifications, conversations, messages, stories, explore, profile posts, and follow lists request paginated backend data.
- Load-more actions are guarded by provider state to avoid duplicate requests.
- Backend now clamps oversized `per_page` values so the app cannot accidentally request huge pages.

## Polling Risks

- Feed status and comment status polling use timers.
- Providers already guard against starting duplicate timers and dispose timers when providers are disposed.
- Polling should remain inactive on login screens and be stopped on logout.

## Large Screen/Widget Risks

- Feed and profile screens are the most likely to grow large as features expand.
- Lists should stay item-based with reusable cards and skeletons rather than large monolithic layouts.

## Improvements Applied

- Added `flutter_image_compress`.
- Added `ImageCompressor` helper for avatar, cover, post, and story uploads.
- Compression uses safe defaults and falls back to the original file if compression fails.
- Added reusable lightweight skeleton widgets for users, notifications, conversations, and stories.
- Replaced generic initial loading spinners in several list screens with skeleton placeholders.
- Kept existing cached network image usage and fixed aspect-ratio image layouts.

## Future Improvements

- Use `Selector` for notification badges, loading buttons, and tab-local state where rebuilds become noticeable.
- Add automatic infinite scroll for long lists if the UX needs it.
- Add thumbnail URLs once the backend stores media variants.
- Pause polling using app lifecycle hooks for all near-real-time providers.
- Add request cancellation for search if network traces show stale responses.
