# Account Management Roadmap

## Current Features

- User settings row with privacy and notification preferences.
- Account status on users: `active`, `deactivated`, `banned`.
- Safe account deactivation with Sanctum token revocation.
- Safe delete endpoint that deactivates instead of hard deleting.
- Flutter settings screens for Account, Privacy, and Notifications.

## Future Full Deletion Workflow

- Add a deletion request table with requested date, grace period, and completion timestamp.
- Anonymize user-owned content where retention is required.
- Delete or detach media assets from storage.
- Add admin review and audit logging.
- Notify the user before final deletion.

## Future Password Login Support

- Add email/password registration for non-social accounts.
- Add password change and password reset flows.
- Require recent authentication before destructive account actions.

## Future Two-Factor Authentication

- Add TOTP setup and recovery codes.
- Require 2FA for sensitive settings changes.
- Add trusted device management.

## Future Blocked Users

- Add blocked users table.
- Prevent blocked users from messaging, following, and interacting.
- Hide blocked user content where appropriate.

## Future Privacy Enforcement

- Enforce `allow_messages` in the conversation creation API.
- Enforce `show_email` consistently across all public user resources.
- Add private profile visibility rules.

## Future Push Notification Preferences

- Connect push notification tokens to user settings.
- Respect push/email preferences in notification dispatch jobs.
- Add per-event notification controls.
