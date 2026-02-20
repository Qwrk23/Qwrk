# Changelist: Frita – Voice Handle v2

**Date:** 2026-02-07
**Base:** `Workflows/Frita – Voice Handle (2).json`
**New:** `Workflows/Frita – Voice Handle v2.json`
**Phase:** Phase 2 — Keyword-based intent routing (crawl mode)

---

## Changes vs Original

### Switch Node — Extended from 4 rules to 12 + fallback

| Output | Intent | Keywords (OR) |
|--------|--------|---------------|
| 0–3 | password_reset | password, locked out, reset, forgot |
| 4–7 | guest_wifi | wifi, wi-fi, wireless, internet |
| 8–11 | benefits_contact | benefits, insurance, medical, health |
| 12 (fallback) | unknown | No match on any rule |

- Added `"fallbackOutput": "extra"` to Switch options

### New Set Nodes (3 added)

| Node | Intent | Response |
|------|--------|----------|
| Set guest_wifi | guest_wifi | "The guest Wi-Fi network is Guest-WiFi. The password is Welcome123." |
| Set benefits_contact | benefits_contact | "For benefits or medical questions, please contact the Benefits Help Desk at 800-555-0199." |
| Set unknown | unknown | "I'm sorry — I didn't catch a supported request. I'll create a ticket and have someone follow up." |

All Set nodes have `includeOtherFields: true`.

### Existing Node Renames

| Old Name | New Name | Reason |
|----------|----------|--------|
| Edit Fields1 | Set password_reset | Clarity — disambiguate from normalization node |

### Respond to Webhook — Now Dynamic

- **Before:** Hardcoded password_reset TwiML in `responseBody`
- **After:** `<Response><Say>{{$json.response_text}}</Say></Response>` — reads from upstream Set node

### Preserved (Unchanged)

- Webhook node (entry point, path, responseMode)
- Edit Fields node (speech normalization: toLowerCase + trim)
- pinData (locked-out test utterance)
- Content-Type: text/xml header
- instanceId, webhookId

### Set to Inactive

- `"active": false` — must be activated manually after import to avoid conflict with v1
