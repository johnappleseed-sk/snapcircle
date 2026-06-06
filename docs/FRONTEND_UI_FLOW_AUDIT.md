# SnapCircle Frontend UI and Flow Audit

## 1. Current Frontend Status

SnapCircle's Flutter frontend is feature-rich and connected to the Laravel API. Authentication, profile, feed, post creation, post detail, likes, comments, follows, explore, saved posts, notifications, chat, stories, settings, reports, and basic admin screens are present. The app uses Provider for state, Dio through `ApiClient`, secure token storage, `go_router`, and reusable widgets for cards, buttons, avatars, loading, errors, and empty states.

The main gap was not missing backend connectivity as much as a fragmented app flow: Home owned partial bottom navigation, Messages was not a first-class tab, Create was a direct post action instead of a creation hub, and some profile/settings actions felt disconnected. The app now has a shared shell for the main tabs, while detail flows remain reachable through dedicated routes.

## 2. Backend APIs Not Fully Used

| Backend Feature | API Exists | Flutter Screen Exists | Fully Integrated | Notes |
|---|---|---|---|---|
| Authentication | Yes | Yes | Done | Social and demo auth connect through `AuthRepository`. |
| Profile | Yes | Yes | Done | Current profile and user profile screens use backend profile APIs. |
| Edit profile | Yes | Yes | Done | Avatar, cover, profile fields, and privacy flag are connected. |
| Feed | Yes | Yes | Done | Feed lists posts and supports refresh/load more. |
| Feed modes | Yes | Yes | Done | For You, Following, Popular, and Mine are exposed. |
| Post detail | Yes | Yes | Done | Post detail loads a post and links to comments. |
| Create post | Yes | Yes | Done | Create tab now opens Create Post/Create Story choices. |
| Likes | Yes | Yes | Done | Like/unlike uses local state updates. |
| Comments | Yes | Yes | Done | Comments list, create, edit/delete own comments, report comments. |
| Follow system | Yes | Yes | Done | Profile and explore user cards support follow/unfollow. |
| Search users | Yes | Yes | Partial | Explore search is stronger than the older Search wrapper. |
| Explore | Yes | Yes | Done | Recommended users, trending posts, post grids, filters. |
| Saved posts | Yes | Yes | Done | Saved Posts route is now reachable from Profile. |
| Notifications | Yes | Yes | Done | Badge, filters, mark read/all read, delete, navigation. |
| Chat | Yes | Yes | Done | Messages is now a main bottom tab. |
| Stories | Yes | Yes | Done | Home row, create story, viewer, viewed state, delete own story. |
| Settings | Yes | Yes | Done | Settings accessible from Profile. |
| Reports | Yes | Yes | Done | Post, comment, and user report dialogs are connected. |
| Admin | Yes | Yes | Partial | Basic dashboard, reports, and users screens exist for admin/moderator roles. |

## 3. UI Problems Found

- Navigation: bottom navigation lived inside Home and only exposed Feed, Explore, Create, and Profile. Messages was hidden behind an app bar icon.
- Screen layout: main tabs were not represented as one consistent app shell.
- Visual consistency: reusable widgets exist, but some actions still used local button patterns.
- Spacing: most screens use `AppSizes`, but some older sections still use literal spacing.
- Buttons: Profile had a Saved Posts button with no route action.
- Cards: cards are consistent enough for the assignment, but nested screens could use more density tuning later.
- Colors: color constants are used widely; a few widgets still use direct Material defaults.
- Typography: `AppTextStyles` exists, but some screen headings rely on local theme calls.
- Empty/loading/error states: most screens have them; admin screens are intentionally simple.
- Profile flow: current profile had settings/logout but saved posts was disconnected.
- Feed flow: feed modes, stories, refresh, skeleton loading, post actions, and unread notification badges are integrated on Home. Search is now treated as an Explore behavior instead of competing with the feed modes on Home.
- Create post flow: the Create tab now opens a post/story hub. Create Post includes validation, image selection, preview/removal, loading state, character count, and success navigation.
- Chat flow: conversations existed but were not a main app tab.
- Settings flow: settings works and now exposes Admin Panel for admin/moderator users.

## 4. User Flow Problems Found

- Login to home flow works, but Home previously had too much responsibility as both screen and shell.
- Home navigation did not include Messages as a first-class destination.
- Create post flow did not clearly offer Create Story.
- Viewing post details and comments works, with report/delete actions available.
- Profile edit flow works, but current profile needed a live Saved Posts button.
- Follow user flow works through profiles and explore.
- Notification flow works from Home app bar and maintains badge count.
- Chat flow works better as a main Messages tab.
- Story flow is integrated on Home, with Create Story now available from Create.
- Settings flow works from Profile, including admin entry for privileged roles.

## 5. Improvement Plan

1. Add a reusable `AppShell` for primary navigation.
2. Promote Messages to the bottom navigation.
3. Add a Create hub for post/story creation.
4. Keep existing detail routes outside the shell.
5. Connect disconnected profile actions like Saved Posts.
6. Keep report/admin features role-aware and hidden from normal users.
7. Continue polishing screen-level spacing, typography, and empty states in future passes.

## 6. Improvements Completed In This Pass

- Added a reusable app shell for Home, Explore, Create, Messages, and Profile.
- Promoted Messages to a primary tab.
- Added a Create hub for Create Post and Create Story.
- Kept `/search` working by routing it to Explore.
- Connected Saved Posts from the current user profile.
- Tightened Home into a feed-first screen with stories, feed mode chips, loading, empty, retry, pull-to-refresh, and new-post banner support.
- Added a Stories section header and empty story message for fresh accounts.
- Improved PostCard action wrapping on narrow screens.
- Added Create Post live character count and disabled submit state.
