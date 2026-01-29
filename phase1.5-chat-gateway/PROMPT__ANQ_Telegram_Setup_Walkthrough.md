# Prompt for ANQ: Telegram Gateway Setup Walkthrough

Copy everything below the line and paste to ANQ:

---

## Context

I just completed Phase 1.5 of Qwrk - a validated n8n Chat Gateway that bypasses the BUG-008 payload limits we had with CustomGPT. The Chat Trigger version works perfectly.

Now I want to connect it to **Telegram** so I can:
1. Chat with ChatGPT or other tools
2. Copy useful content
3. Paste into Telegram with a save command
4. Have it saved to Qwrk via the Gateway

CC (Claude Code) created a Telegram workflow file for me:
- **File:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json`

## What I Need

Walk me through setting this up **step by step**. I need help with:

1. **Creating a Telegram Bot** via BotFather
2. **Getting the bot token**
3. **Importing the workflow** into n8n
4. **Creating the Telegram credential** in n8n
5. **Assigning credentials** to all the nodes that need them
6. **Testing** the bot works
7. **Troubleshooting** if something fails

## Technical Details

The workflow has these nodes that need credentials:
- `Telegram_Trigger` - needs Telegram API credential
- `Send_Response` - needs same Telegram API credential
- `OpenAI_Chat_Model` - needs OpenAI API credential
- `Tool_List_Journals` - needs HTTP Basic Auth (Gateway)
- `Tool_Query` - needs HTTP Basic Auth (Gateway)
- `Tool_Save_Journal` - needs HTTP Basic Auth (Gateway)
- `Tool_Save_Project` - needs HTTP Basic Auth (Gateway)

Gateway Basic Auth credentials:
- **User:** `qwrk-gateway`
- **Password:** `aslfja'wwe*(#fhwoII843ghlw_ek2l`

The workflow uses the same tools and patterns as the validated Chat Gateway - just swaps Chat Trigger for Telegram Trigger and adds a Send_Response node.

## My Environment

- n8n instance at: `https://n8n.halosparkai.com`
- Gateway webhook: `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1`
- I already have OpenAI credentials configured in n8n
- I already have Gateway Basic Auth credentials configured in n8n

## Expected Usage

Once working, I should be able to send messages like:

```
Save this as a journal titled "Architecture Notes":

Today we discussed the future of Qwrk...
[pasted content]
```

And get back: `Saved: Architecture Notes`

## Please Guide Me

Start from the very beginning (creating the Telegram bot) and walk me through each step. Wait for my confirmation at each step before moving to the next. If I hit errors, help me troubleshoot.

---

End of prompt.
