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

## Near Real-Time Updates

### Purpose

Make SnapCircle feel more alive without introducing a full WebSocket stack yet. Phase 6 uses lightweight polling for feed status, comment status, and notification unread counts.

### Polling Strategy

The app polls small status endpoints instead of repeatedly fetching full feeds or full comment lists.

| Area | Endpoint | Interval | UI Behavior |
|---|---|---:|---|
| Feed status | `GET /api/feed/status` | 45 seconds | Shows a "New posts available" banner when newer posts exist. |
| Notifications | `GET /api/feed/status` | 45 seconds | Updates the unread notification badge from the same lightweight response. |
| Comments status | `GET /api/posts/{post}/comments/status` | 30 seconds | Shows a "New comments available" banner while the comments screen is open. |

The feed and comments do not auto-refresh while the user is reading. Users choose when to refresh from the banner.

### Backend Status Endpoints

```http
GET /api/feed/status
GET /api/posts/{post}/comments/status
```

Both routes are protected by Laravel Sanctum and return counts plus latest record metadata only.

### Future WebSocket Upgrade Plan

This phase uses lightweight polling instead of WebSockets. In future production versions, Laravel Broadcasting, Laravel Reverb, Pusher, or Firebase Cloud Messaging can be used for real-time updates.

## Messaging / Chat MVP

### Purpose

Allow users to start private one-to-one conversations and exchange direct messages through the existing Laravel REST API and Flutter app.

### Database Tables

- `conversations`: shared conversation record.
- `conversation_user`: participants in each conversation.
- `messages`: message text, sender, read timestamp, and conversation relationship.

### Backend Endpoints

```http
GET /api/conversations
POST /api/conversations
GET /api/conversations/{conversation}
GET /api/conversations/{conversation}/messages
POST /api/conversations/{conversation}/messages
PUT /api/messages/{message}/read
```

### Frontend Screens

- Conversations screen at `/messages`
- Chat detail screen at `/messages/{conversationId}`
- Message button on other users' profiles
- Messages icon in the home feed app bar

### User Flow

1. User opens another user's profile.
2. User taps Message.
3. The app starts or reuses a one-to-one conversation.
4. User sends and reads messages in the chat detail screen.
5. The conversations list shows latest message previews and unread badges.

### Limitations

- This MVP uses REST requests, not WebSockets.
- Conversations are one-to-one only.
- Conversation delete/archive is intentionally not implemented yet.
- Message attachments and typing indicators are future work.

### Future Real-Time Upgrade Notes

The REST chat can later be upgraded with Laravel Broadcasting, Laravel Reverb, Pusher, or Firebase Cloud Messaging for live message delivery, push notifications, typing indicators, and read receipt updates.

## Stories Feature MVP

### Purpose

Allow users to share temporary image stories with an optional caption. Stories appear above the home feed and expire after 24 hours.

### Database Tables

- `stories`: owner, uploaded media path, caption, expiry timestamp, and soft delete state.
- `story_views`: unique viewer records for story view tracking.

### Backend Endpoints

```http
GET /api/stories
POST /api/stories
GET /api/stories/{story}
DELETE /api/stories/{story}
POST /api/stories/{story}/view
GET /api/users/{user}/stories
```

### Frontend Screens And Widgets

- `StoriesRow` appears above feed controls.
- `StoryCircle` shows active stories with viewed/unviewed styling.
- `CreateStoryScreen` lets users pick an image, add a caption, and upload.
- `StoryViewerScreen` opens stories full-screen, marks them viewed, and lets owners delete.

### Rules

- Stories expire 24 hours after creation.
- Expired stories are not returned by list, show, or user-story endpoints.
- Each user can view a story once; duplicate view records are prevented.
- Only story owners can delete their stories.

### Testing Notes

- Create a story and confirm it appears in the home stories row.
- Open a story and confirm it becomes viewed.
- Confirm view counts do not increase on duplicate opens by the same user.
- Delete your own story and confirm it disappears.
- Confirm expired stories are hidden.

## Explore and Discovery

### Purpose

Help users discover posts, people, trending content, and recommended accounts inside SnapCircle.

### Backend Endpoints

```http
GET /api/explore/posts
GET /api/explore/users
GET /api/explore/trending-posts
GET /api/explore/recommended-users
GET /api/explore/search
```

### Discovery Surfaces

- Explore posts: latest or popular discoverable posts.
- Trending posts: engagement-ranked posts from a recent window.
- Recommended users: users the authenticated user does not already follow.
- Global search: searches posts and users together.

### Flutter UI

The bottom navigation uses Explore instead of the older Search tab. The old `/search` route still opens the Explore screen.

Explore includes:

- debounced search bar
- recommended users horizontal section
- trending posts horizontal section
- latest/popular sort chips
- post discovery grid
- follow/unfollow from recommended user cards

### Testing Notes

- Open Explore and confirm recommended users, trending posts, and explore posts load.
- Search by post text and by user name.
- Toggle Latest and Popular sorting.
- Follow a recommended user and confirm the card state updates.
- Open a post and a user from Explore.
