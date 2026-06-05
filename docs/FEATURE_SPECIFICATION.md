# SnapCircle Feature Specification

This document describes product-facing SnapCircle features as the project evolves from assignment MVP into a startup-ready social app.

## Better Feed Experience

### Goal

Make the feed more useful, navigable, and engaging without breaking the existing posts API or Flutter integrations.

### Feed Modes

| Feed | API Mode | Description |
|---|---|---|
| For You | `all` | Shows latest posts from all users. |
| Following | `following` | Shows posts from users followed by the authenticated user, plus the user's own posts. |
| Popular | `popular` | Shows posts ordered by likes count, comments count, then latest. |
| My Posts | `mine` | Shows only posts created by the authenticated user. |

### API

Endpoint:

```http
GET /api/posts
```

Query parameters:

```txt
mode      all | following | popular | mine
search    optional keyword
page      optional page number
per_page  optional page size
```

Example:

```http
GET /api/posts?mode=following&page=1&per_page=10
```

Response includes:

- post id
- content
- image URL
- author user
- likes count
- comments count
- liked by me
- owner state
- update/delete permission flags
- pagination metadata

### Flutter UI

The home feed includes:

- Feed mode selector chips.
- Post search field.
- Pull to refresh.
- Load more pagination.
- Skeleton loading cards.
- Mode-specific empty states.
- Post detail navigation.

### Post Detail Screen

Route:

```txt
/posts/{postId}
```

The post detail screen:

- Loads a single post if it is not already in the feed cache.
- Reuses the polished `PostCard` layout.
- Supports like/unlike through the existing feed provider.
- Shows a button to open comments.
- Allows owners to delete their post and navigate back safely.

### Empty States

| Context | Title | Subtitle |
|---|---|---|
| For You | No posts yet. | Follow people or create your first post. |
| Following | No posts from people you follow. | Find users to follow and build your circle. |
| Popular | No popular posts yet. | Like and comment on posts to make them trend. |
| Mine | You have not posted yet. | Share your first SnapCircle moment. |
| Search | No posts found. | Try a different keyword. |

## Save and Share Posts

### Purpose

Let users keep posts for later and share interesting posts outside SnapCircle.

### Backend Endpoints

```http
POST /api/posts/{post}/save
DELETE /api/posts/{post}/save
GET /api/saved-posts
```

### Backend Behavior

- Saving a post creates a unique `saved_posts` record for the authenticated user and post.
- Duplicate saves are prevented.
- Unsaving a post removes the saved record if it exists.
- Saved posts are returned latest saved first.
- Post resources include `saves_count` and `saved_by_me`.

### Frontend Screens

- Feed post cards include Save and Share actions.
- Saved posts can be opened from the feed app bar.
- Profile includes a Saved Posts card.
- Saved Posts screen shows saved posts with loading, empty, error, pull-to-refresh, and load-more states.

### User Flow

1. User opens the feed.
2. User taps the bookmark icon on a post.
3. The post is saved and the saves count updates.
4. User opens Saved Posts from the feed app bar or Profile screen.
5. User can revisit, open, comment on, share, or unsave posts.

### Sharing

Sharing is handled in Flutter using `share_plus`.

Example share text:

```txt
Check out this post on SnapCircle: {content}
```

If a post has no text content:

```txt
Check out this post on SnapCircle.
```

### Testing Notes

- Save a post from the feed and confirm the bookmark state changes.
- Save the same post again and confirm no duplicate saved record is created.
- Open Saved Posts and confirm the saved post appears.
- Unsave from Saved Posts and confirm it is removed from the list.
- Share a post and confirm the platform share sheet opens.

## Notifications System

### Purpose

Notify users when other people interact with their SnapCircle content or follow them.

### Notification Types

| Type | Trigger | Receiver |
|---|---|---|
| `post_liked` | Another user likes a post | Post owner |
| `post_commented` | Another user comments on a post | Post owner |
| `user_followed` | Another user follows a profile | Followed user |

### Backend Database Design

The `notifications` table stores:

- receiver user id
- actor user id
- notification type
- optional post id
- optional comment id
- data JSON for previews
- read timestamp
- timestamps

### Backend Triggers

Notifications are created through `NotificationService` from:

- `LikeController`
- `CommentController`
- `FollowController`

The service prevents self-notifications and avoids duplicate unread like/follow notifications where useful.

### Frontend Screen

The Flutter app includes a Notifications screen with:

- All, Unread, and Read filters
- pull to refresh
- load more
- mark all as read
- delete notification
- tap-to-open related post or user profile

### Unread Badge

The home feed app bar displays a notification icon with an unread badge count from:

```http
GET /api/notifications/unread-count
```

### Testing Notes

- Like another user's post and confirm they receive a notification.
- Comment on another user's post and confirm they receive a notification.
- Follow another user and confirm they receive a notification.
- Open the notification list and mark one notification as read.
- Mark all notifications as read and confirm the badge clears.
- Delete a notification and confirm it disappears from the list.
