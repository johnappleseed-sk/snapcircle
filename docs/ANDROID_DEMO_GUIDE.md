# SnapCircle Android Demo Guide

This guide is for installing, testing, and demoing SnapCircle on an Android emulator or a real Android phone.

Final presentation companion docs:

- Demo script: `docs/FINAL_DEMO_SCRIPT.md`
- Screenshot plan: `docs/SCREENSHOT_GUIDE.md`
- Feature list: `docs/FEATURE_LIST.md`
- Architecture explanation: `docs/TECHNICAL_ARCHITECTURE.md`

## Requirements

- Flutter SDK with Android toolchain installed.
- Android Studio or Android SDK command-line tools.
- A running Laravel backend.
- MySQL running and seeded with demo data.
- Android emulator or physical Android phone with USB debugging enabled.
- Phone and computer on the same Wi-Fi for physical-device testing.

## Backend Setup

From the project root:

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve --host=0.0.0.0 --port=8000
```

Backend health check on the computer:

```txt
http://127.0.0.1:8000/api/health
```

Current detected LAN IP for this machine:

```txt
172.20.10.3
```

Physical Android devices should use:

```txt
http://172.20.10.3:8000/api
```

If the Wi-Fi network changes, find the new LAN IP before running the app.

## Find The Computer LAN IP

macOS:

```bash
ipconfig getifaddr en0
```

If that returns nothing, inspect the active route:

```bash
route get default
```

Use the IP address on the active Wi-Fi interface. It usually looks like `192.168.x.x` or `10.x.x.x`.

## Android Emulator Setup

The Android emulator reaches the host computer through `10.0.2.2`.

Run:

```bash
cd frontend
flutter pub get
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

Build an emulator debug APK:

```bash
cd frontend
flutter build apk --debug --dart-define=SNAPCIRCLE_API_BASE_URL=http://10.0.2.2:8000/api
```

## Real Android Device Setup

1. Connect the phone by USB or use wireless debugging.
2. Enable Developer options and USB debugging.
3. Keep the phone and computer on the same Wi-Fi.
4. Start Laravel with `--host=0.0.0.0`.
5. Open the backend health URL in the phone browser:

```txt
http://172.20.10.3:8000/api/health
```

Run on a connected Android phone:

```bash
cd frontend
flutter run -d android --dart-define=SNAPCIRCLE_API_BASE_URL=http://172.20.10.3:8000/api
```

Build a physical-device debug APK:

```bash
cd frontend
flutter build apk --debug --dart-define=SNAPCIRCLE_API_BASE_URL=http://172.20.10.3:8000/api
```

## Install A Debug APK

The debug APK is generated at:

```txt
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

Install with Flutter/ADB when a device is connected:

```bash
cd frontend
flutter install -d android
```

Or install directly with ADB:

```bash
/Users/John/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If sharing the APK manually, copy `app-debug.apk` to the phone and allow install from unknown sources for the file manager or browser used to open it.

## Demo Login

Use the local demo account:

```txt
Email: maya@snapcircle.local
Password: password
```

The Android login screen also includes a local demo login button for faster demos.

## Android Demo Flow Checklist

Use this checklist for emulator or real-device smoke testing:

1. Open app.
2. Login with demo account.
3. Load home feed.
4. Pull to refresh feed.
5. Create text post.
6. Create image post.
7. Create multiple-image post.
8. Remove one selected image before posting.
9. Swipe carousel in feed.
10. Open post detail and swipe carousel.
11. Confirm profile grid shows the first image and multiple-image indicator.
12. Like and unlike a post.
13. Comment on a post.
14. Save and unsave a post.
15. Explore/search.
16. View another user profile.
17. Report a user or post with a specific reason.
18. Block a user from the profile menu or feed post menu.
19. Confirm blocked user's posts are hidden and follow/message actions are unavailable.
20. Open Settings > Blocked users and unblock the user.
21. Turn Private account on.
22. Send a follow request from another account.
23. Approve a follow request.
24. Reject a follow request.
25. Cancel a pending request from the requesting account.
26. Confirm approved followers can see private posts.
27. Turn Private account off and confirm normal follow behavior.
28. Edit own profile.
29. Upload avatar.
30. View notifications.
31. Open chat.
32. Send message.
33. Open settings.
34. Logout.
35. Login again.
36. Confirm token persistence by closing and reopening the app while logged in.

## Final Screenshot Checklist

Capture the final submission screenshots after the smoke test passes. Recommended screens are listed in `docs/SCREENSHOT_GUIDE.md` and include login, home feed, create post, image carousel, comments, explore, profile, edit profile, notifications, chat, settings, and admin/report review.

## Troubleshooting

Backend not reachable:

- Confirm Laravel is running with `php artisan serve --host=0.0.0.0 --port=8000`.
- Confirm the phone and computer are on the same Wi-Fi.
- Open `http://YOUR_COMPUTER_LAN_IP:8000/api/health` in the phone browser.
- Check macOS firewall or security software for port `8000` blocking.

Login fails:

- Run `php artisan migrate --seed` in `backend`.
- Use `maya@snapcircle.local` and `password`.
- Confirm the app was launched or built with the correct `SNAPCIRCLE_API_BASE_URL`.

Images not uploading:

- Run `php artisan storage:link`.
- Confirm the backend URL is reachable from the Android device.
- Make sure Android has photo access when prompted by `image_picker`.
- Check Laravel logs in `backend/storage/logs` for upload validation errors.

