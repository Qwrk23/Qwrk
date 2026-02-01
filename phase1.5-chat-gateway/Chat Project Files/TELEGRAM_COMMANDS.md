# Qwrk Telegram Command Reference

Complete reference for all commands supported by the Qwrk Telegram Gateway.

---

## Save Commands

**CRITICAL: All save commands MUST include tags.** Use `with tags [tag1], [tag2]` after the title.

### Save Journal
```
Save journal titled "[TITLE]" with tags [tag1], [tag2]: [CONTENT]
```
**Aliases:** "save journal", "journal:", "save as journal"

**Examples:**
```
Save journal titled "Daily Standup Notes" with tags standup, team: Discussed blockers, agreed to prioritize bug fixes.
```
```
Save journal titled "Idea - Voice Capture" with tags idea, voice: What if we could save journals via voice memo?
```

---

### Save Project
```
Save project titled "[TITLE]" with tags [tag1], [tag2]: [SUMMARY]
```
**Note:** Projects start as "seed" stage automatically.

**Examples:**
```
Save project titled "Auth Gate MVP" with tags seed, auth: User authentication for beta launch.
```
```
Save project titled "Q2 Marketing Campaign" with tags seed, marketing: Campaign strategy for Q2.
```

---

### Save Snapshot
```
Save snapshot titled "[TITLE]" with tags [tag1], [tag2]: [CONTENT]
```
**Use for:** Decisions, milestones, governance records

**Examples:**
```
Save snapshot titled "Decision - Database Selection" with tags decision, infrastructure: Chose Supabase for integrated auth and realtime.
```
```
Save snapshot titled "Milestone - Phase 1 Complete" with tags milestone, phase1: All Gateway actions implemented and tested.
```

---

### Save Restart
```
Save restart titled "[TITLE]" with tags [tag1], [tag2]: [CONTEXT]
```
**Use for:** Session handoffs, "where I left off"

**Examples:**
```
Save restart titled "Resume Auth Work" with tags restart, auth: Left off at login flow, next step is logout implementation.
```

---

### Save Instruction Pack
```
Save instruction pack titled "[TITLE]" with tags [tag1], [tag2]: [INSTRUCTIONS]
```
**Use for:** Custom rules and shortcuts

**Examples:**
```
Save instruction pack titled "Meeting Notes Format" with tags instruction, meetings: Always include attendees, decisions, and action items.
```

---

## List Commands

```
list journals
list projects
list snapshots
list restarts
list instruction packs
```

**Returns:** 10 most recent items with:
- Position number (1-10)
- Title
- Truncated artifact_id
- Date

**Example response:**
```
1. Auth Discussion (a409...) - Jan 29
2. Daily Notes (b512...) - Jan 28
3. Meeting Summary (c623...) - Jan 27
```

---

## Retrieve Commands

### By Position (after listing)
```
retrieve 1
```
Gets the first item from your most recent list.

### By Title
```
retrieve Auth Gate MVP
```
Searches for matching title, then retrieves full content.

### By Number Reference
```
get 3
show 2
```
Alternative syntax for retrieve by position.

---

## Promote Commands

```
promote [PROJECT NAME] to [STAGE]
```

**Valid stages:** sapling, tree, oak, archive

**Examples:**
```
promote Auth Gate MVP to sapling
promote Marketing Campaign to tree
promote Old Feature to archive
```

---

## Natural Language Variations

The Telegram bot understands natural language, so these all work:

**Saving:**
- "Save this as a journal titled X"
- "Create a journal called X with this content"
- "Journal: X - [content]"
- "Save snapshot X: [content]"

**Listing:**
- "Show my journals"
- "What projects do I have?"
- "List my recent snapshots"

**Retrieving:**
- "Get the first one"
- "Show me Auth Gate MVP"
- "What's in that journal?"

**Promoting:**
- "Promote X to the next stage"
- "Move X to sapling"
- "Advance X to tree"

---

## Tips

1. **Tags are required** - Always include `with tags [tag1], [tag2]`
2. **Titles matter** - Use descriptive titles for easy retrieval
3. **Content can be long** - Gateway handles 5000+ characters
4. **Plain text only** - No markdown, bullets, or special characters in content
5. **Retrieve after list** - "retrieve 1" uses the last list context
6. **Be specific with names** - Helps the AI find the right artifact

---

## Error Handling

If something fails, the bot will tell you:
- "Could not find [TITLE]" - Check spelling
- "Permission denied" - Shouldn't happen in MVP
- "Invalid transition" - Check current lifecycle stage

For any issues, the bot will suggest alternatives.
