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

### Option A — Rojo (recommended for development)
1. Install [Rojo](https://rojo.space) (`aftman add rojo-rbx/rojo` or the VS Code extension).
2. From this folder, build the plugin model:
   ```bash
   rojo build bloxsmith-plugin/default.project.json -o Bloxsmith.rbxm
   ```
3. Copy `Bloxsmith.rbxm` into your Roblox `Plugins` folder
   (Studio → **Plugins** tab → **Plugins Folder**), or drag it into Studio, right-click →
   **Save as Local Plugin**.

### Option B — Manual
1. In Studio, create a `Script` in `ServerStorage` and paste `src/init.server.lua`.
2. Recreate the `Util`, `Services`, and `UI` folders as `ModuleScript`s matching `src/`.
3. Right-click the root Script → **Save as Local Plugin**.

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

Everything the AI changes is wrapped in a `ChangeHistoryService` recording, so **Ctrl+Z**
undoes it like any other Studio edit.
