# SnapCircle Testing Checklist

Use this checklist before final submission.

## Backend

- [ ] Laravel server starts successfully
- [ ] Database migrations run successfully
- [ ] Seeders run successfully
- [ ] Health API works
- [ ] Google login endpoint works
- [ ] Facebook login endpoint works
- [ ] Protected routes require token
- [ ] Posts API works
- [ ] Likes API works
- [ ] Comments API works
- [ ] Profile API works
- [ ] Follow API works
- [ ] Tests pass
- [ ] `php artisan route:list` lists API routes without errors
- [ ] Demo account exists: `maya@snapcircle.local` / `password`
- [ ] Storage link exists for uploaded media

## Frontend

- [ ] Flutter app starts successfully
- [ ] Login screen displays
- [ ] Google login button works
- [ ] Facebook login button works
- [ ] Home feed loads posts
- [ ] User can create post
- [ ] User can upload image post
- [ ] User can like/unlike post
- [ ] User can comment on post
- [ ] User can edit/delete own comment
- [ ] User can view profile
- [ ] User can edit profile
- [ ] User can search users
- [ ] User can follow/unfollow users
- [ ] User can create a multiple-image carousel post
- [ ] User can save/unsave a post
- [ ] User can open Saved Posts
- [ ] User can report post/comment/user
- [ ] User can block/unblock user
- [ ] User can view stories
- [ ] User can open notifications and mark all read
- [ ] User can open chat and send message
- [ ] User can open settings, privacy, notifications, account, and blocked users
- [ ] Logout works

## Android Demo QA

- [ ] Emulator uses `http://10.0.2.2:8000/api`
- [ ] Physical device uses computer LAN IP
- [ ] Backend health endpoint opens from Android browser
- [ ] Keyboard does not cover comment/message inputs
- [ ] Bottom navigation does not overlap primary content
- [ ] Image carousel sizes correctly
- [ ] Empty states are clear
- [ ] Error states include retry or useful action
- [ ] Dark mode contrast is readable
- [ ] No obvious overflow warnings during the demo flow
- [ ] Debug APK builds when Flutter/Android toolchain is available

## Submission

- [ ] README completed
- [ ] API documentation completed
- [ ] Final demo script completed
- [ ] Feature list completed
- [ ] Technical architecture completed
- [ ] Screenshot guide completed
- [ ] Screenshots added or screenshot plan included
- [ ] Code pushed to GitHub
- [ ] No `.env` committed
- [ ] No `vendor/` committed
- [ ] No `build/` committed
- [ ] No APK committed unless specifically requested
