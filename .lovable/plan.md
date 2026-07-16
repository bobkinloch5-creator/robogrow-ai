## Goal

Make Bloxsmith feel responsive and reliable on real games. Four focused passes — no rewrites, only targeted fixes to the highest-impact code paths.

## 1. Streaming / job polling (AIService + App)

Right now `AIService:request` is a single blocking `HttpService:RequestAsync` — even though the backend already supports the `stream: true` + `poll` protocol we shipped last turn. On large generations users see a frozen "Thinking…" spinner for 30-60s with no progress and a hard fail if Roblox HTTP times out.

Changes in `bloxsmith-plugin/src/Services/AIService.lua`:
- Add `requestStreaming(opts, onPartial)` that:
  1. POSTs the normal payload with `stream = true`, receives `{ jobId }`.
  2. Polls `{ mode = "poll", jobId }` every ~1.2s (backoff to 2.5s after 20s).
  3. Fires `onPartial(partialText)` whenever `partial` grows, so the chat panel can render tokens as they arrive.
  4. Resolves when `done: true` with the same result shape as `request()`, or on `error`.
  5. Total wall-clock cap: 180s, then surface a clean timeout error.
- Keep the old `request()` as a fallback for non-streaming modes (`toolbox_search` already uses its own path).

Changes in `bloxsmith-plugin/src/UI/App.lua` (chat send path):
- Route `chat` / `agent` / `generate` through `requestStreaming` with an `onPartial` that updates the current AI bubble's rich text incrementally.
- Add a visible "Cancel" affordance while a job is running; cancel just stops polling client-side (backend job self-expires).

## 2. Apply pipeline correctness (ApplyService)

The apply layer is where AI actions turn into real hierarchy changes — most user-visible "it didn't work" moments live here.

Targeted fixes in `bloxsmith-plugin/src/Services/ApplyService.lua`:
- Wrap every mutation in `ChangeHistoryService:TryBeginRecording` / `:FinishRecording` per action group so Ctrl+Z always undoes the full batch, not a single primitive.
- Normalize path resolution: accept `ServerScriptService/Foo/Bar`, `game.ServerScriptService.Foo.Bar`, and `Foo/Bar` with a resolved parent hint. Fall back to creating missing Folders on the way down (with a single warn per created folder).
- On `create_script`, if a script with the same name already exists at the target path, replace `Source` instead of creating a duplicate — this is the #1 source of `Script`, `Script (1)`, `Script (2)` clutter.
- Invalidate `ContextService._treeCache` after every successful apply group so the next AI turn sees the new hierarchy.
- Return a structured summary `{ applied, skipped, failed, details[] }` and surface it in the UI action pill.

## 3. UI / UX polish (App.lua + Theme)

Small, high-signal only — no visual redesign.

- Debounce chat scroll-to-bottom during streaming (currently thrashes on every partial).
- Thinking panel: collapse by default, remember open/closed per session, stop reflow flicker when the block is finalized.
- Send button: disabled state during in-flight job, spinner inside instead of overlay.
- Keyboard: Enter sends, Shift+Enter newline (verify it's not already this way; fix if not).
- Settings page: surface current backend URL + Roblox user ID + resolved plan mode as read-only rows for support debugging.

## 4. Context / perf on big places (ContextService)

- Lower default `MaxContextInstances` walk depth from 4 to 3 when tree size exceeds a threshold — most large games have deep model nests that add no signal.
- Skip descending into instances tagged `Bloxsmith_Ignore` (custom attribute) so users can exclude giant terrain-mesh folders.
- Cache `getSelection()` results within a single request (currently recomputed per context build).
- Bump `TREE_CACHE_TTL` from 12s → 20s and expose invalidation to ApplyService (see §2).

## Version + release

- Rebuild single-file plugin via `bloxsmith-plugin/bundle.py`, copy to `public/Bloxsmith.lua`.
- Bump version to `3.23.0` in `Dashboard.tsx`, `Docs.tsx`, and the plugin `Config.lua` version string.
- No backend redeploy needed — job protocol already ships.

## Out of scope

- No new AI features, no prompt changes, no new tables, no new edge functions.
- No visual redesign of the chat panel.
- No changes to `bloxsmith-ai/index.ts` unless a bug is found while wiring the client (I'll flag before touching).

## Verification

- `wc -l` + spot `rg` on changed files.
- Test streaming path with `supabase--curl_edge_functions` (`stream:true` then `poll`) to confirm shape still matches what the new client expects.
- Confirm `public/Bloxsmith.lua` grep shows `3.23.0` and the streaming poll code.
