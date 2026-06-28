# Snap Circle UI and Feature Concept

This concept updates Snap Circle into a mobile-first social app for sharing quick moments with close friends, trusted groups, and event-based circles. The goal is to keep the familiar feed, stories, chat, and profile patterns while making the product feel cleaner, faster, safer, and more playful.

## Product Direction

Snap Circle should feel like a private social camera wrapped around close relationships. The app should make it obvious where to capture a moment, who will see it, and how friends can respond.

Core experience goals:

- Fast sharing: camera, stories, chats, and circles are reachable in one tap.
- Safer sharing: every post and snap clearly shows its audience before sending.
- Close-friend energy: circles, streaks, reactions, memories, and shared albums make small groups feel alive.
- Low clutter: dense social features are grouped behind familiar tabs, bottom sheets, and contextual actions.
- Friendly accessibility: readable type, strong contrast, large tap targets, clear labels, and predictable navigation.

## Primary Navigation

Use five main tabs, with Camera as the center action:

| Tab | Purpose | Key Actions |
|---|---|---|
| Home | Personal feed and quick access | Stories, recent circles, camera shortcut, profile shortcut |
| Circles | Private groups and shared albums | Create circle, circle stories, polls, albums, members |
| Camera | Capture and share snaps | Photo, video, filters, stickers, music, AI captions |
| Chats | Direct and circle messaging | Pinned chats, streaks, voice notes, quick replies |
| Profile | Identity, memories, privacy | Stats, badges, circles, saved posts, settings |

Secondary destinations such as Explore, Notifications, Settings, Admin, Post Detail, Comments, and Story Viewer remain reachable through app bars, cards, and deep links instead of competing for bottom-nav space.

## Design System

### Visual Personality

The new style should feel bright, youthful, and calm. Use rounded surfaces, bold icons, soft color accents, and short animations. Avoid heavy visual noise: the UI should feel playful through motion and details, not through clutter.

### Color Tokens

| Token | Light Mode | Dark Mode | Use |
|---|---|---|---|
| Primary | `#2563EB` | `#60A5FA` | Main actions, selected tabs, links |
| Circle | `#7C3AED` | `#A78BFA` | Circle features, private group highlights |
| Moment | `#EC4899` | `#F472B6` | Stories, memories, reactions |
| Fresh | `#06B6D4` | `#22D3EE` | Camera tools, info states |
| Success | `#16A34A` | `#4ADE80` | Sent, shared, accepted |
| Warning | `#F59E0B` | `#FBBF24` | Privacy reminders, streaks |
| Background | `#FAFAFA` | `#000000` | App background |
| Surface | `#FFFFFF` | `#0A0A0A` | Navigation, sheets, cards |
| Border | `#E4E4E7` | `#27272A` | Dividers and quiet outlines |

Use subtle gradients only in high-value surfaces such as story rings, circle covers, camera capture states, or empty-state illustrations. Most screens should use solid surfaces and accent chips for clarity.

### Typography

- Brand and page titles: 24-32px, extra bold, tight but readable line height.
- Section titles: 17-20px, bold, sentence case.
- Body text: 14-16px, medium weight, generous line height.
- Metadata and labels: 11-13px, bold enough to stay readable.
- Buttons: 14-15px, bold, never all caps.

### Shape and Spacing

- Cards and controls: 8px radius by default.
- Avatars, story rings, and capture controls: circular.
- Bottom sheets: 20-24px top radius.
- Screen padding: 16px mobile default, 12px for compact phones.
- Card gaps: 10-14px in feeds, 16-24px between larger sections.
- Tap targets: minimum 44x44px, with visible focus and pressed states.

### Iconography

Use bold, familiar Material icons consistently:

- Camera: `camera_alt`, `flash_on`, `flip_camera_ios`, `auto_awesome`.
- Circles: `groups_2`, `lock`, `photo_library`, `poll`, `celebration`.
- Chats: `chat_bubble`, `mic`, `push_pin`, `favorite`, `bolt`.
- Profile: `person`, `verified`, `shield`, `history`, `settings`.

### Motion

- Tab transitions: 180-220ms fade and slight slide.
- Button press: 90-120ms scale.
- Story/circle cards: gentle entrance fade on first load.
- Camera capture: quick flash overlay and haptic feedback.
- Message reactions: small pop animation, then settle.

### Accessibility

