# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

smm.nvim is a Neovim plugin that connects to the Spotify Web API to display and control Spotify playback from inside Neovim. It does not stream audio — it remote-controls whatever Spotify client is already open on the user's devices.

Dependencies: `nvim-lua/plenary.nvim` (HTTP, async), `nvim-telescope/telescope.nvim` (search UI).

## Formatting

This project uses [StyLua](https://github.com/JohnnyMorganz/StyLua). Run it with:

```
stylua .
```

Key style rules (from `.stylua.toml`): 2-space indent, single quotes preferred, no call parentheses, 160-column width, Unix line endings.

## Architecture

### Entry points

- `plugin/smm.lua` — Neovim plugin loader; calls `require('smm').setup(config)`
- `lua/smm/init.lua` — `M.setup()` wires together the three subsystems: `spotify`, `playback`, `search`
- `lua/smm/commands.lua` — registers the `:Spotify` user command; routes sub-commands to `playback` module functions

### Subsystems

**`lua/smm/spotify/`** — Spotify authentication and API

- `auth/init.lua` — OAuth PKCE flow: opens browser, starts a local socket server to receive the callback, exchanges code for tokens
- `auth/sock.lua` — temporary TCP server that captures the OAuth redirect
- `auth/requests.lua` — token exchange and refresh HTTP calls (synchronous, via `utils/api_sync.lua`)
- `token.lua` — persists the refresh token to `$HOME/.local/state/nvim/spotify/refresh_token` as AES-256-CBC ciphertext (via openssl CLI)
- `requests.lua` — all Spotify Web API calls (GET/PUT/POST/DELETE); each function checks token scope, auto-refreshes the access token if it expires within 30 s, and wraps the call in retry logic for 5xx/429 responses
- `init.lua` — `M.authenticate()` orchestrates token load-or-OAuth, then checks/updates the account type (free vs. premium)

**`lua/smm/playback/`** — the running playback session

- `manager.lua` — owns the session state (`playback_info`, the timer). `start_session()` creates a `Timer` and wires it to handler closures. `stop_session()` tears everything down.
- `timer.lua` — `SMM_PlaybackTimer` wraps `vim.uv.new_timer()`. Every `timer_update_interval` ms it increments `current_pos` and calls `update`; every `timer_sync_interval` ms it calls `sync` (an async Spotify API fetch) to re-anchor the position.
- `handlers.lua` — factory functions (e.g. `create_sync_handler`, `create_pause_handler`) that return closures. The manager calls these factories once and stores the results. Each handler calls a function in `spotify/requests.lua` and mutates playback state on success.
- `init.lua` — public API consumed by `commands.lua`: `toggle_window`, `pause`, `resume`, `play`, `next`, `previous`, etc. Also owns the `SMM_UI_Window` instance and extmark-based clickable song links.
- `utils.lua` — formats a `SMM_PlaybackInfo` table into lines for the floating window

**`lua/smm/search/`** — Telescope pickers

- `media.lua` — parses Spotify search results into model objects, presents a Telescope picker, calls back with the selected item
- `device.lua` — same pattern for device selection

**`lua/smm/models/`** — data model classes

- `base.lua` — `SMM_BaseMedia` base class with `id`, `name`, `uri`, `external_urls`; `get_spotify_url()` reads `external_urls.spotify`
- `track.lua`, `album.lua`, `artist.lua`, `playlist.lua`, `device.lua` — inherit from `BaseMedia` (or define standalone) and add type-specific fields
- `ui/interface.lua` — `SMM_UI_Window` class: creates/updates/closes a `nvim_open_win` floating window; applies Spotify-green highlight
- `ui/utils.lua` — computes `row`/`col` for each of the four corner positions and `Center`

**`lua/smm/utils/`** — shared utilities

- `api_async.lua` — thin wrapper around `plenary.curl` for async GET/POST/PUT/DELETE; attaches `Authorization: Bearer` header and parses JSON responses
- `api_sync.lua` — synchronous version used only by auth token exchange
- `crypto.lua` — AES-256-CBC encrypt/decrypt via the `openssl` CLI (PBKDF2 key from machine-id + `$HOME`); also PKCE helpers (SHA-256, URL-safe base64)
- `encoding.lua` — URL query-string and JSON encoding helpers
- `logger.lua` — wraps `vim.notify` with debug/info/warn/error levels; enabled only when `config.debug = true`
- `os.lua` — `open_browser(url)` cross-platform helper

### Data flow for a playback update

1. `Timer` fires every `timer_update_interval` ms → calls `update_handler(current_pos)`
2. `update_handler` (from `handlers.create_update_handler`) increments `playback_info.progress_ms`, calls `on_interface_update` → `playback.update_playback_window` re-renders the float
3. Every `timer_sync_interval` ms → `sync_handler` fires `spotify/requests.get_playback_state` (async) → result parsed by `playback/utils.get_playbackinfo` → `manager.playback_info` updated → timer re-anchored

### Token security model

The refresh token is encrypted before writing to disk. The AES-256 key is derived from a SHA-256 hash of `"smm.nvim:v1:" + machine_id + ":" + $HOME`. Legacy plaintext tokens are migrated automatically on first load.