App stuck loading:

- Pull to refresh or restart the app.
- Confirm backend health endpoint works.
- Log out and log in again if the token is stale.

Blocked user still appears:

- Pull to refresh the feed, explore screen, profile, or notifications.
- Confirm the block action completed and the app is connected to the same backend used by the test account.
- Existing historical records are not deleted; the app hides blocked users from core discovery and interaction surfaces.

Report submission fails:

- Select a supported reason: spam, harassment, hate, violence, nudity, scam, misinformation, or other.
- Duplicate pending reports for the same target are rejected until an admin reviews the original report.

Cleartext HTTP issue:

- Local HTTP is allowed for Android debug/profile builds.
- Release builds should use HTTPS.
- If a debug APK cannot reach HTTP, rebuild with the correct dart define and confirm the debug manifest is being used.

Phone and computer not on same Wi-Fi:

- Use the same Wi-Fi network for both devices.
- Avoid guest networks that isolate clients.
- If needed, use USB reverse/tethering or deploy the backend to an HTTPS host.

## Known Limitations

- Google and Facebook login require real OAuth credentials and provider setup.
- The debug APK is for local demo/testing, not Play Store release.
- Release signing is not configured for production distribution.
- Physical-device testing still depends on the phone being able to reach the developer machine over Wi-Fi.
- Blocking and reporting are ready for demo, but manual real-device QA should still confirm feed filtering, profile state, chat prevention, and blocked-users settings on the target phone.

## Multiple Image Posts Feature Pass

Android-specific notes:

- The create post screen uses Android's system photo picker through `image_picker.pickMultiImage`.
- Users can select up to 10 images; the Laravel API validates the same maximum and 4 MB per image.
- Multiple images are uploaded as multipart `images[]`; legacy single-image uploads with `image` still work.
- Feed and post detail use a horizontal carousel with page dots.
- Profile and Explore grids use the first image as the thumbnail and show a stacked-image indicator when a post has multiple images.
- Returned media URLs require `php artisan storage:link` and a backend host reachable from the Android emulator or phone.

## Private Account and Follow Requests Feature Pass

Android-specific notes:

- Settings > Privacy Settings includes a Private account toggle with confirmation.
- Private accounts require follow approval before posts and stories are visible.
- Follow Requests is available from Profile and Settings.
- Pending requests show as Requested on private profiles and can be cancelled by tapping Requested.
- Follow request notifications open the Follow Requests screen.
- Backend filters private content in feed, Explore, profile posts, stories, post detail, comments, likes, and saves.

Manual Android checklist:

1. Login as the private account owner.
2. Enable Private account.
3. Login as a second user.
4. Send a follow request.
5. Confirm the private profile shows the locked message and Requested button.
6. Login as the owner.
7. Approve the request from Follow Requests.
8. Login as the second user and confirm private posts are visible.
9. Repeat with reject and cancel request paths.

## Android Push Notifications Feature Pass

Android Firebase setup:

- Add Firebase Android app package `com.snapcircle.app`.
- Download `google-services.json` from Firebase Console.
- Place it at `frontend/android/app/google-services.json`.
- Keep `google-services.json` out of git.
- Store the backend Firebase service account JSON outside git, for example `backend/storage/firebase-service-account.json`.
- Set `FIREBASE_PROJECT_ID` and `FIREBASE_SERVICE_ACCOUNT_PATH` in `backend/.env`.

Device token API:

- `POST /api/device-tokens` registers the current Android FCM token.
- `DELETE /api/device-tokens` removes the current Android FCM token on logout when possible.

Notification triggers:

- Likes, comments, follows, follow requests, approved follow requests, and new chat messages create in-app notifications and attempt FCM delivery.
- Push payloads include route data such as `type`, `post_id`, `user_id`, `conversation_id`, and `message_id`.

Manual Android checklist:

1. Install a build that includes the real `google-services.json`.
2. Login and confirm a row is created in `device_tokens`.
3. Trigger a like from another account and confirm the push opens the post.
4. Trigger a comment and confirm the push opens the post.
5. Trigger a follow request and confirm the push opens Follow Requests.
6. Approve a request and confirm the push opens the approving user's profile.
7. Send a chat message and confirm the push opens the conversation.
8. Logout and confirm the token is removed when the device is online.

Known limitations:

- A real Firebase project and service account are required before pushes can be delivered.
- Per-category push preferences are not stored separately yet; the existing Push notifications setting controls delivery globally.

## Feature Expansion and UI Improvement Pass

Android-specific notes:

- The shared post menu now includes View profile, Copy post text, Save/unsave, Report, Block, Edit, and Delete actions depending on ownership.
- Saved Posts now uses the same post action model as the main feed and confirms destructive deletes.
- Post Detail now keeps block/report/save/profile actions available after opening an individual post.
- No fake saved collections or typing indicators are shown.

Manual Android checklist:

1. Login as a user with at least one own post and one post from another user.
2. Confirm own post menu shows Edit and Delete.
3. Confirm another user's post menu shows Report and Block.
4. Copy text from a text post and confirm the success message appears.
5. Save and unsave a post from the menu and from the action row.
6. Open Saved Posts, unsave a post, and confirm it leaves the list.
7. Delete an owned saved post and confirm the delete dialog appears first.
8. Open Post Detail for another user's post and confirm Block is available.