- Keep text contrast at WCAG AA or better.
- Provide text labels for icon-only actions through tooltips and semantics.
- Avoid relying only on color for privacy states; pair color with lock, shield, or audience labels.
- Support reduced motion by shortening or removing decorative animations.
- Keep dynamic text from overflowing by using wrapping, max lines, and responsive constraints.

## Screen-by-Screen Concept

### 1. Home Screen

Purpose: quick pulse of close friends, stories, and recent activity.

Layout:

- Top app bar with Snap Circle wordmark, notification badge, and compact profile avatar.
- Search field or icon leading to Explore.
- Quick action rail below the app bar:
  - Camera
  - My Story
  - Circles
  - Chats
  - Profile
- Stories row with:
  - Add story tile
  - Close friends story ring
  - Circle story rings with small group badges
- "Today in your circles" section with 2-3 compact circle cards:
  - Circle name
  - member avatars
  - unread stories count
  - latest shared moment thumbnail
- Feed filter segmented control:
  - For You
  - Close Friends
  - Circles
  - Popular
- Post feed with smoother cards:
  - larger media preview
  - clearer author and audience label
  - reaction row with like, reply, share, save
  - quick reply chips for stories and circle posts

Feature improvements:

- Audience chip on every post: Public, Friends, Close Friends, or Circle name.
- New-post banner stays compact and anchored near the top of the feed.
- "Share a moment" composer opens Camera by default, with text post as a secondary option.
- Empty feed suggests: add friends, create a circle, or capture first snap.

### 2. Circles Tab

Purpose: make private group sharing the heart of Snap Circle.

Layout:

- Header with title "Circles" and create button.
- Horizontal circle type filters:
  - All
  - Close Friends
  - School
  - Family
  - Events
- Featured "Close Friends" card for the most active circle.
- Circle list cards:
  - cover image or soft accent background
  - circle name and privacy label
  - stacked member avatars
  - story count, album count, unread chat count
  - quick buttons for Story, Album, Poll, Chat

Create circle flow:

- Choose template:
  - Close friends
  - School friends
  - Family
  - Event
  - Custom
- Add name, cover, privacy, members, and default posting rules.
- Set default sharing mode:
  - Stories expire after 24 hours
  - Album posts stay saved
  - Admin approval for new members

Circle detail layout:

- Cover header with circle name, member count, privacy status, and settings.
- Story carousel for circle stories.
- Tab bar:
  - Moments
  - Album
  - Chat
  - Polls
  - Members
- Pinned announcement card for events or plans.
- Quick composer with Camera, Poll, Album Upload, and Message.

Circle features:

- Circle stories: short-lived stories visible only to members.
- Shared albums: persistent photo collections for trips, classes, family events, or birthdays.
- Reactions: emoji reactions on snaps, album photos, polls, and messages.
- Polls: quick group decisions with options, expiration, and visible voters.
- Quick replies: reusable reply chips like "On my way", "Love this", "Send more", and "Where was this?"
- Member roles: Owner, Admin, Member.
- Safety controls: remove member, mute circle, leave circle, report content.

### 3. Camera Experience

Purpose: fastest path from moment to trusted audience.

Layout:

- Full-screen camera preview.
- Top controls:
  - Close
  - Flash
  - Timer
  - Audience selector
  - Flip camera
- Bottom controls:
  - Gallery
  - Capture button
  - Camera mode carousel
  - Send shortcut
- Right-side tool stack:
  - Filters
  - Stickers
  - Caption
  - Music
  - AI Suggestions

Modes:

- Snap
- Video
- Story
- Circle
- Memory

AI-powered suggestions:

- Caption ideas based on image context and selected audience.
- Effect suggestions such as warm, party, study, food, travel, or throwback.
- Memory prompts like "One year ago with this circle" or "Add to school album."
- Smart audience suggestion based on people detected, location, or recent sharing patterns.

Sharing flow:

- Capture or select media.
- Edit with caption, stickers, music, crop, filters, and privacy.
- Choose audience:
  - My Story
  - Close Friends
  - Specific Circle
  - Direct Chat
  - Save to Memories
- Send with one primary button and optional "also save to album" toggle.

### 4. Chats Tab

Purpose: direct and circle conversations that feel lightweight and alive.

Layout:

- Header with "Chats", search, and new message button.
- Pinned chats section with small horizontal cards.
- Chat list grouped by:
  - Pinned
  - Circles
  - Direct
