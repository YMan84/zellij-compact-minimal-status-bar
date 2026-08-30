# ⚡ zj-status-bar ⚡

A minimal, transparent status bar plugin for [`zellij`](https://zellij.dev/), built on top of
the built-in `compact-bar` plugin (zellij `0.45.x`), repackaged and customized.

## What it looks like / does

A single-row status bar at the bottom of the screen that shows your open tabs as
colored pills, separated by solid `│` chips, with a transparent background so the
terminal shows through.

### Features (changes vs. the stock compact-bar)

#### Added / changed
- Transparent bar background (terminal shows through)
- Solid `│` chips between tab pills in place of powerline arrows
- Colored tab pills (kept from stock) on a transparent bar

#### Removed
- The `Zellij` label in the top-left corner
- The session-name / breadcrumb chip at the far left (tabs start flush)
- The `LOCKED` / `NORMAL` mode pill on the far right
- The `F1 Tooltip` pill on the far right (the tooltip feature itself still works)

## Requirements

- zellij `0.45.x` (the plugin binds the 0.45 plugin ABI)

## Installation

1. Build the wasm (see [Development](#development) — build inside the zellij source tree).
2. Copy the resulting `zj-status-bar.wasm` to your zellij plugins directory, e.g.:
   ```
   cp compact-bar.wasm ~/.config/zellij/plugins/zj-status-bar.wasm
   ```
3. In `~/.config/zellij/config.kdl`, point the `compact-bar` alias at it:
   ```kdl
   plugins {
       compact-bar location="file:~/.config/zellij/plugins/zj-status-bar.wasm"
   }
   ```
   (The layout pipeline loads the `compact-bar` alias at the bottom of the screen.)
4. Restart zellij.

### File-loaded plugin permissions (IMPORTANT)

A plugin loaded via `file:` is not treated as built-in, and this is the one thing that
causes the bar to be **completely invisible** if misconfigured.

In zellij, built-in plugins (`zellij:compact-bar`) are auto-granted every permission. A
`file:`-loaded plugin is not, and many events — notably `TabUpdate`, `ModeUpdate`, and
`PaneUpdate`, which the status bar entirely depends on to know what to draw — are gated
behind the `ReadApplicationState` permission. If those are denied, the plugin receives no
state and renders as a blank/transparent bar with no tabs.

Two things are therefore required:

1. **The code requests the permissions it needs.** `src/main.rs` calls `request_permission`
   at load time, requesting `ReadApplicationState`, `ChangeApplicationState`,
   `MessageAndLaunchOtherPlugins`, `RunActionsAsUser`, and `Reconfigure`. Without this call,
   a `file:`-loaded compact-bar silently gets nothing and is invisible.

2. **Grant permissions.** On first load zellij shows a permission prompt on the bar.
   This plugin sets itself **selectable on load** (and back to non-selectable once
   granted), so you can focus the bar pane (click it) and press `y` to accept. No
   command-line grant exists.

   Alternatively, pre-grant via `~/.cache/zellij/permissions.kdl` (e.g. to avoid the
   prompt or cover non-interactive setups):

```kdl
"/home/<your-user>/.config/zellij/plugins/zj-status-bar.wasm" {
    ReadApplicationState
    ChangeApplicationState
    RunActionsAsUser
    Reconfigure
    MessageAndLaunchOtherPlugins
}
```

One-liner to add/pre-grant it (checks for an existing block, appends only if missing):

```bash
P=~/.cache/zellij; F=$P/permissions.kdl; W='"/home/'$USER'/.config/zellij/plugins/zj-status-bar.wasm"'; B='{ ReadApplicationState ChangeApplicationState RunActionsAsUser Reconfigure MessageAndLaunchOtherPlugins }'
mkdir -p "$P"
if grep -q "$W" "$F" 2>/dev/null; then echo "already granted"; else { echo "$W $B"; } >> "$F"; echo "appended"; fi
```

**Why this is needed:** plugins that ship with zellij (`zellij:compact-bar`, `zellij:tab-bar`,
etc.) are granted these permissions by default — they're treated as trusted built-ins, so
they never prompt and just work. This plugin is loaded from a `file:`, so it is **not**
trusted by default and must be granted the same permissions explicitly.

> [!NOTE]
> `Reconfigure` is a special case: it is requested but zellij may log a `Reconfigure`
> `<command> denied` error once at load time. This happens because the tooltip keybind
> (`tooltip "F1"`) calls `reconfigure()` during `load()`, before the async permission reply
> is applied. It is harmless — the bar still renders — but it will appear in
> `/tmp/zellij-*/zellij-log/zellij.log`.

## Development

The plugin source lives in `src/`. Because the built-in zellij `compact-bar` is developed
inside the zellij repository, the plugin must be compiled against zellij's **in-tree**
`zellij-tile`/`zellij-tile-utils` crates (path deps), not the crates.io versions, to match the
plugin ABI your zellij binary expects.

1. Clone the zellij `v0.45.0` source:
   ```
   git clone --branch v0.45.0 https://github.com/zellij-org/zellij.git
   ```
2. Copy this project's `src/*.rs` over `default-plugins/compact-bar/src/` in that checkout.
3. Build (the workspace's `rust-toolchain.toml` pins `wasm32-wasip1`):
   ```
   cd zellij
   cargo build -p compact-bar --release --target wasm32-wasip1
   ```
4. The artifact is at `target/wasm32-wasip1/release/compact-bar.wasm`.

#### Why the stock compact-bar won't build this way

The stock compact-bar never calls `request_permission` because, as a built-in plugin, it
never needs to. When you load it via `file:` instead (as this project does), that built-in
shortcut no longer applies and the events it subscribes to get permission-denied — the bar
renders but with no tabs (invisible). Do **not** remove the `request_permission` call in
`src/main.rs`; it is what makes the file-loaded variant receive state.

> [!NOTE]
> A standalone `Cargo.toml` using `zellij-tile = "0.45"` from crates.io is included for
> reference, but the resulting wasm is not guaranteed to load in zellij 0.45.x. Build from
> the zellij source tree for a byte-compatible plugin.

## License

MIT