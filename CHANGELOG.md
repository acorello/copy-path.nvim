# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

## [0.1.0] - 2026-04-10

### Added

- Initial release
- 11 path kinds: relative, full, filename, stem, extension, dir_full, dir_rel, line, line_full, github, github_line
- `:CopyPath*` user commands (11 commands)
- Configurable keymaps with LazyVim-safe defaults
- Visual mode line range support for line-aware kinds
- GitHub/GitLab permalink generation
- File tree integration (neo-tree, nvim-tree, snacks explorer)
- Built-in picker (Snacks, Telescope, fzf-lua, vim.ui.select)
- which-key group integration
- `:checkhealth copy-path`
- "Copied:" prefix in notifications