- Conversation row:
  - avatar or circle icon
  - name
  - last message preview
  - streak badge
  - unread badge
  - mute or pinned indicator

Chat detail:

- Minimal header with avatar, name, activity, and actions.
- Message bubbles with clear sender states.
- Reaction bar on long press.
- Composer with:
  - camera
  - text field
  - voice note
  - stickers
  - quick replies
- Context panel for circle chats:
  - shared media
  - polls
  - pinned messages
  - members

Chat features:

- Message reactions.
- Voice notes with hold-to-record and slide-to-cancel.
- Pinned chats and pinned messages.
- Streak reminders for close friends and circles.
- Circle-based group chats linked directly to Circle detail.
- Quick replies from snaps, stories, and polls.
- Read states that stay subtle and do not clutter the bubble layout.

### 5. Stories and Snap Viewer

Purpose: immersive, fast consumption with easy replies.

Layout:

- Full-screen story media with progress bars.
- Top row:
  - avatar
  - name
  - circle/audience badge
  - more menu
- Bottom reply area:
  - quick reaction row
  - reply field
  - share/send button

Story features:

- Circle story badge when the story belongs to a private circle.
- Quick replies with common phrases.
- Reaction stack visible to the author.
- Viewer list with privacy-aware visibility.
- Add to shared album when story belongs to a circle.

### 6. Profile Screen

Purpose: identity, memories, circles, and privacy at a glance.

Layout:

- Cover image with gradient fallback.
- Avatar, name, username, privacy badge, and edit/follow/chat actions.
- Stats row:
  - Moments
  - Circles
  - Friends
  - Memories
- Badge strip:
  - Early member
  - Top friend
  - Streak keeper
  - Circle host
- Profile tabs:
  - Moments
  - Memories
  - Circles
  - Badges
- Profile completion card remains only when useful.
- Quick actions:
  - Edit profile
  - Privacy
  - Saved
  - Settings

Profile features:

- Memories timeline grouped by month, circle, or event.
- Circle membership cards with privacy labels.
- Public/private preview toggle to see what others can view.
- Badge detail sheets explaining how each badge was earned.
- Safer profile metadata defaults: private accounts hide circles, location, and activity unless enabled.

### 7. Privacy and Settings

Purpose: make safety understandable without burying controls.

Settings structure:

- Account
- Privacy and Safety
- Notifications
- Circles
- Memories
- Appearance
- Blocked users
- Help and feedback

Privacy screen:

- Friendly privacy summary at the top:
  - "Your account is private"
  - "Only approved friends can see your moments"
  - "Circle posts stay inside their circle"
- Toggle groups:
  - Account visibility
  - Story replies
  - Message requests
  - Who can add me to circles
  - Show activity status
  - Show memories suggestions
- Privacy presets:
  - Open
  - Friends only
  - Private
  - Custom

Safety features:

- Blocked users with search.
- Report history for user confidence.
- Circle invite approvals.
- Sensitive content warning for unknown senders.
- Clear "What others see" preview.

### 8. Explore and Search

Purpose: discovery without overwhelming the private-first product.

Layout:

- Search bar at top.
- Recent searches as small chips.
- Trending tags and public posts.
- Recommended people.
- Recommended circles only if public/invite-based circles are supported.

Feature direction:

- Explore remains secondary to Home and Circles.
- Public discovery should never expose private circle content.
- Search results should separate People, Posts, Tags, and Circles.

### 9. Notifications

Purpose: clear activity without becoming a noisy main tab.

Layout:

- Filters:
  - All
  - Mentions
  - Circles
  - Requests
- Notification cards with source avatar, action icon, timestamp, and one clear CTA.
- Circle invites and follow requests use richer cards with Accept and Decline.

Feature direction:

- Bundle repeated reactions into one notification.
- Prioritize privacy and security alerts.
- Add digest controls for circles and chats.

## Key User Flows

### Capture and Share to a Circle

1. User taps center Camera tab.
2. Camera opens with last-used audience visible.
3. User captures snap.
4. AI suggests caption and effect.
5. User selects a circle or accepts the suggested audience.
6. User sends, optionally saving to shared album.
7. Circle members see the snap in Circle Stories and circle chat preview.

### Create a Private Circle

1. User opens Circles tab.
2. User taps Create.
3. User picks a template such as School, Family, Close Friends, or Event.
4. User adds members and sets privacy rules.
5. App creates circle with starter actions: Story, Album, Poll, Chat.
6. Empty circle suggests first snap, first poll, or first album.

