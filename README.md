# KC AI Plugins

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[中文](README_zh.md)

You know the drill. A colleague asks for "that QA skill you keep talking about", and ten minutes later you're both still on a call going "okay, now copy this folder, no, the other folder, now open your MCP config..." This repo exists so that call never happens again.

Each plugin here is a **pack**: the skills for one job, plus the MCP servers they need, installed in one step. It works on both **Claude Code** and **Codex**. Codex happens to read Claude's plugin manifests directly, so there is exactly one set of files and nobody has to keep two of them in sync. (We checked. Twice. On a scratch config, because we are not brave.)

Just want one skill and none of the ceremony? The à la carte menu is still open at [kc_ai_skills](https://github.com/KerberosClaw/kc_ai_skills).

## Why we split these out of kc_ai_skills

Short version: a skill folder turned out to be half of what people actually need.

- **Some skills don't work alone.** `qa` drives a real browser through Playwright MCP. Handing someone the skill folder without the MCP config is like handing over a car without the keys: technically complete, practically decorative.
- **Some skills are one job wearing three hats.** `qa` collects success-path screenshots, `project-docs` turns them into a manual, `md2pdf` turns the manual into something you can email. Installing them one by one meant someone always ended up with two out of three.
- **Copying folders doesn't scale, even for one person.** Before this repo, these skills lived as hand-made symlinks, one per agent per machine, and every new machine meant remembering which ones to link. Switching to the plugin covered seven environments: three Claude accounts and Codex on one laptop, Claude and Codex on a second machine, Claude on a third. That's now one install command each, and updates come through the marketplace instead of a small archaeology project.
- **Colleagues use different agents.** Some are on Claude Code, some on Codex. A pack that installs the same way on both means nobody gets left out, and nobody maintains a "Codex edition".

kc_ai_skills keeps doing what it was always good at: a big shelf of individual skills. Skills that moved here are still listed there, with a pointer to their new home.

## Plugins

| Plugin | Skills | Bundled MCP | What it is for |
|---|---|---|---|
| [doc-qa](plugins/doc-qa/) | `project-docs`, `qa`, `md2pdf` | Playwright | Document an existing project, QA it through the real UI, and hand both over as PDF |

### doc-qa

- **project-docs**: reads an existing codebase and writes the documents the next person will wish existed. Maintainers get technical docs (Mermaid diagrams, interfaces, operations). End users and administrators get step-by-step manuals with real screenshots, because nobody has ever found a button from an architecture diagram.
- **qa**: for that special moment when every unit test and API test is green, and the first real human to touch the UI gets stuck anyway. It lines up the requirement documents against the frontend and backend code to find the rules nobody wrote down, turns them into traceable test cases, runs them with Playwright, and writes a report that only claims what the evidence actually supports. No "zero defects" from a test run that never ran.
- **md2pdf**: turns one Markdown file into an A4 PDF. Mermaid, Chinese text, wide tables and page breaks are handled; we already stepped on every one of those rakes so you don't have to.

They chain nicely: `qa` quietly collects screenshots for `project-docs` while it tests, and `md2pdf` turns either result into something you can attach to an email without apologising.

## More packs are coming

doc-qa is the first pack, not the last. Installing one pack turned out to be so much less painful than wiring up skills by hand that we fully intend to keep doing it.

The rule for what becomes a pack: **a few skills that people keep using together for the same job**, especially when they also need an MCP server or have to reach colleagues on different agents. Likely candidates sitting in kc_ai_skills right now include the spec and requirements workflow, and Traditional Chinese writing review. No promises on names or dates; when a pack lands, it shows up in the table above and in `/plugin marketplace update`.

## Install

### Claude Code

```text
/plugin marketplace add KerberosClaw/kc_ai_plugins
/plugin install doc-qa@kc-ai-plugins
```

Skills get the plugin name as a prefix: `/doc-qa:qa`, `/doc-qa:project-docs`, `/doc-qa:md2pdf`. Or just ask in plain words ("run a QA pass on this project"); the agent will figure it out.

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

A plugin brings the skills and the MCP configuration. It does not bring the tools those skills call, so these need to be on the machine already:

| Needed by | Tool | macOS | Debian / Ubuntu / WSL |
|---|---|---|---|
| Playwright MCP | Node.js (for `npx`) | `brew install node` | `sudo apt install nodejs npm` |
| md2pdf | pandoc | `brew install pandoc` | `sudo apt install pandoc` |
| md2pdf | weasyprint | `brew install weasyprint` | `sudo apt install weasyprint` |
| md2pdf | mermaid-cli | `npm install -g @mermaid-js/mermaid-cli` | same |
| md2pdf | Chinese font | built in | `sudo apt install fonts-noto-cjk` |

On Windows, run the agent inside WSL. `md2pdf` is a bash script, and weasyprint on native Windows wants its own GTK install. We tried to make it not matter. It mattered.

## Using a skill without the plugin

Every skill is a self-contained folder under `plugins/<plugin>/skills/`. If you only want one, copy the whole folder into `~/.claude/skills/` or `~/.codex/skills/` like in the old days. You give up the bundled MCP server and automatic updates, but we won't judge.

## Repository layout

```text
.claude-plugin/marketplace.json    lists every plugin (read by both Claude Code and Codex)
plugins/<plugin>/
  .claude-plugin/plugin.json       plugin name and version
  .mcp.json                        MCP servers the plugin starts
  skills/<skill>/SKILL.md          one folder per skill
  skills/<skill>/agents/openai.yaml  Codex display metadata
```

Packs are named after the job a colleague wants done, not after some technical category nobody searches for. Each skill lives in exactly one pack, so there is never a question of which copy is the real one.

## License

MIT
