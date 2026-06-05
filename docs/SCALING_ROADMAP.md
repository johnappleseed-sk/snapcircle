# SnapCircle Scaling Roadmap

## Redis Caching

Use Redis for short-lived public metadata, feed counters, unread counts, and rate-limit backing storage. User-specific cache keys must include the user id and any filters that affect response flags.

## Queue Workers

Move notification fanout, email delivery, push notification dispatch, and media processing to Laravel queues. Run workers with Supervisor or a managed worker service in production.

## Object Storage/CDN

Store avatars, covers, posts, and stories in S3-compatible object storage. Serve media through a CDN with cache headers and responsive image variants.

## Background Jobs

Generate thumbnails, remove expired stories, clean temporary uploads, and aggregate trend scores in background jobs instead of request cycles.

## WebSockets

Replace polling for notifications, feed status, comments, and chat with WebSockets when the app needs true real-time behavior.

## Database Monitoring

Track slow queries, index usage, connection count, lock waits, and table growth. Use Laravel Telescope locally and production-safe monitoring in deployed environments.

## API Metrics

Measure latency, error rates, request volume, cache hit rate, and per-endpoint throughput.

## Load Testing

Run repeatable load tests for authentication, feed, explore, notifications, and chat before production releases.

## Horizontal Scaling

Keep the API stateless with Sanctum tokens, external cache/session stores, shared object storage, and queue-backed background work so multiple app servers can run safely.

## Push Notifications

Use a queue-backed push notification service for mobile notifications instead of sending push work inside user request handlers.
