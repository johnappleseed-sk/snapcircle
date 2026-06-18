# SnapCircle Screenshot Guide

Use this checklist for final report, slides, and demo proof. Prefer Android emulator screenshots with the seeded demo account so the UI looks consistent.

## 1. Splash Or Login Screen

- What to capture: Splash state if visible, then the login screen with email/password, demo login, and social login actions.
- Why it matters: shows the Android entry point and authentication options.
- Suggested demo action: start from a logged-out app state.

## 2. Demo Login State

- What to capture: Maya logged in, either on the home feed or immediately after login.
- Why it matters: proves the local demo account is ready.
- Suggested demo action: login with `maya@snapcircle.local` / `password`.

## 3. Home Feed

- What to capture: story row, feed tabs, post cards, avatar/name/timestamp, media, and action row.
- Why it matters: this is the main social media experience.
- Suggested demo action: pull to refresh before capturing.

## 4. Post With Image Or Multiple Images

- What to capture: a carousel post with page dots and a visible image.
- Why it matters: highlights Android media upload and carousel rendering.
- Suggested demo action: use the seeded weekend market post or create a new multi-image post.

## 5. Create Post Screen

- What to capture: composer, text input, image picker controls, selected image previews, and submit button.
- Why it matters: proves users can create content.
- Suggested demo action: type `Final demo post from Android` and select one or more images.

## 6. Post Detail And Comments

- What to capture: post detail, comments list, comment composer, and comment menu.
- Why it matters: shows engagement beyond the feed.
- Suggested demo action: open a post, add a short comment, then show edit/delete/report options where allowed.

## 7. Explore And Search

- What to capture: search bar, recommended users, trending tags/posts, recent searches, or search results.
- Why it matters: shows discovery.
- Suggested demo action: search `maya`, `dara`, `travel`, or `foodie`.

## 8. User Profile

- What to capture: avatar, cover image, name, username, bio, stats, action buttons, posts, and stories.
- Why it matters: shows identity and social graph.
- Suggested demo action: open Dara or Lina from Explore.

## 9. Edit Profile

- What to capture: edit profile form with name, username, bio, location, website, avatar, and cover controls.
- Why it matters: shows account personalization.
- Suggested demo action: open Maya's own profile and tap Edit.

## 10. Follow Or Following State

- What to capture: Follow, Following, or Requested button state on another profile.
- Why it matters: shows the follow system and private-account behavior.
- Suggested demo action: follow/unfollow a seeded user or turn on Private account and request access from another account.

## 11. Notifications

- What to capture: unread styling, mark-all-read action, notification items, and delete action if visible.
- Why it matters: shows activity feedback and route-aware notifications.
- Suggested demo action: generate a like/comment/follow notification if seeded data is empty.

## 12. Chat List

- What to capture: conversation list with avatar, latest message, timestamp, and unread visual state if available.
- Why it matters: shows direct messaging entry point.
- Suggested demo action: open Messages from the feed app bar.

## 13. Chat Detail

- What to capture: message bubbles, timestamp, send box, and send loading state if possible.
- Why it matters: proves two-way messaging UI.
- Suggested demo action: send `Looks great for the final demo!`.

## 14. Settings

- What to capture: grouped settings sections for account, privacy, notifications, appearance, and about.
- Why it matters: shows app completeness and account controls.
- Suggested demo action: open Settings from profile or app navigation.

## 15. Safety, Report, Or Block Screen

- What to capture: report dialog/sheet, post menu safety actions, blocked users screen, or blocked profile state.
- Why it matters: shows responsible product design and moderation readiness.
- Suggested demo action: open another user's post menu and show Report/Block without submitting a real duplicate report unless needed.

## 16. Admin Or Report Screen

- What to capture: admin reports list/detail, moderation status controls, or dashboard stats.
- Why it matters: proves backend moderation support.
- Suggested demo action: login as an admin/moderator account and open Admin > Reports after creating a demo report.

## Screenshot Tips

- Use the same Android emulator size for all screenshots.
- Refresh data before capturing.
- Avoid screenshots showing `.env`, tokens, service account files, local private paths, or APK folders.
- Store selected screenshots under `docs/screenshots/` if required for submission.
- Do not commit APK files or build folders unless explicitly requested.
