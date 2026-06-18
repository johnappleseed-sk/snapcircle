# SnapCircle Final Demo Script

Use this script for the final Android presentation. Keep the backend running before the demo starts and use the Android emulator URL unless presenting from a physical phone.

## Demo Setup

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

## 5-Minute Walkthrough

1. Open SnapCircle and briefly describe it as a Flutter and Laravel social media app for sharing posts, stories, comments, messages, and profile updates.
2. Login with the demo account or use the demo login button.
3. Show the home feed, story row, post cards, image carousel, like/comment/save actions, and pull-to-refresh.
4. Create a quick text post, then mention that the same screen supports single-image and multiple-image carousel posts.
5. Open a post detail page, add a comment, and show edit/delete/report options where permissions allow them.
6. Use the post menu to show View profile, Copy post text, Save/unsave, Report, Block, Edit, and Delete.
7. Open Explore, search for a user or topic, show recommended users, trending tags, and post results.
8. Open a user profile, show profile header, stats, posts, stories, Follow/Message actions, and private/blocked states if available.
9. Open Notifications, show unread styling, mark all read, and explain route-aware notification taps.
10. Open Messages, show conversation list, chat bubbles, send box, loading state, and message read behavior.
11. Open Settings, show privacy, blocked users, notifications, account actions, and logout confirmation.
12. Logout and login again to show the auth/session flow.

## Longer Demo Flow

Use this when there is enough time:

1. Login as Maya.
2. Create a multiple-image post and show carousel swiping in the feed.
3. Like, unlike, comment, edit your comment, and delete your comment.
4. Save a post, open Saved Posts, then unsave it.
5. Search for Dara or Lina from Explore and open the profile.
6. Follow/unfollow the user and open followers/following lists.
7. Turn on Private account in Settings > Privacy Settings.
8. Login as another user and send a follow request.
9. Return to Maya and approve or reject the follow request.
10. Report a post or user, then login as an admin account to show report review if the audience asks.

## Presenter Notes

- Keep the phone/emulator on a stable network because demo images may use remote URLs.
- If push notifications are not configured, explain that in-app notifications work and Android FCM needs Firebase credentials outside git.
- Do not show `.env`, private Firebase files, local tokens, or service account JSON on screen.
- If the backend is unreachable, open `http://127.0.0.1:8000/api/health` on the computer and `http://10.0.2.2:8000/api/health` from the emulator browser.

## Quick Recovery

- Feed is empty: run `php artisan migrate --seed`, then refresh.
- Images fail: run `php artisan storage:link` and confirm the API URL is reachable from Android.
- Login fails: use `maya@snapcircle.local` and `password`, then confirm the backend is running.
- Flutter build fails locally: verify Flutter and Android SDK are on PATH.
