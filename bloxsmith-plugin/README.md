# 🔨 Bloxsmith — AI Copilot for Roblox Studio

Bloxsmith is a modular, dark-themed Roblox Studio plugin that acts as an AI development
assistant: chat, script generation, fixing/optimizing, UI & full game-system generation,
security scanning, performance analysis, cleanup tools, error monitoring, a multi-step
build agent, and a project health dashboard — all with full undo/redo via
`ChangeHistoryService` and human approval before any change is applied.

The plugin holds **no AI key**. It talks to a secure backend (a Lovable Cloud edge
function) that proxies to the AI provider, so your credentials never live inside the
`.rbxm`.

---

## Install

### Option A — Single `.lua` file (easiest, no tools needed)
1. Download **`Bloxsmith.lua`** (from the website dashboard, or the file in this folder).
2. In Studio, open the **Plugins** tab → **Plugins Folder** and drop `Bloxsmith.lua` inside,
   or drag it into Studio, right-click → **Save as Local Plugin**.
3. Restart Studio if the button doesn't appear, then click **Bloxsmith**.

> `Bloxsmith.lua` is a single self-contained build generated from `src/`. Regenerate it
> after changing any source file with:
> ```bash
> python3 bloxsmith-plugin/bundle.py
> ```

### Option B — Rojo (recommended for development)
1. Install [Rojo](https://rojo.space) (`aftman add rojo-rbx/rojo` or the VS Code extension).
2. From this folder, build the plugin model:
   ```bash
   rojo build bloxsmith-plugin/default.project.json -o Bloxsmith.rbxm
   ```
3. Copy `Bloxsmith.rbxm` into your Roblox `Plugins` folder
   (Studio → **Plugins** tab → **Plugins Folder**), or drag it into Studio, right-click →
   **Save as Local Plugin**.


---

## Setup
1. Open Studio → **Plugins** tab → click the **Bloxsmith** button.
2. The first AI request will ask permission for HTTP — allow it.
3. Open **Settings** in the plugin and confirm the **Backend URL** (pre-filled).
   You can point it at any compatible backend later.

---

## Features
- **Chat** — project-aware assistant that reads your selection & hierarchy.
- **Generate** — scripts, UIs, and complete systems (inventory, shop, quests, combat,
  leaderboards, progression) inserted straight into the right services.
- **Fix / Explain / Optimize** — operate on the currently selected script.
- **Agent** — multi-step tasks; proposes actions and applies them only after you approve.
- **Security scanner** — flags exploitable patterns and bad practices.
- **Performance analyzer** — finds lag sources, excessive instances, and leaks.
- **Cleanup** — naming, organization, duplicates, empty folders.
- **Error monitor** — captures Studio output errors and offers AI fixes.
- **Docs generator** — Markdown docs for scripts & systems.
- **Health dashboard** — Security / Performance / Organization scores + AI recommendations.

### Build Agent actions
The agent can propose and apply a full range of changes (each behind an approval click):
`create_script`, `replace_script`, `create_folder`, `create_instance` (parts, GUIs,
remotes, values, with typed properties), `set_property`, `rename_instance`,
`move_instance`, and `delete_instance`. Multi-file generations get a single
**Insert all files** button.

### Reliability
- Automatic retries with exponential backoff on transient network / rate-limit errors.
- Class whitelist + property coercion guard against malformed AI output.
- One-click starter prompts to get building instantly.

Everything the AI changes is wrapped in a `ChangeHistoryService` recording, so **Ctrl+Z**
undoes it like any other Studio edit.

