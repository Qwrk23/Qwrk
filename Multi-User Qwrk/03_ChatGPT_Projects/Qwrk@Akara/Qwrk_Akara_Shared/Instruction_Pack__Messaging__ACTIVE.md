# Instruction Pack: Messaging (ACTIVE)

> Covers `messaging.send_email` and `messaging.create_calendar_event` Gateway actions.
>
> **ACTIVE Alias:** This file is the current authoritative version of the Messaging instruction pack. Managed via Pattern C — on version bump, this file is archived and a new ACTIVE file is written. The Instruction Pack Index always references this filename.

---

## Send Email (`messaging.send_email`)

### Canonical Rule

Qwrk emails should be sent using `body_html`.

Recommended practice is to include both:

- `body_html` for clean rendering in modern email clients
- `body_text` as plain-text fallback for compatibility

Do **not** use a `body` field. Gateway validation requires at least one of `body_html` or `body_text`.

### Preferred Payload Pattern

```json
{
  "gw_action": "messaging.send_email",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "to": ["recipient@example.com"],
  "subject": "Subject line",
  "body_html": "<p>Email body (HTML)</p>",
  "body_text": "Email body (plain text fallback)"
}
```

### Minimum Valid Payload

```json
{
  "gw_action": "messaging.send_email",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "to": ["recipient@example.com"],
  "subject": "Subject line",
  "body_html": "<p>Email body (HTML)</p>"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `to` | YES | Non-empty array of valid email addresses. Supports one or more recipients. |
| `subject` | YES | Plain text subject line. |
| `body_html` | YES* | Strongly recommended canonical field for readable formatting in email clients. |
| `body_text` | YES* | Optional but recommended plain-text fallback. |

`*` At least one of `body_html` or `body_text` is required. Best practice is to provide both.

Sends via Gmail (Qwrk identity). A communication snapshot is saved automatically.

### Validation Notes

Observed Gateway validation rules:

1. `to` must be an array, not a string.
2. At least one of `body_html` or `body_text` is required.
3. `body` is not a valid substitute.

Valid:

```json
"to": ["akara@example.com"]
```

Also valid:

```json
"to": ["akara@example.com", "someone@example.com"]
```

Invalid:

```json
"to": "akara@example.com"
```

Invalid:

```json
{
  "subject": "Test",
  "body": "Hello"
}
```

### Email Formatting Standard

Use `body_html` for all emails unless there is a specific reason to send plain text only.

Preferred HTML structure:

1. Greeting paragraph
2. Short context paragraph
3. Clear section heading or lead-in
4. Ordered list for steps or actions
5. Unordered list for file names, checks, or grouped items
6. Short closing paragraph
7. Signature block

### HTML Style Guidance

Use lightweight, email-safe HTML only:

- `<p>` for paragraphs
- `<strong>` for emphasis
- `<ol>` and `<ul>` for lists
- `<li>` for list items
- `<br>` for simple line breaks inside signature blocks
- `<code>` for filenames, payload field names, and exact literals

Avoid relying on complex CSS, scripts, or app-style layouts.

### Email Quality Rules

- Never send long instructions as a single plain-text blob when `body_html` is available.
- When referencing filenames, wrap them in `<code>`.
- When giving steps, use an ordered list.
- When giving grouped checks or file sets, use bullets.
- Keep paragraphs short.
- Prefer readable formatting over dense prose.
- Include a simple sign-off.
- `body_text` should reflect the same meaning as `body_html`, not different content.

### Signature Guidance

Default signature pattern — adapt to context:

```html
<p>Thank you,<br>
Akara</p>

<p>—<br>
Sent via Qwrk</p>
```

Use a personal signature when the email is sent in the user's voice. Otherwise, use a Qwrk system signature or a combined signature where appropriate.

---

## Create Calendar Event (`messaging.create_calendar_event`)

```json
{
  "gw_action": "messaging.create_calendar_event",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "title": "Meeting title",
  "start": "2026-03-15T09:00:00-05:00",
  "end": "2026-03-15T10:00:00-05:00",
  "description": "Optional description",
  "location": "Optional location",
  "attendees": ["person@example.com"]
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `title` | YES | Event title |
| `start` | YES | ISO 8601 datetime with timezone |
| `end` | YES | ISO 8601 datetime, must be after `start` |
| `description` | no | Plain text or HTML |
| `location` | no | Free-text |
| `attendees` | no | Array of email addresses. Invitations sent automatically. |

Creates on Qwrk's Google Calendar. A communication snapshot is saved automatically.

---

## Response Format

Both actions return:

```json
{
  "ok": true,
  "gw_action": "messaging.send_email",
  "artifact_id": "<uuid>",
  "trace_id": "msg_<uuid>"
}
```

## Error Codes

| Code | Meaning |
|------|---------|
| `VALIDATION_ERROR` | Missing or invalid required fields |
| `PROVIDER_DISPATCH_FAILED` | Gmail/Calendar API rejected the request |
| `ARTIFACT_SAVE_FAILED` | Message sent but snapshot save failed |

---

## Constraints

- Email payload `to` must be passed as an array.
- Multiple recipients are supported in a single email action.
- At least one of `body_html` or `body_text` is required.
- `body_html` is the canonical format for Qwrk emails.
- `body` is not a valid email body field.
- CC/BCC not supported in v2.2.
- Attachments not supported in v2.2.
- Recurring calendar events not supported in v2.2.

---

*CHANGELOG: ACTIVE (2026-03-30): Introduced ACTIVE alias pattern. Content identical to Akara v2.2. Filename is now the stable entry point referenced by Instruction Pack Index — on version bump, this file is archived via Pattern C and replaced with updated content. Prior version: `Archive/Instruction_Pack__Messaging__v2.2__2026-03-30.md`. v2.2 (2026-03-21): Akara workspace adaptation from Prime Messaging IP v2.2.*
