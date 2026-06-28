# SnapCircle Feature List

SnapCircle is a Flutter Android and Laravel REST API social media app built for a university project demo. The features below are grouped for final submission.

## 1. Authentication

- Email registration and login.
- Demo login for presentations.
- Forgot/reset password API flow.
- Google and Facebook login hooks.
- Laravel Sanctum bearer token authentication.
- Secure token storage in Flutter.
- Logout and expired-session handling.

## 2. Feed And Posts

- Home feed with pull-to-refresh and pagination.
- Feed modes including For You, Following, Popular, and Mine.
- Text posts.
- Create, edit, delete, and view post detail.
- Post action menu with permission-aware owner/non-owner actions.
- Share post text/link.

## 3. Media

- Single-image post upload.
- Multiple-image carousel post upload.
- Carousel display in feed and post detail.
- Profile and Explore thumbnails with multiple-image indicators.
- Backend `post_media` records while preserving first-image compatibility.

## 4. Likes, Comments, And Saved Posts

- Like/unlike posts.
- Comment list with loading, empty, error, and pagination states.
- Create comments.
- Edit/delete own comments.
- Report comments.
- Save/unsave posts.
- Saved Posts screen.

## 5. Profiles And Follow System

- Own profile and user profile screens.
- Edit profile with avatar, cover image, bio, location, website, and privacy state.
- Profile stats for posts, followers, and following.
- Follow/unfollow users.
- Followers and following lists.
- Private accounts and follow requests.
- Follow request approval/rejection.

## 6. Explore And Search

- Explore posts.
- Search users and posts.
- Recommended users.
- Trending posts.
- Trending tags.
- Recent searches stored locally.
- Clear recent searches.

## 7. Stories

- Story row in the home feed.
- Create story.
- View story.
- Story view tracking.
- Profile stories section.

## 8. Notifications

- Notification list.
- Unread count and badge.
- Mark all as read.
- Mark single notification read.
- Delete notification.
- Notification tap routing to posts, profiles, conversations, follow requests, or notifications fallback.
- Android FCM token registration support when Firebase is configured.

## 9. Chat

- Conversation list.
- Chat detail screen.
- Message bubbles.
- Send message loading state.
- Duplicate-send prevention.
- Mark received messages as read when supported by the backend.

## 10. Safety And Moderation

- Block/unblock users.
- Blocked users settings screen.
- Report posts, comments, users, and generic targets.
- Blocking checks across feed, discovery, profile, chat, and follow flows.
- Private-account visibility checks.

## 11. Admin

- Admin dashboard.
- Admin report list.
- Admin report detail and status updates.
- Admin user routes.
- Admin post/comment moderation routes.
- Admin user search with role and account-status filters.
- Paginated admin user, post, and comment moderation lists.

## 12. Settings

- Account settings.
- Privacy settings.
- Notification settings.
- Blocked users.
- Follow requests shortcut.
- Appearance note using system theme.
- Logout and account danger-zone flows.

## 13. Android And Demo Support

- Android emulator API URL: `http://10.0.2.2:8000/api`.
- Physical device API URL: `http://YOUR_COMPUTER_LAN_IP:8000/api`.
- Debug APK build command documented.
- Local HTTP enabled for debug/profile Android builds.
- Final demo script, screenshot guide, architecture doc, testing checklist, and final submission checklist.

## Known Limitations

- Video posts are future work.
- Real-time typing indicators are future work.
- Push delivery needs Firebase project files and backend service account configuration outside git.
- Release signing and Play Store release configuration are not included.

## Advanced Features and Functionality Expansion Pass

Date: 2026-06-28

- Saved collections: create, rename, delete, list collections, add saved posts to collections, remove posts from collections, and browse collection posts.
- User activity page: recent posts, comments, liked posts, saved posts, and followed users through `GET /api/me/activity`.
- Notification preferences: category toggles for likes, comments, follows, follow requests, messages, and mentions, with backend notification creation respecting disabled categories.
- Explore/search/hashtags: existing Explore search, trending posts, recommended users, content-derived trending tags, clickable post hashtags, and tag post browsing remain supported.
- Demo seed data includes saved collections.

Remaining limitations: reposts, mention autocomplete, normalized hashtag tables, video posts, and typing indicators remain future phases.
