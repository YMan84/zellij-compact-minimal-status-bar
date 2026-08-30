# Changelog

## [0.45.0] - 2026-08-30

Rebuilt on the stock zellij `compact-bar` (v0.45.x) and customized.

### Added
- New project layout: plugin source repackaged at the crate root (`src/`), built from inside
  the zellij `v0.45.0` source tree for ABI compatibility.

### Changed
- Transparent bar background — the terminal shows through the status row.
- Colored tab pills separated by solid `│` chips instead of powerline arrows.
- Bar is selectable on first load so the file-loaded plugin's permission prompt can be
  accepted with `y` (focus the bar, then `y`); it returns to non-selectable once granted.

### Removed
- The `Zellij` label.
- The session-name / breadcrumb chip at the far left.
- The `LOCKED` / `NORMAL` mode pill on the far right.
- The `F1 Tooltip` pill on the far right (the tooltip action-bar still works).

### Fixed (vs. loading a stock-like plugin from a file)
- The plugin explicitly requests the permissions it requires. A `file:`-loaded plugin is not
  treated as built-in, so without `request_permission` it received no `TabUpdate` /
  `ModeUpdate` / `PaneUpdate` events and rendered as an invisible bar.