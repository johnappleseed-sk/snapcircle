# SnapCircle Final Demo Script

Use this 5-7 minute script for the final Android presentation. Speak naturally, but keep the order tight so every major feature appears.

## Setup

Backend:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Android emulator:

```bash
cd frontend
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

Demo login:

```txt
Email: maya@snapcircle.local
Password: password
```

## 5-7 Minute Presentation Script

1. Introduce SnapCircle.
   Say: "SnapCircle is a full-stack Android social media app built with Flutter and Laravel. It is designed for sharing posts, image moments, stories, comments, notifications, and private messages."

2. Explain the problem and purpose.
   Say: "The goal is to show a real mobile social app architecture, not only static screens. Flutter handles the Android experience, while Laravel provides authenticated REST APIs, validation, database storage, and moderation workflows."

3. Show login.
   Open the app and login with the demo account. Mention email login, demo login, reset password flow, and social login hooks.

4. Show the feed.
   Show the story row, feed tabs, post cards, timestamps, media, like/comment/save actions, and pull-to-refresh. Point out loading, empty, and error states are handled.

5. Create a post.
   Open Create Post, type a short caption, and mention that the same flow supports text-only, single-image, and multiple-image carousel posts.

6. Like, comment, and save.
   Like/unlike a post, open comments, add a comment, and save/unsave a post. Open Saved Posts if time allows.

7. Explore users and posts.
   Open Explore, search for a user or topic, show recommended users, trending tags, and post results.

8. Show profile and follow states.
   Open a user profile, show avatar, cover image, stats, posts/stories, Follow/Message buttons, followers/following lists, and private/requested states if available.

9. Show notifications.
   Open Notifications, show unread state, mark all read, and explain notification taps can route to posts, profiles, chats, or follow requests.

10. Show chat.
    Open Messages, enter a conversation, show message bubbles and send a short message.

11. Show safety and report features.
    Open a post or profile menu and show Report and Block. Mention the backend also supports admin moderation review.

12. Show settings and logout.
    Open Settings, show privacy, blocked users, notifications, account actions, and logout.

13. Explain backend, admin, and API strength.
    Say: "The backend has protected Sanctum routes, request validation, Eloquent models, API resources, reports, blocking checks, private-account rules, notifications, chat, and admin moderation routes."

14. End with future improvements.
    Say: "Next production improvements would be release signing, HTTPS deployment, cloud media storage, saved collections, video posts, stronger real-time chat, and Firebase production push setup."

## Presenter Recovery Notes

- If feed is empty, run `php artisan migrate --seed` and refresh.
- If port `8000` is occupied, stop the other service or run Laravel on another port and update `SNAPCIRCLE_API_BASE_URL`.
- If images fail, run `php artisan storage:link` and confirm Android can reach the backend URL.
- If Flutter build fails, confirm Flutter and Android SDK are on PATH.
- Do not show `.env`, tokens, Firebase private files, service account JSON, or APK/build folders on screen.
