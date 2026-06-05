# SnapCircle Real-Time Roadmap

SnapCircle Phase 6 uses lightweight polling as a safe first step toward real-time behavior.

## Current Polling Approach

- `GET /api/feed/status` checks latest post metadata, total posts, and unread notification count.
- `GET /api/posts/{post}/comments/status` checks latest comment metadata and comment totals.
- Flutter polls feed status every 45 seconds.
- Flutter polls comment status every 30 seconds only while the comments screen is open.
- The UI shows refresh banners instead of auto-reloading content while users are reading.

## Limitations of Polling

- Updates are delayed until the next poll interval.
- Polling still creates background HTTP traffic.
- Polling does not support instant push delivery.
- Polling is less efficient for high-scale real-time conversations.

## Future WebSocket Approach

A production real-time version can broadcast events when posts, comments, likes, follows, and notifications are created. The Flutter app can subscribe to authenticated channels and update local state immediately.

Possible technologies:

- Laravel Broadcasting
- Laravel Reverb
- Pusher
- Firebase Cloud Messaging

## Recommended Upgrade Order

1. Notification push updates
2. Chat real-time messages
3. Live comments
4. Live feed updates
