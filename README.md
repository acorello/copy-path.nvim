# copy-path.nvim

Copy current buffer path variants to clipboard with configurable keymaps and user commands.

![demo](https://raw.githubusercontent.com/hong4rc/copy-path.nvim/demo/demo.gif)

## Features

- **11 path kinds**: relative, full, filename, stem, extension, directory (full/relative), line reference (relative/full), GitHub permalink (with/without line)
- **Zero config** — works out of the box with sensible defaults
- **LazyVim compatible** — default keymaps avoid all LazyVim conflicts
- **`:CopyPath*` commands** — 11 user commands registered automatically
- **File tree support** — works from neo-tree, nvim-tree, and snacks explorer
- **Built-in picker** — Snacks, Telescope, fzf-lua, or `vim.ui.select` fallback
- **Visual mode** — line-aware kinds support visual selection ranges
- **GitHub permalinks** — copy shareable links with branch/commit and line numbers
- **which-key integration** — group labels registered when which-key is available
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
  "hong4rc/copy-path.nvim",
  event = "VeryLazy",
  opts = {},
}
```

## Configuration

All fields are optional. Unspecified values use defaults.

```lua
return {
  "hong4rc/copy-path.nvim",
  event = "VeryLazy",
  opts = {
    -- Show vim.notify() after each copy (default: true)
    notify = true,

    -- which-key group label, or false to disable (default: "copy path")
    which_key_group = "copy path",

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
| `:CopyPathGitHub` | GitHub permalink | `https://github.com/user/repo/blob/main/src/foo/Bar.tsx` |
| `:CopyPathGitHubLine` | GitHub + line | `https://github.com/user/repo/blob/main/src/foo/Bar.tsx#L42` |

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

Verifies Neovim version, clipboard provider, and optional dependencies (which-key, nvim-notify).

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

# Lint
luacheck lua/
```

## License

GPL-2.0 — same as the Linux kernel.
