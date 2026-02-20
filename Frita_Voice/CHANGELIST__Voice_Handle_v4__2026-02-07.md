# Changelist: Frita – Voice Handle v4

**Date:** 2026-02-07
**Base:** `Workflows/Frita – Voice Handle v3.json`
**New:** `Workflows/Frita – Voice Handle v4.json`
**Reason:** Align response text with updated PRD (voice-is-not-a-UI principle)

---

## Changes (Response Text Only — No Structural Changes)

| Intent | v3 (old) | v4 (new) | Why |
|--------|----------|----------|-----|
| guest_wifi | "The guest Wi-Fi network is Guest-WiFi. The password is Welcome123." | "I'll text you the guest Wi-Fi information now." | Don't read passwords aloud over voice |
| benefits_contact | "For benefits or medical questions, please contact the Benefits Help Desk at 800-555-0199." | "I'll text you the benefits help desk information." | Don't read phone numbers aloud over voice |
| password_reset (not recognized) | "...I don't recognize this phone number, so I'll open a ticket..." | "...I'll open a ticket and have someone from the service desk contact you shortly." | Don't leak that a lookup happened and failed |

## WALK Phase Note

"I'll text you..." responses are narrative-only in CRAWL — no SMS is actually sent. When WALK adds real SMS/Teams delivery, the spoken language does not need to change.
