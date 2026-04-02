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
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
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
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
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
"to": ["joel@halosparkai.com"]
```

Also valid:

```json
"to": ["joel@halosparkai.com", "j_blagg@hotmail.com"]
```

Invalid:

```json
"to": "joel@halosparkai.com"
```

Invalid:

```json
{
  "subject": "Test",
  "body": "Hello"
}
```

### Email Formatting Standard

Use `body_html` for all operator-facing and customer-facing Qwrk emails unless there is a specific reason to send plain text only.

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

### Qwrk Email Quality Rules

- Never send long operational instructions as a single plain-text blob when `body_html` is available.
- When referencing filenames, wrap them in `<code>`.
- When giving steps, use an ordered list.
- When giving grouped checks or file sets, use bullets.
- Keep paragraphs short.
- Prefer readable operator formatting over dense prose.
- Include a simple sign-off.
- `body_text` should reflect the same meaning as `body_html`, not different content.

### Standard Signature Guidance

Default automated email signature pattern:

```html
<p>Thank you,<br>
Joel</p>

<p>—<br>
Sent via Qwrk Messaging Subsystem</p>
```

Use a human signature only when the email is intentionally being sent in Joel's voice. Otherwise, use a Qwrk system signature or a combined human + system signature where appropriate.

### Recommended HTML Example

```json
{
  "gw_action": "messaging.send_email",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "to": ["recipient@example.com"],
  "subject": "New Qwrk Update Files",
  "body_html": "<p>Hi Akara,</p><p>You have new <strong>Qwrk update files</strong> to process in your <strong>Qwrk_Akara_Shared</strong> folder.</p><p><strong>Two actions are required:</strong></p><ol><li><strong>Add one new file</strong><ul><li><code>Instruction_Pack_Index.md</code></li></ul></li><li><strong>Replace one existing file</strong><ul><li>Remove <code>Instruction_Pack__Payload_Discipline__v1.md</code></li><li>Add <code>Instruction_Pack__Payload_Discipline__v2.md</code></li></ul></li></ol><p><strong>Step-by-step:</strong></p><ol><li>Open the <strong>Qwrk_Akara_Shared</strong> folder.</li><li>Locate <code>Instruction_Pack_Index.md</code>.</li><li>Upload it into your Qwrk project files.</li><li>Locate <code>Instruction_Pack__Payload_Discipline__v1.md</code> in the project files.</li><li>Remove it.</li><li>Return to the shared folder.</li><li>Locate <code>Instruction_Pack__Payload_Discipline__v2.md</code>.</li><li>Upload it into the project files.</li><li>Confirm the final state:<ul><li><code>Instruction_Pack_Index.md</code> present</li><li><code>Instruction_Pack__Payload_Discipline__v1.md</code> removed</li><li><code>Instruction_Pack__Payload_Discipline__v2.md</code> present</li></ul></li></ol><p>That will bring your system instructions fully up to date.</p><p>Thank you,<br>Joel</p><p>—<br>Sent via Qwrk Messaging Subsystem</p>",
  "body_text": "Hi Akara,\n\nYou have new Qwrk update files to process in your Qwrk_Akara_Shared folder.\n\nTwo actions are required:\n\n1. Add one new file\n   - Instruction_Pack_Index.md\n\n2. Replace one existing file\n   - Remove Instruction_Pack__Payload_Discipline__v1.md\n   - Add Instruction_Pack__Payload_Discipline__v2.md\n\nStep-by-step:\n1. Open the Qwrk_Akara_Shared folder.\n2. Locate Instruction_Pack_Index.md.\n3. Upload it into your Qwrk project files.\n4. Locate Instruction_Pack__Payload_Discipline__v1.md in the project files.\n5. Remove it.\n6. Return to the shared folder.\n7. Locate Instruction_Pack__Payload_Discipline__v2.md.\n8. Upload it into the project files.\n9. Confirm the final state:\n   - Instruction_Pack_Index.md present\n   - Instruction_Pack__Payload_Discipline__v1.md removed\n   - Instruction_Pack__Payload_Discipline__v2.md present\n\nThat will bring your system instructions fully up to date.\n\nThank you,\nJoel\n\n—\nSent via Qwrk Messaging Subsystem"
}
```

---

## Create Calendar Event (`messaging.create_calendar_event`)

```json
{
  "gw_action": "messaging.create_calendar_event",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
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

## Known Recipients

| Name | Email | Workspace |
|------|-------|-----------|
| Akara | joel@halosparkai.com | Akara_Blagg (`963973e0-a98c-4044-b421-71e7348eaeaf`) |

When sending to a known recipient, use the email from this table. Do not infer or guess email addresses.

---

## Constraints

- Email payload `to` must be passed as an array.
- Multiple recipients are supported in a single email action.
- At least one of `body_html` or `body_text` is required.
- `body_html` is the canonical format for Qwrk emails.
- `body` is not a valid email body field.
- CC/BCC not supported in v2.2.
- Attachments not supported in v2.2.
- Recurring calendar events not supported in v2.2 (tracked as T124).
- Both actions are Prime-workspace only.

---

*CHANGELOG: ACTIVE (2026-03-30): Introduced ACTIVE alias pattern. Content identical to v2.2. Filename is now the stable entry point referenced by Instruction Pack Index — on version bump, this file is archived via Pattern C and replaced with updated content. Prior version: `instruction_pack_messaging_v_2_2.md` (v2.2). v2.2 (2026-03-12): Added email rendering and formatting standards. v2.1 (2026-03-12): Multi-recipient correction. v2.0 (2026-03-12): Array-based `to` field. v1.0 (2026-03-12): Initial.*
