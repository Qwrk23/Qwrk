# Scout Digest - 2026-05-06

Pilot run for Dex / Horizon Scout. This digest used public, primary-source materials only. No database, Gateway, QSB, n8n, Supabase project, or broad repository access was used.

## A. Potentially Material to Qwrk Context

### OpenAI introduced workspace agents in ChatGPT

- Source: https://openai.com/index/introducing-workspace-agents-in-chatgpt/
- Source type: Vendor product announcement
- Source date: 2026-04-22
- Date observed: 2026-05-06
- What changed:
  - OpenAI announced shared workspace agents in ChatGPT for teams.
  - The announcement describes agents that can run long-running workflows within organization-set permissions and controls.
  - The release positions these agents as an evolution of GPTs and notes use across ChatGPT and Slack.
- Why it matched scout filters: AI platform release; agentic workspace surface; governance and permission controls.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### Google expanded Gemini API File Search for multimodal RAG

- Source: https://blog.google/innovation-and-ai/technology/developers-tools/expanded-gemini-api-file-search-multimodal-rag/
- Source type: Vendor developer announcement
- Source date: 2026-05-05
- Date observed: 2026-05-06
- What changed:
  - Google announced Gemini API File Search support for multimodal data.
  - The update adds custom metadata filtering and page-level citations.
  - Google frames the feature around more efficient and verifiable retrieval-augmented generation.
- Why it matched scout filters: Knowledge-management AI; context engineering; grounded retrieval and citation surfaces.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### n8n announced MCP server workflow creation and updates

- Source: https://blog.n8n.io/n8n-mcp-server/
- Source type: Vendor product blog
- Source date: 2026-04-29
- Date observed: 2026-05-06
- What changed:
  - n8n announced that its MCP server can build new workflows from prompts and update existing workflows.
  - The blog says the MCP server previously executed existing workflows, and now can create and modify workflows inside an n8n instance.
  - The described flow includes building, validating, running, and fixing workflows.
- Why it matched scout filters: MCP ecosystem; workflow automation; agent-to-automation surface.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

## B. Worth Knowing

### Anthropic released financial-services agent templates and Microsoft 365 add-ins

- Source: https://www.anthropic.com/news/finance-agents
- Source type: Vendor product announcement
- Source date: 2026-05-05
- Date observed: 2026-05-06
- What changed:
  - Anthropic announced ten ready-to-run agent templates for financial-services workflows.
  - The announcement says the templates ship as plugins in Claude Cowork and Claude Code, and as cookbooks for Claude Managed Agents.
  - Anthropic also announced Claude add-ins for Excel, PowerPoint, Word, and Outlook support marked as coming soon.
- Why it matched scout filters: Anthropic release; agent templates; cross-application context and workflow surface.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### GitHub added security tools to the GitHub MCP Server

- Source: https://github.blog/changelog/2026-05-05-secret-scanning-with-github-mcp-server-is-now-generally-available/
- Source type: Vendor changelog
- Source date: 2026-05-05
- Date observed: 2026-05-06
- What changed:
  - GitHub announced secret scanning with the GitHub MCP Server as generally available.
  - The feature lets MCP-compatible coding agents or IDEs scan code for exposed secrets before commit or pull request.
  - GitHub says the tools honor existing push protection customization.
- Why it matched scout filters: MCP ecosystem; agentic developer tooling; safety and guardrail surface.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

## C. Competitor / Adjacent Activity

### Notion released new admin controls for Custom Agents

- Source: https://www.notion.com/en-gb/releases/2026-05-05
- Source type: Vendor release note
- Source date: 2026-05-05
- Date observed: 2026-05-06
- What changed:
  - Notion released admin controls for Custom Agents.
  - Controls include creation permissions, per-agent credit limits, workspace-level credit limits for Enterprise, usage dashboards, and agent disablement.
  - Notion also describes automatic pauses when credits run out or agent spend rises unusually fast.
- Why it matched scout filters: Knowledge-management AI product; agent governance controls; adjacent workspace automation.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### Cursor added context usage breakdown for agents

- Source: https://cursor.com/changelog/05-06-26
- Source type: Vendor changelog
- Source date: 2026-05-06
- Date observed: 2026-05-06
- What changed:
  - Cursor announced a context usage breakdown for agents.
  - The changelog says the breakdown is meant to diagnose context issues across rules, skills, MCPs, and subagents.
- Why it matched scout filters: Agent development tool; prompt/context engineering surface; skill and MCP visibility.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### xAI launched Connectors on Grok Web

- Source: https://x.ai/news/grok-connectors
- Source type: Vendor product announcement
- Source date: 2026-05-06
- Date observed: 2026-05-06
- What changed:
  - xAI announced Connectors for Grok Web.
  - The announcement describes app integrations that let Grok read, summarize, create, edit, and update across connected tools.
  - The listed connector examples include SharePoint, Outlook, Gmail, Google Drive, Google Calendar, Google Docs, Google Sheets, Google Slides, Slack, and Linear.
- Why it matched scout filters: AI platform release; cross-tool agent integration; competitor/adjacent workspace surface.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

## D. Discard Log

### OpenAI and AWS announced OpenAI models, Codex, and Managed Agents on AWS

- Source reviewed: https://openai.com/index/openai-on-aws
- Source type: Vendor partnership announcement
- Date observed: 2026-05-06
- Reason excluded: Relevant primary source, but excluded to keep the pilot within the 5-8 included-source target after the direct ChatGPT workspace-agents announcement was included.

### GitHub dependency scanning with GitHub MCP Server

- Source reviewed: https://github.blog/changelog/2026-05-05-dependency-scanning-with-github-mcp-server-is-in-public-preview/
- Source type: Vendor changelog
- Date observed: 2026-05-06
- Reason excluded: Primary source and relevant to MCP-enabled security tooling, but closely adjacent to the included GitHub secret-scanning MCP item.

### Cursor enterprise model controls and spend analytics

- Source reviewed: https://cursor.com/changelog/05-04-26
- Source type: Vendor changelog
- Date observed: 2026-05-06
- Reason excluded: Primary source and relevant to agent governance, but less tightly matched to context-engineering visibility than the included Cursor context usage breakdown.

### Supabase automatic PostgREST retries

- Source reviewed: https://supabase.com/changelog
- Source type: Vendor changelog
- Date observed: 2026-05-06
- Reason excluded: Primary source and recent enough, but the item is a client-library reliability update rather than an AI platform, agent, MCP, knowledge-management, or competitor signal for this pilot.

### Supabase MCP deployment docs

- Source reviewed: https://supabase.com/docs/guides/getting-started/byo-mcp
- Source type: Vendor documentation
- Date observed: 2026-05-06
- Reason excluded: Useful primary documentation, but it was not treated as a dated announcement in this pilot run.

### Linear Agent announcement

- Source reviewed: https://linear.app/changelog/2026-03-24-introducing-linear-agent
- Source type: Vendor changelog
- Date observed: 2026-05-06
- Reason excluded: Primary source and relevant to adjacent agent surfaces, but older than the tight pilot window and already outside the 5-8 source target.

## Boundary Confirmation

This digest is observation only. It contains no recommendations, priorities, or work orders. Joel decides whether to capture, ignore, or route anything forward.
