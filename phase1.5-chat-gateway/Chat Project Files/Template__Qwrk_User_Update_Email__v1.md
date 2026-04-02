# Template — Qwrk User Update Email (v1)

**scope:** `operational`
**status:** Active
**created:** 2026-03-29
**origin:** Standardized rollout communication for beta user SI/IP deployments

---

## Purpose

Reusable email template for notifying Qwrk beta users when system instruction or instruction pack updates are deployed to their workspace. Used by CC to generate `messaging.send_email` payloads.

---

## Subject Line

**Action required:** `Qwrk Update — Action Required`

**Informational (no file changes):** `Qwrk Update — What's New`

---

## Template Structure

### Section 1 — Greeting + What's New

```
Hi {RECIPIENT_NAME},

{FEATURE_SUMMARY}

{WHY_IT_MATTERS}
```

`FEATURE_SUMMARY`: 1-3 sentences describing the update in plain language. What changed. No technical jargon. Write for the user, not for the builder.

`WHY_IT_MATTERS`: 1 sentence explaining why the user should care. CC must never skip this — if you can't articulate why it matters to the user, the update isn't ready to communicate.

### Section 2 — How It Works (if new capability)

```
How it works:
- {BEHAVIOR_POINT_1}
- {BEHAVIOR_POINT_2}
- {BEHAVIOR_POINT_3}

You don't need to do anything special. Just talk to Q like you normally would. Q knows how to handle the rest.
```

Include this section only when introducing a new user-facing capability. Omit for backend-only or governance-only updates.

### Section 3 — Expectation Setting (if new capability)

```
We review {DOMAIN} regularly and use it to improve Qwrk — you may see changes directly or we may follow up if we need more detail.
```

Include when the update creates a feedback loop or implies Team Qwrk will act on user input. Omit for purely technical updates.

### Section 4 — File Actions (if action required)

```
To activate this, you need to {ACTION_SUMMARY} in your Qwrk project.

Go to your {SHARED_FOLDER_NAME} folder and upload the following files into your ChatGPT Qwrk project:

1. Replace your system instructions file:
   - Remove the current {OLD_SI_FILENAME} (or whichever version you have)
   - Upload {NEW_SI_FILENAME}

2. Add new file(s):
   - {NEW_FILE_1}
   - {NEW_FILE_2}

3. Replace existing file(s): (if applicable)
   - Remove {OLD_FILE}
   - Upload {NEW_FILE}

After uploading, confirm your project files include:
- {EXPECTED_FILE_1} (updated)
- {EXPECTED_FILE_2} (new)
- {EXPECTED_FILE_3} (new)

Once those files are in place, you're good to go.
```

Omit Section 4 entirely if no file changes are required.

### Section 5 — Closing

```
If you have any questions, just ask Q — or send me a note.

Thank you,
Joel

—
Sent via Qwrk
```

---

## Variable Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `{RECIPIENT_NAME}` | User's first name | `Akara` |
| `{FEATURE_SUMMARY}` | Plain language description of update | `You have a new capability in Qwrk: Feedback Snapshots.` |
| `{WHY_IT_MATTERS}` | 1 sentence explaining why the user should care | `This helps us capture your feedback so we can improve Qwrk faster.` |
| `{BEHAVIOR_POINT_N}` | How the feature works, from user's perspective | `If it sounds like feedback, Q will offer to capture it.` |
| `{DOMAIN}` | What area this touches | `feedback` / `your workspace` / `project tracking` |
| `{ACTION_SUMMARY}` | Brief count of file actions | `add 3 new files` / `replace 1 file and add 2 new files` |
| `{SHARED_FOLDER_NAME}` | User's shared folder name | `Qwrk_Akara_Shared` |
| `{OLD_SI_FILENAME}` | Current SI filename to remove | `qwrk_akara_system_instructions_v_1_3.md` |
| `{NEW_SI_FILENAME}` | Updated SI filename to upload | `qwrk_akara_system_instructions_v_1_4.md` |
| `{NEW_FILE_N}` | New files to add | `Instruction_Pack__Feedback_Snapshot__v1.md` |
| `{OLD_FILE}` | File being replaced | *(only if replacing a non-SI file)* |
| `{NEW_FILE}` | Replacement file | *(only if replacing a non-SI file)* |
| `{EXPECTED_FILE_N}` | Final state verification list | All files that should be present after update |

---

## Tone Rules

- Confident, not corporate
- Clear actions, not procedural anxiety
- Write for a person, not a developer
- Never promise capabilities that aren't built yet
- Never imply automation that doesn't exist
- "You're good to go" > "That will bring your system fully up to date"
- Do not include more than 3 behavior points — if it takes more, the feature explanation needs simplifying
- Do not include more than 5 file actions — if it takes more, batch the deployment or simplify the rollout

---

## HTML Rendering Rules

When generating the `messaging.send_email` payload:

- Use `<p>` for paragraphs
- Use `<ul>` / `<ol>` for lists
- Use `<strong>` for emphasis
- Use `<code>` for filenames
- Use `<hr>` to separate feature description from file actions
- Include both `body_html` and `body_text`
- Follow Messaging IP v2.2 formatting standards

---

## CHANGELOG

### v1 — 2026-03-29

Initial creation. Standardized template for beta user update emails. Parameterized structure with 5 sections: greeting + feature summary, how it works, expectation setting, file actions, closing. Derived from Akara Feedback Snapshot rollout email (session 114c).
