# KC AI Plugins

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[中文](README_zh.md)

Workflow plugins for **Claude Code** and **Codex**. Each plugin bundles a few skills that belong to the same job, plus the MCP servers they need, so one install gets a colleague everything for that job.

The same repo works for both agents: Codex reads the Claude plugin manifests directly, so there is one set of files and nothing to keep in sync.

Looking for individual skills instead? See [kc_ai_skills](https://github.com/KerberosClaw/kc_ai_skills).

## Plugins

| Plugin | Skills | Bundled MCP | What it is for |
|---|---|---|---|
| [doc-qa](plugins/doc-qa/) | `project-docs`, `qa`, `md2pdf` | Playwright | Document an existing project, QA it through the real UI, and hand both over as PDF |

### doc-qa

- **project-docs**: audits an existing codebase and writes the documents the next person needs. Technical docs for maintainers (Mermaid diagrams, interfaces, operations) and step-by-step manuals with real screenshots for end users and administrators.
- **qa**: for the case where unit and API tests are green but a real person gets stuck in the UI. Compares requirement documents with frontend and backend code to dig out rules nobody wrote down, turns them into traceable test cases, runs them with Playwright, and writes a report whose conclusions only claim what the evidence supports.
- **md2pdf**: converts one Markdown file into an A4 PDF. Handles Mermaid, CJK text, wide tables and page breaks.

They chain naturally: `qa` collects success-path screenshots that `project-docs` uses in the manual, and `md2pdf` turns either output into something you can send.

## Install

### Claude Code

```text
/plugin marketplace add KerberosClaw/kc_ai_plugins
/plugin install doc-qa@kc-ai-plugins
```

Skills are namespaced by plugin: `/doc-qa:qa`, `/doc-qa:project-docs`, `/doc-qa:md2pdf`. Asking in plain words ("run a QA pass on this project") also works.

### Codex

```bash
codex plugin marketplace add KerberosClaw/kc_ai_plugins
codex plugin add doc-qa@kc-ai-plugins
```

### Update

| | Command |
|---|---|
| Claude Code | `/plugin marketplace update kc-ai-plugins` |
| Codex | `codex plugin marketplace upgrade kc-ai-plugins` |

## System requirements

The plugin brings the skills and the MCP configuration. These tools must already be on the machine:

| Needed by | Tool | macOS | Debian / Ubuntu / WSL |
|---|---|---|---|
| Playwright MCP | Node.js (for `npx`) | `brew install node` | `sudo apt install nodejs npm` |
| md2pdf | pandoc | `brew install pandoc` | `sudo apt install pandoc` |
| md2pdf | weasyprint | `brew install weasyprint` | `sudo apt install weasyprint` |
| md2pdf | mermaid-cli | `npm install -g @mermaid-js/mermaid-cli` | same |
| md2pdf | Chinese font | built in | `sudo apt install fonts-noto-cjk` |

On Windows, run the agent inside WSL. `md2pdf` uses a bash script, and weasyprint on native Windows needs a separate GTK install.

## Using a skill without the plugin

Every skill is a self-contained folder under `plugins/<plugin>/skills/`. Copy the whole folder into `~/.claude/skills/` or `~/.codex/skills/` if you only want one. You lose the bundled MCP server and automatic updates.

## Repository layout

```text
.claude-plugin/marketplace.json    lists every plugin (read by both Claude Code and Codex)
plugins/<plugin>/
  .claude-plugin/plugin.json       plugin name and version
  .mcp.json                        MCP servers the plugin starts
  skills/<skill>/SKILL.md          one folder per skill
  skills/<skill>/agents/openai.yaml  Codex display metadata
```

Plugins are named after the job a colleague wants done, not after a technical category. Each skill lives in exactly one plugin.

## License

MIT
