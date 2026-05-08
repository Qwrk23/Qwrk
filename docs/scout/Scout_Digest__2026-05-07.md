# Scout Digest - 2026-05-07

Pilot run #2 for Dex / Horizon Scout. This digest used public, primary-source materials only. No database, Gateway, QSB, n8n runtime, Supabase project, or broad repository access was used.

Pilot #2 uses the tightened instruction-pack contract:

- Scout Confidence
- Qwrk Relevance Signals scored across five vectors
- Qwrk Relevance Vector tags
- Possible Routing Bucket as non-executable classification only

## A. Potentially Material to Qwrk Context

### GitHub opened enterprise-managed Copilot CLI plugins in public preview

- Source: https://github.blog/changelog/2026-05-06-enterprise-managed-plugins-in-github-copilot-cli-are-now-in-public-preview
- Source type: Vendor changelog
- Source date: 2026-05-06
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: medium
  - Governance signal: high
  - Architecture signal: medium
  - UX signal: medium
  - Competitive positioning signal: medium
- Qwrk Relevance Vector: `agent-governance`, `skills-and-mcp`
- Possible Routing Bucket: Watch
- What changed:
  - GitHub announced enterprise-managed plugins for GitHub Copilot CLI.
  - Enterprise administrators can distribute plugins, set baseline standards, and install plugins automatically for licensed users.
  - The changelog says plugins can include hooks and MCP configurations that remain enabled across an enterprise.
- Why it matched scout filters: Agent governance, managed skills/plugins, and MCP configuration are all visible in the source.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### n8n expanded its MCP server from workflow execution to workflow creation and updates

- Source: https://blog.n8n.io/n8n-mcp-server/
- Source type: Vendor product blog
- Source date: 2026-04-29
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: medium
  - Governance signal: medium
  - Architecture signal: high
  - UX signal: medium
  - Competitive positioning signal: medium
- Qwrk Relevance Vector: `mcp`, `workflow-automation`
- Possible Routing Bucket: Watch
- What changed:
  - n8n announced that its MCP server can build new workflows from prompts and update existing workflows.
  - The blog distinguishes this instance-level MCP server from the MCP Server Trigger node.
  - The described flow includes generating, validating, executing, and fixing workflows from an MCP-compatible client.
- Why it matched scout filters: MCP ecosystem movement; workflow automation; agent-to-runtime boundary surface.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### Google added multimodal support, metadata filtering, and page citations to Gemini API File Search

- Source: https://blog.google/innovation-and-ai/technology/developers-tools/expanded-gemini-api-file-search-multimodal-rag/
- Source type: Vendor developer announcement
- Source date: 2026-05-05
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: medium
  - Governance signal: low
  - Architecture signal: high
  - UX signal: medium
  - Competitive positioning signal: medium
- Qwrk Relevance Vector: `rag`, `citation-grounding`
- Possible Routing Bucket: Watch
- What changed:
  - Google announced multimodal support for Gemini API File Search.
  - The update adds custom metadata filtering.
  - The update adds page-level citations for grounded retrieval outputs.
- Why it matched scout filters: Knowledge-management AI, retrieval, context engineering, and citation surfaces are all directly present.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### Supabase released `@supabase/server` in public beta

- Source: https://supabase.com/blog/introducing-supabase-server
- Source type: Vendor product blog
- Source date: 2026-05-06
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: low
  - Governance signal: medium
  - Architecture signal: high
  - UX signal: low
  - Competitive positioning signal: low
- Qwrk Relevance Vector: `supabase-runtime`, `auth-boundary`
- Possible Routing Bucket: Watch
- What changed:
  - Supabase announced `@supabase/server` in public beta.
  - The package handles auth verification, Supabase client setup, request context, and common server-side boilerplate.
  - The post says it works across Edge Functions, Cloudflare Workers, Hono, and Bun.
- Why it matched scout filters: Supabase platform movement; server-side auth/context boundary; possible relevance to systems using Supabase as a kernel.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

## B. Worth Knowing

### Anthropic released financial-services agent templates and Microsoft 365 add-ins

- Source: https://www.anthropic.com/news/finance-agents
- Source type: Vendor product announcement
- Source date: 2026-05-05
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: medium
  - Governance signal: medium
  - Architecture signal: medium
  - UX signal: medium
  - Competitive positioning signal: medium
- Qwrk Relevance Vector: `agent-templates`, `workspace-ai`
- Possible Routing Bucket: Watch
- What changed:
  - Anthropic announced ten ready-to-run financial-services agent templates.
  - The announcement says the templates ship as plugins in Claude Cowork and Claude Code, and as cookbooks for Claude Managed Agents.
  - Anthropic also announced Claude add-ins for Excel, PowerPoint, Word, and Outlook support marked as coming soon.
- Why it matched scout filters: AI platform release; managed agent templates; cross-document workspace tooling.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

## C. Competitor / Adjacent Activity

### Notion added a Custom Agent Directory

