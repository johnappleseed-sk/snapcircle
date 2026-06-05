# SnapCircle Feature Specification

This document describes product-facing SnapCircle features as the project evolves from assignment MVP into a startup-ready social app.

## Better Feed Experience

### Goal

Make the feed more useful, navigable, and engaging without breaking the existing posts API or Flutter integrations.

### Feed Modes

| Feed | API Mode | Description |
|---|---|---|
| For You | `all` | Shows latest posts from all users. |
| Following | `following` | Shows posts from users followed by the authenticated user, plus the user's own posts. |
| Popular | `popular` | Shows posts ordered by likes count, comments count, then latest. |
| My Posts | `mine` | Shows only posts created by the authenticated user. |

### API

Endpoint:

```http
GET /api/posts
```

Query parameters:

```txt
mode      all | following | popular | mine
search    optional keyword
page      optional page number
per_page  optional page size
```

Example:

```http
GET /api/posts?mode=following&page=1&per_page=10
```

Response includes:

- post id
- content
- image URL
- author user
- likes count
- comments count
- liked by me
- owner state
- update/delete permission flags
- pagination metadata

### Flutter UI

The home feed includes:

- Feed mode selector chips.
- Post search field.
- Pull to refresh.
- Load more pagination.
- Skeleton loading cards.
- Mode-specific empty states.
- Post detail navigation.

### Post Detail Screen

Route:

```txt
/posts/{postId}
```

The post detail screen:

- Loads a single post if it is not already in the feed cache.
- Reuses the polished `PostCard` layout.
- Supports like/unlike through the existing feed provider.
- Shows a button to open comments.
- Allows owners to delete their post and navigate back safely.

### Empty States

| Context | Title | Subtitle |
|---|---|---|
| For You | No posts yet. | Follow people or create your first post. |
| Following | No posts from people you follow. | Find users to follow and build your circle. |
| Popular | No popular posts yet. | Like and comment on posts to make them trend. |
| Mine | You have not posted yet. | Share your first SnapCircle moment. |
| Search | No posts found. | Try a different keyword. |
