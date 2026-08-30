# AGENTS.md

Guidance for AI agents (and contributors) working on this repository.

## What this project is

A fork/customization of zellij's built-in **compact-bar** status-bar plugin, repackaged as a
minimal, **transparent** bottom status bar for zellij **0.45.x**.

- Upstream: https://github.com/zellij-org/zellij (`default-plugins/compact-bar/`, release `v0.45.0`)
- Remote: `origin` → https://github.com/YMan84/zellij-minimal-status-bar.git
- Pristine stock reference is vendored under `vendor/compact-bar-stock/`.

## Building

We build from inside the zellij `v0.45.0` source tree, reusing zellij's own build setup
(pinned `zellij-tile`/`zellij-tile-utils`, toolchain, and `wasm32-wasip1` target).

```
git clone --branch v0.45.0 https://github.com/zellij-org/zellij.git
cp <this repo>/src/*.rs zellij/default-plugins/compact-bar/src/
cd zellij
cargo build -p compact-bar --release --target wasm32-wasip1
cp target/wasm32-wasip1/release/compact-bar.wasm ~/.config/zellij/plugins/zj-status-bar.wasm
```

The zellij workspace's `rust-toolchain.toml` pins Rust `1.95.0` with target `wasm32-wasip1`
(`wasm32-wasi` was renamed to `wasm32-wasip1`).

## Installing & wiring it up

1. Copy the built `compact-bar.wasm` to `~/.config/zellij/plugins/zj-status-bar.wasm`.
2. In `~/.config/zellij/config.kdl`, the compact layout loads the **`compact-bar`** alias
   (NOT `status-bar` — that was a red herring). Point it at the file:
   ```kdl
   plugins {
       compact-bar location="file:~/.config/zellij/plugins/zj-status-bar.wasm"
   }
   ```
3. Restart zellij.

## Permissions: the file-loaded plugin trap (critical)

A plugin loaded via `file:` (not `zellij:`) is **not** treated as built-in by zellij. Built-in
plugins are auto-granted every permission; a `file:` one must explicitly request them.

Consequences:
- Many events the bar depends on — `TabUpdate`, `ModeUpdate`, `PaneUpdate` — are gated behind
  `ReadApplicationState`. If denied, the plugin receives no state and renders a **blank /
  invisible** bar (this was the long, hard-won bug of this session).
- The plugin therefore calls `request_permission([ReadApplicationState, ChangeApplicationState,
  MessageAndLaunchOtherPlugins, RunActionsAsUser, Reconfigure])` in `src/main.rs`. Do not remove it.
- The plugin sets itself **selectable on load** (`set_selectable(true)`) so the permission
  prompt can be focused (click the bar) and accepted with `y`; it flips back to
  `set_selectable(false)` on `PermissionRequestResult`. This is what makes the `y/n` prompt usable.
- Pre-granting is an alternative: edit `~/.cache/zellij/permissions.kdl` with a block keyed by
  the absolute wasm path. (See README for the one-liner.)

### Harmless `Reconfigure` denial
At load, zellij may log:
`Plugin '...zj-status-bar.wasm (ID 2)' permission 'Reconfigure' denied - Command 'Reconfigure' denied`
This is expected: the tooltip keybind (`tooltip "F1"`) calls `reconfigure()` during `load()`,
before the async permission reply lands. It is harmless; the bar still renders.

## Customizations made vs. stock (`src/` vs `vendor/compact-bar-stock/`)

Diff with: `diff -r vendor/compact-bar-stock/src src/`

- **Transparent bar** (`src/main.rs`): `render_background_with_text` no longer paints a
  full-row background; it emits `\u{1b}[0m\u{1b}[49m\u{1b}[0K` (reset, default bg, clear line).
- **`│` chip separator** (`src/line.rs`, `src/tab.rs`): `tab_separator` always returns `"│"`
  (stock used powerline `ARROW_SEPARATOR`). Chips render on the **right** of each tab; colored
  tab pills kept.
- **Flush-left tabs**: removed the `Zellij` label, session-name/breadcrumb prefix chip
  (`src/line.rs` `build()`).
- **Empty right side** (`src/line.rs` `RightSideElementsBuilder::build`): removed the mode pill,
  the `F1 Tooltip` indicator, and the swap-layout status ("vertical"/"horizontal" text). The
  right side now renders nothing by design.
- Kept from stock: `(FULLSCREEN)`, `(SYNC)`, `[!]` indicators — these are stock behavior, not
  custom additions.

## Files

- `src/` — customized plugin source (the real work lives in `main.rs`, `line.rs`, `tab.rs`).
- `vendor/compact-bar-stock/` — pristine stock `v0.45.0` compact-bar source, for diffing only.
- `scripts/fetch-stock.sh` — regenerates `vendor/compact-bar-stock` from upstream.
- `Cargo.toml` / `.cargo/config.toml` — **reference only**; the working wasm is built from
  the zellij source tree (see [Building](#building)), not by `cargo build`ing this repo.
- `README.md`, `CHANGELOG.md` — kept current with the customizations and permission docs.

## Status / history

- Committed as `3387b3c` "Add minimal transparent compact-bar status bar for zellij 0.45".
- Images for the README live in `assets/` (committed to the repo).