### Reply to a Friend's Moment

1. User views story from Home.
2. User taps a quick reaction or writes a reply.
3. Reply opens the relevant direct chat or circle chat.
4. Story context appears above the first reply.
5. User can continue chatting, react, or send a voice note.

### Review Privacy

1. User opens Profile.
2. User taps Privacy.
3. Privacy summary explains current visibility.
4. User selects preset or custom controls.
5. App shows a preview of what friends, non-friends, and circle members can see.

## Component Inventory

Reusable components to add or update:

- `AudienceChip`: shows Public, Friends, Close Friends, or Circle.
- `QuickActionRail`: Home shortcuts for Camera, Story, Circles, Chats, Profile.
- `CircleCard`: compact and large variants for circle lists and Home previews.
- `StoryRing`: user and circle story states with viewed/unviewed styling.
- `SnapCaptureButton`: animated capture button with mode state.
- `ToolRailButton`: camera tools with tooltip and selected state.
- `ReactionPicker`: emoji reactions for posts, stories, snaps, and messages.
- `QuickReplyBar`: horizontal suggested replies.
- `PrivacySummaryCard`: plain-language privacy state and action.
- `BadgePill`: profile achievements and circle roles.
- `PinnedChatCard`: compact pinned conversation preview.
- `VoiceNoteComposer`: record, preview, send, and cancel states.

## Content and Microcopy

Tone should be simple, warm, and confidence-building.

Examples:

- Audience label: "Close Friends only"
- Circle empty state: "Start this circle with a snap, poll, or shared album."
- Camera AI prompt: "Try a caption for this moment"
- Privacy summary: "Your circle posts stay inside the circle."
- Chat streak: "Keep your streak alive today"
- Send confirmation: "Shared with Family Circle"

Avoid technical language such as "permissions configured", "visibility state", or "resource owner." Use plain explanations tied to who can see or reply.

## Implementation Phases

### Phase 1: Navigation and Visual Refresh

- Move primary navigation toward Home, Circles, Camera, Chats, Profile.
- Add Home quick action rail.
- Refresh cards, chips, icons, spacing, and motion.
- Add audience chips to posts and stories.
- Improve dark-mode contrast and selected states.

### Phase 2: Circle Experience

- Add Circles tab and circle list.
- Add create circle flow and templates.
- Add circle detail with Moments, Album, Chat, Polls, Members.
- Add circle story badges and privacy labels.
- Connect circle chat entry points.

### Phase 3: Camera and Sharing

- Redesign camera capture UI.
- Add audience selector and send sheet.
- Add caption, sticker, music, and filter tool rails.
- Add AI suggestion UI hooks for captions, effects, memories, and audiences.
- Optimize capture-to-send path.

### Phase 4: Chat Upgrades

- Add pinned chats.
- Add reactions and quick replies.
- Add voice notes.
- Add streak reminders.
- Add circle chat context panel.

### Phase 5: Profile, Memories, and Privacy

- Add profile stats, badges, memories, and circle cards.
- Redesign privacy settings with presets and previews.
- Add memories timeline and memory suggestions.
- Add clearer blocked-user and safety flows.

## Success Metrics

- Time to share a snap to a circle is under 10 seconds.
- Main actions are reachable within one tap from Home or bottom navigation.
- Users can identify the audience of every post or snap without opening details.
- Fewer support questions about private accounts and circle visibility.
- Higher usage of stories, circle chats, and shared albums.
- No major overflow issues on compact mobile screens.
- Analyzer and widget tests stay green after each implementation phase.

## Build Notes for the Current App

SnapCircle already includes feed, stories, explore, profiles, settings, notifications, chat, saved posts, blocking, reporting, and admin flows. The redesign should build on those foundations instead of replacing them all at once.

Recommended first code targets:

- Extend `AppShell` with a Circles tab and camera-first center action.
- Add a `features/circles` module with circle models, provider, repository, screens, and widgets.
- Reuse existing stories, chat, media, report, and profile patterns for circle-specific surfaces.
- Update `HomeScreen` with quick actions, audience chips, and circle previews.
- Update `CreateHubScreen` or replace it with a camera-first sharing flow.
- Keep backend integration incremental: circle list, circle detail, circle posts/stories, albums, polls, then chat enhancements.
