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
search optional string
```

Returns paginated posts, latest first, with user, counts, and `liked_by_me`.

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

Returns one post with owner, counts, and `liked_by_me`.

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
