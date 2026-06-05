# SnapCircle UI/UX Checklist

Use this checklist after Phase 2 UI updates and before taking assignment screenshots.

- [x] Splash screen polished
- [x] Login screen polished
- [x] Feed screen polished
- [x] Post cards polished
- [x] Create post screen polished
- [x] Comments screen polished
- [x] Profile screen polished
- [x] Edit profile screen polished
- [x] Search screen polished
- [x] User profile screen polished
- [x] Followers/following screen polished
- [x] Loading states added
- [x] Empty states added
- [x] Error states added
- [x] SnackBars consistent
- [x] App theme consistent
- [ ] No UI overflow found during manual device testing
- [x] `flutter analyze` passes

## Manual Screen Review

Review these screens on at least one mobile-sized emulator or device:

- Splash
- Login
- Feed
- Create post
- Comments
- Profile
- Edit profile
- Search/Explore
- User profile
- Followers
- Following

## Notes

- Keep the Laravel backend running before testing authenticated screens.
- Run `php artisan storage:link` in the backend if uploaded images do not appear.
- On Android emulator, the API should be reachable through `http://10.0.2.2:8000/api`.