- Source: https://www.notion.com/releases
- Source type: Vendor release log
- Source date: 2026-05-06
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: high
  - Governance signal: medium
  - Architecture signal: low
  - UX signal: high
  - Competitive positioning signal: high
- Qwrk Relevance Vector: `workspace-ai`, `agent-discovery`
- Possible Routing Bucket: Watch
- What changed:
  - Notion announced a dedicated Custom Agent Directory inside the Library.
  - The release log says users can browse workspace agents, pin favorites, and create new agents from the sidebar.
  - The item follows Notion's May 5 release of admin controls for Custom Agents.
- Why it matched scout filters: Knowledge-management AI product; agent discovery surface; adjacent workspace automation.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### Cursor added context usage breakdown for agents

- Source: https://cursor.com/changelog/05-06-26
- Source type: Vendor changelog
- Source date: 2026-05-06
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: medium
  - Governance signal: low
  - Architecture signal: medium
  - UX signal: high
  - Competitive positioning signal: medium
- Qwrk Relevance Vector: `context-engineering`, `mcp`
- Possible Routing Bucket: Watch
- What changed:
  - Cursor announced a context usage breakdown for agents.
  - The changelog says the breakdown helps diagnose context issues.
  - Cursor names rules, skills, MCPs, and subagents as surfaces covered by the breakdown.
- Why it matched scout filters: Prompt/context engineering; agent observability; adjacent coding-agent product.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

### xAI launched Connectors on Grok Web

- Source: https://x.ai/news/grok-connectors
- Source type: Vendor product announcement
- Source date: 2026-05-06
- Date observed: 2026-05-07
- Scout Confidence: high
- Qwrk Relevance Signals:
  - Product thesis signal: high
  - Governance signal: medium
  - Architecture signal: medium
  - UX signal: high
  - Competitive positioning signal: high
- Qwrk Relevance Vector: `workspace-ai`, `connectors`
- Possible Routing Bucket: Watch
- What changed:
  - xAI announced Connectors on Grok Web.
  - The announcement describes integrations that let Grok read, summarize, create, edit, and update across connected tools.
  - Listed connector examples include SharePoint, Outlook, Gmail, Google Drive, Google Calendar, Slack, Linear, and Microsoft/Google document surfaces.
- Why it matched scout filters: AI platform release; cross-tool workspace integration; competitor/adjacent surface.
- Boundary note: No recommendation; Joel decides whether to capture, ignore, or route.

## D. Discard Log

### GitHub secret scanning through GitHub MCP Server

- Source reviewed: https://github.blog/changelog/2026-05-05-secret-scanning-with-github-mcp-server-is-now-generally-available/
- Source type: Vendor changelog
- Date observed: 2026-05-07
- Reason excluded: Primary source and relevant to MCP-enabled safety checks, but closely adjacent to the included GitHub enterprise-managed plugins item.

### GitHub dependency scanning through GitHub MCP Server

- Source reviewed: https://github.blog/changelog/2026-05-05-dependency-scanning-with-github-mcp-server-is-in-public-preview/
- Source type: Vendor changelog
- Date observed: 2026-05-07
- Reason excluded: Primary source and relevant to MCP-enabled security tooling, but overlapping with the included GitHub plugin-management signal and the discarded secret-scanning MCP item.

### OpenAI models, Codex, and Managed Agents on AWS

- Source reviewed: https://openai.com/index/openai-on-aws
- Source type: Vendor partnership announcement
- Date observed: 2026-05-07
- Reason excluded: Primary source and relevant, but already captured in Pilot #1 discard log and not newer than the tighter May 5-6 signal set.

### OpenAI ChatGPT for Clinicians

- Source reviewed: https://openai.com/index/making-chatgpt-better-for-clinicians/
- Source type: Vendor product announcement
- Date observed: 2026-05-07
- Reason excluded: Primary source and credible, but more domain-specific than the included workspace-agent, MCP, context, and governance signals.

### Supabase OAuth token endpoint status-code change

- Source reviewed: https://supabase.com/changelog/45468-breaking-change-oauth-token-endpoint-will-return-http-200-instead-of-201
- Source type: Vendor changelog
- Date observed: 2026-05-07
- Reason excluded: Primary source and operationally concrete, but narrower than the included `@supabase/server` beta signal for this scout pass.

### Meta AI age-assurance measures

- Source reviewed: https://about.fb.com/news/page/185/
- Source type: Vendor newsroom listing
- Date observed: 2026-05-07
- Reason excluded: Primary-source lead, but the available result was a newsroom listing rather than a reviewed item page in this pass.

### Linear Agent announcement

- Source reviewed: https://linear.app/changelog/2026-03-24-introducing-linear-agent
- Source type: Vendor changelog
- Date observed: 2026-05-07
- Reason excluded: Primary source and relevant to adjacent agent surfaces, but older than the pilot window and already excluded from Pilot #1.

## Possible Routing Buckets

Non-executable classification only:

- Ignore
- Watch
- Candidate twig
- Needs Joel review

## Boundary Confirmation

This digest is observation only. It contains no recommendations, priorities, or work orders. Joel decides whether to capture, ignore, or route anything forward.
