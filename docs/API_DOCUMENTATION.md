# SnapCircle API Documentation

Base URL:

```txt
http://127.0.0.1:8000
```

Protected endpoints require a Sanctum bearer token:

```http
Authorization: Bearer {token}
Accept: application/json
```

## Response Format

Success:

```json
{
  "success": true,
  "message": "Success message",
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "message": "Error message",
  "errors": {}
}
```

## Health Check

### GET /api/health

Authentication: No

Response:

```json
{
  "status": "ok",
  "app": "SnapCircle API"
}
```

## Authentication

### POST /api/auth/google

Authentication: No

Request:

```json
{
  "access_token": "google_access_token_here"
}
```

Response:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {},
    "token": "plain_text_token",
    "token_type": "Bearer"
  }
}
```

Error:

```json
{
  "success": false,
  "message": "Invalid social token",
  "errors": {}
}
```

### POST /api/auth/facebook

Authentication: No

Request:

```json
{
  "access_token": "facebook_access_token_here"
}
```

Response format matches Google login.

### GET /api/user

Authentication: Yes

Returns the authenticated user.

### POST /api/logout

Authentication: Yes

Deletes the current Sanctum access token.

## Profile

### GET /api/profile

Authentication: Yes

Returns the authenticated user's profile with `posts_count`, `followers_count`, and `following_count`.

### PUT /api/profile

Authentication: Yes

Request type: `multipart/form-data`

Fields:

```txt
name    required string max:255
bio     nullable string max:500
avatar  nullable image jpg,png,jpeg,webp max:2MB
```

## Users

### GET /api/users

Authentication: Yes

Query parameters:

```txt
search optional string
```

Returns paginated users with counts and `is_followed_by_me`.

### GET /api/users/{user}

Authentication: Yes

Returns a public user profile without sensitive provider IDs or tokens.

## Follow System

### POST /api/users/{user}/follow

Authentication: Yes

Follows another user. Users cannot follow themselves.

### DELETE /api/users/{user}/follow

Authentication: Yes

Unfollows another user.

### GET /api/users/{user}/followers

Authentication: Yes

Returns a paginated list of users following the selected user.

### GET /api/users/{user}/following

Authentication: Yes

Returns a paginated list of users the selected user follows.

Follow status response:

```json
{
  "success": true,
  "message": "User followed successfully",
  "data": {
    "followers_count": 10,
    "following_count": 5,
    "is_followed_by_me": true
  }
}
```

## Posts

### GET /api/posts

Authentication: Yes

Query parameters:

```txt
mode     optional string: all, following, popular, mine
search   optional string max:255
page     optional integer min:1
per_page optional integer min:1 max:50
```

Examples:

```http
GET /api/posts?mode=all&page=1&per_page=10
GET /api/posts?mode=following&page=1&per_page=10
GET /api/posts?mode=popular&page=1&per_page=10
GET /api/posts?mode=mine&page=1&per_page=10
GET /api/posts?mode=all&search=hello&page=1&per_page=10
```

Feed modes:

- `all`: latest posts from everyone.
- `following`: posts from followed users plus the authenticated user's own posts.
- `popular`: posts ordered by likes count, comments count, then latest.
- `mine`: posts created by the authenticated user.

Response:

```json
{
  "success": true,
  "message": "Posts fetched successfully",
  "data": {
    "data": [
      {
        "id": 1,
        "content": "Hello SnapCircle",
        "image_url": null,
        "created_at": "2026-06-05T00:00:00.000000Z",
        "user": {},
        "likes_count": 3,
        "comments_count": 2,
        "saves_count": 1,
        "liked_by_me": false,
        "saved_by_me": true,
        "is_owner": true,
        "can_update": true,
        "can_delete": true
      }
    ],
    "current_page": 1,
    "last_page": 1,
    "per_page": 10,
    "total": 1
  }
}
```

### POST /api/posts

Authentication: Yes

Request type: `multipart/form-data`

Fields:

```txt
content nullable string max:5000
image   nullable image jpg,png,jpeg,webp max:2MB
```

At least `content` or `image` is required.

### GET /api/posts/{post}

Authentication: Yes

Returns one post with owner, counts, `liked_by_me`, `saved_by_me`, `saves_count`, `is_owner`, `can_update`, and `can_delete`.

Flutter route:

```txt
/posts/{postId}
```

### PUT /api/posts/{post}

Authentication: Yes

Only the post owner can update. Supports replacing image uploads.

### DELETE /api/posts/{post}

Authentication: Yes

Only the post owner can soft delete.

## Likes

### POST /api/posts/{post}/like

Authentication: Yes

Likes a post. Duplicate likes return a clean already-liked message.

### DELETE /api/posts/{post}/like

Authentication: Yes

Unlikes a post. If the post was not liked, returns a clean not-liked message.

## Saved Posts

### POST /api/posts/{post}/save

Authentication: Yes

Saves a post for the authenticated user. Duplicate saves return a clean already-saved message.

Response:

```json
{
  "success": true,
  "message": "Post saved successfully",
  "data": {
    "post_id": 1,
    "saved_by_me": true,
    "saves_count": 12
  }
}
```

### DELETE /api/posts/{post}/save

Authentication: Yes

Removes a post from the authenticated user's saved posts. If the post was not saved, the API still returns a successful response with `saved_by_me` set to `false`.

Response:

```json
{
  "success": true,
  "message": "Post removed from saved posts",
  "data": {
    "post_id": 1,
    "saved_by_me": false,
    "saves_count": 11
  }
}
```

### GET /api/saved-posts

Authentication: Yes

Query parameters:

```txt
page     optional integer min:1
per_page optional integer min:1 max:50
```

Returns paginated saved posts, latest saved first.

Response shape:

```json
{
  "success": true,
  "message": "Saved posts fetched successfully",
  "data": {
    "data": [],
    "current_page": 1,
    "last_page": 1,
    "per_page": 10,
    "total": 0
  }
}
```

Post resources include `saves_count` and `saved_by_me`.

## Comments

### GET /api/posts/{post}/comments

Authentication: Yes

Returns paginated comments, latest first, with comment owner data.

### POST /api/posts/{post}/comments

Authentication: Yes

Request:

```json
{
  "comment": "Nice post!"
}
```

Rules: `comment` is required, string, max 1000 characters.

### PUT /api/comments/{comment}

Authentication: Yes

Only the comment owner can update.

Request:

```json
{
  "comment": "Updated comment text"
}
```

### DELETE /api/comments/{comment}

Authentication: Yes

Only the comment owner can soft delete.
