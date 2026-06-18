# SnapCircle Screenshot Guide

Use these screenshots for the final report, slides, and demo proof. Prefer Android emulator screenshots with the same seeded demo account so the UI looks consistent.

## 1. Login Screen

- What to show: SnapCircle login form, demo login option, and social login buttons.
- Suggested demo data: no data needed.
- Why it matters: proves the app has an Android entry point and authentication flow.

## 2. Home Feed

- What to show: story row, feed tabs, post cards, avatar/name/timestamp, actions, and pull-to-refresh if possible.
- Suggested demo data: Maya account with seeded posts from Dara and Lina.
- Why it matters: this is the main social media experience.

## 3. Create Post

- What to show: composer, text field, image picker controls, disabled/loading submit state if captured during upload.
- Suggested demo data: short caption such as `Final demo post from Android`.
- Why it matters: proves users can contribute content.

## 4. Image Carousel Post

- What to show: a post with multiple images, carousel dots, like/comment/save row, and post menu.
- Suggested demo data: seeded weekend market post or a new multi-image post.
- Why it matters: highlights the newer multi-image feature.

## 5. Post Detail And Comments

- What to show: post detail, comment list, comment composer, and comment menu.
- Suggested demo data: use a post with existing seeded comments.
- Why it matters: shows deeper engagement beyond the feed.

## 6. Explore And Search

- What to show: search bar, recent searches, recommended users, trending tags/posts, or search results.
- Suggested demo data: search `maya`, `dara`, `travel`, or `foodie`.
- Why it matters: shows discovery and navigation.

## 7. Profile

- What to show: cover image, avatar, display name, username, bio, stats row, action buttons, posts/stories.
- Suggested demo data: Maya's own profile or Dara's user profile.
- Why it matters: shows identity, social graph, and profile polish.

## 8. Edit Profile

- What to show: edit profile fields for name, username, bio, location, website, avatar/cover image controls.
- Suggested demo data: do not reveal private real data; use demo-only fields.
- Why it matters: proves account personalization.

## 9. Notifications

- What to show: unread styling, notification list, mark-all-read action, delete action if visible.
- Suggested demo data: seeded or generated likes/comments/follows.
- Why it matters: shows activity feedback and routing readiness.

## 10. Chat

- What to show: conversation list or chat detail with message bubbles and send box.
- Suggested demo data: a seeded conversation or a message sent during demo.
- Why it matters: shows direct messaging support.

## 11. Settings

- What to show: grouped account, privacy, notification, appearance, help/about, and blocked-user sections.
- Suggested demo data: Maya account.
- Why it matters: shows app completeness and safety controls.

## 12. Admin Or Report Screen

- What to show: report list/detail or admin moderation dashboard if logged in as an admin/moderator.
- Suggested demo data: create one report during the demo, then review it as an admin account.
- Why it matters: shows moderation and responsible product design.

## Screenshot Tips

- Use the same Android emulator size for all screenshots.
- Refresh the feed before capturing.
- Avoid screenshots that show `.env`, tokens, service account files, or private machine paths.
- Capture light mode and dark mode only if time allows; prioritize the required flow first.
- Do not include APK files in git; store screenshots under `docs/screenshots/` if needed for submission.
