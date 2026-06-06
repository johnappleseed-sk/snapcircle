# SnapCircle Frontend Backend API Coverage

| Feature | Backend Endpoint | Flutter Repository | Flutter Provider | UI Screen | Status |
|---|---|---|---|---|---|
| Auth Google | `POST /api/auth/google` | `AuthRepository` | `AuthProvider` | `LoginScreen` | Done |
| Auth Facebook | `POST /api/auth/facebook` | `AuthRepository` | `AuthProvider` | `LoginScreen` | Done |
| Demo auth | `POST /api/auth/demo` | `AuthRepository` | `AuthProvider` | `LoginScreen` | Done |
| Current user | `GET /api/user` | `AuthRepository` | `AuthProvider` | Splash/router | Done |
| Logout | `POST /api/logout` | `AuthRepository` | `AuthProvider` | Profile/Settings | Done |
| Current profile | `GET /api/profile` | `ProfileRepository` | `ProfileProvider` | `ProfileScreen` | Done |
| Edit profile | `PUT /api/profile` | `ProfileRepository` | `ProfileProvider` | `EditProfileScreen` | Done |
| Users list | `GET /api/users` | `ProfileRepository` | `UsersProvider` | Search/Explore | Partial |
| User detail | `GET /api/users/{user}` | `ProfileRepository` | `ProfileProvider` | `UserProfileScreen` | Done |
| User posts | `GET /api/users/{user}/posts` | `ProfileRepository` | `ProfileProvider` | Profile posts | Done |
| Follow | `POST /api/users/{user}/follow` | `ProfileRepository` | `ProfileProvider` | Profile/Explore | Done |
| Unfollow | `DELETE /api/users/{user}/follow` | `ProfileRepository` | `ProfileProvider` | Profile/Explore | Done |
| Followers | `GET /api/users/{user}/followers` | `ProfileRepository` | `ProfileProvider` | `FollowListScreen` | Done |
| Following | `GET /api/users/{user}/following` | `ProfileRepository` | `ProfileProvider` | `FollowListScreen` | Done |
| Feed posts | `GET /api/posts` | `FeedRepository` | `FeedProvider` | `HomeScreen` | Done |
| Create post | `POST /api/posts` | `FeedRepository` | `FeedProvider` | `CreatePostScreen` | Done |
| Post detail | `GET /api/posts/{post}` | `FeedRepository` | local state | `PostDetailScreen` | Done |
| Delete post | `DELETE /api/posts/{post}` | `FeedRepository` | `FeedProvider` | Post menus | Done |
| Like post | `POST /api/posts/{post}/like` | `LikeRepository` | `FeedProvider` | `PostCard` | Done |
| Unlike post | `DELETE /api/posts/{post}/like` | `LikeRepository` | `FeedProvider` | `PostCard` | Done |
| Save post | `POST /api/posts/{post}/save` | `SavedPostRepository` | `FeedProvider` | `PostCard` | Done |
| Saved posts | `GET /api/saved-posts` | `SavedPostRepository` | `SavedPostsProvider` | `SavedPostsScreen` | Done |
| Comments | `GET /api/posts/{post}/comments` | `CommentRepository` | `CommentsProvider` | `CommentsScreen` | Done |
| Create comment | `POST /api/posts/{post}/comments` | `CommentRepository` | `CommentsProvider` | `CommentsScreen` | Done |
| Update comment | `PUT /api/comments/{comment}` | `CommentRepository` | `CommentsProvider` | `CommentTile` | Done |
| Delete comment | `DELETE /api/comments/{comment}` | `CommentRepository` | `CommentsProvider` | `CommentTile` | Done |
| Notifications | `GET /api/notifications` | `NotificationRepository` | `NotificationsProvider` | `NotificationsScreen` | Done |
| Unread count | `GET /api/notifications/unread-count` | `NotificationRepository` | `NotificationsProvider`/`RealtimeProvider` | Home badge | Done |
| Conversations | `GET /api/conversations` | `ConversationRepository` | `ConversationsProvider` | `ConversationsScreen` | Done |
| Messages | `GET /api/conversations/{id}/messages` | `MessageRepository` | `MessagesProvider` | `ChatDetailScreen` | Done |
| Send message | `POST /api/conversations/{id}/messages` | `MessageRepository` | `MessagesProvider` | `ChatDetailScreen` | Done |
| Stories | `GET /api/stories` | `StoryRepository` | `StoriesProvider` | `StoriesRow` | Done |
| Create story | `POST /api/stories` | `StoryRepository` | `StoriesProvider` | `CreateStoryScreen` | Done |
| Story detail | `GET /api/stories/{story}` | `StoryRepository` | `StoriesProvider` | `StoryViewerScreen` | Done |
| Mark story viewed | `POST /api/stories/{story}/view` | `StoryRepository` | `StoriesProvider` | `StoryViewerScreen` | Done |
| Explore posts | `GET /api/explore/posts` | `ExploreRepository` | `ExploreProvider` | `ExploreScreen` | Done |
| Recommended users | `GET /api/explore/recommended-users` | `ExploreRepository` | `ExploreProvider` | `ExploreScreen` | Done |
| Settings | `GET /api/settings` | `SettingsRepository` | `SettingsProvider` | Settings screens | Done |
| Update settings | `PUT /api/settings` | `SettingsRepository` | `SettingsProvider` | Settings screens | Done |
| Report post | `POST /api/posts/{post}/report` | `ReportRepository` | `ReportProvider` | `ReportDialog` | Done |
| Report comment | `POST /api/comments/{comment}/report` | `ReportRepository` | `ReportProvider` | `ReportDialog` | Done |
| Report user | `POST /api/users/{user}/report` | `ReportRepository` | `ReportProvider` | `ReportDialog` | Done |
| Admin dashboard | `GET /api/admin/dashboard` | `AdminRepository` | `AdminProvider` | `AdminDashboardScreen` | Done |
| Admin reports | `GET /api/admin/reports` | `AdminRepository` | `AdminProvider` | `AdminReportsScreen` | Done |
| Admin users | `GET /api/admin/users` | `AdminRepository` | `AdminProvider` | `AdminUsersScreen` | Done |
