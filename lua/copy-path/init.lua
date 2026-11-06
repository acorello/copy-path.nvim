local M = {}
local config = require("copy-path.config")
local commands = require("copy-path.commands")
local keymaps_mod = require("copy-path.keymaps")
local git = require("copy-path.git")
local tree = require("copy-path.tree")
local picker_mod = require("copy-path.picker")

local cfg = {}

local line_kinds = { line = true, line_full = true, github_line = true }

local function line_ref(range)
  if range then
    local first, last = math.min(range[1], range[2]), math.max(range[1], range[2])
    return first == last and tostring(first) or (first .. "-" .. last)
  end
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start = vim.fn.line("v")
    local finish = vim.fn.line(".")
    if start > finish then
      start, finish = finish, start
    end
    if start == finish then
      return tostring(start)
    end
    return start .. "-" .. finish
  end
  return tostring(vim.fn.line("."))
end

local function github_line_fragment(range)
  return "#L" .. line_ref(range):gsub("-", "-L")
end

local function get_path(expand_str)
  local path = require("copy-path.path")
  local tree_path = tree.get_path()
  if expand_str == "%:." or expand_str == "%:.:h" then
    local full = tree_path or (not tree.is_tree() and vim.api.nvim_buf_get_name(0) or "")
    if full == "" then
      return ""
    end
    local relative = path.relative(full, cfg.root)
    return expand_str == "%:.:h" and vim.fn.fnamemodify(relative, ":h") or relative
  end
  if tree_path then
    if expand_str == "%:p" then
      return tree_path
    end
    if expand_str == "%:t" then
      return vim.fn.fnamemodify(tree_path, ":t")
    end
    if expand_str == "%:t:r" then
      return vim.fn.fnamemodify(tree_path, ":t:r")
    end
    if expand_str == "%:e" then
      return vim.fn.fnamemodify(tree_path, ":e")
    end
    if expand_str == "%:p:h" then
      return vim.fn.fnamemodify(tree_path, ":p:h")
    end
    return vim.fn.fnamemodify(tree_path, ":.")
  end
  -- In a tree buffer but no file selected — don't fall back to buffer name
  if tree.is_tree() then
    return ""
  end
  return vim.fn.expand(expand_str)
end

local resolvers = {
  relative = {
    fn = function()
      return get_path("%:.")
    end,
    label = "Relative path",
  },
  full = {
    fn = function()
      return get_path("%:p")
    end,
    label = "Full path",
  },
  filename = {
    fn = function()
      return get_path("%:t")
    end,
    label = "File name",
  },
  stem = {
    fn = function()
      return get_path("%:t:r")
    end,
    label = "File stem",
  },
  extension = {
    fn = function()
      return get_path("%:e")
    end,
    label = "Extension",
  },
  dir_full = {
    fn = function()
      return get_path("%:p:h")
    end,
    label = "Full dir",
  },
  dir_rel = {
    fn = function()
      return get_path("%:.:h")
    end,
    label = "Relative dir",
  },
  line = {
    fn = function(range)
      local p = get_path("%:.")
      return p ~= "" and (p .. ":" .. line_ref(range)) or ""
    end,
    label = "Relative + line",
  },
  line_full = {
    fn = function(range)
      local p = get_path("%:p")
      return p ~= "" and (p .. ":" .. line_ref(range)) or ""
    end,
    label = "Full + line",
  },
  github = {
    fn = function()
      local p = get_path("%:p")
      return p ~= "" and git.permalink(p) or ""
    end,
    label = "GitHub URL",
  },
  github_line = {
    fn = function(range)
      local p = get_path("%:p")
      if p == "" then
        return ""
      end
      local url = git.permalink(p)
      return url ~= "" and (url .. github_line_fragment(range)) or ""
    end,
    label = "GitHub + line",
  },
}

local function _copy(value, label)
  if value == nil or value == "" then
    return
  end
  vim.fn.setreg("+", value)
  if cfg.notify then
    vim.notify(label .. ": " .. value, vim.log.levels.INFO, { title = "Copied" })
  end
end

function M.setup(opts)
  if vim.g.copy_path_setup_done then
    return
  end

  cfg = config.resolve(opts)

  local errors = config.validate(cfg)
  if #errors > 0 then
    for _, e in ipairs(errors) do
      vim.notify("copy-path: " .. e, vim.log.levels.WARN)
    end
    cfg = config.resolve({})
  end

  commands.register(cfg.command_prefix, M.copy)
  keymaps_mod.group(cfg.keymaps, cfg.which_key_group)
  keymaps_mod.register(cfg.keymaps, M.copy, resolvers, line_kinds)

  if cfg.picker_keymap then
    vim.keymap.set("n", cfg.picker_keymap, function()
      M.pick()
    end, { desc = "Copy path (picker)" })
  end

  vim.g.copy_path_setup_done = true
end

function M.copy(kind, range)
  local r = resolvers[kind]
  if not r then
    error("copy-path: unknown kind '" .. tostring(kind) .. "'")
  end
  _copy(r.fn(range), r.label)
end

function M.get(kind)
  local r = resolvers[kind]
  if not r then
    error("copy-path: unknown kind '" .. tostring(kind) .. "'")
  end
  return r.fn()
end

function M.pick()
  picker_mod.open(resolvers, function(_, value, label)
    _copy(value, label)
  end, cfg.picker)
end

function M.resolvers()
  return resolvers
end

return M
