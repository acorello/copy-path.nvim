# copy-path.nvim

Maintained fork: [acorello/copy-path.nvim](https://github.com/acorello/copy-path.nvim),
based on [hong4rc/copy-path.nvim](https://github.com/hong4rc/copy-path.nvim).

[![CI](https://github.com/hong4rc/copy-path.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/hong4rc/copy-path.nvim/actions/workflows/ci.yml)
[![License: GPL-2.0](https://img.shields.io/github/license/hong4rc/copy-path.nvim)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.9+-blueviolet?logo=neovim&logoColor=white)](https://neovim.io)

Copy buffer paths to clipboard – 11 path kinds, GitHub permalinks, file tree support, built-in picker. Zero config, LazyVim compatible.

![demo](https://raw.githubusercontent.com/hong4rc/copy-path.nvim/demo/demo.gif)

## Features

- **11 path kinds**: relative, full, filename, stem, extension, directory (full/relative), line reference (relative/full), GitHub permalink (with/without line)
- **Zero config** — works out of the box with sensible defaults
- **LazyVim compatible** – disable individual default keymaps to avoid local conflicts
- **`:CopyPath*` commands** — 11 user commands registered automatically
- **File tree support** — works from neo-tree, nvim-tree, and snacks explorer
- **Built-in picker** — Snacks, Telescope, fzf-lua, or `vim.ui.select` fallback
- **Visual mode** — line-aware kinds support visual selection ranges
- **GitHub permalinks** – copy immutable commit links with optional line numbers
- **which-key integration** – opt-in shared-prefix group labels
- **Notification support** — works with nvim-notify, snacks.nvim notifier, or plain `vim.notify`
- **Health check** — `:checkhealth copy-path`

## Requirements

- Neovim >= 0.9
- Clipboard provider (pbcopy on macOS, xclip/wl-clipboard on Linux)
- Git (for GitHub permalink feature)

## Installation

### lazy.nvim / LazyVim (zero config)

```lua
-- lua/plugins/copy-path.lua
return {
  "acorello/copy-path.nvim",
  event = "VeryLazy",
  opts = {},
}
```

## Configuration

All fields are optional. Unspecified values use defaults.

```lua
return {
  "acorello/copy-path.nvim",
  event = "VeryLazy",
  opts = {
    -- Show vim.notify() after each copy (default: true)
    notify = true,

    -- Opt-in which-key label for a shared mapping prefix (default: false).
    -- This renames that prefix's group; leave disabled for LazyVim's file group.
    which_key_group = false,

    -- Optional function(path, bufnr) returning a project root, or nil for detection.
    root = false,

    -- Prefix for :CopyPath* commands, or false to disable (default: "CopyPath")
    command_prefix = "CopyPath",

    -- Picker backend: "auto", "snacks", "telescope", "fzf_lua", or false
    -- "auto" detects in order: snacks → telescope → fzf_lua → vim.ui.select
    picker = "auto",

    -- Keymap to open the picker, or false to disable (default: "<leader>fP")
    picker_keymap = "<leader>fP",

    -- Keymap bindings per kind. Set to false to disable a keymap.
    keymaps = {
      relative    = "<leader>fy",     -- src/foo/Bar.tsx
      full        = "<leader>fY",     -- /home/user/project/src/foo/Bar.tsx
      filename    = "<leader>fN",     -- Bar.tsx
      line        = "<leader>fl",     -- src/foo/Bar.tsx:42
      github_line = "<leader>fG",     -- https://github.com/.../Bar.tsx#L42
      line_full   = false,            -- disabled by default
      stem        = false,            -- disabled by default
      extension   = false,            -- disabled by default
      dir_full    = false,            -- disabled by default
      dir_rel     = false,            -- disabled by default
      github      = false,            -- disabled by default
    },
  },
}
```

### Enable all keymaps

```lua
opts = {
  keymaps = {
    relative    = "<leader>fy",
    full        = "<leader>fY",
    filename    = "<leader>fN",
    stem        = "<leader>fs",
    extension   = "<leader>fx",
    dir_full    = "<leader>fD",
    dir_rel     = "<leader>fd",
    line        = "<leader>fl",
    line_full   = "<leader>fL",
    github      = "<leader>fg",
    github_line = "<leader>fG",
  },
}
```

### Custom command prefix

```lua
opts = { command_prefix = "Yank" }
-- Creates :Yank, :YankFull, :YankName, :YankGitHub, etc.
```

## Path and Git reference behaviour

Relative paths use `root(path, bufnr)` when configured, otherwise the selected
file's Git root, otherwise the nearest ancestor containing `package.json`,
`pyproject.toml`, `go.mod` or `Cargo.toml`. Without a project root, paths are
relative to cwd when contained there, and absolute otherwise. A root must contain
the selected file; unrelated roots fall back to the same cwd/absolute policy.
An unnamed buffer or an explorer directory selection produces no copy.

LazyVim users can opt into its LSP-aware root policy without making it a plugin
dependency. In a lazy.nvim spec's `opts`:

```lua
root = function(path, bufnr)
  if vim.api.nvim_buf_get_name(bufnr) == path then
    return LazyVim.root.get({ buf = bufnr })
  end
  -- Explorer selections use the plugin's file-based detection.
end,
```

Git metadata is resolved afresh from the selected file's repository, independent
of cwd. URLs use `origin` and the current commit SHA, including in detached HEAD;
HTTP(S) credentials are removed and file paths are percent-encoded. HTTPS,
HTTP, `git@host:path` and `ssh://user@host/path` remotes are supported. Other
remote formats, repositories without a commit/origin, and non-repository files
produce no URL. URLs use GitHub-style `/blob/` paths; other hosts may differ.
Links refer to committed content, not unsaved or uncommitted changes.

Copying writes only the `+` register; it does not explicitly overwrite the
unnamed register. Neovim's `clipboard` option still controls normal register
aliasing. Picker confirmation copies the value displayed when opened, even if
the buffer or selection subsequently changes.

## Commands

| Command | What it copies | Example |
|---|---|---|
| `:CopyPath` | Relative path | `src/foo/Bar.tsx` |
| `:CopyPathFull` | Full path | `/home/user/project/src/foo/Bar.tsx` |
| `:CopyPathName` | File name | `Bar.tsx` |
| `:CopyPathStem` | File stem | `Bar` |
| `:CopyPathExt` | Extension | `tsx` |
| `:CopyPathDir` | Full directory | `/home/user/project/src/foo` |
| `:CopyPathDirRel` | Relative directory | `src/foo` |
| `:CopyPathLine` | Relative + line | `src/foo/Bar.tsx:42` |
| `:CopyPathLineFull` | Full + line | `/home/user/project/src/foo/Bar.tsx:42` |
| `:CopyPathGitHub` | GitHub permalink | `https://github.com/user/repo/blob/<commit-sha>/src/foo/Bar.tsx` |
| `:CopyPathGitHubLine` | GitHub + line | `https://github.com/user/repo/blob/<commit-sha>/src/foo/Bar.tsx#L42` |

Line-aware commands accept Ex addresses: `:42CopyPathLine`,
`:10,25CopyPathLineFull` and `:'<,'>CopyPathGitHubLine`. Without an explicit
address they use the current cursor or live visual selection. Single-line
selections use `:42` or `#L42`; ranges use `:10-25` or `#L10-L25`.

## Keymaps

Default keymaps (normal mode):

| Keymap | Action | Command |
|---|---|---|
| `<leader>fy` | Copy relative path | `:CopyPath` |
| `<leader>fY` | Copy full path | `:CopyPathFull` |
| `<leader>fN` | Copy file name | `:CopyPathName` |
| `<leader>fl` | Copy relative + line | `:CopyPathLine` |
| `<leader>fG` | Copy GitHub + line | `:CopyPathGitHubLine` |
| `<leader>fP` | Open picker | all kinds |

Set any keymap to `false` to disable it. Override with any valid lhs string.

Line-aware keymaps (`line`, `line_full`, `github_line`) support **visual mode** — selecting a range copies `file:3-7` or `#L3-L7`.

## File Tree Support

Copy paths directly from your file explorer without opening the file:

- **neo-tree** — cursor on a file node, run any `:CopyPath*` command
- **nvim-tree** — same behavior
- **snacks explorer** — same behavior

## Picker

Press `<leader>fP` (or your configured keymap) to open a picker showing all path kinds with their current values. Select one to copy it.

Supported backends (auto-detected in order):
1. [snacks.nvim](https://github.com/folke/snacks.nvim)
2. [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
3. [fzf-lua](https://github.com/ibhagwan/fzf-lua)
4. `vim.ui.select` (builtin fallback)

## Health Check

```vim
:checkhealth copy-path
```

See `:checkhealth copy-path` for environment checks.

## Lua API

```lua
local cp = require("copy-path")

cp.setup({})              -- Initialize (call once)
cp.copy("relative")       -- Copy to clipboard + notify
cp.get("full")            -- Get value without copying
cp.pick()                 -- Open picker for all kinds
cp.resolvers()            -- Get resolver table for custom pickers
```

### Custom picker example

```lua
local items = {}
for kind, r in pairs(require("copy-path").resolvers()) do
  table.insert(items, { kind = kind, value = r.fn(), label = r.label })
end
```

## Contributing

```bash
# Run tests
nvim --headless -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

# The optional Snacks integration suite uses an installed
# ~/.local/share/nvim/lazy/snacks.nvim and is skipped when absent.
# Clipboard writes are intercepted by regression tests; no system clipboard access.

# Lint
luacheck lua/
```

## License

GPL-2.0 — same as the Linux kernel.
