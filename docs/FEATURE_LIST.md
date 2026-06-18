# SnapCircle Feature List

SnapCircle is a Flutter Android and Laravel REST API social media app for a university project demo. The feature set is organized around a real mobile social flow.

## Authentication

- Email registration and login.
- Demo login for presentations.
- Forgot/reset password API flow.
- Google and Facebook login hooks.
- Laravel Sanctum bearer token authentication.
- Secure token storage in Flutter.
- Logout and expired-session handling.

## Feed And Posts

- Home feed with pull-to-refresh and pagination.
- Feed modes such as For You, Following, Popular, and Mine.
- Text posts.
- Single-image posts.
- Multiple-image carousel posts.
- Create, edit, delete, and view post detail.
- Like/unlike posts.
- Save/unsave posts and Saved Posts screen.
- Share post text/link.
- Post menu with owner and non-owner actions.

## Comments

- Comment list with loading, empty, error, and pagination states.
- Create comments.
- Edit own comments.
- Delete own comments.
- Report comments.
- Comment count updates in the feed.

## Profiles And Social Graph

- Own profile and public user profile screens.
- Edit profile with avatar, cover image, bio, location, website, and privacy state.
- Profile stats for posts, followers, and following.
- Follow/unfollow users.
- Followers and following list screens.
- Private accounts and follow requests.
- Follow request approval/rejection.
- Profile posts and stories sections.

## Safety And Moderation

- Block/unblock users.
- Blocked users settings screen.
- Report posts, comments, users, and generic targets.
- Admin dashboard.
- Admin report list and report detail.
- Admin user and content moderation routes/screens.

## Explore And Search

- Explore posts.
- Search users and posts.
- Recommended users.
- Trending posts.
- Trending tags.
- Recent searches stored locally.
- Clear recent searches.

## Stories

- Story row in the home feed.
- Create story.
- View story.
- Story view tracking.
- Profile stories section.

## Notifications

- Notification list.
- Unread count and badge.
- Mark all as read.
- Mark single notification read.
- Delete notification.
- Notification tap routing to posts, profiles, conversations, follow requests, or notification fallback.
- Android FCM token registration support when Firebase is configured.

## Chat

- Conversation list.
- Chat detail.
- Message bubbles.
- Send message loading state.
- Duplicate-send prevention.
- Mark received messages as read when supported by the backend.

## Settings

- Account settings.
- Privacy settings.
- Notification settings.
- Blocked users.
- Follow requests shortcut.
- Appearance note using system theme.
- Logout and account danger-zone flows.

## Android Demo Support

- Android emulator API URL: `http://10.0.2.2:8000/api`.
- Physical device API URL: `http://YOUR_COMPUTER_LAN_IP:8000/api`.
- Debug APK build command documented.
- Local HTTP enabled for debug/profile Android builds.
- Presentation flow, screenshot guide, and testing checklist included.

## Known Limitations

- Saved collections are future work.
- Video posts are future work.
- Real-time typing indicators are future work.
- Push delivery needs Firebase project files and backend service account configuration outside git.
- Release signing and Play Store release configuration are not included.
